# justcarlson.com

## What This Is

A personal blog for Justin Carlson, built by forking and rebranding steipete.me (Peter Steinberger's Astro blog). The site provides a clean writing space with Leaf Blue/AstroPaper v4 theming, JC monogram branding, and Gravatar integration. Deployed on Vercel at justcarlson.com.

## Core Value

A clean, personal space to write — free of the previous owner's identity and content.

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
- ✓ Replace avatar with Gravatar — v0.1.0 (via Gravatar, not GitHub profile)
- ✓ Implement favicon from custom JC monogram SVG — v0.1.0
- ✓ Update social links (GitHub: justcarlson, LinkedIn: justincarlson0, X: _justcarlson) — v0.1.0
- ✓ Rewrite README for new repo — v0.1.0
- ✓ Create placeholder About page with personal photo — v0.1.0
- ✓ Update newsletter form to be configurable (disabled until service configured) — v0.1.0
- ✓ Clean up Peter-specific customizations in CSS — v0.1.0

### Active

- [ ] Set up newsletter service (Buttondown or alternative)
- [ ] Write actual About page bio content
- [ ] Write first real blog post

### Out of Scope

- Comments system — not in original, not adding now
- Custom domain DNS setup — handled separately in Vercel

## Context

**Shipped:** v0.1.0 MVP (2026-01-30)
- 6 phases, 16 plans executed
- 391 files changed (+8,037 / -15,241 lines)
- 5,615 lines of TypeScript/Astro/CSS

**Tech stack:**
- Astro 5.x with content collections
- Tailwind CSS 4
- TypeScript
- Vercel deployment with analytics

**Current state:**
- All Peter Steinberger content removed (110 posts, 191 images)
- Justin Carlson identity applied throughout
- Gravatar avatar on homepage and blog posts
- About page with personal photo (Astro Image optimized)
- Leaf Blue / AstroPaper v4 theme colors active
- JC monogram favicon in browser tabs
- PWA manifest with correct branding
- Obsidian template ready for blog authoring
- Build validation confirms clean source files

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

---
*Last updated: 2026-01-30 after v0.1.0 milestone*
