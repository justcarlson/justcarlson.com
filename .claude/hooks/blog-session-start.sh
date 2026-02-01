#!/usr/bin/env bash
# SessionStart hook for blog publishing workflow
# Outputs actionable suggestion based on current state

CONFIG_FILE="$CLAUDE_PROJECT_DIR/.claude/settings.local.json"

# Check if vault is configured
if [[ ! -f "$CONFIG_FILE" ]] || ! jq -e '.obsidianVaultPath' "$CONFIG_FILE" >/dev/null 2>&1; then
    echo "Obsidian vault not configured. Run /blog:install to set up."
    exit 0
fi

# Vault configured - check for posts ready to publish
VAULT_PATH=$(jq -r '.obsidianVaultPath' "$CONFIG_FILE")
if [[ -d "$VAULT_PATH" ]]; then
    # Count posts with Published status (case-insensitive)
    POST_COUNT=$(find "$VAULT_PATH" -name "*.md" -type f -exec grep -l -i "- Published" {} \; 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$POST_COUNT" -gt 0 ]]; then
        echo "Ready: $POST_COUNT post(s) with Published status. Run /blog:publish to continue."
    fi
fi

exit 0
