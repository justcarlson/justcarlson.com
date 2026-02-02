#!/usr/bin/env bash
# scripts/migrate-schema.sh - One-time schema migration script
#
# Migrates vault posts from old `status: Published` schema to new `draft: true/false` schema.
# This is a standalone migration script, not added to justfile (one-time use).
#
# Usage:
#   ./scripts/migrate-schema.sh           # Execute migration
#   ./scripts/migrate-schema.sh --dry-run # Preview changes without modifying files
#   ./scripts/migrate-schema.sh --help    # Show usage information

# Source common library for yq helpers and color constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# Configuration
# ============================================================================

DRY_RUN=false
VERBOSE=false

# Counters
MIGRATED=0
ALREADY_DONE=0
ERRORS=0

# ============================================================================
# Usage
# ============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Migrate vault posts from status/published schema to draft-based schema.

Options:
    --dry-run    Preview changes without modifying files
    --verbose    Show detailed output for each file
    --help       Show this help message

Description:
    This script migrates posts in the Obsidian vault from the old schema:
        status: Published (or Draft)
        published: <date>

    To the new schema:
        draft: true/false

    The migration:
    - Preserves existing draft values if present
    - Sets draft: false for posts with status: Published
    - Sets draft: true for all other posts
    - Preserves existing pubDatetime values
    - Backfills pubDatetime from file mtime for published posts without it
    - Removes status and published fields from all posts
    - Creates .bak backup files before any modification
    - Is idempotent (safe to run multiple times)

Examples:
    # Preview what would change
    ./scripts/migrate-schema.sh --dry-run

    # Execute migration
    ./scripts/migrate-schema.sh

    # Execute with verbose output
    ./scripts/migrate-schema.sh --verbose
EOF
}

# ============================================================================
# Helper Functions
# ============================================================================

is_post_file() {
    # Check if file is a post (has categories with [[Posts]] wikilink)
    # Excludes template files
    local file="$1"

    # Skip template files
    if [[ "$file" == *"/Templates/"* ]] || [[ "$(basename "$file")" == *"Template"* ]]; then
        return 1
    fi

    # Check for categories line with [[Posts]] wikilink
    if grep -q 'categories:' "$file" 2>/dev/null && grep -q '\[\[Posts\]\]' "$file" 2>/dev/null; then
        return 0
    fi

    return 1
}

is_already_migrated() {
    # Check if file is already migrated (has draft field AND no status field)
    local file="$1"
    local yq_cmd
    yq_cmd=$(_get_yq_cmd)

    local has_draft
    local has_status

    # Check if draft field exists
    has_draft=$("$yq_cmd" --front-matter=extract 'has("draft")' "$file" 2>/dev/null)

    # Check if status field exists
    has_status=$("$yq_cmd" --front-matter=extract 'has("status")' "$file" 2>/dev/null)

    if [[ "$has_draft" == "true" ]] && [[ "$has_status" == "false" ]]; then
        return 0
    fi

    return 1
}

get_draft_value() {
    # Determine what draft value should be
    # Returns "true" or "false"
    local file="$1"
    local yq_cmd
    yq_cmd=$(_get_yq_cmd)

    # First check if draft field already exists
    local has_draft
    has_draft=$("$yq_cmd" --front-matter=extract 'has("draft")' "$file" 2>/dev/null)

    if [[ "$has_draft" == "true" ]]; then
        # Get the actual value (handles boolean false correctly)
        local existing_draft
        existing_draft=$("$yq_cmd" --front-matter=extract '.draft' "$file" 2>/dev/null)
        echo "$existing_draft"
        return
    fi

    # Check if status contains "Published"
    local status
    status=$("$yq_cmd" --front-matter=extract '.status // []' "$file" 2>/dev/null)

    if echo "$status" | grep -q "Published"; then
        echo "false"
    else
        echo "true"
    fi
}

needs_pubdatetime_backfill() {
    # Check if pubDatetime needs to be backfilled
    # Returns 0 if needs backfill, 1 otherwise
    local file="$1"
    local draft_value="$2"
    local yq_cmd
    yq_cmd=$(_get_yq_cmd)

    # Only backfill for published posts (draft: false)
    if [[ "$draft_value" == "true" ]]; then
        return 1
    fi

    # Check if pubDatetime exists and is not empty
    local pubdatetime
    pubdatetime=$("$yq_cmd" --front-matter=extract '.pubDatetime // ""' "$file" 2>/dev/null)

    if [[ -z "$pubdatetime" ]] || [[ "$pubdatetime" == "null" ]]; then
        return 0
    fi

    return 1
}

