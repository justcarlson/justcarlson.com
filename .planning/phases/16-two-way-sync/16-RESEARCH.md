# Phase 16: Two-Way Sync - Research

**Researched:** 2026-02-01
**Domain:** Bash shell scripting, YAML frontmatter modification, file safety patterns
**Confidence:** HIGH

## Summary

This phase implements bidirectional metadata sync between the Obsidian vault source files and blog copies. Currently, `just publish` and `just unpublish` only modify the blog repository; this phase extends them to update the original Obsidian source files with publication metadata (`draft: true/false`, `pubDatetime`).

The standard approach uses mikefarah/yq v4's `--front-matter=process` with `-i` flag for in-place YAML modification, combined with a backup-before-modify pattern (cp to `.bak` file). This leverages the yq infrastructure already established in Phase 15. The dry-run pattern follows established conventions: use a global flag and wrap modifying operations with conditional checks.

**Primary recommendation:** Add `update_obsidian_source()` function to common.sh that creates `.bak` backup then uses `yq --front-matter=process -i` for field updates. Extend publish.sh and unpublish.sh to call this after successful blog operations.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| mikefarah/yq | v4.52.x | YAML frontmatter modification | Has `--front-matter=process -i` for in-place markdown editing |
| bash cp | coreutils | Backup creation | `cp file{,.bak}` pattern for pre-modification backup |
| jq | latest | JSON config reading | Already used for settings.local.json |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| date | coreutils | ISO8601 timestamp generation | `date -Iseconds` for pubDatetime value |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| .bak files | Write-to-temp-then-rename | More complex; .bak is simpler for single-file edits with human-recoverable backups |
| yq in-place | sed -i with backup | yq understands YAML structure; sed is fragile for quoted values |
| Per-file backup | Git stash | Overkill for single file; user may not have clean git state |

## Architecture Patterns

### Recommended Function Structure
```
scripts/lib/common.sh (add functions):
├── update_obsidian_source()    # Main sync function
├── get_author_from_config()    # Read author from settings.local.json
└── create_backup()             # cp file{,.bak} helper

scripts/publish.sh (extend):
└── After copy_post(), call update_obsidian_source() with draft=false, set pubDatetime

scripts/unpublish.sh (extend):
└── After remove_post(), call update_obsidian_source() with draft=true
└── Add --dry-run flag support
```

### Pattern 1: Backup-Before-Modify
**What:** Create `.bak` copy of file before any modification
**When to use:** Before modifying user's source files (Obsidian vault)
**Example:**
```bash
# Source: Standard bash practice
create_backup() {
    local file="$1"
    cp "$file" "${file}.bak"
    echo -e "  ${CYAN}Backup:${RESET} ${file}.bak"
}

# Usage before yq modification:
create_backup "$obsidian_file"
yq --front-matter=process -i '.draft = false' "$obsidian_file"
```

### Pattern 2: yq Frontmatter In-Place Update
**What:** Modify YAML frontmatter while preserving markdown content
**When to use:** Any frontmatter field update in markdown files
**Example:**
```bash
# Source: https://mikefarah.gitbook.io/yq/usage/front-matter

# Set boolean field
yq --front-matter=process -i '.draft = false' "$file"

# Set string field with variable (use strenv for special characters)
export DATETIME="2026-02-01T12:00:00-08:00"
yq --front-matter=process -i '.pubDatetime = strenv(DATETIME)' "$file"

# Multiple updates in one command
yq --front-matter=process -i '.draft = false | .pubDatetime = strenv(DATETIME)' "$file"
```

