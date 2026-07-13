#!/usr/bin/env bash
# Normalize Obsidian blog notes and the blog template for the current publisher.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

DRY_RUN=false
INCLUDE_ALL=false
VERIFY_ONLY=false

print_usage() {
    echo "Usage: $0 [--dry-run] [--all] [--verify]"
    echo ""
    echo "Normalize blog note frontmatter in the configured Obsidian vault."
    echo ""
    echo "Options:"
    echo "  --dry-run  Show changes without modifying the vault"
    echo "  --all      Process every Markdown file with YAML frontmatter"
    echo "  --verify   Check canonical fields without modifying the vault"
    echo "  --help     Show this help"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --all)
            INCLUDE_ALL=true
            shift
            ;;
        --verify)
            VERIFY_ONLY=true
            shift
            ;;
        --help|-h)
            print_usage
            exit "$EXIT_SUCCESS"
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${RESET}" >&2
            print_usage >&2
            exit "$EXIT_ERROR"
            ;;
    esac
done

load_config

if ! _has_mikefarah_yq; then
    echo -e "${RED}Error: mikefarah/yq v4+ is required for vault migration.${RESET}" >&2
    exit "$EXIT_ERROR"
fi

yq_cmd=$(_get_yq_cmd)
timestamp=$(date +%Y%m%d-%H%M%S)
backup_root="${VAULT_PATH}/.blog-migration-backups/${timestamp}"

template_folder="Templates"
templates_config="${VAULT_PATH}/.obsidian/templates.json"
if [[ -f "$templates_config" ]]; then
    configured_template_folder=$(jq -r '.folder // empty' "$templates_config" 2>/dev/null || true)
    if [[ -n "$configured_template_folder" ]]; then
        template_folder="$configured_template_folder"
    fi
fi
blog_template_file="${VAULT_PATH}/${template_folder}/Blog Post.md"

candidate_count=0
changed_count=0
verified_errors=0

has_frontmatter() {
    [[ "$(head -1 "$1" 2>/dev/null)" == "---" ]]
}

