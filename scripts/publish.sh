#!/usr/bin/env bash
# Publish workflow: discover posts from Obsidian vault marked as Published
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Config file location (matches setup.sh)
CONFIG_FILE=".claude/settings.local.json"

# Project paths
BLOG_DIR="src/content/blog"

# Exit codes
EXIT_SUCCESS=0
EXIT_ERROR=1
EXIT_CANCELLED=130

# Global arrays for post data
declare -a POST_FILES=()
declare -a POST_TITLES=()
declare -a POST_DATES=()
declare -a POST_DISPLAY=()
declare -a POST_IS_UPDATE=()
declare -a SELECTED_FILES=()

# ============================================================================
# Configuration
# ============================================================================

load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}Error: Config file not found: $CONFIG_FILE${RESET}" >&2
        echo -e "${YELLOW}Run 'just setup' first to configure your Obsidian vault path.${RESET}" >&2
        exit $EXIT_ERROR
    fi

    if ! command -v jq &>/dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${RESET}" >&2
        echo -e "${YELLOW}Install with: pacman -S jq (Arch) or brew install jq (macOS)${RESET}" >&2
        exit $EXIT_ERROR
    fi

    VAULT_PATH=$(jq -r '.obsidianVaultPath // empty' "$CONFIG_FILE")

    if [[ -z "$VAULT_PATH" ]]; then
        echo -e "${RED}Error: Obsidian vault path not configured.${RESET}" >&2
        echo -e "${YELLOW}Run 'just setup' to configure your vault path.${RESET}" >&2
        exit $EXIT_ERROR
    fi

    if [[ ! -d "$VAULT_PATH" ]]; then
        echo -e "${RED}Error: Vault directory does not exist: $VAULT_PATH${RESET}" >&2
        echo -e "${YELLOW}Run 'just setup' to reconfigure your vault path.${RESET}" >&2
        exit $EXIT_ERROR
    fi

    echo -e "Vault: ${CYAN}$VAULT_PATH${RESET}"
}

# ============================================================================
# Post Discovery
# ============================================================================

slugify() {
    # Convert filename to slug: lowercase, spaces to hyphens, remove special chars
    local name="$1"
    # Remove .md extension if present
    name="${name%.md}"
    # Lowercase
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    # Replace spaces with hyphens
    name=$(echo "$name" | tr ' ' '-')
    # Remove special characters except hyphens
    name=$(echo "$name" | sed 's/[^a-z0-9-]//g')
    # Collapse multiple hyphens
    name=$(echo "$name" | sed 's/-\+/-/g')
    # Remove leading/trailing hyphens
    name=$(echo "$name" | sed 's/^-//' | sed 's/-$//')
    echo "$name"
}

extract_frontmatter_value() {
    # Extract a simple value from YAML frontmatter
    local file="$1"
    local key="$2"

    # Read until --- (end of frontmatter), grep for key, extract value
    sed -n '/^---$/,/^---$/p' "$file" | grep -E "^${key}:" | head -1 | sed "s/^${key}:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//' | tr -d '\r'
}

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

posts_are_identical() {
    # Compare Obsidian post content with existing blog post
    # Returns 0 if identical, 1 if different
    local obsidian_file="$1"
    local blog_file="$2"

    # For now, do a simple diff. Future enhancement could normalize frontmatter.
    diff -q "$obsidian_file" "$blog_file" &>/dev/null
}

discover_posts() {
    echo ""
    echo -e "${CYAN}Searching for posts...${RESET}"

    # Find all markdown files with status: - Published (case-insensitive)
    # The pattern matches YAML list format: status:\n  - Published
    local found_files=()

    while IFS= read -r -d '' file; do
        # Check if file contains status with Published value
        # Using perl for multiline matching: status:\s*\n\s*-\s*[Pp]ublished
        if perl -0777 -ne 'exit(!/status:\s*\n\s*-\s*[Pp]ublished/i)' "$file" 2>/dev/null; then
            found_files+=("$file")
        fi
    done < <(find "$VAULT_PATH" -name "*.md" -type f -print0 2>/dev/null)

    if [[ ${#found_files[@]} -eq 0 ]]; then
        return
    fi

    echo -e "Found ${GREEN}${#found_files[@]}${RESET} post(s) with Published status"
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
# Main
# ============================================================================

main() {
    echo ""
    echo "=== Publish Workflow ==="
    echo ""

    # Load configuration
    load_config

    # Discover posts
    discover_posts

    # Check if any posts to publish
    if [[ ${#POST_FILES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No posts ready to publish.${RESET}"
        echo ""
        echo "To publish a post, set its status to 'Published' in Obsidian:"
        echo "  status:"
        echo "    - Published"
        echo ""
        exit $EXIT_SUCCESS
    fi

    echo "Found ${GREEN}${#POST_FILES[@]}${RESET} post(s) ready to publish"
    echo ""

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

    echo ""
    echo -e "${GREEN}Selected ${#SELECTED_FILES[@]} post(s) for publishing${RESET}"
    echo ""

    # Output selected files (for pipeline stages)
    for file in "${SELECTED_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""

    # Store selected files for next pipeline stages
    # Future: pass to validation, transformation, commit stages

    exit $EXIT_SUCCESS
}

main "$@"
