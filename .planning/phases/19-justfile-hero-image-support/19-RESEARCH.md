# Phase 19: Justfile Hero Image Support - Research

**Researched:** 2026-02-02
**Domain:** Bash scripting, YAML frontmatter processing, yq (mikefarah/yq)
**Confidence:** HIGH

## Summary

This phase updates the justfile publishing workflow scripts to properly handle the new hero image fields (`heroImage`, `heroImageAlt`, `heroImageCaption`) added in Phase 18. The codebase already has a well-established pattern for frontmatter processing using mikefarah/yq.

Analysis of the existing scripts reveals:

1. **publish.sh** (lines 401-413): Already compares `heroImage` field when checking for content changes via `posts_are_identical()`. However, it does NOT compare `heroImageAlt` or `heroImageCaption`.

2. **normalize_frontmatter()** (lines 261-280): Removes empty `heroImage` lines but has no handling for the new alt/caption fields.

3. **common.sh**: The `get_frontmatter_field()` function works correctly with any field name - no changes needed.

4. **Obsidian template** (Phase 18): Already includes `heroImageAlt:` and `heroImageCaption:` fields.

The primary work is:
- Update `posts_are_identical()` to include `heroImageAlt` and `heroImageCaption` in comparison
- Update `normalize_frontmatter()` to remove empty `heroImageAlt` and `heroImageCaption` lines (same pattern as `heroImage`)

**Primary recommendation:** Add `heroImageAlt` and `heroImageCaption` to the fields array in `posts_are_identical()` and add removal of empty lines to `normalize_frontmatter()` following the existing `heroImage` pattern.

## Standard Stack

The established tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| mikefarah/yq | 4.x | YAML frontmatter processing | Already in use via `go-yq` (Arch) or `yq` |
| Bash | 5.x | Shell scripting | POSIX-compliant, already used |
| Perl | 5.x | Text manipulation | Already used for regex operations |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| jq | 1.7+ | JSON config reading | Already used for settings.local.json |
| grep/sed | GNU | Pattern matching | Fallback when yq unavailable |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| yq for YAML | sed regex | yq is more robust, already used everywhere |
| Perl for regex | sed | Perl handles edge cases better, already used |

**Installation:** No new packages needed - all tools already in place.

## Architecture Patterns

### Current Script Structure
```
scripts/
├── lib/
│   └── common.sh        # Shared library: frontmatter extraction, yq helpers
├── publish.sh           # Main publishing workflow - NEEDS UPDATE
├── unpublish.sh         # Unpublish workflow - no changes needed
├── list-posts.sh        # Post listing - no changes needed
└── migrate-schema.sh    # Schema migration - reference for yq patterns
```

### Pattern 1: Field Comparison Array
**What:** Maintain a list of frontmatter fields to compare when detecting changes
**Where:** `publish.sh` line 402
**Current:**
```bash
local fields=("title" "description" "pubDatetime" "heroImage")
```
**Updated:**
```bash
local fields=("title" "description" "pubDatetime" "heroImage" "heroImageAlt" "heroImageCaption")
```

### Pattern 2: Empty Field Removal (Normalization)
**What:** Remove empty optional fields from frontmatter before publishing
**Where:** `publish.sh` lines 277-278
**Current:**
```bash
# Remove empty heroImage lines
content=$(echo "$content" | perl -pe 's/^heroImage:\s*$\n?//m')
```
**Extended pattern:**
```bash
# Remove empty hero image fields (heroImage, heroImageAlt, heroImageCaption)
content=$(echo "$content" | perl -pe 's/^heroImage:\s*$\n?//m')
content=$(echo "$content" | perl -pe 's/^heroImageAlt:\s*$\n?//m')
content=$(echo "$content" | perl -pe 's/^heroImageCaption:\s*$\n?//m')
```

### Pattern 3: Two-Way Sync Field Preservation
**What:** The `update_obsidian_source()` function in common.sh only modifies `draft` and `pubDatetime` fields
**Impact:** Hero image fields are untouched during sync - this is correct behavior
**No changes needed:** Hero image data flows one-way from Obsidian to blog

