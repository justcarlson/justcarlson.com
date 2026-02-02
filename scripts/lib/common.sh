#!/usr/bin/env bash
# scripts/lib/common.sh - Shared library for blog publishing scripts
#
# This library provides common constants and utilities used across
# publish.sh, unpublish.sh, list-posts.sh, and other scripts.
#
# Usage:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "${SCRIPT_DIR}/lib/common.sh"
#
# Or for scripts in the same directory as lib/:
#   source "${SCRIPT_DIR}/../lib/common.sh"

# ============================================================================
# Source Guard (prevent double-sourcing)
# ============================================================================
[[ -n "${_COMMON_SH_LOADED:-}" ]] && return
readonly _COMMON_SH_LOADED=1

# ============================================================================
# Strict Mode
# ============================================================================
set -euo pipefail

# ============================================================================
# Color Constants
# ============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly BLUE='\033[0;34m'
readonly RESET='\033[0m'

# ============================================================================
# Configuration Constants
# ============================================================================
readonly CONFIG_FILE=".claude/settings.local.json"
readonly BLOG_DIR="src/content/blog"
readonly ASSETS_DIR="public/assets/blog"

# ============================================================================
# Exit Codes
# ============================================================================
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_CANCELLED=130

# ============================================================================
# Frontmatter Extraction Functions
# ============================================================================

# Check if mikefarah/yq (Go version) is available
# Returns 0 if available, 1 otherwise
_has_mikefarah_yq() {
    # Check for go-yq (Arch package name) or yq with mikefarah signature
    if command -v go-yq &>/dev/null; then
        return 0
    fi
    if command -v yq &>/dev/null && yq --version 2>&1 | grep -q "mikefarah"; then
        return 0
    fi
    return 1
}

# Get the yq command to use (go-yq or yq)
_get_yq_cmd() {
    if command -v go-yq &>/dev/null; then
        echo "go-yq"
    else
        echo "yq"
    fi
}

extract_frontmatter() {
    # Extract YAML frontmatter content (between first two --- lines)
    # Uses yq if mikefarah/yq is available, otherwise sed fallback
    local file="$1"

    if _has_mikefarah_yq; then
        local yq_cmd
        yq_cmd=$(_get_yq_cmd)
        "$yq_cmd" --front-matter=extract '.' "$file" 2>/dev/null
    else
        # Fallback to sed (less reliable but works for simple cases)
        sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
    fi
}

