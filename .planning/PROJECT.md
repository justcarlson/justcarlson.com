# justcarlson.com

## What This Is

A personal blog for Just Carlson, built by forking and rebranding steipete.me (Peter Steinberger's Astro blog). The site mixes personal writing with tech/dev content. Deployed on Vercel at justcarlson.com.

## Core Value

A clean, personal space to write — free of the previous owner's identity and content.

## Requirements

### Validated

- ✓ Static site generation with Astro — existing
- ✓ Blog post content collection system — existing
- ✓ Light/dark theme toggle — existing
- ✓ RSS feed — existing
- ✓ SEO/OG image generation — existing
- ✓ PWA/offline support — existing
- ✓ Vercel Analytics integration — existing

### Active

- [ ] Remove all Peter Steinberger content (posts, images, identity)
- [ ] Update site config to Just Carlson identity
- [ ] Apply Leaf Blue (light) + AstroPaper v4 Special (dark) color scheme
- [ ] Replace avatar with GitHub profile image
- [ ] Implement favicon from custom JC monogram SVG via astro-favicons
- [ ] Update social links (GitHub: justcarlson, LinkedIn: justincarlson0)
- [ ] Rewrite README for new repo
- [ ] Create placeholder About page
- [ ] Update newsletter form to be configurable (keep component, remove Peter's Buttondown)
- [ ] Clean up Peter-specific customizations in CSS

### Out of Scope

- Writing actual blog posts — focus is on making the blog "mine" first
- Newsletter service setup — will configure later
- Custom domain DNS setup — handled separately in Vercel
- Comments system — not in original, not adding now

## Context

**Source repo:** Fork of steipete/steipete.me (Peter Steinberger's personal blog)

**Tech stack (existing):**
- Astro 5.x with content collections
- Tailwind CSS 4
- TypeScript
- Vercel deployment with analytics

**Current state:**
- Codebase already mapped (`.planning/codebase/`)
- Contains ~100+ blog posts from Peter (2012-2025)
- Contains hundreds of images in `public/assets/img/`
- Config files reference steipete.me throughout

**Color scheme chosen:**
- Light mode: Leaf Blue (`--background: #f2f5ec`, `--accent: #1158d1`)
- Dark mode: AstroPaper v4 Special (`--background: #000123`, `--accent: #617bff`)

## Constraints

- **Existing structure**: Keep Astro's file-based routing and content collection patterns
- **Minimal changes**: Only change what's necessary for rebranding — don't refactor working code
- **Favicon source**: Use `~/Downloads/favicon.svg` (JC monogram, #222222 bg, white text)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use astro-favicons integration | Automated generation of all favicon sizes at build time | — Pending |
| Leaf Blue + AstroPaper v4 color scheme | Cohesive cool tones, blue light / purple-blue dark | — Pending |
| Keep newsletter component | May want newsletter later, easier to keep than rebuild | — Pending |
| Delete all Peter's content | Clean slate, fresh start | — Pending |

---
*Last updated: 2025-01-28 after initialization*
