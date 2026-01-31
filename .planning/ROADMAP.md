# Roadmap: justcarlson.com

## Milestones

- v0.1.0 MVP Rebranding - Phases 1-6 (shipped 2026-01-30)
- v0.2.0 Publishing Workflow - Phases 7-10 (in progress)

## Phases

<details>
<summary>v0.1.0 MVP Rebranding (Phases 1-6) - SHIPPED 2026-01-30</summary>

### Phase 1: Foundation
**Goal**: Project infrastructure and identity setup
**Plans**: 2 plans (complete)

### Phase 2: Components
**Goal**: UI component rebranding
**Plans**: 2 plans (complete)

### Phase 3: Infrastructure
**Goal**: Build and deployment setup
**Plans**: 3 plans (complete)

### Phase 4: Content Polish
**Goal**: Content cleanup and validation
**Plans**: 4 plans (complete)

### Phase 5: Personal Brand Cleanup
**Goal**: Complete identity transition
**Plans**: 4 plans (complete)

### Phase 6: About Page Photo
**Goal**: Personal photo on About page
**Plans**: 1 plan (complete)

</details>

### v0.2.0 Publishing Workflow (In Progress)

**Milestone Goal:** Frictionless publishing from Obsidian with validation, rollback, and confidence that builds always pass.

**Architecture:** Three-layer pattern (justfile + hooks + optional skills)

#### Phase 7: Setup & Safety
**Goal**: Justfile foundation with configuration and git protection
**Depends on**: Phase 6 (v0.1.0 complete)
**Requirements**: JUST-01, JUST-02, JUST-03, HOOK-01, HOOK-02, HOOK-03 (HOOK-04 deferred)
**Success Criteria** (what must be TRUE):
  1. User can run `just setup` and it prompts for Obsidian vault path interactively
  2. After setup, `.claude/settings.local.json` contains the configured vault path
  3. All other justfile recipes read vault path from config (no hardcoded paths)
  4. Running `claude --init` triggers `just setup` automatically via Setup hook
  5. Dangerous git operations (`--force`, `reset --hard`, `checkout .`, `clean -f`) are blocked with clear error messages
**Research recommended**: false
**Plans**: 2 plans

Plans:
- [x] 07-01: Justfile foundation and setup recipe
- [x] 07-02: Claude hooks (setup trigger, git safety)

#### Phase 8: Core Publishing
**Goal**: User can publish posts from Obsidian with full validation pipeline
**Depends on**: Phase 7 (setup creates config that publish reads)
**Requirements**: JUST-04, JUST-05, JUST-06, JUST-07, JUST-08, JUST-09, JUST-10, JUST-11, JUST-12, JUST-13, JUST-14
**Success Criteria** (what must be TRUE):
  1. User can run `just publish` to find all `draft: false` posts in configured Obsidian path
  2. Posts with invalid/missing frontmatter (title, pubDatetime, description) are flagged with clear errors
  3. Valid posts are copied to `src/content/blog/YYYY/` (year from pubDatetime) with referenced images in `public/assets/blog/`
  4. Biome lint passes and full build succeeds before any commit happens
  5. Changes are committed with conventional message (feat: for new, fix: for update) and pushed to origin
  6. User can run `just publish --dry-run` to preview all actions without executing
**Research recommended**: false
**Plans**: 4 plans

Plans:
- [x] 08-01: Publish recipe and post discovery
- [x] 08-02: Frontmatter validation and image handling
- [x] 08-03: Lint, build, commit, push pipeline with dry-run
- [x] 08-04: UAT gap closure (ANSI output, lint-staged, dry-run prompts)

#### Phase 9: Utilities
**Goal**: User can preview, list drafts, and unpublish posts
**Depends on**: Phase 7 (uses config), Phase 8 (unpublish reverses publish)
**Requirements**: JUST-15, JUST-16, JUST-17, JUST-18, JUST-19, JUST-20
**Success Criteria** (what must be TRUE):
  1. User can run `just list-drafts` to see all `draft: false` posts in Obsidian
  2. Each listed post shows validation status (ready vs missing required fields)
  3. User can run `just unpublish [file]` to remove a post from repo while keeping Obsidian source
  4. Unpublish commits and pushes removal with conventional message
  5. User can run `just preview` to start Astro dev server for local review
**Research recommended**: false
**Plans**: TBD

Plans:
- [ ] 09-01: List drafts and preview recipes
- [ ] 09-02: Unpublish recipe

#### Phase 10: Skills Layer
**Goal**: Optional Claude oversight wrapping justfile commands
**Depends on**: Phases 7-9 (skills wrap justfile recipes)
**Requirements**: SKILL-01, SKILL-02, SKILL-03
**Success Criteria** (what must be TRUE):
  1. User can run `/publish` skill for human-in-the-loop oversight of publishing
  2. `/publish` skill wraps `just publish` (no duplicated logic)
  3. Skills use `disable-model-invocation: true` (manual invocation only, no auto-triggering)
**Research recommended**: false
**Plans**: TBD

Plans:
- [ ] 10-01: Publish skill with manual invocation

## Progress

**Execution Order:** Phases execute in numeric order: 7 -> 8 -> 9 -> 10

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v0.1.0 | 2/2 | Complete | 2026-01-29 |
| 2. Components | v0.1.0 | 2/2 | Complete | 2026-01-29 |
| 3. Infrastructure | v0.1.0 | 3/3 | Complete | 2026-01-29 |
| 4. Content Polish | v0.1.0 | 4/4 | Complete | 2026-01-29 |
| 5. Personal Brand Cleanup | v0.1.0 | 4/4 | Complete | 2026-01-29 |
| 6. About Page Photo | v0.1.0 | 1/1 | Complete | 2026-01-30 |
| 7. Setup & Safety | v0.2.0 | 2/2 | Complete | 2026-01-30 |
| 8. Core Publishing | v0.2.0 | 4/4 | Complete | 2026-01-31 |
| 9. Utilities | v0.2.0 | 0/2 | Not started | - |
| 10. Skills Layer | v0.2.0 | 0/1 | Not started | - |

---
*Roadmap created: 2026-01-30*
*Last updated: 2026-01-31 (Phase 8 complete with gap closure)*