migrate_file() {
    # Migrate a single file
    local file="$1"
    local yq_cmd
    yq_cmd=$(_get_yq_cmd)

    local basename
    basename=$(basename "$file")

    # Determine draft value
    local draft_value
    draft_value=$(get_draft_value "$file")

    # Check for pubDatetime backfill
    local needs_backfill=false
    local mtime=""
    if needs_pubdatetime_backfill "$file" "$draft_value"; then
        needs_backfill=true
        mtime=$(date -r "$file" -Iseconds)
    fi

    # Get current pubDatetime for display
    local current_pubdatetime
    current_pubdatetime=$("$yq_cmd" --front-matter=extract '.pubDatetime // ""' "$file" 2>/dev/null)

    # Check current status field
    local current_status
    current_status=$("$yq_cmd" --front-matter=extract '.status // []' "$file" 2>/dev/null)

    # Check if draft already exists
    local has_draft
    has_draft=$("$yq_cmd" --front-matter=extract 'has("draft")' "$file" 2>/dev/null)

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${CYAN}File:${RESET} $basename"
        echo -e "  ${CYAN}Current status:${RESET} $(echo "$current_status" | tr '\n' ' ')"
        echo -e "  ${CYAN}New draft value:${RESET} $draft_value"
        if [[ "$has_draft" == "true" ]]; then
            echo -e "  ${CYAN}Draft field:${RESET} already exists, preserving value"
        else
            echo -e "  ${CYAN}Draft field:${RESET} will be set to $draft_value"
        fi
        if [[ "$needs_backfill" == "true" ]]; then
            echo -e "  ${CYAN}pubDatetime:${RESET} will backfill from mtime: $mtime"
        else
            echo -e "  ${CYAN}pubDatetime:${RESET} preserved ($current_pubdatetime)"
        fi
        echo -e "  ${CYAN}Actions:${RESET} remove status, remove published"
        echo ""
        return 0
    fi

    # Create backup before modification
    cp "$file" "${file}.bak"
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${CYAN}Backup:${RESET} ${file}.bak"
    fi

    # Set draft field if not already set
    if [[ "$has_draft" != "true" ]]; then
        if [[ "$draft_value" == "false" ]]; then
            "$yq_cmd" --front-matter=process -i '.draft = false' "$file"
        else
            "$yq_cmd" --front-matter=process -i '.draft = true' "$file"
        fi
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "  ${GREEN}Set:${RESET} draft = $draft_value"
        fi
    fi

    # Backfill pubDatetime if needed
    if [[ "$needs_backfill" == "true" ]]; then
        export DATETIME="$mtime"
        "$yq_cmd" --front-matter=process -i '.pubDatetime = strenv(DATETIME)' "$file"
        unset DATETIME
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "  ${GREEN}Set:${RESET} pubDatetime = $mtime (backfilled from mtime)"
        fi
    fi

    # Delete status field
    "$yq_cmd" --front-matter=process -i 'del(.status)' "$file"
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}Removed:${RESET} status field"
    fi

    # Delete published field
    "$yq_cmd" --front-matter=process -i 'del(.published)' "$file"
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}Removed:${RESET} published field"
    fi

    # Verify modification
    local verify_draft
    local verify_status
    local verify_published

    verify_draft=$("$yq_cmd" --front-matter=extract 'has("draft")' "$file" 2>/dev/null)
    verify_status=$("$yq_cmd" --front-matter=extract 'has("status")' "$file" 2>/dev/null)
    verify_published=$("$yq_cmd" --front-matter=extract 'has("published")' "$file" 2>/dev/null)

    if [[ "$verify_draft" != "true" ]] || [[ "$verify_status" != "false" ]] || [[ "$verify_published" != "false" ]]; then
        echo -e "  ${RED}Error:${RESET} Verification failed for $basename"
        echo -e "    draft exists: $verify_draft (expected: true)"
        echo -e "    status exists: $verify_status (expected: false)"
        echo -e "    published exists: $verify_published (expected: false)"
        echo -e "  ${YELLOW}Restoring:${RESET} from backup"
        mv "${file}.bak" "$file"
        return 1
    fi

    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}Verified:${RESET} migration successful"
    fi

    return 0
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo -e "${RED}Error:${RESET} Unknown option: $1" >&2
                usage
                exit 1
                ;;
        esac
    done

    # Load config to get VAULT_PATH
    load_config

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}=== DRY RUN MODE ===${RESET}"
        echo -e "No files will be modified."
        echo ""
    fi

    echo -e "${CYAN}Discovering posts...${RESET}"
    echo ""

    # Find and process all posts
    local posts=()
    while IFS= read -r -d '' file; do
        if is_post_file "$file"; then
            posts+=("$file")
        fi
    done < <(find "$VAULT_PATH" -name "*.md" -type f -print0 2>/dev/null)

    if [[ ${#posts[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No posts found in vault.${RESET}"
        exit 0
    fi

    echo -e "Found ${#posts[@]} post(s) to process."
    echo ""

    # Process each post
    for file in "${posts[@]}"; do
        local basename
        basename=$(basename "$file")

        echo -e "${BLUE}Processing:${RESET} $basename"

        # Check if already migrated
        if is_already_migrated "$file"; then
            echo -e "  ${GREEN}Already done:${RESET} has draft field, no status field"
            ALREADY_DONE=$((ALREADY_DONE + 1))
            echo ""
            continue
        fi

        # Migrate the file
        if migrate_file "$file"; then
            if [[ "$DRY_RUN" != "true" ]]; then
                echo -e "  ${GREEN}Migrated${RESET}"
            fi
            MIGRATED=$((MIGRATED + 1))
        else
            ERRORS=$((ERRORS + 1))
        fi

        echo ""
    done

    # Summary
    echo -e "${CYAN}=== Summary ===${RESET}"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}Would migrate:${RESET} $MIGRATED file(s)"
    else
        echo -e "${GREEN}Migrated:${RESET} $MIGRATED file(s)"
    fi
    echo -e "${GREEN}Already done:${RESET} $ALREADY_DONE file(s)"
    if [[ $ERRORS -gt 0 ]]; then
        echo -e "${RED}Errors:${RESET} $ERRORS file(s)"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}Migration complete.${RESET}"
}

main "$@"
