#!/usr/bin/env bash
# SessionStart hook for blog publishing workflow
# Outputs JSON with hookSpecificOutput.additionalContext for user-visible messages

CONFIG_FILE="$CLAUDE_PROJECT_DIR/.claude/settings.local.json"

# Check if vault is configured
if [[ ! -f "$CONFIG_FILE" ]] || ! jq -e '.obsidianVaultPath' "$CONFIG_FILE" >/dev/null 2>&1; then
    jq -n '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: "Obsidian vault not configured. Run /blog:install to set up."}}'
    exit 0
fi

# Vault configured - check for posts ready to publish
VAULT_PATH=$(jq -r '.obsidianVaultPath' "$CONFIG_FILE")
if [[ -d "$VAULT_PATH" ]]; then
    # Count posts with Published status using same pattern as list-posts.sh
    # YAML format: status:\n  - Published
    POST_COUNT=0
    while IFS= read -r -d '' file; do
        if perl -0777 -ne 'exit(!/status:\s*\n\s*-\s*[Pp]ublished/i)' "$file" 2>/dev/null; then
            ((POST_COUNT++))
        fi
    done < <(find "$VAULT_PATH" -name "*.md" -type f -print0 2>/dev/null)
    if [[ "$POST_COUNT" -gt 0 ]]; then
        jq -n --arg msg "Ready: $POST_COUNT post(s) with Published status. Run /blog:publish to continue." \
            '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $msg}}'
    fi
fi

exit 0
