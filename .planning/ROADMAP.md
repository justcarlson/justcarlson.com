# Roadmap: v0.4.0 Obsidian + Blog Integration Refactor

## Overview

This milestone eliminates technical debt in the publishing workflow by consolidating ~280 lines of duplicated code into a shared library, replacing fragile sed/regex YAML manipulation with yq, implementing two-way sync between Obsidian and blog metadata, and migrating from `status: Published` to `draft: false` as the canonical field. Three phases: foundation (library + tooling), features (two-way sync), then migration (schema cleanup).

## Milestones

- v0.1.0 MVP - Phases 1-6 (shipped 2026-01-30)
- v0.2.0 Publishing Workflow - Phases 7-10 (shipped 2026-01-31)
- v0.3.0 Polish & Portability - Phases 11-14 (shipped 2026-02-01)
- **v0.4.0 Obsidian + Blog Integration Refactor** - Phases 15-17 (in progress)

## Phases

- [x] **Phase 15: Library Extraction + yq Integration** - Consolidate duplicated code and establish reliable YAML tooling
- [x] **Phase 16: Two-Way Sync** - Bidirectional metadata sync between Obsidian and blog
- [ ] **Phase 17: Schema Migration** - Replace status field with draft as source of truth

## Phase Details

### Phase 15: Library Extraction + yq Integration

**Goal**: Eliminate code duplication and establish reliable YAML manipulation patterns
**Depends on**: Nothing (first phase of v0.4.0)
**Requirements**: LIB-01, LIB-02, LIB-03, LIB-04, LIB-05, CONF-02
**Success Criteria** (what must be TRUE):
  1. `yq --version` returns mikefarah/yq v4.x in both local and devcontainer environments
  2. All three scripts (publish.sh, unpublish.sh, list-posts.sh) source common.sh without errors
  3. Running `shellcheck scripts/*.sh scripts/lib/*.sh` produces no errors
  4. Frontmatter extraction using yq correctly handles quoted values, multiline fields, and arrays
**Plans:** 2 plans

Plans:
- [x] 15-01-PLAN.md — Install yq in devcontainer + create common.sh skeleton with constants
- [x] 15-02-PLAN.md — Extract functions to common.sh + migrate all scripts to source it

### Phase 16: Two-Way Sync

**Goal**: Bidirectional metadata sync keeps Obsidian source and blog copy consistent
**Depends on**: Phase 15 (uses yq patterns and common.sh)
**Requirements**: SYNC-01, SYNC-02, SYNC-03, SYNC-04, SYNC-05, CONF-01
**Success Criteria** (what must be TRUE):
  1. Running `just publish` on a post sets `draft: false` and `pubDatetime` in the Obsidian source file
  2. Running `just unpublish` on a post sets `draft: true` in the Obsidian source file
  3. A `.bak` file is created before any Obsidian file modification
  4. Running `just unpublish --dry-run` shows what would change without modifying any files
  5. Author field in published posts uses value from settings.local.json, not hardcoded string
**Plans:** 3 plans

Plans:
- [x] 16-01-PLAN.md — Add update_obsidian_source and get_author_from_config functions to common.sh
- [x] 16-02-PLAN.md — Extend publish.sh with two-way sync and config-driven author
- [x] 16-03-PLAN.md — Extend unpublish.sh with --dry-run flag and Obsidian source sync

### Phase 17: Schema Migration

**Goal**: `draft: true/false` becomes the single source of truth for publish state
**Depends on**: Phase 16 (sync must work before changing source of truth)
**Requirements**: MIGR-01, MIGR-02, MIGR-03, MIGR-04, MIGR-05, MIGR-06, MIGR-07
**Success Criteria** (what must be TRUE):

*Discovery:*
  1. `just list-posts` discovers posts by checking `draft: false` (not `status: Published`)

*Obsidian Template (new posts):*
  2. `draft: true` present (source of truth, default unpublished)
  3. `pubDatetime:` empty (set by publish script, not template)
  4. `created:` set at template creation time (when note was made)
  5. NO `status` field (removed, replaced by draft)
  6. NO `published` field (removed, redundant with pubDatetime)

*Existing Posts:*
  7. All published posts in vault have `draft: false`
  8. All published posts have valid `pubDatetime` (preserved or backfilled)

*Obsidian Configuration:*
  9. `types.json` updated: `draft` as boolean type
  10. Base/Category views filter by `draft` field, not `status`

*Obsidian View Validation (per Kepano Meta patterns):*
  11. Posts Base view correctly shows published posts (`draft: false`)
  12. Posts Base view correctly shows draft posts (`draft: true`)
  13. Posts Category view (`[[Posts]]`) displays posts with draft status visible
  14. Views compatible with Kepano's Ontology structure (categories, type, topics)

*Astro Schema:*
  15. `content.config.ts` updated: remove `status` and `published` from schema (or mark deprecated)

**Plans**: TBD

Plans:
- [ ] 17-01: [TBD - determined during plan-phase]

## Progress

**Execution Order:**
Phases execute in numeric order: 15 -> 16 -> 17

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 15. Library Extraction | 2/2 | Complete | 2026-02-01 |
| 16. Two-Way Sync | 3/3 | Complete | 2026-02-02 |
| 17. Schema Migration | 0/? | Not started | - |

---
*Roadmap created: 2026-02-01*
*Milestone: v0.4.0 Obsidian + Blog Integration Refactor*