get_frontmatter_field() {
    # Extract a specific field value from frontmatter
    # Handles quoted strings, colons in values, and missing fields
    # Uses yq if mikefarah/yq is available, otherwise sed fallback
    local file="$1"
    local field="$2"

    if _has_mikefarah_yq; then
        local yq_cmd
        yq_cmd=$(_get_yq_cmd)
        # Use // "" to return empty string instead of null for missing fields
        "$yq_cmd" --front-matter=extract ".$field // \"\"" "$file" 2>/dev/null
    else
        # Fallback to sed (less reliable but works for simple cases)
        # Extract frontmatter, find field, strip quotes
        # Use || true to handle missing fields (grep returns 1 when no match)
        sed -n '/^---$/,/^---$/p' "$file" | \
            grep -E "^${field}:" | \
            head -1 | \
            sed "s/^${field}:[[:space:]]*//" | \
            sed 's/^["\x27]//' | \
            sed 's/["\x27]$//' | \
            tr -d '\r' || true
    fi
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
    # Returns 0 if valid, 1 if invalid
    # Outputs error messages to stdout (one per line)
    local file="$1"
    local errors=()

    # Check if file has frontmatter
    if ! head -1 "$file" | grep -q "^---$"; then
        errors+=("No frontmatter found (YAML block between --- markers)")
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    # Extract required fields
    local title
    local pubDatetime
    local description

    title=$(get_frontmatter_field "$file" "title")
    pubDatetime=$(get_frontmatter_field "$file" "pubDatetime")
    description=$(get_frontmatter_field "$file" "description")

    # Validate title
    if [[ -z "$title" ]]; then
        errors+=("Missing title (required for SEO and display)")
    fi

    # Validate pubDatetime
    if [[ -z "$pubDatetime" ]]; then
        errors+=("Missing pubDatetime (required for post ordering and URLs)")
    elif ! validate_iso8601 "$pubDatetime"; then
        errors+=("Invalid pubDatetime format: '$pubDatetime' (expected YYYY-MM-DDTHH:MM:SS or YYYY-MM-DD)")
    fi

    # Validate description
    if [[ -z "$description" ]]; then
        errors+=("Missing description (required for SEO and previews)")
    fi

    # Output errors (one per line)
    if [[ ${#errors[@]} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    return 0
}

# ============================================================================
# Utility Functions
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

load_config() {
    # Load and validate settings.local.json
    # Sets VAULT_PATH global variable
    # Exits with error if config is invalid
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

get_author_from_config() {
    # Read author from settings.local.json
    # Returns configured author or empty string if not set
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return
    fi
    jq -r '.author // empty' "$CONFIG_FILE" 2>/dev/null
}

update_obsidian_source() {
    # Update Obsidian source file with publication metadata
    # Args:
    #   $1: obsidian_file - Path to source file in vault
    #   $2: action - "publish" or "unpublish"
    #   $3: dry_run - "true" or "false" (optional, default false)
    local obsidian_file="$1"
    local action="$2"
    local dry_run="${3:-false}"

    if [[ ! -f "$obsidian_file" ]]; then
        echo -e "${YELLOW}Warning: Source file not found: $obsidian_file${RESET}" >&2
        return 1
    fi

    local yq_cmd
    yq_cmd=$(_get_yq_cmd)

    if [[ "$action" == "publish" ]]; then
        # Check if pubDatetime is already set (preserve existing date for updates)
        local existing_datetime
        existing_datetime=$(get_frontmatter_field "$obsidian_file" "pubDatetime")

        if [[ "$dry_run" == "true" ]]; then
            echo -e "  [DRY-RUN] Would update Obsidian source:"
            echo -e "    File: $obsidian_file"
            echo -e "    draft: false"
            if [[ -z "$existing_datetime" ]]; then
                local datetime
                datetime=$(date -Iseconds)
                echo -e "    pubDatetime: $datetime (auto-set)"
            else
                echo -e "    pubDatetime: $existing_datetime (preserved)"
            fi
        else
            # Create backup (SYNC-04)
            cp "$obsidian_file" "${obsidian_file}.bak"
            echo -e "  ${CYAN}Backup:${RESET} ${obsidian_file}.bak"

            if [[ -z "$existing_datetime" ]]; then
                # Set pubDatetime only if empty
                local datetime
                datetime=$(date -Iseconds)
                export DATETIME="$datetime"
                "$yq_cmd" --front-matter=process -i \
                    '.draft = false | .pubDatetime = strenv(DATETIME)' \
                    "$obsidian_file"
                unset DATETIME
                echo -e "  ${GREEN}Updated source:${RESET} draft=false, pubDatetime=$datetime"
            else
                # Only update draft status, preserve existing pubDatetime
                "$yq_cmd" --front-matter=process -i '.draft = false' "$obsidian_file"
                echo -e "  ${GREEN}Updated source:${RESET} draft=false (pubDatetime preserved)"
            fi
        fi

    elif [[ "$action" == "unpublish" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            echo -e "  [DRY-RUN] Would update Obsidian source:"
            echo -e "    File: $obsidian_file"
            echo -e "    draft: true"
        else
            # Create backup (SYNC-04)
            cp "$obsidian_file" "${obsidian_file}.bak"
            echo -e "  ${CYAN}Backup:${RESET} ${obsidian_file}.bak"

            # Update frontmatter
            "$yq_cmd" --front-matter=process -i '.draft = true' "$obsidian_file"

            echo -e "  ${GREEN}Updated source:${RESET} draft=true"
        fi
    fi
}

extract_frontmatter_value() {
    # Alias for get_frontmatter_field (backward compatibility)
    # Some scripts use this name instead of get_frontmatter_field
    get_frontmatter_field "$1" "$2"
}
