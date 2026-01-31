---
phase: 08-core-publishing
plan: 02
subsystem: publish
tags: [bash, validation, yaml, images, wiki-links, perl]

# Dependency graph
requires:
  - phase: 08-01
    provides: publish.sh with post discovery and selection
provides:
  - Frontmatter validation (title, pubDatetime, description)
  - Wiki-link to markdown image conversion
  - Local image copying to public/assets/blog/[slug]/
affects: [08-03-commit, 08-04-verify]

# Tech tracking
tech-stack:
  added: []
  patterns: [perl for regex transformations, collect-all-errors validation]

key-files:
  created: []
  modified: [scripts/publish.sh]

key-decisions:
  - "Validate all posts before displaying errors (not fail-fast)"
  - "Prompt user to continue with valid posts when some invalid"
  - "Wiki-links with alt text (![[img|alt]]) preserve alt text in markdown"
  - "Missing images warn but don't block publishing"
  - "Search Attachments folder first, then recursive vault search for images"

patterns-established:
  - "Frontmatter extraction with sed between --- markers"
  - "ISO 8601 validation with bash regex"
  - "Wiki-link conversion with perl regex"
  - "Image path rewriting to /assets/blog/[slug]/"

# Metrics
duration: 3min
completed: 2026-01-31
---

# Phase 8 Plan 2: Validation and Image Handling Summary

**Frontmatter validation with collect-all-errors pattern plus wiki-link conversion and local image copying to slug-based asset directories**

## Performance

- **Duration:** 3 min
- **Started:** 2026-01-31T17:58:55Z
- **Completed:** 2026-01-31T18:01:55Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added frontmatter validation checking title, pubDatetime, description (required fields)
- Implemented collect-all-errors pattern: validates all posts before displaying grouped errors
- Added partial-valid handling: prompts user to continue with valid posts only
- Wiki-style `![[image.png]]` converted to markdown with slug-based asset paths
- Wiki-links with alt text `![[img|alt text]]` preserve alt text in output
- Local images copied from Obsidian vault Attachments folder to public/assets/blog/[slug]/
- Missing images produce warning only (don't block publishing)
- Remote URLs (http/https) left unchanged

## Task Commits

Each task was committed atomically:

1. **Task 1: Add frontmatter validation** - `66d2059` (feat)
2. **Task 2: Add image handling and wiki-link conversion** - `7e8a5ab` (feat)

## Files Created/Modified

- `scripts/publish.sh` - Added 326 lines with validation and image handling functions

## Decisions Made

1. **Collect-all-errors pattern** - Validate all selected posts before displaying any errors, grouped by file. Better UX than fail-fast.
2. **Partial-valid prompt** - When some posts valid and some invalid, prompt "2 of 3 posts are valid. Publish the valid ones? [Y/n]"
3. **ISO 8601 flexible** - Accept both full datetime (YYYY-MM-DDTHH:MM:SS) and date-only (YYYY-MM-DD)
4. **Image search fallback** - First check Attachments folder, then recursive vault search for images in subdirectories
5. **Alt text preservation** - Wiki-links `![[img|alt]]` become `![alt](/assets/blog/slug/img)` not `![img](/assets/...)`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - uses existing vault configuration from `just setup`.

## Next Phase Readiness

- Validation and image handling complete for Plan 03 (git commit stage)
- Posts are now transformed and copied to src/content/blog/YYYY/
- Images copied to public/assets/blog/[slug]/
- Script structure ready for final commit/verify integration

---
*Phase: 08-core-publishing*
*Completed: 2026-01-31*