### Anti-Patterns to Avoid
- **Adding validation for hero image fields:** These are optional, don't validate
- **Modifying common.sh `validate_frontmatter()`:** Hero image fields should not be validated (they're optional)
- **Adding hero image fields to unpublish.sh:** Unpublishing doesn't need to know about hero images

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML field extraction | Custom regex | `get_frontmatter_field()` in common.sh | Already handles edge cases |
| Empty field removal | Complex sed | Perl -pe pattern (already used) | Consistent with existing code |
| Field comparison | Custom diff | Loop over fields array pattern | Already implemented, just extend |

**Key insight:** All needed infrastructure exists. This phase is purely about extending existing patterns to cover new fields.

## Common Pitfalls

### Pitfall 1: Not Including All Three Fields in Comparison
**What goes wrong:** If only `heroImage` is compared, changes to alt/caption won't trigger republish detection
**Why it happens:** Forgetting that `posts_are_identical()` needs all three fields
**How to avoid:** Add all three fields to the comparison array: `heroImage`, `heroImageAlt`, `heroImageCaption`
**Warning signs:** Editing alt text in Obsidian doesn't show as "update" in publish list

### Pitfall 2: Removing Non-Empty Fields
**What goes wrong:** Regex accidentally removes fields with content
**Why it happens:** Incorrect regex pattern
**How to avoid:** Use exact pattern `^fieldName:\s*$` which only matches empty lines (the `$` anchors to end-of-line, ensuring nothing follows the colon/spaces)
**Warning signs:** Posts lose their hero image data during publish

### Pitfall 3: Breaking Backward Compatibility
**What goes wrong:** Old posts fail to publish
**Why it happens:** Making hero image fields mandatory in validation
**How to avoid:** Hero image fields are NEVER validated - they remain purely optional
**Warning signs:** `just list-posts` shows "Invalid" for posts without hero images

### Pitfall 4: Modifying Wrong File Section
**What goes wrong:** Changes break other functionality
**Why it happens:** Editing wrong function in publish.sh
**How to avoid:** Changes are limited to two specific functions: `posts_are_identical()` and `normalize_frontmatter()`
**Warning signs:** Tests fail for unrelated publish operations

## Code Examples

Verified patterns from existing codebase:

### Update posts_are_identical() - Line 402
```bash
# Source: publish.sh posts_are_identical() function
# Current:
local fields=("title" "description" "pubDatetime" "heroImage")
# Update to:
local fields=("title" "description" "pubDatetime" "heroImage" "heroImageAlt" "heroImageCaption")
```

### Update normalize_frontmatter() - After Line 278
```bash
# Source: publish.sh normalize_frontmatter() function
# Add after existing heroImage removal (line 278):

# Remove empty heroImageAlt lines (heroImageAlt: followed by newline or nothing)
content=$(echo "$content" | perl -pe 's/^heroImageAlt:\s*$\n?//m')

# Remove empty heroImageCaption lines (heroImageCaption: followed by newline or nothing)
content=$(echo "$content" | perl -pe 's/^heroImageCaption:\s*$\n?//m')
```

### Complete normalize_frontmatter() After Changes
```bash
normalize_frontmatter() {
    # Normalize frontmatter types for Astro schema compatibility
    # Takes content as input, returns normalized content
    local content="$1"

    # Get author from config, fallback to site default
    local author
    author=$(get_author_from_config)
    if [[ -z "$author" ]]; then
        author="Justin Carlson"  # Default from site config
    fi

    # Replace author array with config value
    content=$(echo "$content" | perl -0777 -pe "s/^author:\s*\n\s*-\s*.*\$/author: \"$author\"/m")

    # Remove empty heroImage lines (heroImage: followed by newline or nothing)
    content=$(echo "$content" | perl -pe 's/^heroImage:\s*$\n?//m')

    # Remove empty heroImageAlt lines
    content=$(echo "$content" | perl -pe 's/^heroImageAlt:\s*$\n?//m')

    # Remove empty heroImageCaption lines
    content=$(echo "$content" | perl -pe 's/^heroImageCaption:\s*$\n?//m')

    echo "$content"
}
```

### Test Cases to Verify

**Test 1: Empty fields are removed**
```yaml
# Before (Obsidian template default)
heroImage:
heroImageAlt:
heroImageCaption:

# After normalize_frontmatter()
# (all three lines removed)
```

**Test 2: Populated fields are preserved**
```yaml
# Before
heroImage: /assets/blog/my-post/hero.png
heroImageAlt: My hero image description
heroImageCaption: Photo credit here

# After
heroImage: /assets/blog/my-post/hero.png
heroImageAlt: My hero image description
heroImageCaption: Photo credit here
# (no change - fields have content)
```

**Test 3: Mixed empty/populated preserved correctly**
```yaml
# Before
heroImage: /assets/blog/my-post/hero.png
heroImageAlt:
heroImageCaption: Photo credit

# After
heroImage: /assets/blog/my-post/hero.png
heroImageCaption: Photo credit
# (only heroImageAlt removed since it was empty)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Only compare `heroImage` | Compare all three hero fields | Phase 19 | Changes to alt/caption trigger republish |
| Only remove empty `heroImage:` | Remove all three empty hero fields | Phase 19 | Cleaner frontmatter in published posts |

**Deprecated/outdated:**
- None - this is a new feature addition extending Phase 18

## Open Questions

Things that couldn't be fully resolved:

1. **Should migrate-schema.sh handle hero image cleanup?**
   - What we know: migrate-schema.sh is for one-time schema migration (status -> draft)
   - What's unclear: Whether existing posts in vault need heroImageAlt/heroImageCaption cleanup
   - Recommendation: No - migrate-schema.sh is for draft migration only. Posts created with old templates without these fields don't need migration since the fields are optional.

2. **Should list-posts.sh display hero image status?**
   - What we know: list-posts.sh shows title, date, status (ready/invalid)
   - What's unclear: Whether users want to see if posts have hero images
   - Recommendation: Out of scope for Phase 19. Could be a future enhancement but not part of SCRIPT-01 requirement.

## Sources

### Primary (HIGH confidence)
- `/home/jc/developer/justcarlson.com/scripts/publish.sh` - main script with functions to update
- `/home/jc/developer/justcarlson.com/scripts/lib/common.sh` - shared library patterns
- `/home/jc/developer/justcarlson.com/src/content.config.ts` - schema definition (heroImageAlt, heroImageCaption on lines 21-22)
- `/home/jc/developer/justcarlson.com/.planning/phases/18-image-caption-support/18-RESEARCH.md` - Phase 18 context

### Secondary (MEDIUM confidence)
- `/home/jc/developer/justcarlson.com/scripts/migrate-schema.sh` - reference for yq patterns and field manipulation
- `/home/jc/notes/personal-vault/Templates/Post Template.md` - Obsidian template with new fields

### Tertiary (LOW confidence)
- None - all findings verified from codebase

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all tools already in use, verified from codebase
- Architecture: HIGH - extending existing patterns, minimal changes
- Pitfalls: HIGH - based on actual code structure and documented patterns

**Research date:** 2026-02-02
**Valid until:** 2026-03-02 (30 days - stable domain, bash scripts don't change rapidly)