is_blog_note() {
    local file="$1"
    local relative="${file#"${VAULT_PATH}/"}"

    if [[ "$file" == "$blog_template_file" ]]; then
        return 1
    fi

    if [[ "$INCLUDE_ALL" == "true" ]]; then
        return 0
    fi

    if [[ "$relative" == "Blog Posts/"* ]]; then
        return 0
    fi

    local result
    result=$("$yq_cmd" --front-matter=extract -r '
        has("pubDatetime") or
        has("published") or
        ((.status // "") | tostring | test("published"; "i")) or
        ((.categories // "") | tostring | test("posts"; "i"))
    ' "$file" 2>/dev/null || true)

    [[ "$result" == "true" ]]
}

is_canonical() {
    local file="$1"
    local result
    result=$("$yq_cmd" --front-matter=extract -r '
        has("title") and
        has("description") and
        has("draft") and
        has("pubDatetime") and
        has("tags") and
        (has("status") | not) and
        (has("published") | not)
    ' "$file" 2>/dev/null || true)

    [[ "$result" == "true" ]]
}

backup_file() {
    local file="$1"
    local relative="${file#"${VAULT_PATH}/"}"
    local destination="${backup_root}/${relative}"

    mkdir -p "$(dirname "$destination")"
    cp -p "$file" "$destination"
}

normalize_note() {
    local file="$1"
    local filename
    local fallback_title
    local explicit_draft
    local legacy_status
    local current_title
    local current_description
    local current_pub_datetime
    local legacy_published
    local tags_present
    local tags_length
    local topics_length
    local default_draft="true"
    local temp_file

    filename=$(basename "$file")
    fallback_title="${filename%.md}"
    explicit_draft=$(get_frontmatter_field "$file" "draft")
    legacy_status=$(get_frontmatter_field "$file" "status" | tr '[:upper:]' '[:lower:]')
    current_title=$(get_frontmatter_field "$file" "title")
    current_description=$(get_frontmatter_field "$file" "description")
    current_pub_datetime=$(get_frontmatter_field "$file" "pubDatetime")
    legacy_published=$(get_frontmatter_field "$file" "published")
    tags_present=$("$yq_cmd" --front-matter=extract -r 'has("tags")' "$file")
    tags_length=$("$yq_cmd" --front-matter=extract -r '.tags // [] | length' "$file")
    topics_length=$("$yq_cmd" --front-matter=extract -r '.topics // [] | length' "$file")

    if [[ "$explicit_draft" == "false" ]]; then
        default_draft="false"
    elif [[ -z "$explicit_draft" && "$legacy_status" == *"published"* ]]; then
        default_draft="false"
    fi

    temp_file=$(mktemp)
    cp "$file" "$temp_file"

    export FALLBACK_TITLE="$fallback_title"
    export DEFAULT_DRAFT="$default_draft"

    if [[ -z "$current_title" ]]; then
        "$yq_cmd" --front-matter=process -i '.title = strenv(FALLBACK_TITLE)' "$temp_file"
    fi
    if [[ -z "$current_description" ]]; then
        "$yq_cmd" --front-matter=process -i '.description = "TBD"' "$temp_file"
    fi
    if [[ -z "$explicit_draft" ]]; then
        "$yq_cmd" --front-matter=process -i '.draft = (strenv(DEFAULT_DRAFT) == "true")' "$temp_file"
    fi
    if [[ -z "$current_pub_datetime" && -n "$legacy_published" ]]; then
        "$yq_cmd" --front-matter=process -i '.pubDatetime = .published' "$temp_file"
    elif [[ -z "$current_pub_datetime" ]]; then
        "$yq_cmd" --front-matter=process -i '.pubDatetime = null' "$temp_file"
    fi
    if [[ "$tags_length" -eq 0 && "$topics_length" -gt 0 ]]; then
        "$yq_cmd" --front-matter=process -i '.tags = .topics' "$temp_file"
    elif [[ "$tags_present" != "true" ]]; then
        "$yq_cmd" --front-matter=process -i '.tags = []' "$temp_file"
    fi
    "$yq_cmd" --front-matter=process -i 'del(.status) | del(.published)' "$temp_file"

    unset FALLBACK_TITLE DEFAULT_DRAFT

    if cmp -s "$file" "$temp_file"; then
        rm -f "$temp_file"
        return
    fi

    ((++changed_count))
    local relative="${file#"${VAULT_PATH}/"}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}Would normalize:${RESET} $relative"
        rm -f "$temp_file"
        return
    fi

    backup_file "$file"
    mv "$temp_file" "$file"
    echo -e "  ${GREEN}Normalized:${RESET} $relative"
}

write_blog_template() {
    local template_file="$blog_template_file"
    local temp_file
    temp_file=$(mktemp)

    printf '%s\n' \
        '---' \
        'title: "{{title}}"' \
        'pubDatetime:' \
        'description: "TBD"' \
        'tags: []' \
        'draft: true' \
        '---' \
        '' > "$temp_file"

    if [[ -f "$template_file" ]] && cmp -s "$template_file" "$temp_file"; then
        rm -f "$temp_file"
        return
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}Would write template:${RESET} ${template_file#"${VAULT_PATH}/"}"
        rm -f "$temp_file"
        return
    fi

    if [[ -f "$template_file" ]]; then
        backup_file "$template_file"
    fi

    mkdir -p "$(dirname "$template_file")"
    mv "$temp_file" "$template_file"
    echo -e "  ${GREEN}Template ready:${RESET} ${template_file#"${VAULT_PATH}/"}"
}

echo ""
if [[ "$VERIFY_ONLY" == "true" ]]; then
    echo -e "${CYAN}Verifying Obsidian blog notes...${RESET}"
else
    echo -e "${CYAN}Scanning Obsidian blog notes...${RESET}"
fi

while IFS= read -r -d '' file; do
    has_frontmatter "$file" || continue
    is_blog_note "$file" || continue
    ((++candidate_count))

    if [[ "$VERIFY_ONLY" == "true" ]]; then
        if ! is_canonical "$file"; then
            ((++verified_errors))
            echo -e "  ${RED}Noncanonical:${RESET} ${file#"${VAULT_PATH}/"}"
        fi
    else
        if ! is_canonical "$file"; then
            normalize_note "$file"
        fi
    fi
done < <(
    find "$VAULT_PATH" \
        -path "${VAULT_PATH}/.obsidian" -prune -o \
        -path "${VAULT_PATH}/.blog-migration-backups" -prune -o \
        -name "*.md" -type f -print0
)

if [[ "$VERIFY_ONLY" == "true" ]]; then
    echo ""
    if [[ $verified_errors -gt 0 ]]; then
        echo -e "${RED}Verification failed:${RESET} $verified_errors of $candidate_count blog note(s) need migration."
        exit "$EXIT_ERROR"
    fi
    echo -e "${GREEN}Verification passed:${RESET} $candidate_count blog note(s) use canonical frontmatter."
    exit "$EXIT_SUCCESS"
fi

write_blog_template

echo ""
if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${CYAN}Dry run complete:${RESET} $changed_count of $candidate_count blog note(s) would change."
else
    echo -e "${GREEN}Migration complete:${RESET} $changed_count of $candidate_count blog note(s) changed."
    if [[ $changed_count -gt 0 ]]; then
        echo -e "Backups: ${CYAN}$backup_root${RESET}"
    fi
    echo "Run 'just migrate-vault --verify' to verify the result."
fi
