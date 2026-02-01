# Roadmap: justcarlson.com v0.3.0

## Overview

v0.3.0 delivers polish and portability for the blog repository. First, fix the title duplication bug and add tags support to complete the publishing workflow. Then, add one-command bootstrap and dev container support so contributors can spin up the project without friction. This milestone continues from v0.2.0 (phases 7-10) with phases 11-12.

## Milestones

- [x] **v0.1.0 MVP** - Phases 1-6 (shipped 2026-01-29)
- [x] **v0.2.0 Publishing Workflow** - Phases 7-10 (shipped 2026-01-31)
- [ ] **v0.3.0 Polish & Portability** - Phases 11-12 (in progress)

## Phases

- [ ] **Phase 11: Content & Workflow Polish** - Fix template bugs, add tags, rename skills
- [x] **Phase 12: Bootstrap & Portability** - One-command setup, dev container support

## Phase Details

### Phase 11: Content & Workflow Polish
**Goal**: Publishing workflow is complete with proper title handling and tag support
**Depends on**: Phase 10 (v0.2.0 complete)
**Requirements**: TMPL-01, TMPL-02, TMPL-03, TMPL-04, SKIL-01, SKIL-02
**Success Criteria** (what must be TRUE):
  1. New posts from Obsidian template have title only in frontmatter, no duplicate H1 in body
  2. Existing published posts display correctly without redundant headings
  3. Tags added in Obsidian appear on published blog posts with proper formatting
  4. All skills discoverable via `/blog:` prefix in Claude (like GSD's `/gsd:` pattern)
  5. SessionStart hook references correct `/blog:install` skill name
  6. SessionStart hook shows user-visible suggestion when vault not configured
**Plans**: 4 plans

Plans:
- [x] 11-01-PLAN.md - Fix template and content issues (TMPL-01, TMPL-02, TMPL-03, TMPL-04)
- [x] 11-02-PLAN.md - Rename skills to blog: prefix and enhance SessionStart (SKIL-01, SKIL-02)
- [x] 11-03-PLAN.md - Fix command directory structure for discoverability (gap closure)
- [ ] 11-04-PLAN.md - Fix SessionStart hook JSON output for user visibility (gap closure)

### Phase 12: Bootstrap & Portability
**Goal**: Fresh clones work with one command; dev containers enable instant contribution
**Depends on**: Phase 11
**Requirements**: BOOT-01, BOOT-02, BOOT-03, BOOT-04, DEVC-01, DEVC-02, DEVC-03
**Success Criteria** (what must be TRUE):
  1. `just bootstrap` installs all dependencies and validates setup in one command
  2. Node version auto-switches correctly via nvm/fnm/mise reading .nvmrc
  3. README Quick Start section guides new users from clone to preview
  4. `just preview` works without vault configured for code exploration
  5. Opening project in VS Code with Dev Containers extension offers "Reopen in Container"
  6. Dev container starts successfully with all dependencies installed
**Plans**: 2 plans

Plans:
- [x] 12-01-PLAN.md - Bootstrap script, .nvmrc, vault-optional mode, README Quick Start (BOOT-01, BOOT-02, BOOT-03, BOOT-04)
- [x] 12-02-PLAN.md - Dev container configuration with auto-bootstrap (DEVC-01, DEVC-02, DEVC-03)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 11. Content & Workflow Polish | v0.3.0 | 3/4 | In Progress | - |
| 12. Bootstrap & Portability | v0.3.0 | 2/2 | Complete | 2026-02-01 |

---
*Roadmap created: 2026-01-31*
*Milestone: v0.3.0 Polish & Portability*
