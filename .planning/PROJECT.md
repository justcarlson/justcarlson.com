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

### Active

**v0.3.0 Polish & Portability:**
- [ ] Fix title duplication in Obsidian template and strip existing H1s from posts
- [ ] Add `just bootstrap` for one-command fresh clone setup
- [ ] Update README with clear first-run instructions
- [ ] Audit scripts for hardcoded assumptions
- [ ] Document dev container preparation (foundation for future)

### Deferred

- Set up newsletter service (Buttondown or alternative) — v0.3.0+
- Write actual About page bio content — content work
- Social auto-posting (X, BlueSky, LinkedIn) — API complexity
- Maintenance hook for health checks (HOOK-04) — v0.3.0+

### Out of Scope

- Comments system — not in original, not adding now
- Custom domain DNS setup — handled separately in Vercel
- Real-time sync (file watcher) — batch publish sufficient for manual workflow
- Multiple vault support — YAGNI for personal blog

## Context

**Shipped:** v0.2.0 Publishing Workflow (2026-01-31)
- 4 phases, 12 plans executed
- 62 files changed (+8,543 / -112 lines)
- 2,393 lines of Bash scripts + justfile + hooks
- 5 Claude skills with stop hook verification

**Tech stack:**
- Astro 5.x with content collections
- Tailwind CSS 4
- TypeScript
- Vercel deployment with analytics
- justfile + Bash scripts for publishing workflow
- Claude Code hooks for safety and setup

**Current state:**
- All Peter Steinberger content removed (110 posts, 191 images)
- Justin Carlson identity applied throughout
- Publishing workflow: `just publish` from Obsidian with full validation
- Git safety hooks blocking dangerous operations
- 5 Claude skills for human-in-the-loop oversight
- Obsidian vault integration with automatic post discovery

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

---
*Last updated: 2026-01-31 after v0.3.0 milestone start*
