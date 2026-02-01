# Phase 11: Content & Workflow Polish - Research

**Researched:** 2026-01-31
**Domain:** Claude Code Skills/Hooks, Obsidian-to-Astro Publishing Workflow, Content Frontmatter
**Confidence:** HIGH

## Summary

This phase addresses three distinct areas: fixing the title duplication bug in templates, renaming skills to use the `/blog:` prefix for discoverability, and enhancing the SessionStart hook to detect state and provide appropriate suggestions.

**CORRECTION:** Colons ARE valid in skill names. GSD uses this pattern extensively (`gsd:plan-phase`, `gsd:execute-phase`, etc.). The colon is set in the frontmatter `name:` field. Skills can be organized in subdirectories (e.g., `blog/publish/SKILL.md` with `name: blog:publish`).

For SessionStart hooks, stdout text is added as context that Claude can see and act on. The hook receives source information indicating startup/resume/clear/compact status.

**Recommendation:** Use `/blog:publish`, `/blog:install`, etc. (colon-based naming like GSD). Group all blog skills in a `blog/` skills subdirectory for organization.

## Standard Stack

This phase uses existing infrastructure - no new libraries needed.

### Core (Already in Place)
| Component | Purpose | Status |
|-----------|---------|--------|
| `.claude/skills/` | Skill definitions | Exists, needs renaming |
| `.claude/settings.json` | Hook configuration | Exists, needs update |
| `scripts/publish.sh` | Publish workflow | Exists, works |
| Astro Content Collections | Blog schema with tags | Exists, works |

### Supporting Components
| Component | Purpose | Notes |
|-----------|---------|-------|
| `src/content.config.ts` | Defines blog schema | tags default to `["others"]` |
| `src/utils/getUniqueTags.ts` | Tag extraction | Already functional |
| `src/components/Tag.astro` | Tag rendering | Uses `#` prefix, clickable |

## Architecture Patterns

### Skill Naming Convention

**CORRECTED:** Colons ARE valid in skill names (GSD uses `gsd:plan-phase`, `gsd:execute-phase`, etc.). Use `name: blog:publish` in frontmatter.

**Current skills:**
```
.claude/skills/
  install/SKILL.md      (name: install)
  publish/SKILL.md      (name: publish)
  list-posts/SKILL.md   (name: list-posts)
  maintain/SKILL.md     (name: maintain)
  unpublish/SKILL.md    (name: unpublish)
```

**Recommended pattern (colon-based, like GSD):**
```
.claude/skills/blog/
  install/SKILL.md      (name: blog:install)
  publish/SKILL.md      (name: blog:publish)
  list-posts/SKILL.md   (name: blog:list-posts)
  maintain/SKILL.md     (name: blog:maintain)
  unpublish/SKILL.md    (name: blog:unpublish)
  help/SKILL.md         (name: blog:help)   [NEW]
```

Note: The directory structure doesn't affect the command name. The `name` field in frontmatter determines the `/slash-command`. GSD uses this pattern: `~/.claude/commands/gsd/plan-phase.md` → `name: gsd:plan-phase`.

### SessionStart Hook State Detection

**Current implementation:**
```json
{
  "SessionStart": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "test -f ... || echo 'Vault not configured. Run /install for guided setup.'"
        }
      ]
    }
  ]
}
```

**Enhanced implementation approach:**
```bash
#!/bin/bash
# SessionStart hook for blog publishing workflow

CONFIG_FILE="$CLAUDE_PROJECT_DIR/.claude/settings.local.json"

# Check if vault is configured
if [[ ! -f "$CONFIG_FILE" ]] || ! jq -e '.obsidianVaultPath' "$CONFIG_FILE" >/dev/null 2>&1; then
    echo "Obsidian vault not configured. Run /blog-install to set up."
    exit 0
fi

# Vault configured - check for posts ready to publish
VAULT_PATH=$(jq -r '.obsidianVaultPath' "$CONFIG_FILE")
if [[ -d "$VAULT_PATH" ]]; then
    # Check if any posts have Published status
    POST_COUNT=$(find "$VAULT_PATH" -name "*.md" -type f -exec grep -l "Published" {} \; 2>/dev/null | wc -l)
    if [[ $POST_COUNT -gt 0 ]]; then
        echo "Ready to publish: $POST_COUNT post(s) with Published status. Run /blog-publish to continue."
    else
        echo "Blog workflow ready. Use /blog-help to see available commands."
    fi
fi

exit 0
```