### Pattern 3: Dry-Run Flag Pattern
**What:** Preview changes without modifying files
**When to use:** Commands that modify external files (especially user's vault)
**Example:**
```bash
# Source: Standard CLI convention

# At top of script
DRY_RUN=false

# Argument parsing
case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
esac

# Before modification
if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY-RUN] Would update: $file"
    echo "  draft: false"
    echo "  pubDatetime: $datetime"
else
    create_backup "$file"
    yq --front-matter=process -i ".draft = false | .pubDatetime = \"$datetime\"" "$file"
fi
```

### Pattern 4: Config-Driven Author Value
**What:** Read author name from settings.local.json instead of hardcoding
**When to use:** Any place that needs the author name for frontmatter
**Example:**
```bash
# Source: Existing load_config pattern in common.sh

get_author_from_config() {
    # Read author from settings.local.json, with fallback
    local author
    author=$(jq -r '.author // empty' "$CONFIG_FILE" 2>/dev/null)
    if [[ -z "$author" ]]; then
        # Fallback to default (could also read from consts.ts)
        author="Justin Carlson"
    fi
    echo "$author"
}

# Usage in normalize_frontmatter:
local author
author=$(get_author_from_config)
content=$(echo "$content" | perl -0777 -pe "s/^author:\s*\n\s*-\s*.*\$/author: \"$author\"/m")
```

### Anti-Patterns to Avoid
- **Modifying vault files without backup:** User cannot recover if something goes wrong
- **Hardcoding author name:** Breaks portability; should come from config
- **Using yq without --front-matter flag:** Will corrupt markdown content after frontmatter
- **Dry-run that still creates files:** Dry-run must be truly read-only

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML field modification | sed/perl regex | `yq --front-matter=process -i` | Handles all YAML edge cases |
| ISO8601 timestamps | Manual string formatting | `date -Iseconds` | Correct format with timezone |
| File backup | Custom backup logic | `cp file{,.bak}` | One-liner, bash builtin |
| Config value reading | grep/sed JSON parsing | `jq -r '.field'` | Already established pattern |

**Key insight:** yq with `--front-matter=process -i` handles the hard part (modifying YAML while preserving markdown content). The backup pattern is simple insurance that makes the operation reversible.

## Common Pitfalls

### Pitfall 1: Forgetting --front-matter Flag
**What goes wrong:** yq treats entire file as YAML, corrupts markdown content
**Why it happens:** Default yq behavior is pure YAML processing
**How to avoid:** Always use `--front-matter=process` for markdown files
**Warning signs:** File content after `---` is corrupted or missing

### Pitfall 2: yq Version Mismatch
**What goes wrong:** `--front-matter` flag not recognized or behaves differently
**Why it happens:** System has kislyuk/yq (Python) instead of mikefarah/yq (Go)
**How to avoid:** Check `yq --version` shows "mikefarah/yq"; use existing `_has_mikefarah_yq()` check
**Warning signs:** "unknown flag" errors, syntax errors

### Pitfall 3: Timezone Issues with pubDatetime
**What goes wrong:** Timestamps have wrong timezone or no timezone
**Why it happens:** Using `date` without timezone flag
**How to avoid:** Use `date -Iseconds` which includes timezone offset (e.g., `-08:00`)
**Warning signs:** pubDatetime shows UTC when user is in PST

### Pitfall 4: Backup File Accumulation
**What goes wrong:** Multiple `.bak` files accumulate over time
**Why it happens:** Each publish/unpublish creates new backup
**How to avoid:**
- Only create backup if modification will actually happen
- Document that .bak files are user's responsibility to clean up
- Consider: overwrite existing .bak (simpler) vs timestamp suffix (more backups)
**Warning signs:** Obsidian vault has many `.bak` files

### Pitfall 5: Dry-Run Leaking Side Effects
**What goes wrong:** Dry-run still modifies files or creates backups
**Why it happens:** Some code paths not wrapped in dry-run check
**How to avoid:** Audit all file-modifying operations; use centralized function
**Warning signs:** `.bak` files created during `--dry-run`

### Pitfall 6: Config File Missing Author Field
**What goes wrong:** Author normalization fails or uses wrong value
**Why it happens:** Existing settings.local.json doesn't have `author` field
**How to avoid:** Use fallback pattern; optionally prompt user during setup
**Warning signs:** Posts have null/empty author, or author stays as Obsidian format

## Code Examples

Verified patterns from official sources:

### Complete update_obsidian_source Function
```bash
# Source: yq docs + established common.sh patterns

update_obsidian_source() {
    # Update Obsidian source file with publication metadata
    # Args:
    #   $1: obsidian_file - Path to source file in vault
    #   $2: action - "publish" or "unpublish"
    #   $3: dry_run - "true" or "false"
    local obsidian_file="$1"
    local action="$2"
    local dry_run="${3:-false}"

    if [[ ! -f "$obsidian_file" ]]; then
        echo -e "${YELLOW}Warning: Source file not found: $obsidian_file${RESET}"
        return 1
    fi

    local yq_cmd
    yq_cmd=$(_get_yq_cmd)

    if [[ "$action" == "publish" ]]; then
        # Set draft=false and pubDatetime
        local datetime
        datetime=$(date -Iseconds)

        if [[ "$dry_run" == "true" ]]; then
            echo -e "  [DRY-RUN] Would update Obsidian source:"
            echo -e "    File: $obsidian_file"
            echo -e "    draft: false"
            echo -e "    pubDatetime: $datetime"
        else
            # Create backup
            cp "$obsidian_file" "${obsidian_file}.bak"
            echo -e "  ${CYAN}Backup:${RESET} ${obsidian_file}.bak"

            # Update frontmatter
            export DATETIME="$datetime"
            "$yq_cmd" --front-matter=process -i \
                '.draft = false | .pubDatetime = strenv(DATETIME)' \
                "$obsidian_file"
            unset DATETIME

            echo -e "  ${GREEN}Updated:${RESET} draft=false, pubDatetime=$datetime"
        fi

    elif [[ "$action" == "unpublish" ]]; then
        # Set draft=true
        if [[ "$dry_run" == "true" ]]; then
            echo -e "  [DRY-RUN] Would update Obsidian source:"
            echo -e "    File: $obsidian_file"
            echo -e "    draft: true"
        else
            # Create backup
            cp "$obsidian_file" "${obsidian_file}.bak"
            echo -e "  ${CYAN}Backup:${RESET} ${obsidian_file}.bak"

            # Update frontmatter
            "$yq_cmd" --front-matter=process -i '.draft = true' "$obsidian_file"

            echo -e "  ${GREEN}Updated:${RESET} draft=true"
        fi
    fi
}
```

### Get Author from Config
```bash
# Source: Existing jq pattern in common.sh

get_author_from_config() {
    # Read author from settings.local.json
    # Returns configured author or empty string if not set
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return
    fi

    jq -r '.author // empty' "$CONFIG_FILE" 2>/dev/null
}

# Usage in normalize_frontmatter:
normalize_frontmatter() {
    local content="$1"

    # Get author from config, fallback to site default
    local author
    author=$(get_author_from_config)
    if [[ -z "$author" ]]; then
        author="Justin Carlson"  # Default from consts.ts
    fi

    # Replace author array with string
    content=$(echo "$content" | perl -0777 -pe "s/^author:\s*\n\s*-\s*.*\$/author: \"$author\"/m")

    # ... rest of normalization
    echo "$content"
}
```

### ISO8601 Timestamp Generation
```bash
# Source: GNU coreutils date documentation

# Full ISO8601 with timezone offset
datetime=$(date -Iseconds)
# Output: 2026-02-01T12:34:56-08:00

# If you need UTC specifically:
datetime=$(date -u -Iseconds)
# Output: 2026-02-01T20:34:56+00:00
```

### Extending unpublish.sh with --dry-run
```bash
# Source: Established pattern from publish.sh

# Add to argument parsing in unpublish.sh:
DRY_RUN=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            # ... existing options
        esac
    done
}

# In main flow, after identifying post to unpublish:
if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY-RUN] Would remove from blog: $post_path"
    echo "[DRY-RUN] Would update Obsidian source: $obsidian_file"
    echo "  draft: true"
else
    remove_post "$post_path"
    update_obsidian_source "$obsidian_file" "unpublish" "$DRY_RUN"
fi
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One-way publish (vault -> blog only) | Two-way sync (metadata flows back) | This phase | Source of truth stays in sync |
| Hardcoded author string | Config-driven author | This phase | Multi-user/fork friendly |
| No Obsidian file modification | Backup + yq modification | This phase | Safe with recovery option |

**Deprecated/outdated:**
- Manual status editing in Obsidian after publish/unpublish (now automated)
- Using `status: Published` as discovery trigger (phase changes to `draft: false`)

## Open Questions

Things that couldn't be fully resolved:

1. **Should setup.sh prompt for author name?**
   - What we know: Config currently only has `obsidianVaultPath`; could add `author` field
   - What's unclear: Whether to add it to setup flow or just document manual config
   - Recommendation: Add optional `--author` flag to setup.sh, but don't require it (use fallback)

2. **Backup file naming: `.bak` vs timestamped?**
   - What we know: Simple `.bak` overwrites previous backup; timestamped creates multiple files
   - What's unclear: User preference and vault hygiene
   - Recommendation: Use simple `.bak` (one backup) - keeps vault clean, user can manually backup if needed

3. **Should we find Obsidian source from blog post?**
   - What we know: publish.sh tracks source file -> blog path mapping during processing
   - What's unclear: For unpublish, we start with blog file, need to find Obsidian source
   - Recommendation: Store source path in frontmatter during publish (add `sourceFile` field) OR search vault by slug

## Sources

### Primary (HIGH confidence)
- [yq Front Matter documentation](https://mikefarah.gitbook.io/yq/usage/front-matter) - --front-matter flag usage and modes
- [yq GitHub repository](https://github.com/mikefarah/yq) - -i flag, strenv() function, version info
- [GNU coreutils date](https://www.gnu.org/software/coreutils/manual/html_node/date-invocation.html) - ISO8601 format with -Iseconds

### Secondary (MEDIUM confidence)
- [Bash backup patterns](https://backendtea.com/how-to/backup-file-bash/) - cp file{,.bak} expansion
- [Dry-run patterns](https://www.codegenes.net/blog/show-commands-without-executing-them/) - --dry-run flag implementation
- Phase 15 research - Established yq patterns in this codebase

### Tertiary (LOW confidence)
- None - all findings verified with primary or secondary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - yq patterns verified in Phase 15 and official docs
- Architecture: HIGH - Extends existing patterns in common.sh
- Pitfalls: HIGH - Based on documented yq limitations and established bash practices

**Research date:** 2026-02-01
**Valid until:** 2026-03-01 (30 days - stable domain, builds on Phase 15)

---

## Appendix: Requirements Mapping

| Requirement | Implementation |
|-------------|----------------|
| SYNC-01: unpublish sets draft: true | `update_obsidian_source "$file" "unpublish"` |
| SYNC-02: publish sets pubDatetime | `update_obsidian_source` with `date -Iseconds` |
| SYNC-03: publish sets draft: false | `update_obsidian_source "$file" "publish"` |
| SYNC-04: Backup before Obsidian modification | `cp "$file" "${file}.bak"` before yq |
| SYNC-05: unpublish --dry-run | `DRY_RUN` flag in unpublish.sh |
| CONF-01: Author from config | `get_author_from_config()` function |
