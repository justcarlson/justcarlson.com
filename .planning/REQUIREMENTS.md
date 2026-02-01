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
- [ ] **MIGR-02**: Obsidian Post Template updated (remove status, published fields; add draft: true)
- [ ] **MIGR-03**: Existing published posts migrated (add draft: false if missing)
- [ ] **MIGR-04**: Obsidian types.json updated (draft as boolean type)
- [ ] **MIGR-05**: Obsidian Base/Category views configured to filter by draft field

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
| LIB-01 | TBD | Pending |
| LIB-02 | TBD | Pending |
| LIB-03 | TBD | Pending |
| LIB-04 | TBD | Pending |
| LIB-05 | TBD | Pending |
| SYNC-01 | TBD | Pending |
| SYNC-02 | TBD | Pending |
| SYNC-03 | TBD | Pending |
| SYNC-04 | TBD | Pending |
| SYNC-05 | TBD | Pending |
| MIGR-01 | TBD | Pending |
| MIGR-02 | TBD | Pending |
| MIGR-03 | TBD | Pending |
| MIGR-04 | TBD | Pending |
| MIGR-05 | TBD | Pending |
| CONF-01 | TBD | Pending |
| CONF-02 | TBD | Pending |

**Coverage:**
- v0.4.0 requirements: 17 total
- Mapped to phases: 0
- Unmapped: 17 ⚠️

---
*Requirements defined: 2026-02-01*
*Last updated: 2026-02-01 after initial definition*
