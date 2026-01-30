# Project Research Summary

**Project:** justcarlson.com v0.2.0 Publishing Workflow
**Domain:** justfile + Claude hooks for Obsidian-to-Astro publishing
**Researched:** 2026-01-30
**Confidence:** HIGH

## Executive Summary

This project implements a three-layer publishing workflow that enables frictionless Obsidian-to-Astro blog publishing with built-in validation and safety. The architecture separates deterministic commands (justfile), automated safety gates (hooks), and intelligent oversight (Claude skills). The critical insight: **the justfile is the source of truth** — all entry points (terminal, hooks, skills) execute the same justfile recipes, ensuring consistency.

The recommended approach leverages existing infrastructure (Astro 5, Tailwind CSS 4, Sharp for image optimization, Biome for linting) and requires zero additional dependencies. The workflow validates frontmatter, copies posts to year-based folders, handles image references, and runs build checks before committing. Safety is enforced through git hooks that block destructive operations while preserving developer productivity.

The primary risks are cross-shell compatibility issues in justfile recipes, Obsidian-specific markdown syntax incompatibilities, and partial commits leaving the site broken. These are mitigated through explicit shell configuration, syntax conversion during publishing, and atomic operations with build-before-commit validation.

## Key Findings

### Recommended Stack

All required tools are already present in the codebase. No new dependencies needed.

**Core technologies:**
- **justfile**: Command runner for deterministic publishing workflow — simpler than Makefile, portable, testable
- **Claude hooks**: Setup automation (runs `just setup` on `--init`) and safety gates — official Claude Code feature
- **Git hooks**: Block dangerous operations (`--force`, `reset --hard`) — works even without Claude
- **Existing tools**: Astro 5.16.6, Biome, Sharp, gray-matter — already configured and working

**Key stack decisions:**
- Use manual favicon generation with Sharp/resvg (already installed) instead of astro-favicons plugin
- Use .githooks/ for safety (not Claude PreToolUse) so protection works outside Claude
- Use settings.local.json for user config (gitignored, machine-specific paths)
- Use bash explicitly (`set shell := ["bash", "-cu"]`) to avoid cross-platform issues

### Expected Features

**Must have (table stakes):**
- `just publish` — single command to validate, copy, lint, build, commit, push
- `just setup` — interactive Obsidian vault path configuration
- `just list-drafts` — show posts with `draft: false` ready to publish
- Frontmatter validation — required fields (title, pubDatetime, description)
- Image copying — parse markdown for references, copy to `public/assets/blog/`
- Git safety — block `--force`, `reset --hard`, `checkout .`, `clean -f`

**Should have (competitive):**
- Validation status per post — show "ready" vs "missing: title" in list-drafts
- Automatic year folder detection — extract from pubDatetime, create YYYY/ folder
- Dry-run mode — preview actions without executing (`just publish --dry-run`)
- Claude skills (`/publish-blog`) — human-in-the-loop with disable-model-invocation: true
- Progress reporting — echo step names during execution

**Defer (v2+):**
- Real-time sync (file watcher) — batch publish sufficient for manual workflow
- Social auto-posting — API complexity, rate limits, defer to future
- Newsletter integration — separate concern from publishing
- Multiple vault support — YAGNI for personal blog

### Architecture Approach

The three-layer pattern separates concerns into deterministic commands, automated safety, and optional intelligent oversight. **Layer 1 (justfile)** contains all business logic and works standalone. **Layer 2 (hooks)** triggers setup automatically and enforces safety without user action. **Layer 3 (skills)** provides Claude oversight with manual invocation only.

