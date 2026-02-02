#!/usr/bin/env bash
# Publish workflow: discover posts from Obsidian vault marked as Published
set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Dry-run mode (set by --dry-run argument)
DRY_RUN=false

# Non-interactive mode flags
SELECT_ALL=false
SELECT_POST=""
AUTO_CONFIRM=false

# Retry configuration
MAX_RETRY_ATTEMPTS=3

# Global arrays for post data
declare -a POST_FILES=()
declare -a POST_TITLES=()
declare -a POST_DATES=()
declare -a POST_DISPLAY=()
declare -a POST_IS_UPDATE=()
declare -a SELECTED_FILES=()

# Tracking arrays for rollback
declare -a CREATED_FILES=()
declare -a CREATED_DIRS=()

# Post metadata for commits (populated during processing)
declare -a PROCESSED_SLUGS=()
declare -a PROCESSED_TITLES=()
declare -a PROCESSED_YEARS=()
declare -a PROCESSED_IS_UPDATE=()

# ============================================================================
# Argument Parsing
# ============================================================================

print_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Publish blog posts from Obsidian vault to the blog repository.

Options:
  --dry-run         Preview what would be published without making changes
  --all, -a         Select all discovered posts (non-interactive)
  --post, -p SLUG   Select a specific post by slug or filename
  --yes, -y         Auto-confirm all prompts (validation, push)
  --help, -h        Show this help message

Interactive mode (default):
  Without --all or --post, uses gum/fzf/numbered selection to choose posts.
  This requires a TTY and won't work in Claude Code.

Non-interactive mode (for Claude Code):
  $0 --all --yes                    # Publish all posts
  $0 --post hello-world --yes       # Publish specific post
  $0 --dry-run --all                # Preview all posts

Examples:
  $0                          # Interactive selection
  $0 --dry-run                # Preview what would be published
  $0 --post my-post --yes     # Publish 'my-post' non-interactively
  $0 --all --yes              # Publish all posts non-interactively
EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --all|-a)
                SELECT_ALL=true
                shift
                ;;
            --post|-p)
                SELECT_POST="$2"
                shift 2
                ;;
            --yes|-y)
                AUTO_CONFIRM=true
                shift
                ;;
            --help|-h)
                print_help
                ;;
            *)
                shift
                ;;
        esac
    done
}

# ============================================================================
# Rollback Functions
# ============================================================================

track_created_file() {
    # Track a file created during publishing for potential rollback
    local file="$1"
    CREATED_FILES+=("$file")
}

track_created_dir() {
    # Track a directory created during publishing for potential rollback
    local dir="$1"
    CREATED_DIRS+=("$dir")
}

