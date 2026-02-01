# Roadmap: justcarlson.com v0.3.0

## Overview

v0.3.0 delivers polish and portability for the blog repository. First, fix the title duplication bug and add tags support to complete the publishing workflow. Then, add one-command bootstrap and dev container support so contributors can spin up the project without friction. Finally, adopt robust Python hook infrastructure and clean up accumulated technical debt. This milestone continues from v0.2.0 (phases 7-10) with phases 11-14.

## Milestones

- [x] **v0.1.0 MVP** - Phases 1-6 (shipped 2026-01-29)
- [x] **v0.2.0 Publishing Workflow** - Phases 7-10 (shipped 2026-01-31)
- [x] **v0.3.0 Polish & Portability** - Phases 11-14 (shipped 2026-02-01)

## Phases

- [x] **Phase 11: Content & Workflow Polish** - Fix template bugs, add tags, rename skills
- [x] **Phase 12: Bootstrap & Portability** - One-command setup, dev container support
- [x] **Phase 13: Hook Infrastructure** - Python hooks with logging, env loading, timeout protection
- [x] **Phase 14: Refactor Cleanup** - Code cleanup, remove dead code, consolidate patterns

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
  6. SessionStart hook provides vault state context to Claude (timeout protected)
**Plans**: 5 plans

Plans:
- [x] 11-01-PLAN.md - Fix template and content issues (TMPL-01, TMPL-02, TMPL-03, TMPL-04)
- [x] 11-02-PLAN.md - Rename skills to blog: prefix and enhance SessionStart (SKIL-01, SKIL-02)
- [x] 11-03-PLAN.md - Fix command directory structure for discoverability (gap closure)
- [x] 11-04-PLAN.md - Fix SessionStart hook JSON output for user visibility (gap closure)
- [x] 11-05-PLAN.md - Add timeout protection and update success criteria (gap closure)

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

### Phase 13: Hook Infrastructure
**Goal**: Robust Python hook system following install-and-maintain patterns
**Depends on**: Phase 11 (existing bash hook)
**Requirements**: HOOK-01, HOOK-02, HOOK-03, HOOK-04
**Success Criteria** (what must be TRUE):
  1. SessionStart hook is Python with uv, matching install-and-maintain pattern
  2. Hook loads .env variables into CLAUDE_ENV_FILE for bash persistence
  3. Hook logs to file (.claude/hooks/session_start.log) for debugging
  4. Hook checks vault configuration and posts-ready status
  5. Hook has timeout protection (10s) in settings.json
  6. Hook provides context to Claude via additionalContext
**Plans**: 1 plan

Plans:
- [x] 13-01-PLAN.md - Convert SessionStart to Python with full infrastructure

### Phase 14: Refactor Cleanup
**Goal**: Clean codebase with consolidated patterns, CLI discoverability, and no dead code
**Depends on**: Phase 13
**Requirements**: CLIX-01, CLIX-02, CLIX-03, CLEAN-01, CLEAN-02
**Success Criteria** (what must be TRUE):
  1. All scripts support `--help` flag for CLI discovery
  2. All scripts with prompts support non-interactive mode for Claude Code (no TTY required)
  3. `just publish --post <slug> --yes` publishes a post without TTY
  4. `just setup --vault <path>` configures vault without TTY
  5. No dead code or unused exports in src/
  6. Consistent error handling patterns across all scripts
**Plans**: 2 plans

Plans:
- [x] 14-01-PLAN.md - Install Knip, remove dead components and layouts
- [x] 14-02-PLAN.md - Consolidate constants, verify CLI compliance

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 11. Content & Workflow Polish | v0.3.0 | 5/5 | Complete | 2026-02-01 |
| 12. Bootstrap & Portability | v0.3.0 | 2/2 | Complete | 2026-02-01 |
| 13. Hook Infrastructure | v0.3.0 | 1/1 | Complete | 2026-02-01 |
| 14. Refactor Cleanup | v0.3.0 | 2/2 | Complete | 2026-02-01 |

---
*Roadmap created: 2026-01-31*
*Milestone: v0.3.0 Polish & Portability*
