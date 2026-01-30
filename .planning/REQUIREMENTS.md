# Requirements: justcarlson.com v0.2.0

**Defined:** 2026-01-30
**Architecture:** Three-layer pattern (justfile + hooks + optional skills)
**Core Value:** Frictionless publishing from Obsidian with validation, rollback, and confidence that builds always pass.

## v0.2.0 Requirements

### Layer 1: justfile Commands

#### Setup
- [ ] **JUST-01**: User can run `just setup` to configure Obsidian vault path interactively
- [ ] **JUST-02**: `just setup` writes vault path to `.claude/settings.local.json` (gitignored)
- [ ] **JUST-03**: All other recipes read vault path from config

#### Publishing
- [ ] **JUST-04**: User can run `just publish` to publish all ready posts
- [ ] **JUST-05**: `just publish` finds all `draft: false` posts in configured Obsidian path
- [ ] **JUST-06**: `just publish` validates frontmatter (title, pubDatetime, description required)
- [ ] **JUST-07**: `just publish` copies posts to `src/content/blog/YYYY/` (year from pubDatetime)
- [ ] **JUST-08**: `just publish` detects and copies referenced images to `public/assets/blog/`
- [ ] **JUST-09**: `just publish` runs Biome lint before commit
- [ ] **JUST-10**: `just publish` runs `npm run build` before push
- [ ] **JUST-11**: `just publish` commits with conventional message (feat: for new, fix: for update)
- [ ] **JUST-12**: `just publish` pushes to origin
- [ ] **JUST-13**: User can run `just publish --dry-run` to preview actions without executing
- [ ] **JUST-14**: `just publish` reports progress (echoes step names during execution)

#### Utilities
- [ ] **JUST-15**: User can run `just list-drafts` to see ready-to-publish posts
- [ ] **JUST-16**: `just list-drafts` shows validation status per post (ready vs missing fields)
- [ ] **JUST-17**: User can run `just unpublish [file]` to remove a post from repo
- [ ] **JUST-18**: `just unpublish` keeps source file in Obsidian
- [ ] **JUST-19**: `just unpublish` commits and pushes removal
- [ ] **JUST-20**: User can run `just preview` to start Astro dev server

### Layer 2: Hooks & Safety

- [ ] **HOOK-01**: Setup hook runs `just setup` on `claude --init`
- [ ] **HOOK-02**: Hook configuration stored in `.claude/settings.json` (committed)
- [ ] **HOOK-03**: Git safety hook blocks dangerous operations (`--force`, `reset --hard`, `checkout .`, `clean -f`)
- [ ] **HOOK-04**: Maintenance hook runs health checks on `claude --maintenance`

### Layer 3: Skills (Optional)

- [ ] **SKILL-01**: User can run `/publish` skill for human-in-the-loop oversight
- [ ] **SKILL-02**: `/publish` skill wraps `just publish` (doesn't duplicate logic)
- [ ] **SKILL-03**: `/publish` uses `disable-model-invocation: true` (manual only)

## Future Requirements

| Feature | Milestone | Rationale |
|---------|-----------|-----------|
| Newsletter integration | v0.3.0+ | Separate concern from publishing |
| Social auto-posting | v0.3.0+ | API complexity, rate limits |
| Real-time sync (file watcher) | v0.3.0+ | Batch publish sufficient for manual workflow |
| Multiple vault support | v0.3.0+ | YAGNI for personal blog |

## Out of Scope

| Feature | Reason |
|---------|--------|
| Auto-linting hook | Biome runs in publish workflow already |
| Series/related posts | Not in original blog, not adding |
| Comments system | Not in original, not adding now |
| Skills for every command | justfile is sufficient; /publish skill for oversight only |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| JUST-01 | TBD | Pending |
| JUST-02 | TBD | Pending |
| JUST-03 | TBD | Pending |
| JUST-04 | TBD | Pending |
| JUST-05 | TBD | Pending |
| JUST-06 | TBD | Pending |
| JUST-07 | TBD | Pending |
| JUST-08 | TBD | Pending |
| JUST-09 | TBD | Pending |
| JUST-10 | TBD | Pending |
| JUST-11 | TBD | Pending |
| JUST-12 | TBD | Pending |
| JUST-13 | TBD | Pending |
| JUST-14 | TBD | Pending |
| JUST-15 | TBD | Pending |
| JUST-16 | TBD | Pending |
| JUST-17 | TBD | Pending |
| JUST-18 | TBD | Pending |
| JUST-19 | TBD | Pending |
| JUST-20 | TBD | Pending |
| HOOK-01 | TBD | Pending |
| HOOK-02 | TBD | Pending |
| HOOK-03 | TBD | Pending |
| HOOK-04 | TBD | Pending |
| SKILL-01 | TBD | Pending |
| SKILL-02 | TBD | Pending |
| SKILL-03 | TBD | Pending |

**Coverage:**
- v0.2.0 requirements: 27 total
- Mapped to phases: 0 (roadmap pending)
- Unmapped: 27

---
*Requirements defined: 2026-01-30*
*Architecture: justfile + hooks + optional skills*