rollback_changes() {
    # Remove all created files and directories in reverse order
    echo ""
    echo -e "${YELLOW}Rolling back changes...${RESET}"

    # Remove files first
    for ((i=${#CREATED_FILES[@]}-1; i>=0; i--)); do
        local file="${CREATED_FILES[$i]}"
        if [[ -f "$file" ]]; then
            rm -f "$file"
            echo -e "  ${RED}Removed:${RESET} $file"
        fi
    done

    # Remove directories (only if empty)
    for ((i=${#CREATED_DIRS[@]}-1; i>=0; i--)); do
        local dir="${CREATED_DIRS[$i]}"
        if [[ -d "$dir" ]]; then
            # Only remove if directory is empty
            if [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
                rmdir "$dir" 2>/dev/null && echo -e "  ${RED}Removed:${RESET} $dir"
            fi
        fi
    done

    echo ""
    echo -e "${RED}Publishing failed after $MAX_RETRY_ATTEMPTS attempts. All changes rolled back.${RESET}"
    echo -e "${YELLOW}Your Obsidian files are unchanged. Fix issues and try again.${RESET}"
}

# ============================================================================
# Lint and Build Functions
# ============================================================================

run_lint() {
    # Run npm lint and return exit code
    echo ""
    echo -e "${CYAN}Running lint check...${RESET}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  [DRY-RUN] Would run: npm run lint"
        return 0
    fi

    local output
    local exit_code=0

    if output=$(npm run lint 2>&1); then
        echo -e "${GREEN}Lint passed.${RESET}"
        return 0
    else
        exit_code=$?
        echo -e "${RED}Lint failed:${RESET}"
        echo "$output"
        return $exit_code
    fi
}

run_build() {
    # Run npm build and return exit code
    echo ""
    echo -e "${CYAN}Running build verification...${RESET}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  [DRY-RUN] Would run: npm run build"
        return 0
    fi

    local output
    local exit_code=0

    if output=$(npm run build 2>&1); then
        echo -e "${GREEN}Build passed. Ready to push.${RESET}"
        return 0
    else
        exit_code=$?
        echo -e "${RED}Build failed:${RESET}"
        echo "$output"
        return $exit_code
    fi
}

run_lint_with_retry() {
    # Run lint with retry logic and rollback on persistent failure
    local attempt=1

    while [[ $attempt -le $MAX_RETRY_ATTEMPTS ]]; do
        if run_lint; then
            return 0
        fi

        if [[ $attempt -lt $MAX_RETRY_ATTEMPTS ]]; then
            echo ""
            echo -e "${YELLOW}Lint attempt $attempt of $MAX_RETRY_ATTEMPTS failed.${RESET}"
            # Output special marker for Claude hook
            echo "PUBLISH_LINT_FAILED" >&2
            # Wait briefly for hook to potentially fix
            sleep 1
            echo -e "${CYAN}Retrying lint...${RESET}"
        fi

        ((++attempt))
    done

    # All attempts failed - rollback
    rollback_changes
    exit $EXIT_ERROR
}

run_build_with_retry() {
    # Run build with retry logic and rollback on persistent failure
    local attempt=1

    while [[ $attempt -le $MAX_RETRY_ATTEMPTS ]]; do
        if run_build; then
            return 0
        fi

        if [[ $attempt -lt $MAX_RETRY_ATTEMPTS ]]; then
            echo ""
            echo -e "${YELLOW}Build attempt $attempt of $MAX_RETRY_ATTEMPTS failed.${RESET}"
            # Output special marker for Claude hook
            echo "PUBLISH_BUILD_FAILED" >&2
            # Wait briefly for hook to potentially fix
            sleep 1
            echo -e "${CYAN}Retrying build...${RESET}"
        fi

        ((++attempt))
    done

    # All attempts failed - rollback
    rollback_changes
    exit $EXIT_ERROR
}

# ============================================================================
# Validation
# ============================================================================

# Associative array to store validation errors by file path
declare -A VALIDATION_ERRORS

normalize_frontmatter() {
    # Normalize frontmatter types for Astro schema compatibility
    # Takes content as input, returns normalized content
    local content="$1"

    # Get author from config, fallback to site default
    local author
    author=$(get_author_from_config)
    if [[ -z "$author" ]]; then
        author="Justin Carlson"  # Default from site config
    fi

    # Replace author array with config value
    # Pattern matches: author:\n  - "[[Me]]" or author:\n  - [[Me]] or author:\n  - "Name"
    content=$(echo "$content" | perl -0777 -pe "s/^author:\s*\n\s*-\s*.*\$/author: \"$author\"/m")

    # Remove empty heroImage lines (heroImage: followed by whitespace and newline only)
    content=$(echo "$content" | perl -pe 's/^heroImage:[ \t]*\n//m')

    # Remove empty heroImageAlt lines
    content=$(echo "$content" | perl -pe 's/^heroImageAlt:[ \t]*\n//m')

    # Remove empty heroImageCaption lines
    content=$(echo "$content" | perl -pe 's/^heroImageCaption:[ \t]*\n//m')

    echo "$content"
}

validate_selected_posts() {
    # Validate all selected posts, collecting all errors (not fail-fast)
    echo ""
    echo -e "${CYAN}Validating selected posts...${RESET}"

    local valid_files=()
    local invalid_files=()
    local all_errors=""

    for file in "${SELECTED_FILES[@]}"; do
        local errors
        local filename
        filename=$(basename "$file")

        if errors=$(validate_frontmatter "$file"); then
            valid_files+=("$file")
        else
            invalid_files+=("$file")
            all_errors+="${YELLOW}$filename:${RESET}\n"
            while IFS= read -r error; do
                all_errors+="  ${RED}- $error${RESET}\n"
            done <<< "$errors"
            all_errors+="\n"
        fi
    done

    # Display all errors at once
    if [[ ${#invalid_files[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Validation errors found:${RESET}"
        echo ""
        echo -e "$all_errors"
    fi

    # Handle partial valid scenario
    if [[ ${#invalid_files[@]} -gt 0 && ${#valid_files[@]} -gt 0 ]]; then
        echo -e "${YELLOW}${#valid_files[@]} of ${#SELECTED_FILES[@]} posts are valid.${RESET}"

        if [[ "$DRY_RUN" == "true" ]]; then
            # Auto-continue in dry-run mode
            echo -e "${CYAN}Dry run: auto-continuing with valid posts${RESET}"
        elif [[ "$AUTO_CONFIRM" == "true" ]]; then
            # Auto-continue in non-interactive mode
            echo -e "${CYAN}Auto-continuing with valid posts (--yes)${RESET}"
        else
            read -rp "Publish the valid ones? [Y/n] " response

            if [[ "$response" =~ ^[Nn] ]]; then
                echo ""
                echo -e "${YELLOW}Cancelled. Fix validation errors and try again.${RESET}"
                exit $EXIT_SUCCESS
            fi
        fi

        # Continue with only valid files
        SELECTED_FILES=("${valid_files[@]}")
        echo ""
        echo -e "${GREEN}Continuing with ${#SELECTED_FILES[@]} valid post(s)${RESET}"
    elif [[ ${#invalid_files[@]} -gt 0 && ${#valid_files[@]} -eq 0 ]]; then
        echo -e "${RED}No valid posts to publish. Fix validation errors and try again.${RESET}"
        exit $EXIT_ERROR
    else
        echo -e "${GREEN}All ${#SELECTED_FILES[@]} post(s) passed validation${RESET}"
    fi
}

# ============================================================================
# Post Discovery
# ============================================================================

get_existing_post_path() {
    # Find if a post with this slug already exists in blog directory
    local slug="$1"
    local pub_date="$2"  # Format: YYYY-MM-DD or full datetime

    # Extract year from pub_date
    local year="${pub_date:0:4}"

    # Check if file exists in year directory
    local existing_path="${BLOG_DIR}/${year}/${slug}.md"
    if [[ -f "$existing_path" ]]; then
        echo "$existing_path"
    fi
}

extract_content_body() {
    # Extract content after frontmatter (everything after second ---)
    local file="$1"

    # Skip until after second ---, then print rest
    awk 'BEGIN{count=0} /^---$/{count++; if(count==2){found=1; next}} found{print}' "$file"
}

posts_are_identical() {
    # Compare Obsidian post content with existing blog post
    # Returns 0 if identical (no update needed), 1 if different (needs update)
    #
    # Compares:
    #   - Content body (after frontmatter)
    #   - Key frontmatter: title, description, pubDatetime
    #
    # Ignores:
    #   - author field (gets transformed from [[Me]] to plain name)
    #   - Empty fields that get removed
    #   - Field ordering

    local obsidian_file="$1"
    local blog_file="$2"

    # Compare content bodies
    local obsidian_body blog_body
    obsidian_body=$(extract_content_body "$obsidian_file")
    blog_body=$(extract_content_body "$blog_file")

    if [[ "$obsidian_body" != "$blog_body" ]]; then
        return 1  # Different content
    fi

    # Compare key frontmatter fields
    local fields=("title" "description" "pubDatetime" "heroImage" "heroImageAlt" "heroImageCaption")
    for field in "${fields[@]}"; do
        local obsidian_val blog_val
        obsidian_val=$(get_frontmatter_field "$obsidian_file" "$field")
        blog_val=$(get_frontmatter_field "$blog_file" "$field")

        if [[ "$obsidian_val" != "$blog_val" ]]; then
            return 1  # Different frontmatter
        fi
    done

    return 0  # Identical
}

discover_posts() {
    echo ""
    echo -e "${CYAN}Searching for posts...${RESET}"

    # Find all markdown files with draft: false
    # The pattern matches YAML: draft: false (with optional whitespace)
    local found_files=()

    while IFS= read -r -d '' file; do
        # Check if file contains draft: false
        # Using perl for pattern matching: draft:\s*false
        if perl -0777 -ne 'exit(!/draft:\s*false/i)' "$file" 2>/dev/null; then
            found_files+=("$file")
        fi
    done < <(find "$VAULT_PATH" -name "*.md" -type f -print0 2>/dev/null)

    if [[ ${#found_files[@]} -eq 0 ]]; then
        return
    fi

    echo -e "Found ${GREEN}${#found_files[@]}${RESET} post(s) with draft: false"
    echo ""

    # Process each found file
    for file in "${found_files[@]}"; do
        local title
        local pub_date
        local filename
        local slug
        local existing_path
        local is_update="false"

        # Extract metadata
        title=$(extract_frontmatter_value "$file" "title")
        pub_date=$(extract_frontmatter_value "$file" "pubDatetime")

        # Fallback: use filename as title if not set
        filename=$(basename "$file")
        if [[ -z "$title" ]]; then
            title="${filename%.md}"
        fi

        # Generate slug from filename
        slug=$(slugify "$filename")

        # Check if already published
        existing_path=$(get_existing_post_path "$slug" "$pub_date")

        if [[ -n "$existing_path" ]]; then
            # File exists - check if identical
            if posts_are_identical "$file" "$existing_path"; then
                # Identical - skip this post
                continue
            else
                # Different - mark as update
                is_update="true"
            fi
        fi

        # Format date for display (extract YYYY-MM-DD)
        local display_date="${pub_date:0:10}"
        if [[ -z "$display_date" || "$display_date" == "null" ]]; then
            display_date="(no date)"
        fi

        # Add to arrays
        POST_FILES+=("$file")
        POST_TITLES+=("$title")
        POST_DATES+=("$pub_date")
        POST_IS_UPDATE+=("$is_update")

        # Create display string
        local display="$title - $display_date"
        if [[ "$is_update" == "true" ]]; then
            display="$display (update)"
        fi
        POST_DISPLAY+=("$display")
    done

    # Sort by date descending (newest first)
    # Create array of "date|index" pairs, sort, then reorder
    if [[ ${#POST_FILES[@]} -gt 1 ]]; then
        local sorted_indices=()
        local date_index_pairs=()

        for i in "${!POST_DATES[@]}"; do
            date_index_pairs+=("${POST_DATES[$i]}|$i")
        done

        # Sort descending by date
        mapfile -t sorted_pairs < <(printf '%s\n' "${date_index_pairs[@]}" | sort -t'|' -k1 -r)

        # Extract sorted indices
        for pair in "${sorted_pairs[@]}"; do
            sorted_indices+=("${pair##*|}")
        done

        # Reorder all arrays
        local new_files=() new_titles=() new_dates=() new_display=() new_updates=()
        for idx in "${sorted_indices[@]}"; do
            new_files+=("${POST_FILES[$idx]}")
            new_titles+=("${POST_TITLES[$idx]}")
            new_dates+=("${POST_DATES[$idx]}")
            new_display+=("${POST_DISPLAY[$idx]}")
            new_updates+=("${POST_IS_UPDATE[$idx]}")
        done

        POST_FILES=("${new_files[@]}")
        POST_TITLES=("${new_titles[@]}")
        POST_DATES=("${new_dates[@]}")
        POST_DISPLAY=("${new_display[@]}")
        POST_IS_UPDATE=("${new_updates[@]}")
    fi
}

# ============================================================================
# Interactive Selection
# ============================================================================

select_posts_gum() {
    # Use gum for checkbox-style multi-select
    local selected

    # Build display options
    selected=$(printf '%s\n' "${POST_DISPLAY[@]}" | gum choose --no-limit --header="Select posts to publish (space to toggle, enter to confirm):")

    if [[ -z "$selected" ]]; then
        return 1
    fi

    # Map selected display strings back to file paths
    while IFS= read -r display_line; do
        for i in "${!POST_DISPLAY[@]}"; do
            if [[ "${POST_DISPLAY[$i]}" == "$display_line" ]]; then
                SELECTED_FILES+=("${POST_FILES[$i]}")
                break
            fi
        done
    done <<< "$selected"

    return 0
}

select_posts_fzf() {
    # Fallback to fzf for multi-select
    local selected

    selected=$(printf '%s\n' "${POST_DISPLAY[@]}" | fzf --multi --header="Select posts (TAB to toggle, ENTER to confirm)")

    if [[ -z "$selected" ]]; then
        return 1
    fi

    # Map selected display strings back to file paths
    while IFS= read -r display_line; do
        for i in "${!POST_DISPLAY[@]}"; do
            if [[ "${POST_DISPLAY[$i]}" == "$display_line" ]]; then
                SELECTED_FILES+=("${POST_FILES[$i]}")
                break
            fi
        done
    done <<< "$selected"

    return 0
}

select_posts_numbered() {
    # Fallback to numbered list selection
    echo "Available posts:"
    echo ""

    for i in "${!POST_DISPLAY[@]}"; do
        echo "  $((i + 1)). ${POST_DISPLAY[$i]}"
    done

    echo ""
    echo "Enter post numbers to publish (comma-separated, e.g., 1,3,5)"
    echo "Or 'all' to publish all, 'q' to cancel"
    read -rp "> " selection

    if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
        return 1
    fi

    if [[ "$selection" == "all" || "$selection" == "ALL" ]]; then
        SELECTED_FILES=("${POST_FILES[@]}")
        return 0
    fi

    # Parse comma-separated numbers
    IFS=',' read -ra nums <<< "$selection"
    for num in "${nums[@]}"; do
        # Trim whitespace
        num=$(echo "$num" | tr -d ' ')
        if [[ "$num" =~ ^[0-9]+$ ]]; then
            local idx=$((num - 1))
            if [[ $idx -ge 0 && $idx -lt ${#POST_FILES[@]} ]]; then
                SELECTED_FILES+=("${POST_FILES[$idx]}")
            else
                echo -e "${YELLOW}Warning: Invalid number $num (skipping)${RESET}"
            fi
        fi
    done

    if [[ ${#SELECTED_FILES[@]} -eq 0 ]]; then
        return 1
    fi

    return 0
}

select_posts() {
    echo "Select posts to publish:"
    echo ""

    # Try selection methods in order of preference
    if command -v gum &>/dev/null; then
        if select_posts_gum; then
            return 0
        fi
    elif command -v fzf &>/dev/null; then
        if select_posts_fzf; then
            return 0
        fi
    else
        if select_posts_numbered; then
            return 0
        fi
    fi

    return 1
}

# ============================================================================
# Image Handling
# ============================================================================

extract_images() {
    # Extract image references from post content
    # Returns array of image filenames (local images only)
    local content="$1"
    local images=()

    # Find wiki-style images: ![[image.png]] or ![[image.png|alt text]]
    while IFS= read -r match; do
        if [[ -n "$match" ]]; then
            # Remove any alt text after |
            local img="${match%%|*}"
            images+=("$img")
        fi
    done < <(echo "$content" | grep -oP '!\[\[\K[^\]]+(?=\]\])' || true)

    # Find markdown-style local images: ![alt](path) - skip http/https URLs
    while IFS= read -r match; do
        if [[ -n "$match" && ! "$match" =~ ^https?:// ]]; then
            # Extract just the filename from path
            local img="${match##*/}"
            images+=("$img")
        fi
    done < <(echo "$content" | grep -oP '!\[[^\]]*\]\(\K[^)]+(?=\))' || true)

    # Output unique images
    printf '%s\n' "${images[@]}" | sort -u
}

find_local_image() {
    # Find an image file in the vault's Attachments folder
    local image="$1"
    local vault="$2"

    # Primary location: Attachments folder
    local attachments_path="${vault}/Attachments/${image}"
    if [[ -f "$attachments_path" ]]; then
        echo "$attachments_path"
        return 0
    fi

    # Fallback: search recursively in vault (for images in subdirectories)
    local found
    found=$(find "$vault" -name "$image" -type f 2>/dev/null | head -1)
    if [[ -n "$found" ]]; then
        echo "$found"
        return 0
    fi

    return 1
}

convert_wiki_links() {
    # Convert wiki-style image links to markdown format
    # Takes content and slug, returns converted content
    local content="$1"
    local slug="$2"

    # Convert ![[image.png]] to ![image.png](/assets/blog/slug/image.png)
    # Also handle ![[image.png|alt text]] to ![alt text](/assets/blog/slug/image.png)
    content=$(echo "$content" | perl -pe 's/!\[\[([^|\]]+)\|([^\]]+)\]\]/![$2](\/assets\/blog\/'"$slug"'\/$1)/g')
    content=$(echo "$content" | perl -pe 's/!\[\[([^\]]+)\]\]/![$1](\/assets\/blog\/'"$slug"'\/$1)/g')

    # Rewrite local markdown image paths (not http/https) to use asset directory
    # ![alt](image.png) or ![alt](./image.png) -> ![alt](/assets/blog/slug/image.png)
    content=$(echo "$content" | perl -pe 's/!\[([^\]]*)\]\((?!https?:\/\/)(?:\.\/)?([^\/\)]+)\)/![$1](\/assets\/blog\/'"$slug"'\/$2)/g')

    echo "$content"
}

copy_images() {
    # Copy images to public assets directory
    local slug="$1"
    shift
    local images=("$@")

    if [[ ${#images[@]} -eq 0 ]]; then
        return 0
    fi

    local dest_dir="${ASSETS_DIR}/${slug}"

    if [[ "$DRY_RUN" == "true" ]]; then
        for image in "${images[@]}"; do
            echo -e "  [DRY-RUN] Would copy: $image -> ${dest_dir}/${image}"
        done
        return 0
    fi

    # Create directory and track it
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir"
        track_created_dir "$dest_dir"
    fi

    for image in "${images[@]}"; do
        local source_path
        if source_path=$(find_local_image "$image" "$VAULT_PATH"); then
            local dest_file="${dest_dir}/${image}"
            cp "$source_path" "$dest_file"
            track_created_file "$dest_file"
            echo -e "  ${GREEN}Copied:${RESET} $image"
        else
            echo -e "  ${YELLOW}Warning: Image not found: $image${RESET}"
        fi
    done
}

copy_post() {
    # Copy and transform a post to the blog directory
    local source_path="$1"
    local slug="$2"
    local year="$3"

    local dest_dir="${BLOG_DIR}/${year}"
    local dest_path="${dest_dir}/${slug}.md"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  [DRY-RUN] Would copy: $source_path -> $dest_path"
        return 0
    fi

    # Create year directory if needed and track it
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir"
        track_created_dir "$dest_dir"
    fi

    # Read content
    local content
    content=$(cat "$source_path")

    # Normalize frontmatter types (author array -> string, remove empty heroImage)
    content=$(normalize_frontmatter "$content")

    # Convert wiki-links to markdown
    content=$(convert_wiki_links "$content" "$slug")

    # Check if this is an update (file already exists)
    local is_new=true
    if [[ -f "$dest_path" ]]; then
        is_new=false
    fi

    # Write to destination
    echo "$content" > "$dest_path"

    # Only track as created if it's a new file (not an update)
    if [[ "$is_new" == "true" ]]; then
        track_created_file "$dest_path"
    fi
}

process_posts() {
    # Process all selected posts: extract images, copy, transform
    echo ""
    echo -e "${CYAN}Copying posts and images...${RESET}"

    for i in "${!SELECTED_FILES[@]}"; do
        local file="${SELECTED_FILES[$i]}"
        local filename
        local slug
        local title
        local pub_date
        local year
        local is_update

        filename=$(basename "$file")
        slug=$(slugify "$filename")
        title=$(extract_frontmatter_value "$file" "title")
        pub_date=$(extract_frontmatter_value "$file" "pubDatetime")
        year="${pub_date:0:4}"

        # Determine if this is an update
        local existing_path="${BLOG_DIR}/${year}/${slug}.md"
        if [[ -f "$existing_path" ]]; then
            is_update="true"
        else
            is_update="false"
        fi

        echo ""
        echo -e "${CYAN}Processing:${RESET} $title"

        # Read content
        local content
        content=$(cat "$file")

        # Extract and copy images
        local images=()
        while IFS= read -r img; do
            [[ -n "$img" ]] && images+=("$img")
        done < <(extract_images "$content")

        if [[ ${#images[@]} -gt 0 ]]; then
            echo -e "  ${CYAN}Copying images...${RESET}"
            copy_images "$slug" "${images[@]}"
        fi

        # Copy and transform post
        copy_post "$file" "$slug" "$year"

        # Update Obsidian source file with publication metadata (two-way sync)
        update_obsidian_source "$file" "publish" "$DRY_RUN"

        if [[ "$DRY_RUN" != "true" ]]; then
            echo -e "  ${GREEN}Published:${RESET} ${BLOG_DIR}/${year}/${slug}.md"
        fi

        # Store metadata for commits
        PROCESSED_SLUGS+=("$slug")
        PROCESSED_TITLES+=("$title")
        PROCESSED_YEARS+=("$year")
        PROCESSED_IS_UPDATE+=("$is_update")
    done

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${CYAN}Would process ${#SELECTED_FILES[@]} post(s)${RESET}"
    else
        echo -e "${GREEN}Successfully copied ${#SELECTED_FILES[@]} post(s)${RESET}"
    fi
}

# ============================================================================
# Git Commit Functions
# ============================================================================

commit_posts() {
    # Commit each post individually with conventional commit message
    echo ""
    echo -e "${CYAN}Committing posts...${RESET}"

    local commit_count=0

    for i in "${!PROCESSED_SLUGS[@]}"; do
        local slug="${PROCESSED_SLUGS[$i]}"
        local title="${PROCESSED_TITLES[$i]}"
        local year="${PROCESSED_YEARS[$i]}"
        local is_update="${PROCESSED_IS_UPDATE[$i]}"

        local post_path="${BLOG_DIR}/${year}/${slug}.md"
        local assets_path="${ASSETS_DIR}/${slug}"

        # Determine commit type
        local commit_verb
        if [[ "$is_update" == "true" ]]; then
            commit_verb="update"
        else
            commit_verb="add"
        fi

        local commit_msg="docs(blog): $commit_verb $title"

        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "  [DRY-RUN] Would commit: $commit_msg"
            continue
        fi

        # Stage post file
        git add "$post_path"

        # Stage assets directory if it exists
        if [[ -d "$assets_path" ]]; then
            git add "$assets_path"
        fi

        # Check if there are staged changes before committing
        if git diff --cached --quiet; then
            echo -e "  ${YELLOW}No changes:${RESET} $title (already up to date)"
        else
            # Create commit
            git commit -m "$commit_msg" --quiet
            echo -e "  ${GREEN}Committed:${RESET} $commit_msg"
            ((++commit_count))
        fi
    done

    if [[ "$DRY_RUN" != "true" ]]; then
        echo ""
        echo -e "${GREEN}Created $commit_count commit(s)${RESET}"
    fi
}

push_commits() {
    # Prompt user before pushing to remote
    local commit_count="$1"

    echo ""

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "[DRY-RUN] Would push $commit_count commit(s) to origin"
        return 0
    fi

    local should_push=false

    if [[ "$AUTO_CONFIRM" == "true" ]]; then
        # Auto-push in non-interactive mode
        should_push=true
        echo -e "${CYAN}Auto-pushing (--yes)${RESET}"
    else
        read -rp "Push $commit_count commit(s) to remote? [Y/n] " response

        if [[ ! "$response" =~ ^[Nn] ]]; then
            should_push=true
        fi
    fi

    if [[ "$should_push" == "false" ]]; then
        echo ""
        echo -e "${YELLOW}Commits created locally. Run 'git push' when ready.${RESET}"
        return 0
    fi

    echo ""
    echo -e "${CYAN}Pushing to remote...${RESET}"
    git push
    echo -e "${GREEN}Successfully pushed to remote.${RESET}"
}

# ============================================================================
# Dry Run Summary
# ============================================================================

print_dry_run_summary() {
    # Print a complete summary of what would happen
    echo ""
    echo "=== Dry Run ==="
    echo ""

    echo "Posts to publish:"
    for i in "${!PROCESSED_SLUGS[@]}"; do
        local slug="${PROCESSED_SLUGS[$i]}"
        local title="${PROCESSED_TITLES[$i]}"
        local year="${PROCESSED_YEARS[$i]}"
        local is_update="${PROCESSED_IS_UPDATE[$i]}"

        local status
        if [[ "$is_update" == "true" ]]; then
            status="update"
        else
            status="new"
        fi

        echo "  - \"$title\" -> ${BLOG_DIR}/${year}/${slug}.md ($status)"
    done

    echo ""
    echo "Images to copy:"
    if [[ ${#CREATED_FILES[@]} -eq 0 ]]; then
        echo "  (shown during processing above)"
    fi

    echo ""
    echo "Validation:"
    echo "  - Would run: npm run lint"
    echo "  - Would run: npm run build"

    echo ""
    echo "Commits:"
    for i in "${!PROCESSED_SLUGS[@]}"; do
        local title="${PROCESSED_TITLES[$i]}"
        local is_update="${PROCESSED_IS_UPDATE[$i]}"

        local commit_verb
        if [[ "$is_update" == "true" ]]; then
            commit_verb="update"
        else
            commit_verb="add"
        fi

        echo "  - docs(blog): $commit_verb $title"
    done

    echo ""
    echo "Push:"
    echo "  - Would push ${#PROCESSED_SLUGS[@]} commit(s) to origin"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Parse command line arguments
    parse_args "$@"

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "=== Publish Workflow (Dry Run) ==="
    else
        echo "=== Publish Workflow ==="
    fi
    echo ""

    # Load configuration
    load_config

    # Discover posts
    echo ""
    echo -e "${CYAN}Discovering posts...${RESET}"
    discover_posts

    # Check if any posts to publish
    if [[ ${#POST_FILES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No posts ready to publish.${RESET}"
        echo ""
        echo "To publish a post, set draft: false in the frontmatter:"
        echo "  draft: false"
        echo ""
        exit $EXIT_SUCCESS
    fi

    echo -e "Found ${GREEN}${#POST_FILES[@]}${RESET} post(s) ready to publish"
    echo ""

    # Post selection: handle non-interactive modes first
    if [[ "$SELECT_ALL" == "true" ]]; then
        # --all flag: select all discovered posts
        SELECTED_FILES=("${POST_FILES[@]}")
        echo -e "${CYAN}Selecting all ${#SELECTED_FILES[@]} post(s)${RESET}"
    elif [[ -n "$SELECT_POST" ]]; then
        # --post flag: select specific post by slug or filename
        local found=false
        for i in "${!POST_FILES[@]}"; do
            local file="${POST_FILES[$i]}"
            local filename
            local slug
            filename=$(basename "$file")
            slug=$(slugify "$filename")

            if [[ "$slug" == "$SELECT_POST" || "$filename" == "$SELECT_POST" || "${filename%.md}" == "$SELECT_POST" ]]; then
                SELECTED_FILES+=("$file")
                found=true
                echo -e "${CYAN}Selected: ${POST_TITLES[$i]}${RESET}"
                break
            fi
        done

        if [[ "$found" == "false" ]]; then
            echo -e "${RED}Error: Post not found: $SELECT_POST${RESET}"
            echo ""
            echo "Available posts:"
            for i in "${!POST_FILES[@]}"; do
                local filename
                filename=$(basename "${POST_FILES[$i]}")
                local slug
                slug=$(slugify "$filename")
                echo "  - $slug (${POST_TITLES[$i]})"
            done
            exit $EXIT_ERROR
        fi
    elif [[ "$DRY_RUN" == "true" ]]; then
        # In dry-run without explicit selection, select all posts to show full preview
        SELECTED_FILES=("${POST_FILES[@]}")
        echo -e "${CYAN}Dry run: selecting all ${#SELECTED_FILES[@]} post(s)${RESET}"
    else
        # Interactive selection
        if ! select_posts; then
            echo ""
            echo -e "${YELLOW}No posts selected. Cancelled.${RESET}"
            exit $EXIT_CANCELLED
        fi

        # Validate selection
        if [[ ${#SELECTED_FILES[@]} -eq 0 ]]; then
            echo ""
            echo -e "${YELLOW}No posts selected. Cancelled.${RESET}"
            exit $EXIT_CANCELLED
        fi
    fi

    echo ""
    echo -e "${GREEN}Selected ${#SELECTED_FILES[@]} post(s) for publishing${RESET}"

    # Validate selected posts
    echo ""
    echo -e "${CYAN}Validating posts...${RESET}"
    validate_selected_posts

    # Process posts: extract images, transform wiki-links, copy to blog
    process_posts

    # Run lint verification (after copy, before commits)
    run_lint_with_retry

    # Commit each post
    echo ""
    echo -e "${CYAN}Committing posts...${RESET}"
    commit_posts
    local commit_count=${#PROCESSED_SLUGS[@]}

    # Run build verification (after commits, before push)
    run_build_with_retry

    # Push to remote
    push_commits "$commit_count"

    # Print dry-run summary if applicable
    if [[ "$DRY_RUN" == "true" ]]; then
        print_dry_run_summary
    fi

    echo ""
    echo -e "${GREEN}Publishing complete!${RESET}"
    exit $EXIT_SUCCESS
}

main "$@"
