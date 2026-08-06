#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${repo_root}/scripts/lib/common.sh"
_has_mikefarah_yq
yq_cmd=$(_get_yq_cmd)

test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

workspace="${test_root}/workspace"
vault="${test_root}/vault"
mkdir -p "${workspace}/.claude" "${vault}/.obsidian" "${vault}/Blog Posts" "${vault}/Clippings" "${vault}/Templates"
cp -R "${repo_root}/scripts" "${workspace}/scripts"

jq -n --arg path "$vault" '{obsidianVaultPath: $path}' > "${workspace}/.claude/settings.local.json"
jq -n --arg folder "Templates" '{folder: $folder}' > "${vault}/.obsidian/templates.json"

cat > "${vault}/Blog Posts/Legacy Blog Note.md" <<'EOF'
---
title: Legacy Blog Note
published: 2025-01-02
status: Published
topics:
  - writing
---

Blog body.
EOF

cat > "${vault}/Clippings/Published Clipping.md" <<'EOF'
---
title: Published Clipping
published: 2025-01-02
status: Published
topics:
  - research
---

Clipping body.
EOF

output=$(cd "$workspace" && ./scripts/migrate-vault.sh --dry-run)

grep -q 'Would normalize:.*Blog Posts/Legacy Blog Note.md' <<< "$output"
if grep -q 'Would normalize:.*Clippings/Published Clipping.md' <<< "$output"; then
    echo "FAIL: default migration selected a note outside Blog Posts" >&2
    exit 1
fi
grep -q 'Would write template:.*Templates/Blog Post.md' <<< "$output"

all_output=$(cd "$workspace" && ./scripts/migrate-vault.sh --dry-run --all)
grep -q 'Would normalize:.*Clippings/Published Clipping.md' <<< "$all_output"

clipping_hash=$(sha256sum "${vault}/Clippings/Published Clipping.md")
(cd "$workspace" && ./scripts/migrate-vault.sh >/dev/null)

"$yq_cmd" --front-matter=extract -e '
    .title == "Legacy Blog Note" and
    .pubDatetime == "2025-01-02" and
    .description == "TBD" and
    (.tags | length) == 1 and
    .tags[0] == "writing" and
    .draft == false and
    (has("status") | not) and
    (has("published") | not)
' "${vault}/Blog Posts/Legacy Blog Note.md" >/dev/null
test "$(sha256sum "${vault}/Clippings/Published Clipping.md")" = "$clipping_hash"
test -f "${vault}/Templates/Blog Post.md"
test "$(find "${vault}/.blog-migration-backups" -type f -path '*/Blog Posts/Legacy Blog Note.md' | wc -l)" -eq 1

echo "PASS: default migration is limited to Blog Posts and the configured template"
