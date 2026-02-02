# justcarlson.com

## What This Is

A personal blog for Justin Carlson with a complete publishing workflow. Built by forking and rebranding steipete.me (Peter Steinberger's Astro blog), now featuring frictionless Obsidian-to-blog publishing with validation, git safety, and optional Claude oversight. Deployed on Vercel at justcarlson.com.

## Core Value

A clean, personal space to write — with a publishing workflow that just works.

## Requirements

### Validated

- ✓ Static site generation with Astro — v0.1.0
- ✓ Blog post content collection system — v0.1.0
- ✓ Light/dark theme toggle — v0.1.0
- ✓ RSS feed — v0.1.0
- ✓ SEO/OG image generation — v0.1.0
- ✓ PWA/offline support — v0.1.0
- ✓ Vercel Analytics integration — v0.1.0
- ✓ Remove all Peter Steinberger content (posts, images, identity) — v0.1.0
- ✓ Update site config to Justin Carlson identity — v0.1.0
- ✓ Apply Leaf Blue (light) + AstroPaper v4 Special (dark) color scheme — v0.1.0
- ✓ Replace avatar with Gravatar — v0.1.0
- ✓ Implement favicon from custom JC monogram SVG — v0.1.0
- ✓ Update social links (GitHub, LinkedIn, X) — v0.1.0
- ✓ Rewrite README for new repo — v0.1.0
- ✓ Create placeholder About page with personal photo — v0.1.0
- ✓ Update newsletter form to be configurable (disabled until service configured) — v0.1.0
- ✓ Clean up Peter-specific customizations in CSS — v0.1.0
- ✓ justfile with publishing commands (setup, publish, unpublish, list-posts, preview) — v0.2.0
- ✓ Setup hook for first-time configuration (`claude --init`) — v0.2.0
- ✓ Safety hooks blocking dangerous git operations — v0.2.0
- ✓ Image handling — copy referenced images to public/assets/ — v0.2.0
- ✓ Validation — frontmatter valid, Biome lint, build check before commit — v0.2.0
- ✓ Optional `/publish` skill for human-in-the-loop oversight — v0.2.0
- ✓ Fixed title duplication in Obsidian template and stripped existing H1s — v0.3.0
- ✓ Tags wired up — template field, publish script converts to Astro format — v0.3.0
- ✓ Skills renamed with `blog:` prefix for discoverability — v0.3.0
- ✓ `just bootstrap` for one-command fresh clone setup — v0.3.0
- ✓ README with clear first-run instructions (Quick Start) — v0.3.0
- ✓ Dev container support (devcontainer.json, node_modules volume, auto-bootstrap) — v0.3.0
- ✓ Python SessionStart hook with logging, env loading, timeout protection — v0.3.0
- ✓ All scripts support `--help` and non-interactive mode — v0.3.0
- ✓ No dead code (verified via Knip) — v0.3.0
- ✓ Consolidated constants to single source of truth (consts.ts) — v0.3.0
- ✓ `draft: true/false` as single source of truth (replaces `status: Published`) — v0.4.0
- ✓ `pubDatetime` set by publish script (not template creation time) — v0.4.0
- ✓ Removed redundant `published` and `status` fields from template — v0.4.0
- ✓ Updated Obsidian template, types.json, and Base/Category views — v0.4.0
- ✓ `just publish` updates Obsidian source: sets `draft: false`, sets `pubDatetime` — v0.4.0
- ✓ `just unpublish` updates Obsidian source: sets `draft: true` — v0.4.0
- ✓ Discovery trigger uses `draft: false` — v0.4.0
- ✓ Shared library (scripts/lib/common.sh) with validation and utility functions — v0.4.0
- ✓ Author normalization from config (not hardcoded) — v0.4.0
- ✓ yq integration for reliable YAML frontmatter manipulation — v0.4.0

### Active

**Current Milestone: v0.4.1 Image & Caption Support**

**Goal:** Ensure hero images and inline image captions work correctly in posts.

**Target features:**
- heroImage frontmatter property renders correctly
- Hero images support captions
- Inline figure/figcaption works in post body

### Deferred

- Set up newsletter service (Buttondown or alternative) — v0.5.0+
- Write actual About page bio content — content work
- Social auto-posting (X, BlueSky, LinkedIn) — API complexity
- `just doctor` health check command — v0.5.0+

### Out of Scope

- Comments system — not in original, not adding now
- Custom domain DNS setup — handled separately in Vercel
- Real-time sync (file watcher) — batch publish sufficient for manual workflow
- Multiple vault support — YAGNI for personal blog

## Context

**Shipped:** v0.4.0 Obsidian + Blog Integration Refactor (2026-02-02)
- 3 phases, 8 plans executed
- 37 files changed (+4,556 / -510 lines)
- 2,831 LOC shell scripts
- 19 requirements satisfied with 100% audit pass

**Tech stack:**
- Astro 5.x with content collections
- Tailwind CSS 4
- TypeScript
- Vercel deployment with analytics
- justfile + Bash scripts for publishing workflow
- scripts/lib/common.sh shared library (311 lines)
- mikefarah/yq v4 for YAML frontmatter manipulation
- Python hooks with uv + PEP 723 inline deps
- Claude Code hooks for safety and setup
- Dev container for portable development

**Current state:**
- All Peter Steinberger content removed (110 posts, 191 images)
- Justin Carlson identity applied throughout
- Publishing workflow: `just publish` from Obsidian with full validation
- Two-way sync: publish/unpublish update Obsidian source files
- `draft: true/false` is single source of truth for publish state
- Git safety hooks blocking dangerous operations
- 6 Claude /blog: skills for human-in-the-loop oversight
- Obsidian vault integration with automatic post discovery (draft: false)
- One-command bootstrap (`just bootstrap`) for fresh clones
- Dev container support for instant contribution
- Python SessionStart hook with logging and timeout protection
- Knip-configured for ongoing dead code detection

## Constraints

- **Existing structure**: Keep Astro's file-based routing and content collection patterns
- **Minimal changes**: Only change what's necessary — don't refactor working code

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Centralized config in consts.ts | Single source of truth for identity | ✓ Good — all components import from config |
| Feature flags for optional components | Newsletter can be re-enabled without code changes | ✓ Good — NEWSLETTER_CONFIG.enabled works |
| Leaf Blue + AstroPaper v4 color scheme | Cohesive cool tones, blue light / purple-blue dark | ✓ Good — theme applied site-wide |
| Keep newsletter component disabled | Easier to re-enable later than rebuild | ✓ Good — component ready for service |
| Delete all Peter's content | Clean slate, fresh start | ✓ Good — 110 posts, 191 images removed |
| SVG favicon with CSS media query | Theme-adaptive favicon | ✓ Good — adapts to light/dark |
| Gravatar instead of static avatar | Cross-site consistency, automatic updates | ✓ Good — works everywhere |
| Person vs brand name separation | Justin Carlson (person) vs justcarlson (brand) | ✓ Good — authorFullName field in config |
| Astro Image with widths array | Responsive images without density conflicts | ✓ Good — WebP variants generated |
| Build validation warns only | Don't fail builds for identity leaks | ✓ Good — catches issues without blocking |
| Three-layer architecture (v0.2.0) | justfile is source of truth, hooks add safety, skills add oversight | ✓ Good — clean separation of concerns |
| Config in settings.local.json | Project-local, gitignored, jq-readable | ✓ Good — works across machines |
| Git safety blocks 5 patterns | Prevent catastrophic git operations | ✓ Good — logs blocked ops |
| Unpublish commits but doesn't push | User controls push timing | ✓ Good — safer design |
| Skills require manual invocation | disable-model-invocation prevents auto-triggering | ✓ Good — user stays in control |
| Frontmatter normalization | Handle Obsidian→Astro schema differences | ✓ Good — author array→string, empty heroImage removed |
| Template defaults to draft: true | New posts start unpublished | ✓ Good — prevents accidental publishing |
| Kepano fields as optional nullable | Accept empty YAML values from vault | ✓ Good — schema flexibility |
| Skills renamed with blog: prefix | Discoverability, matches GSD convention | ✓ Good — 6 /blog: commands |
| Node 22 major version in .nvmrc | Auto patch updates via nvm/fnm/mise | ✓ Good — stays current |
| Named volume for node_modules | macOS/Windows bind mount performance | ✓ Good — dev container works fast |
| Python hooks with PEP 723 + uv | Single-file deps, no venv management | ✓ Good — clean hook pattern |
| Logger with dual output | stderr for terminal, file for debugging | ✓ Good — debug without noise |
| trailingSlash: "ignore" | Accept both /posts and /posts/ URLs | ✓ Good — flexible routing |
| Knip for dead code detection | Ongoing codebase hygiene | ✓ Good — removed 16 files |
| Config consolidation to consts.ts | Single source of truth for site config | ✓ Good — cleaner imports |
| draft: false as publish state | Single source of truth, replaces status field | ✓ Good — simpler schema |
| yq for YAML manipulation | Reliable frontmatter editing vs fragile sed/regex | ✓ Good — handles edge cases |
| Shared library common.sh | Eliminate code duplication across scripts | ✓ Good — ~280 lines consolidated |
| Two-way sync on publish/unpublish | Keep Obsidian and blog in sync | ✓ Good — source files updated |
| strenv() for yq variables | Pass shell variables to yq expressions safely | ✓ Good — no injection issues |
| Backup before source modification | .bak files for safety on Obsidian file changes | ✓ Good — recoverable |
| yq has() for boolean detection | Correctly handle draft: false | ✓ Good — false != missing |
| Config-driven author | Author from settings.local.json with fallback | ✓ Good — portable |

---
*Last updated: 2026-02-02 after v0.4.1 milestone started*