**Key insight:** SessionStart stdout is added as context that Claude sees. The hook should output actionable suggestions, not raw data.

### Title Duplication Fix

**Current problem:** Posts have title in both frontmatter AND as H1 in body:
```markdown
---
title: Hello World
---

# Hello World        <-- DUPLICATE

Welcome to my blog...
```

**Solution approach:**

1. **Obsidian Template:** Auto-populate title from filename, no H1 in body
2. **Existing Posts:** Strip leading H1 that matches frontmatter title
3. **Blog Rendering:** Already handles this correctly (PostDetails.astro renders title from frontmatter)

**Template pattern:**
```markdown
---
title: "{{title}}"
pubDatetime: {{date}}T{{time}}:00.000-0500
description:
draft: true
tags: []
categories:
  - "[[Posts]]"
author: "Justin Carlson"
status:
  -
---

<!-- Content starts here, NO H1 -->
```

### Tags Handling

**Current schema** (from `src/content.config.ts`):
```typescript
tags: z.array(z.string()).default(["others"]),
```

**Current rendering** (PostDetails.astro line 160-162):
```astro
<ul class="mt-4 mb-8 sm:my-8">
  {tags.map((tag) => <Tag tag={slugifyStr(tag)} tagName={tag} />)}
</ul>
```

**Tag component** renders with `#` prefix and links to `/tags/{tag}/`.

**"others" tag mystery:** The default value `["others"]` is applied when `tags` is undefined or not provided. If a post has no tags field at all, it gets `["others"]`. This is schema behavior, not a bug.

**Fix approach:** Obsidian template must include empty `tags: []` to avoid the default.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Skill naming with colons | Custom command routing | Hyphenated names | Not supported by Claude Code |
| Tag page generation | Manual routing | Astro dynamic routes | Already exists at `/tags/[tag]/` |
| State detection logic | Complex bash parsing | Simple file/jq checks | KISS principle |

## Common Pitfalls

### ~~Pitfall 1: Colon in Skill Names~~ (CORRECTED)
**CORRECTION:** Colons ARE valid. GSD uses `gsd:plan-phase`, `gsd:execute-phase`, etc. Use `name: blog:publish` in frontmatter.

### Pitfall 2: Title Shows Twice on Blog
**What goes wrong:** Title appears in both rendered frontmatter AND body H1
**Why it happens:** Obsidian template includes `# {{title}}` in body
**How to avoid:** Template should NOT include H1 - frontmatter title is sufficient
**Warning signs:** Reading published post shows duplicate title

### Pitfall 3: "others" Tag Appearing
**What goes wrong:** Posts get tagged with "others" unexpectedly
**Why it happens:** Astro schema defaults `tags` to `["others"]` when field is missing
**How to avoid:** Template must include `tags: []` (empty array, not omitted)
**Warning signs:** /tags/others/ page shows unexpected posts

### Pitfall 4: SessionStart Hook Too Verbose
**What goes wrong:** Long hook output clutters conversation context
**Why it happens:** Treating SessionStart as a diagnostic tool
**How to avoid:** Output should be 1-2 lines of actionable suggestion
**Warning signs:** Claude references hook output in unrelated responses

### Pitfall 5: Kepano Frontmatter Breaks Build
**What goes wrong:** Posts with `categories: - "[[Posts]]"` fail schema validation
**Why it happens:** Astro schema doesn't define `categories` field
**How to avoid:** Ignore/strip Kepano-specific fields during publish OR add them to schema as optional
**Warning signs:** Build errors on category/status/url fields

## Code Examples

### Skill Frontmatter Pattern
```yaml
# Source: Official Claude Code docs (https://code.claude.com/docs/en/skills)
---
name: blog-publish
description: Publish blog posts from Obsidian vault with human oversight
disable-model-invocation: true
hooks:
  Stop:
    - hooks:
        - type: command
          command: "$CLAUDE_PROJECT_DIR/.claude/hooks/verify-build.sh"
          timeout: 120
---
```

### SessionStart Hook Configuration
```json
// Source: Official Claude Code docs (https://code.claude.com/docs/en/hooks)
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/blog-session-start.sh"
          }
        ]
      }
    ]
  }
}
```

