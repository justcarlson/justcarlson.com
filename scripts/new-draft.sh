#!/usr/bin/env bash
# Create an unpublished blog draft in the configured Obsidian vault.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

print_usage() {
    echo "Usage: $0 \"Post title\""
    echo ""
    echo "Creates a draft in the Blog Posts folder of the configured Obsidian vault."
}

if [[ $# -lt 1 ]]; then
    print_usage >&2
    exit "$EXIT_ERROR"
fi

load_config

title="$*"
slug=$(slugify "$title")

if [[ -z "$slug" ]]; then
    echo -e "${RED}Error: The title does not produce a usable filename.${RESET}" >&2
    exit "$EXIT_ERROR"
fi

draft_dir="${VAULT_PATH}/Blog Posts"
draft_file="${draft_dir}/${slug}.md"

if [[ -e "$draft_file" ]]; then
    echo -e "${RED}Error: Draft already exists: $draft_file${RESET}" >&2
    exit "$EXIT_ERROR"
fi

mkdir -p "$draft_dir"

# Quote the title for safe YAML output.
yaml_title=${title//\\/\\\\}
yaml_title=${yaml_title//\"/\\\"}

printf '%s\n' \
    '---' \
    "title: \"${yaml_title}\"" \
    'pubDatetime:' \
    'description: "TBD"' \
    'tags: []' \
    'draft: true' \
    '---' \
    '' > "$draft_file"

echo ""
echo -e "${GREEN}Draft created:${RESET} $draft_file"
echo ""
echo "Write and revise it in Obsidian. When it is ready:"
echo "  1. Replace description: \"TBD\" with the final summary."
echo "  2. Set draft: false."
echo "  3. Run: just publish --post $slug"
