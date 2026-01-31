#!/usr/bin/env bash
# List posts from Obsidian vault with validation status
set -euo pipefail

# Colors for output (matching publish.sh)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Config file location
CONFIG_FILE=".claude/settings.local.json"

# Project paths
BLOG_DIR="src/content/blog"

# Exit codes
EXIT_SUCCESS=0
EXIT_ERROR=1

# Filter mode (default, all, or published)
FILTER_MODE="unpublished"

# ============================================================================
# Argument Parsing
# ============================================================================

print_usage() {
    echo "Usage: $0 [--all | --published]"
    echo ""
    echo "List blog posts from Obsidian with validation status."
    echo ""
    echo "Options:"
    echo "  --all        Show all posts with Published status"
    echo "  --published  Show only posts already in blog repo"
    echo "  (default)    Show only unpublished/new posts"
    echo ""
    echo "Output:"
    echo "  Table showing title, date, status (ready/invalid), and validation errors"
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                FILTER_MODE="all"
                shift
                ;;
            --published)
                FILTER_MODE="published"
                shift
                ;;
            --help|-h)
                print_usage
                ;;
            *)
                echo "Unknown option: $1" >&2
                print_usage
                ;;
        esac
    done
}

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
}

# ============================================================================
# Validation (from publish.sh)
# ============================================================================

