# Project Milestones: justcarlson.com

## v0.5.0 Graceful Fallback (Shipped: 2026-02-02)

**Delivered:** Site loads fully when external services (Gravatar, GitHub chart, analytics) are blocked by privacy tools or firewalls

**Phases completed:** 20-22 (5 plans total)

**Key accomplishments:**
- Vercel Image Optimization configured for external image proxying (Gravatar, GitHub chart)
- Avatar fallback with local WebP image when proxy fails
- GitHub chart graceful fallback with shimmer loading and text link
- Analytics error handling with .catch() for silent degradation
- Playwright testing infrastructure for image fallback verification

**Stats:**
- 38 files changed (+4,112 / -60 lines)
- 3 phases, 5 plans, 9 requirements satisfied
- 1 day (2026-02-02)

**Git range:** `docs(20)` → `docs(22)` (tagged v0.5.0)

**What's next:** Newsletter setup, About page bio, social embeds fallback

---

## v0.4.1 Image & Caption Support (Shipped: 2026-02-02)

**Delivered:** Hero images and inline image captions with accessibility support and wiki-link format handling in publishing workflow

**Phases completed:** 18-19 (5 plans total)

**Key accomplishments:**
- Added heroImageAlt and heroImageCaption optional schema fields with title fallback
- Wrapped hero images in semantic `<figure>` element with optional figcaption
- Extended publish.sh to handle hero image fields in change detection and normalization
- Fixed Perl regex bug preventing heroImage field preservation
- Added wiki-link `[[image.png]]` format support in publishing workflow

**Stats:**
- 27 files changed (+2,921 / -30 lines)
- 2 phases, 5 plans (3 gap closures), 43 commits
- 1 day (2026-02-02)

**Git range:** `feat(18-01)` → `test(19): complete UAT` (tagged v0.4.1)

**What's next:** Newsletter setup, About page bio, next content-focused milestone

---

## v0.4.0 Obsidian + Blog Integration Refactor (Shipped: 2026-02-02)

**Delivered:** `draft: true/false` as single source of truth for publish state, with bidirectional sync between Obsidian and blog

**Phases completed:** 15-17 (8 plans total)

**Key accomplishments:**
- Consolidated ~280 lines of duplicated code into shared library (scripts/lib/common.sh)
- Replaced fragile sed/regex YAML manipulation with yq for reliable frontmatter handling
- Implemented bidirectional sync — publish sets `draft: false` + `pubDatetime`, unpublish sets `draft: true`
- Migrated from `status: Published` to `draft: false` as canonical publish state
- All 4 E2E workflows verified working (publish, unpublish, list-posts, new post from template)

**Stats:**
- 37 files changed (+4,556 / -510 lines)
- 2,831 lines of shell scripts
- 3 phases, 8 plans, 19 requirements satisfied
- 2 days (2026-02-01 → 2026-02-02)

**Git range:** `feat(15-01)` → `feat(17-01)` (tagged v0.4.0)

**What's next:** Newsletter setup, actual blog content, About page bio

---

## v0.3.0 Polish & Portability (Shipped: 2026-02-01)

**Delivered:** Developer experience improvements — one-command bootstrap, dev container support, robust Python hooks, and codebase cleanup

**Phases completed:** 11-14 (10 plans total)

**Key accomplishments:**
- Fixed Obsidian template (no duplicate H1), extended schema for Kepano vault compatibility
- One-command bootstrap (`just bootstrap`) with .nvmrc and comprehensive README Quick Start
- Dev container support with auto-bootstrap for instant contribution
- Python SessionStart hook with logging, env loading, and 10s timeout protection
- Knip-based dead code removal (16 files, 1,467 lines cleaned)
- Consolidated configuration to single source of truth (consts.ts)

**Stats:**
- 78 files changed (+7,145 / -1,676 lines)
- 3,630 lines of TS/Astro/Bash/Python
- 4 phases, 10 plans, 22 requirements satisfied
- 1 day from v0.2.0 to ship (2026-02-01)

**Git range:** `docs(11)` → `docs(14)` (tagged v0.3.0)

**What's next:** Newsletter setup, actual blog content, About page bio

---

## v0.2.0 Publishing Workflow (Shipped: 2026-01-31)

**Delivered:** Frictionless Obsidian-to-blog publishing with validation, git safety, and optional Claude oversight

**Phases completed:** 7-10 (12 plans total)

**Key accomplishments:**
- Justfile-based publishing workflow — `just publish`, `just setup`, `just list-posts`, `just unpublish`, `just preview`
- Obsidian integration — Interactive vault configuration, posts discovered by `status: - Published` in frontmatter
- Full validation pipeline — Frontmatter validation, image handling (wiki-links → markdown), lint/build gates
- Git safety hooks — Blocks dangerous operations (`--force`, `reset --hard`, `checkout .`) with clear errors
- Optional Claude skills — 5 skills with human-in-the-loop oversight and stop hooks for verification
- UAT-driven quality — 4 gap closure plans addressed real-world usage issues (ANSI, lint-staged, frontmatter types)

**Stats:**
- 62 files changed (+8,543 / -112 lines)
- 2,393 lines of Bash scripts + justfile + hooks
- 4 phases, 12 plans, ~45 tasks
- 2 days from v0.1.0 to ship (2026-01-30 → 2026-01-31)

**Git range:** `feat(07-01)` → `docs(blog): add Hello World` (tagged v0.2.0)

**What's next:** Newsletter setup, actual blog content, About page bio

---

## v0.1.0 MVP (Shipped: 2026-01-30)

**Delivered:** Personal blog fully rebranded from steipete.me to justcarlson.com with custom theme, favicon, and clean content slate

**Phases completed:** 1-6 (16 plans total)

**Key accomplishments:**
- Complete identity rebrand — All config, components, and structured data updated to Justin Carlson identity
- Removed all previous owner content — Deleted 110 blog posts, 191 images, and all Peter Steinberger references
- Custom theme and branding — Leaf Blue light / AstroPaper v4 dark color scheme with JC monogram favicon
- Config-driven components — Refactored structured data, sidebar, newsletter to consume centralized config
- Personal brand cleanup — Person name (Justin Carlson) vs brand name (justcarlson) distinction with Gravatar
- About page with optimized photo — Personal photo using Astro Image with WebP and responsive widths

**Stats:**
- 391 files changed (+8,037 / -15,241 lines — net content removal)
- 5,615 lines of TypeScript/Astro/CSS
- 6 phases, 16 plans, ~40 tasks
- 1 day from start to ship (2026-01-29)

**Git range:** `feat(01-01)` → `docs(06)` (tagged v0.1.0)

**What's next:** Newsletter setup, actual blog content, About page bio

---
