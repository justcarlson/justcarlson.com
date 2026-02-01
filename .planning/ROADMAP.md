# Roadmap: v0.4.0 Obsidian + Blog Integration Refactor

## Overview

This milestone eliminates technical debt in the publishing workflow by consolidating ~280 lines of duplicated code into a shared library, replacing fragile sed/regex YAML manipulation with yq, implementing two-way sync between Obsidian and blog metadata, and migrating from `status: Published` to `draft: false` as the canonical field. Three phases: foundation (library + tooling), features (two-way sync), then migration (schema cleanup).

## Milestones

- v0.1.0 MVP - Phases 1-6 (shipped 2026-01-30)
- v0.2.0 Publishing Workflow - Phases 7-10 (shipped 2026-01-31)
- v0.3.0 Polish & Portability - Phases 11-14 (shipped 2026-02-01)
- **v0.4.0 Obsidian + Blog Integration Refactor** - Phases 15-17 (in progress)

## Phases

- [ ] **Phase 15: Library Extraction + yq Integration** - Consolidate duplicated code and establish reliable YAML tooling
- [ ] **Phase 16: Two-Way Sync** - Bidirectional metadata sync between Obsidian and blog
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
**Plans**: TBD

Plans:
- [ ] 15-01: [TBD - determined during plan-phase]

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
**Plans**: TBD

Plans:
- [ ] 16-01: [TBD - determined during plan-phase]

### Phase 17: Schema Migration

**Goal**: `draft: true/false` becomes the single source of truth for publish state
**Depends on**: Phase 16 (sync must work before changing source of truth)
**Requirements**: MIGR-01, MIGR-02, MIGR-03, MIGR-04, MIGR-05
**Success Criteria** (what must be TRUE):
  1. `just list-posts` discovers posts by checking `draft: false` (not `status: Published`)
  2. New posts created from Obsidian template have `draft: true` and no `status` or `published` fields
  3. All existing published posts in vault have `draft: false` field present
  4. Obsidian Base/Category views filter by draft field, not status field
**Plans**: TBD

Plans:
- [ ] 17-01: [TBD - determined during plan-phase]

## Progress

**Execution Order:**
Phases execute in numeric order: 15 -> 16 -> 17

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 15. Library Extraction | 0/? | Not started | - |
| 16. Two-Way Sync | 0/? | Not started | - |
| 17. Schema Migration | 0/? | Not started | - |

---
*Roadmap created: 2026-02-01*
*Milestone: v0.4.0 Obsidian + Blog Integration Refactor*
