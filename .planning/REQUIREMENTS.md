# Requirements: v0.4.0 Obsidian + Blog Integration Refactor

**Defined:** 2026-02-01
**Core Value:** A clean, personal space to write — with a publishing workflow that just works.

## v0.4.0 Requirements

Requirements for the integration refactor. Each maps to roadmap phases.

### Library & Tooling

- [ ] **LIB-01**: yq (mikefarah v4) installed as prerequisite in devcontainer and documented for local install
- [ ] **LIB-02**: `scripts/lib/common.sh` created with shared functions
- [ ] **LIB-03**: Validation functions consolidated (validate_frontmatter, validate_iso8601, extract_frontmatter)
- [ ] **LIB-04**: Utility functions consolidated (slugify, color constants, config reading)
- [ ] **LIB-05**: All scripts source common.sh instead of duplicating code

### Two-Way Sync

- [ ] **SYNC-01**: `just unpublish` sets `draft: true` in Obsidian source file
- [ ] **SYNC-02**: `just publish` sets `pubDatetime` at publish time (not template creation)
- [ ] **SYNC-03**: `just publish` sets `draft: false` in Obsidian source file
- [ ] **SYNC-04**: Backup created before modifying Obsidian files (atomic write pattern)
- [ ] **SYNC-05**: `just unpublish --dry-run` previews changes without modifying files

### Schema Migration

- [ ] **MIGR-01**: Discovery trigger changed from `status: Published` to `draft: false`
- [ ] **MIGR-02**: Obsidian Post Template updated:
  - `draft: true` (source of truth, default unpublished)
  - `pubDatetime:` empty (set by publish script)
  - `created:` set at template time (when note made)
  - Remove `status` field
  - Remove `published` field (redundant with pubDatetime)
- [ ] **MIGR-03**: Existing published posts migrated (add draft: false, preserve pubDatetime)
- [ ] **MIGR-04**: Obsidian types.json updated (draft as boolean type)
- [ ] **MIGR-05**: Obsidian Base/Category views configured to filter by draft field
- [ ] **MIGR-06**: Astro content.config.ts updated (remove/deprecate status and published fields)
- [ ] **MIGR-07**: Obsidian views validated against Kepano Meta patterns (Posts Base shows draft status, Category view works with `[[Posts]]`)

### Configuration

- [ ] **CONF-01**: Author normalization uses config value (not hardcoded "Justin Carlson")
- [ ] **CONF-02**: Constants centralized in common.sh (paths, patterns)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Batch unpublish | Low priority, single-post workflow sufficient |
| modDatetime auto-tracking | Adds complexity, defer to v0.5.0+ |
| Interactive unpublish selection | Current workflow adequate |
| Multiple vault support | YAGNI for personal blog |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| LIB-01 | Phase 15 | Complete |
| LIB-02 | Phase 15 | Complete |
| LIB-03 | Phase 15 | Complete |
| LIB-04 | Phase 15 | Complete |
| LIB-05 | Phase 15 | Complete |
| CONF-02 | Phase 15 | Complete |
| SYNC-01 | Phase 16 | Complete |
| SYNC-02 | Phase 16 | Complete |
| SYNC-03 | Phase 16 | Complete |
| SYNC-04 | Phase 16 | Complete |
| SYNC-05 | Phase 16 | Complete |
| CONF-01 | Phase 16 | Complete |
| MIGR-01 | Phase 17 | Complete |
| MIGR-02 | Phase 17 | Complete |
| MIGR-03 | Phase 17 | Complete |
| MIGR-04 | Phase 17 | Complete |
| MIGR-05 | Phase 17 | Complete |
| MIGR-06 | Phase 17 | Complete |
| MIGR-07 | Phase 17 | Complete |

**Coverage:**
- v0.4.0 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0

---
*Requirements defined: 2026-02-01*
*Traceability updated: 2026-02-01 after roadmap creation*