extract_frontmatter() {
    # Extract YAML frontmatter content (between first two --- lines)
    local file="$1"
    sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

get_frontmatter_field() {
    # Extract a field value from frontmatter content
    local frontmatter="$1"
    local field="$2"

    # Match field: value or field: "value" or field: 'value'
    local value
    value=$(echo "$frontmatter" | grep -E "^${field}:" | head -1 | sed "s/^${field}:[[:space:]]*//" | sed 's/^["\x27]//' | sed 's/["\x27]$//' | tr -d '\r')

    echo "$value"
}

validate_iso8601() {
    # Validate ISO 8601 datetime format: YYYY-MM-DDTHH:MM:SS or YYYY-MM-DD
    local datetime="$1"

    # Check full datetime: YYYY-MM-DDTHH:MM:SS (with optional timezone)
    if [[ "$datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
        return 0
    fi

    # Check date only: YYYY-MM-DD
    if [[ "$datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        return 0
    fi

    return 1
}

validate_frontmatter() {
    # Validate a single file's frontmatter
    # Returns array of error messages (empty = valid)
    local file="$1"
    local errors=()

    # Extract frontmatter
    local frontmatter
    frontmatter=$(extract_frontmatter "$file")

    if [[ -z "$frontmatter" ]]; then
        errors+=("No frontmatter found")
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    # Check required fields
    local title
    local pubDatetime
    local description

    title=$(get_frontmatter_field "$frontmatter" "title")
    pubDatetime=$(get_frontmatter_field "$frontmatter" "pubDatetime")
    description=$(get_frontmatter_field "$frontmatter" "description")

    # Validate title
    if [[ -z "$title" ]]; then
        errors+=("Missing title (required for SEO and display)")
    fi

    # Validate pubDatetime
    if [[ -z "$pubDatetime" ]]; then
        errors+=("Missing pubDatetime (required for post ordering)")
    elif ! validate_iso8601 "$pubDatetime"; then
        errors+=("Invalid pubDatetime format: '$pubDatetime' (expected YYYY-MM-DDTHH:MM:SS or YYYY-MM-DD)")
    fi

    # Validate description
    if [[ -z "$description" ]]; then
        errors+=("Missing description (required for SEO)")
    fi

    # Output errors (one per line)
    if [[ ${#errors[@]} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    return 0
}

extract_frontmatter_value() {
    # Extract a simple value from YAML frontmatter
    local file="$1"
    local key="$2"

    # Read until --- (end of frontmatter), grep for key, extract value
    sed -n '/^---$/,/^---$/p' "$file" | grep -E "^${key}:" | head -1 | sed "s/^${key}:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//' | tr -d '\r'
}

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

is_published_in_blog() {
    # Check if a post exists in the blog repo
    local slug="$1"
    local pub_date="$2"

    # Extract year from pub_date
    local year="${pub_date:0:4}"

    # Check if file exists in year directory
    local blog_path="${BLOG_DIR}/${year}/${slug}.md"
    if [[ -f "$blog_path" ]]; then
        return 0
    fi

    return 1
}

# ============================================================================
# Post Discovery and Listing
# ============================================================================

list_posts() {
    # Discover all posts with Published status
    local found_files=()

    while IFS= read -r -d '' file; do
        # Check if file contains status with Published value
        # Using perl for multiline matching: status:\s*\n\s*-\s*[Pp]ublished
        if perl -0777 -ne 'exit(!/status:\s*\n\s*-\s*[Pp]ublished/i)' "$file" 2>/dev/null; then
            found_files+=("$file")
        fi
    done < <(find "$VAULT_PATH" -name "*.md" -type f -print0 2>/dev/null)

    if [[ ${#found_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No posts found with Published status.${RESET}"
        echo ""
        echo "To mark a post for publishing, add to frontmatter:"
        echo "  status:"
        echo "    - Published"
        exit $EXIT_SUCCESS
    fi

    # Arrays to hold post data
    declare -a titles=()
    declare -a dates=()
    declare -a statuses=()
    declare -a error_msgs=()
    declare -a is_published=()

    # Process each post
    for file in "${found_files[@]}"; do
        local title
        local pub_date
        local filename
        local slug
        local validation_errors
        local status
        local published="false"

        # Extract metadata
        filename=$(basename "$file")
        slug=$(slugify "$filename")
        title=$(extract_frontmatter_value "$file" "title")
        pub_date=$(extract_frontmatter_value "$file" "pubDatetime")

        # Fallback: use filename as title if not set
        if [[ -z "$title" ]]; then
            title="${filename%.md}"
        fi

        # Check if already published in blog
        if [[ -n "$pub_date" ]] && is_published_in_blog "$slug" "$pub_date"; then
            published="true"
        fi

        # Validate frontmatter
        if validation_errors=$(validate_frontmatter "$file"); then
            status="ready"
        else
            status="invalid"
        fi

        # Store data
        titles+=("$title")
        dates+=("$pub_date")
        statuses+=("$status")
        error_msgs+=("$validation_errors")
        is_published+=("$published")
    done

    # Filter based on mode
    local filtered_indices=()
    for i in "${!titles[@]}"; do
        case "$FILTER_MODE" in
            all)
                filtered_indices+=("$i")
                ;;
            published)
                if [[ "${is_published[$i]}" == "true" ]]; then
                    filtered_indices+=("$i")
                fi
                ;;
            unpublished)
                if [[ "${is_published[$i]}" == "false" ]]; then
                    filtered_indices+=("$i")
                fi
                ;;
        esac
    done

    # Check if any posts match filter
    if [[ ${#filtered_indices[@]} -eq 0 ]]; then
        case "$FILTER_MODE" in
            published)
                echo -e "${YELLOW}No published posts found.${RESET}"
                ;;
            unpublished)
                echo -e "${YELLOW}No unpublished posts found.${RESET}"
                ;;
            all)
                echo -e "${YELLOW}No posts found.${RESET}"
                ;;
        esac
        exit $EXIT_SUCCESS
    fi

    # Sort: ready status first, then by date descending
    # Create sort keys: "status_priority|date|index"
    # ready=0, invalid=1 (so ready sorts first)
    declare -a sort_keys=()
    for idx in "${filtered_indices[@]}"; do
        local priority
        if [[ "${statuses[$idx]}" == "ready" ]]; then
            priority="0"
        else
            priority="1"
        fi
        local sort_date="${dates[$idx]:-0000-00-00}"
        sort_keys+=("${priority}|${sort_date}|${idx}")
    done

    # Sort by priority (asc) then date (desc)
    local sorted_indices=()
    while IFS='|' read -r priority date idx; do
        sorted_indices+=("$idx")
    done < <(printf '%s\n' "${sort_keys[@]}" | sort -t'|' -k1,1 -k2,2r)

    # Display table header
    echo ""
    printf "%-40s %-12s %-10s\n" "TITLE" "DATE" "STATUS"
    printf '%.0s─' {1..64}
    echo ""

    # Display posts
    for idx in "${sorted_indices[@]}"; do
        local title="${titles[$idx]}"
        local date="${dates[$idx]}"
        local status="${statuses[$idx]}"
        local errors="${error_msgs[$idx]}"

        # Truncate title if too long
        if [[ ${#title} -gt 40 ]]; then
            title="${title:0:37}..."
        fi

        # Format date for display
        local display_date="${date:0:10}"
        if [[ -z "$display_date" || "$display_date" == "null" ]]; then
            display_date="(no date)"
        fi

        # Color status
        local colored_status
        if [[ "$status" == "ready" ]]; then
            colored_status="${GREEN}Ready${RESET}"
        else
            colored_status="${RED}Invalid${RESET}"
        fi

        # Print row
        printf "%-40s %-12s " "$title" "$display_date"
        echo -e "$colored_status"

        # Print errors if invalid
        if [[ "$status" == "invalid" && -n "$errors" ]]; then
            while IFS= read -r error; do
                echo -e "  ${YELLOW}→${RESET} $error"
            done <<< "$errors"
        fi
    done

    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Parse arguments
    parse_args "$@"

    # Load configuration
    load_config

    # List posts
    list_posts

    exit $EXIT_SUCCESS
}

main "$@"
