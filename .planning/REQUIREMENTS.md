# Requirements: justcarlson.com v0.2.0

**Defined:** 2026-01-30
**Core Value:** Frictionless publishing from Obsidian with validation, rollback, and confidence that builds always pass.

## v0.2.0 Requirements

### Setup

- [ ] **SETUP-01**: `/setup-blog` skill prompts for Obsidian vault path
- [ ] **SETUP-02**: `/setup-blog` writes path to `.claude/settings.local.json`
- [ ] **SETUP-03**: All other skills read path from config
- [ ] **SETUP-04**: If path not configured, skills prompt to run `/setup-blog` first

### Publishing

- [ ] **PUB-01**: `/publish-blog` skill in `.claude/skills/publish-blog/SKILL.md`
- [ ] **PUB-02**: `/publish-blog` finds all `draft: false` posts in configured Obsidian path
- [ ] **PUB-03**: `/publish-blog` validates frontmatter (title, pubDatetime, description filled)
- [ ] **PUB-04**: `/publish-blog` copies posts to `src/content/blog/YYYY/` (year from pubDatetime)
- [ ] **PUB-05**: `/publish-blog` detects and copies referenced images to `public/assets/blog/`
- [ ] **PUB-06**: `/publish-blog` runs Biome lint before commit
- [ ] **PUB-07**: `/publish-blog` runs `npm run build` before push
- [ ] **PUB-08**: `/publish-blog` commits with conventional message (feat/fix based on new/update)
- [ ] **PUB-09**: `/publish-blog` pushes to origin
- [ ] **PUB-10**: `/publish-blog` uses `disable-model-invocation: true` (manual only)
- [ ] **PUB-11**: `/publish-blog` uses `allowed-tools` for pre-approved tools

### Rollback

- [ ] **ROLL-01**: `/unpublish-blog` skill in `.claude/skills/unpublish-blog/SKILL.md`
- [ ] **ROLL-02**: `/unpublish-blog [filename]` removes post from repo
- [ ] **ROLL-03**: `/unpublish-blog` keeps source file in Obsidian
- [ ] **ROLL-04**: `/unpublish-blog` commits and pushes removal
- [ ] **ROLL-05**: `/unpublish-blog` uses `disable-model-invocation: true`

### Utilities

- [ ] **UTIL-01**: `/list-drafts` skill in `.claude/skills/list-drafts/SKILL.md`
- [ ] **UTIL-02**: `/list-drafts` shows posts with `draft: false` in Obsidian
- [ ] **UTIL-03**: `/list-drafts` shows validation status per post (ready/missing fields)
- [ ] **UTIL-04**: `/preview-blog` skill in `.claude/skills/preview-blog/SKILL.md`
- [ ] **UTIL-05**: `/preview-blog` starts Astro dev server

### Hooks & Safety

- [ ] **HOOK-01**: Git safety hook in `.claude/hooks/` blocks dangerous operations
- [ ] **HOOK-02**: Hook config in `.claude/settings.json`

## Out of Scope

| Feature | Reason |
|---------|--------|
| Auto-linting hook | Biome runs in publish workflow already |
| Newsletter integration | Deferred to v0.3.0+ |
| Social auto-posting | API complexity, deferred |
| Series/related posts | Not in steipete.me, not adding |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SETUP-01 | TBD | Pending |
| SETUP-02 | TBD | Pending |
| SETUP-03 | TBD | Pending |
| SETUP-04 | TBD | Pending |
| PUB-01 | TBD | Pending |
| PUB-02 | TBD | Pending |
| PUB-03 | TBD | Pending |
| PUB-04 | TBD | Pending |
| PUB-05 | TBD | Pending |
| PUB-06 | TBD | Pending |
| PUB-07 | TBD | Pending |
| PUB-08 | TBD | Pending |
| PUB-09 | TBD | Pending |
| PUB-10 | TBD | Pending |
| PUB-11 | TBD | Pending |
| ROLL-01 | TBD | Pending |
| ROLL-02 | TBD | Pending |
| ROLL-03 | TBD | Pending |
| ROLL-04 | TBD | Pending |
| ROLL-05 | TBD | Pending |
| UTIL-01 | TBD | Pending |
| UTIL-02 | TBD | Pending |
| UTIL-03 | TBD | Pending |
| UTIL-04 | TBD | Pending |
| UTIL-05 | TBD | Pending |
| HOOK-01 | TBD | Pending |
| HOOK-02 | TBD | Pending |

**Coverage:**
- v0.2.0 requirements: 27 total
- Mapped to phases: 0
- Unmapped: 27

---
*Requirements defined: 2026-01-30*
*Last updated: 2026-01-30 after initial definition*