### blog-help Skill Content
```yaml
---
name: blog-help
description: List all available blog commands
disable-model-invocation: true
---

# Blog Commands

Available commands for the Obsidian-to-blog publishing workflow:

| Command | Description |
|---------|-------------|
| `/blog-install` | Set up Obsidian vault path and verify dependencies |
| `/blog-publish` | Publish posts marked as Published in Obsidian |
| `/blog-list-posts` | List posts with their validation status |
| `/blog-unpublish` | Remove a published post from the blog |
| `/blog-maintain` | Run maintenance checks on dependencies and content |

## Quick Start

1. Run `/blog-install` to configure your Obsidian vault
2. Mark posts as "Published" in Obsidian
3. Run `/blog-publish` to publish them

For more details, invoke any command directly.
```

### Strip Title H1 from Existing Posts
```bash
# Pattern to detect and strip duplicate H1
# If first non-empty line after frontmatter is H1 matching title, remove it

#!/bin/bash
# strip-duplicate-h1.sh

FILE="$1"
TITLE=$(sed -n '/^---$/,/^---$/p' "$FILE" | grep "^title:" | sed 's/^title:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')

# Get content after frontmatter
CONTENT=$(awk 'BEGIN{count=0} /^---$/{count++; if(count==2){found=1; next}} found{print}' "$FILE")

# Check if first non-empty line is H1 matching title
FIRST_LINE=$(echo "$CONTENT" | grep -v "^$" | head -1)
if [[ "$FIRST_LINE" == "# $TITLE" ]]; then
    echo "Stripping duplicate H1 from $FILE"
    # Remove the H1 line
    awk -v title="$TITLE" '
        BEGIN{count=0; stripped=0}
        /^---$/{count++}
        count>=2 && !stripped && /^# / && $0 == "# " title {stripped=1; next}
        {print}
    ' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
fi
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Slash commands in `.claude/commands/` | Skills in `.claude/skills/` with frontmatter | Claude Code 2.1+ | Skills have more features, both still work |
| Skills hidden by default | Skills visible in `/` menu by default | Claude Code 2.1+ | Better discoverability |
| SessionStart as message | SessionStart stdout as context for Claude | Current | Can guide Claude's suggestions |

**Still valid:**
- `.claude/commands/` files work identically to skills
- Skill name from directory or frontmatter `name` field
- `disable-model-invocation: true` prevents auto-triggering

## Open Questions

1. **Kepano field handling decision needed**
   - What we know: Posts have `categories`, `status`, `url`, `created`, `topics` from Kepano template
   - What's unclear: Should publish script strip these, pass them through, or map to blog equivalents?
   - Recommendation: Add to Astro schema as optional fields (`.optional()`) for forward compatibility, let them pass through silently

2. **Stripping `[[Posts]]` wikilinks**
   - What we know: `categories: - "[[Posts]]"` is Obsidian wikilink format
   - What's unclear: Whether to strip completely or convert to plain text
   - Recommendation: Strip completely during publish since `categories` isn't displayed on blog

## Sources

### Primary (HIGH confidence)
- Claude Code Skills Documentation: https://code.claude.com/docs/en/skills
  - Skill naming requirements (lowercase, numbers, hyphens only)
  - Frontmatter fields reference
  - `disable-model-invocation` behavior

- Claude Code Hooks Documentation: https://code.claude.com/docs/en/hooks
  - SessionStart hook input/output
  - stdout added as context for Claude
  - Hook configuration JSON format

### Secondary (MEDIUM confidence)
- Codebase analysis of existing skills and publish.sh
- Kepano vault template structure from GitHub

### Tertiary (LOW confidence)
- WebSearch results on skill naming conventions (no authoritative source found for colon support)

## Metadata

**Confidence breakdown:**
- Skill naming: HIGH - Official documentation confirms format requirements
- SessionStart hooks: HIGH - Official documentation with examples
- Title handling: HIGH - Direct codebase analysis
- Tag handling: HIGH - Direct schema and component analysis
- Kepano compatibility: MEDIUM - Based on Kepano's public vault, not direct user's vault

**Research date:** 2026-01-31
**Valid until:** 2026-03-01 (Claude Code is fast-moving, check for updates)