**Major components:**
1. **justfile** — source of truth for all publishing commands (setup, publish, unpublish, list-drafts, preview)
2. **.claude/settings.json** — committed hook configuration (Setup hook runs `just setup` on `--init`)
3. **.claude/settings.local.json** — gitignored user config (Obsidian vault path, blog subfolder)
4. **.githooks/pre-push** — blocks dangerous git operations before they reach remote
5. **.claude/skills/** — skill definitions that instruct Claude to run justfile recipes

**Build order:** Layer 1 first (justfile recipes), then Layer 2 (safety), then Layer 1 expansion (remaining recipes), finally Layer 3 (skills that wrap Layer 1). This ensures terminal testing without Claude and allows rollback to justfile-only if skills have issues.

### Critical Pitfalls

1. **Justfile variable syntax confusion** — Use `{{var}}` for just variables, `$VAR` for shell environment variables. Mixing these causes undefined variable errors or empty strings.

2. **Each recipe line runs in new shell** — Commands like `cd src` don't persist to next line. Prevention: chain with `&&` or use shebang recipes (`#!/usr/bin/env bash`).

3. **Obsidian image syntax not standard markdown** — `![[image.png]]` doesn't render in Astro. Convert to `![alt](./image.png)` during publishing or configure Obsidian for relative paths.

4. **Relative image paths break in Astro** — Images with `./image.png` fail when Astro copies to `_astro/`. Copy images to `public/assets/blog/` and update paths to `/assets/blog/image.png`.

5. **Partial commits leave broken state** — Committing posts without images or vice versa breaks site. Prevention: atomic operations (copy all, validate all, build check, then commit all).

## Implications for Roadmap

Based on research, suggested phase structure follows dependency order: foundation (Layer 1 core), safety (Layer 2), publishing logic (Layer 1 expansion), skills (Layer 3).

### Phase 1: Setup & Safety (07)
**Rationale:** Configuration and safety must exist before publishing logic. Setup creates the config file that other recipes depend on.
**Delivers:** Working `just setup` command, git safety hooks, config file format
**Addresses:** `just setup` (table stakes), git safety blocking (table stakes), config storage (developer experience)
**Avoids:** Variable syntax confusion (set shell explicitly), each line runs in new shell (establish shebang pattern)
**Research needs:** SKIP — well-documented patterns in Just manual and Claude hooks docs

### Phase 2: Core Publishing (08)
**Rationale:** Publishing logic depends on setup being complete. This is the most complex phase with validation, copying, and commit logic.
**Delivers:** Working `just publish` command with full pipeline (validate, copy posts, copy images, lint, build, commit, push)
**Addresses:** `just publish` (table stakes), frontmatter validation (table stakes), image copying (table stakes), automatic year folder detection (differentiator)
**Avoids:** Obsidian image syntax incompatibility (convert during publish), relative image paths breaking (copy to public/), partial commits (atomic operations), frontmatter validation gaps (validate values not just presence)
**Research needs:** SKIP — patterns established in ARCHITECTURE.md and PITFALLS.md

### Phase 3: Utilities (09)
**Rationale:** Utility commands are simpler and independent. Can be built in parallel or after core publishing.
**Delivers:** `just list-drafts`, `just unpublish`, `just preview`
**Addresses:** `just list-drafts` (table stakes), validation status per post (differentiator), rollback capability (unpublish)
**Avoids:** Draft flag ambiguity (use yq for YAML boolean parsing)
**Research needs:** SKIP — straightforward implementations

### Phase 4: Skills Layer (10)
**Rationale:** Skills wrap justfile recipes, so justfile must be complete and tested first.
**Delivers:** `/setup-blog`, `/publish-blog`, `/unpublish-blog`, `/list-drafts`, `/preview-blog` skills
**Addresses:** Claude integration modes (differentiator), disable-model-invocation (safety), interactive mode (developer experience)
**Avoids:** Skill without disable-model-invocation (prevent auto-invocation), duplicated logic (skills call justfile, not reimplemented)
**Research needs:** SKIP — skill patterns well-documented in Claude Code docs

### Phase Ordering Rationale

- **Layer 1 before Layer 3:** Justfile must be complete and testable from terminal before skills wrap it
- **Setup before Publishing:** Publishing recipes depend on config file that setup creates
- **Safety early:** Git hooks establish safety before destructive operations possible
- **Core before Utilities:** `just publish` is complex and critical; utilities are simpler and can follow
- **Atomic phases:** Each phase delivers working functionality that can be tested independently

### Research Flags

**Skip research for all phases:**
- Phase 07: Justfile syntax and Claude hooks well-documented in official sources
- Phase 08: Obsidian-to-Astro patterns established in ARCHITECTURE.md and PITFALLS.md
- Phase 09: Utility commands are straightforward implementations
- Phase 10: Claude skills patterns documented in official Claude Code skills reference

**Standard patterns present:**
- Justfile command runner: established tool with comprehensive manual
- Claude hooks: official Claude Code feature with complete documentation
- Git hooks: standard git functionality, widely documented
- Astro content collections: well-documented in Astro 5 guides

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All tools already installed and verified in package.json. No new dependencies needed. |
| Features | HIGH | Table stakes features verified across multiple Obsidian-to-Astro workflows. Differentiators from authoritative Claude Code patterns. |
| Architecture | HIGH | Three-layer pattern verified against official Claude Code documentation. Script-as-source-of-truth pattern from community best practices. |
| Pitfalls | HIGH | All critical pitfalls sourced from official documentation (Just manual, Claude hooks reference, Astro guides). |

**Overall confidence:** HIGH

### Gaps to Address

No critical gaps identified. Research covered all necessary areas with authoritative sources:

- **Stack decisions:** Verified against existing codebase (package.json, astro.config.mjs, global.css)
- **Feature expectations:** Cross-referenced multiple Obsidian-to-Astro workflows for table stakes
- **Architecture patterns:** Validated against official Claude Code documentation
- **Pitfall prevention:** Sourced from official documentation and known issues with GitHub issue numbers

**Minor validation during implementation:**
- Test justfile recipes on actual Obsidian vault structure (once setup complete)
- Verify image path conversion handles all edge cases (spaces, special characters, nested folders)
- Confirm git hooks work with both Claude Code and direct terminal usage

## Sources

### Primary (HIGH confidence)
- [Just Programmer's Manual](https://just.systems/man/en/) — recipe syntax, shell configuration, variable scoping
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) — hook events, JSON output, matchers, exit codes
- [Claude Code Skills](https://code.claude.com/docs/en/skills) — skill structure, disable-model-invocation, allowed-tools
- [Claude Code Settings](https://code.claude.com/docs/en/settings) — settings hierarchy, local vs committed
- [Astro Images Guide](https://docs.astro.build/en/guides/images/) — image optimization, Sharp integration
- [Astro Content Collections](https://docs.astro.build/en/guides/content-collections/) — frontmatter schema, validation
- **Codebase verification:** package.json, astro.config.mjs, src/styles/global.css, src/consts.ts

### Secondary (MEDIUM confidence)
- [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery) — script-as-source-of-truth pattern
- [rachsmith.com: Automating Obsidian to Astro](https://rachsmith.com/automating-obsidian-to-astro/) — vault scanning, frontmatter detection
- [walterra.dev: Obsidian/Astro Workflow](https://walterra.dev/blog/2025-03-02-obsidian-astro-workflow) — sync patterns, mobile capture
- [hungrimind.com: Write Like a Pro with Astro and Obsidian](https://www.hungrimind.com/articles/obsidian-with-astro) — image syntax conversion
- [anca.wtf: Configuring Obsidian and Astro Assets](https://www.anca.wtf/posts/configuring-obsidian-and-astro-assets-for-markdoc-content-in-an-astro-blog/) — special character handling

### Known Issues (verified with issue numbers)
- [Claude Code Issue #3983](https://github.com/anthropics/claude-code/issues/3983) — PostToolUse JSON not processed
- [Claude Code Issue #10875](https://github.com/anthropics/claude-code/issues/10875) — Plugin hooks stdout not captured
- [Astro Issue #1188](https://github.com/withastro/astro/issues/1188) — Relative image paths in content collections

---
*Research completed: 2026-01-30*
*Ready for roadmap: yes*
