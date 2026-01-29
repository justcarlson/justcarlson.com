# Phase 1: Foundation - Research

**Researched:** 2026-01-28
**Domain:** Astro site configuration, CSS theming, favicon generation
**Confidence:** HIGH

## Summary

Phase 1 involves straightforward configuration updates and asset generation for the justcarlson.com rebrand. The codebase uses a well-established pattern with `src/consts.ts` for site-wide constants and CSS custom properties in `src/styles/global.css` for theming. Sharp is already installed and is the standard tool for image processing in the Astro ecosystem.

The favicon strategy follows 2026 best practices: an SVG with embedded dark mode support via CSS media queries, plus ICO fallback for legacy browsers. The SVG approach is ideal for the theme-adaptive requirement since it can respond to `prefers-color-scheme`. Sharp-ico provides ICO encoding for the existing Sharp library.

**Primary recommendation:** Use SVG as primary favicon with embedded dark/light styles, generate ICO as fallback using sharp-ico, and apply color scheme changes directly to CSS custom properties in global.css.

## Standard Stack

### Core (Already Installed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| sharp | ^0.34.5 | Image processing | Already in project, industry standard for Node.js image manipulation |
| tailwindcss | ^4.1.18 | CSS framework | Already configured with CSS custom properties pattern |

### To Install

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| sharp-ico | latest | ICO encoding | Creating multi-size favicon.ico from PNG buffers |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| sharp-ico | favicons package | favicons is heavier, generates many files; sharp-ico is lightweight and integrates with existing Sharp |
| Manual favicon files | Astro static endpoint | Static files are simpler but require pre-generation; endpoint auto-generates at build |

**Installation:**
```bash
npm install sharp-ico
```

## Architecture Patterns

### Current Project Structure (Relevant Files)

```
src/
├── consts.ts         # Site config (author, URL, social links array)
├── constants.ts      # Social links with icons (SOCIALS array)
├── config.ts         # Re-exports from consts.ts and constants.ts
├── styles/
│   └── global.css    # CSS custom properties for theming
├── components/
│   ├── BaseHead.astro    # Favicon links, meta tags
│   └── NewsletterForm.astro  # Hardcoded Buttondown URL
└── pages/
    └── (potential favicon.ico.ts endpoint)
public/
├── favicon.ico       # Current favicon (to replace)
├── site.webmanifest  # PWA manifest (needs update)
└── peter-avatar.jpg  # Current avatar (to replace)
```

### Pattern 1: CSS Custom Properties for Theming

**What:** Define color scheme using CSS variables, swap values based on `data-theme` attribute
**When to use:** All theme color changes
**Source:** Current codebase pattern in `src/styles/global.css`

```css
:root,
html[data-theme="light"] {
  --background: #f2f5ec;   /* Leaf Blue light background */
  --foreground: #282728;
  --accent: #1158d1;       /* Leaf Blue accent */
  --muted: #e6e6e6;
  --border: #ece9e9;
}

html[data-theme="dark"] {
  --background: #000123;   /* AstroPaper v4 dark background */
  --foreground: #eaedf3;
  --accent: #617bff;       /* AstroPaper v4 dark accent */
  --muted: #343f60bf;
  --border: #ab4b08;
}
```

### Pattern 2: SVG Favicon with Dark Mode Support

**What:** Single SVG file with embedded CSS media query for theme adaptation
**When to use:** Primary favicon, responds to system dark mode
**Source:** [Evil Martians Favicon Guide](https://evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs), [Owen Conti SVG Dark Mode](https://owenconti.com/posts/supporting-dark-mode-with-svg-favicons)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <style>
    rect { fill: #f2f5ec; }  /* Light mode: Leaf Blue background */
    text { fill: #1158d1; }  /* Light mode: Leaf Blue accent */
    @media (prefers-color-scheme: dark) {
      rect { fill: #000123; }  /* Dark mode: AstroPaper v4 background */
      text { fill: #617bff; }  /* Dark mode: AstroPaper v4 accent */
    }
  </style>
  <rect width="512" height="512"/>
  <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle"
        font-family="sans-serif" font-weight="bold" font-size="280">JC</text>
</svg>
```

### Pattern 3: Astro Static File Endpoint for ICO Generation

**What:** Generate favicon.ico dynamically at build time using sharp-ico
**When to use:** Creating multi-resolution ICO file
**Source:** [kremalicious Astro favicon guide](https://kremalicious.com/favicon-generation-with-astro/)

```typescript
// src/pages/favicon.ico.ts
import type { APIRoute } from 'astro';
import sharp from 'sharp';
import ico from 'sharp-ico';
import path from 'node:path';

const faviconSrc = path.resolve('src/assets/favicon.png');
const sizes = [16, 32, 48];

export const GET: APIRoute = async () => {
  const buffers = await Promise.all(
    sizes.map(async (size) => {
      return await sharp(faviconSrc)
        .resize(size)
        .toFormat('png')
        .toBuffer();
    })
  );

  const icoBuffer = ico.encode(buffers);

  return new Response(icoBuffer, {
    headers: { 'Content-Type': 'image/x-icon' }
  });
};
```

### Anti-Patterns to Avoid

- **Hardcoding URLs in components:** Newsletter form has hardcoded Buttondown URL. Make configurable via props or consts.ts.
- **Separate light/dark favicon files with media attribute:** While supported (97% browsers), embedded SVG styles are cleaner and the project already uses SVG.
- **Over-generating favicon sizes:** Modern browsers only need 32x32 ICO, 180x180 Apple touch, and scalable SVG. Don't generate 20+ files.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ICO encoding | Custom binary manipulation | sharp-ico | ICO format has complex multi-image structure |
| Image resizing | Manual pixel manipulation | Sharp | Handles color profiles, antialiasing, formats |
| SVG to PNG conversion | Canvas/DOM rendering | Sharp | Server-side, consistent output |
| GitHub avatar URL | Hardcoded avatar file | `https://avatars.githubusercontent.com/justcarlson` | Auto-updates with GitHub profile changes |

**Key insight:** Favicon generation looks simple (it's just small images!) but ICO format, Apple touch icons, and PWA manifests have specific requirements that libraries handle correctly.

## Common Pitfalls

### Pitfall 1: Forgetting PWA Manifest Update

**What goes wrong:** Site config updated but PWA manifest in `astro.config.mjs` still references old values
**Why it happens:** PWA config is in Astro config, not consts.ts
**How to avoid:** Update AstroPWA config in astro.config.mjs simultaneously with consts.ts
**Warning signs:** Browser dev tools show old name in "Add to Home Screen"

### Pitfall 2: Inconsistent Theme Colors

**What goes wrong:** Colors updated in global.css but not in BaseHead.astro meta tags or PWA manifest
**Why it happens:** Theme colors appear in multiple places: CSS, meta tags, manifest
**How to avoid:** Grep for hex values before committing; update all occurrences
**Warning signs:** Browser chrome color doesn't match site theme

### Pitfall 3: SVG Favicon Not Updating

**What goes wrong:** Favicon changes not visible after updating SVG
**Why it happens:** Browsers aggressively cache favicons; SVG favicons only respond to system dark mode, not site toggle
**How to avoid:** Hard refresh (Ctrl+Shift+R), clear favicon cache, or add version query param
**Warning signs:** Old favicon persists even after file change

### Pitfall 4: Newsletter Form Still Hardcoded

**What goes wrong:** Newsletter form still submits to Peter's Buttondown
**Why it happens:** Form action URL is hardcoded in component, not from config
**How to avoid:** Extract URL to consts.ts, make component prop-driven, or disable form pending setup
**Warning signs:** Test submission goes to wrong account

### Pitfall 5: Social Links Array Mismatch

**What goes wrong:** SOCIAL_LINKS in consts.ts and SOCIALS in constants.ts get out of sync
**Why it happens:** Two separate arrays for social links exist
**How to avoid:** Consolidate to single source of truth, or update both files together
**Warning signs:** Different social links appear in different parts of site

## Code Examples

### Updating consts.ts

```typescript
// Source: Current codebase pattern
export const SITE: Site = {
  website: "https://justcarlson.com/",
  author: "Just Carlson",
  profile: "https://justcarlson.com/about",
  desc: "Writing about things I find interesting.",  // Casual tone per CONTEXT.md
  title: "Just Carlson",
  ogImage: "og.png",
  lightAndDarkMode: true,
  postPerIndex: 10,
  postPerPage: 10,
  scheduledPostMargin: 15 * 60 * 1000,
  showArchives: false,
  showBackButton: false,
  editPost: {
    enabled: true,
    text: "Edit on GitHub",
    url: "https://github.com/justcarlson/justcarlson.com/edit/main/",
  },
  dynamicOgImage: true,
  lang: "en",
  timezone: "America/Los_Angeles",
};
```

### Updating constants.ts SOCIALS Array

```typescript
// Source: Current codebase pattern
export const SOCIALS = [
  {
    name: "Github",
    href: "https://github.com/justcarlson",
    linkTitle: ` ${SITE.title} on Github`,
    icon: "github",
    active: true,
  },
  {
    name: "LinkedIn",
    href: "https://www.linkedin.com/in/justincarlson0/",
    linkTitle: `${SITE.title} on LinkedIn`,
    icon: "linkedin",
    active: true,
  },
  // Remove X, BlueSky, Mail per user's social presence
] as const;
```

### Theme Colors in global.css

```css
/* Source: Requirements VIS-01, VIS-02 */
:root,
html[data-theme="light"] {
  --background: #f2f5ec;  /* Leaf Blue */
  --foreground: #282728;
  --accent: #1158d1;      /* Leaf Blue accent */
  --muted: #e6e6e6;
  --border: #dde3d5;      /* Harmonize with Leaf Blue */
}

html[data-theme="dark"] {
  --background: #000123;  /* AstroPaper v4 */
  --foreground: #eaedf3;
  --accent: #617bff;      /* AstroPaper v4 accent */
  --muted: #1a1a3d;
  --border: #2a2a5a;
}
```

### BaseHead.astro Theme Meta Tags

```html
<!-- Source: Based on current pattern, updated colors -->
<meta name="theme-color" content="#1158d1" media="(prefers-color-scheme: light)" />
<meta name="theme-color" content="#617bff" media="(prefers-color-scheme: dark)" />
<meta name="msapplication-TileColor" content="#1158d1" />
```

### GitHub Avatar URL

```html
<!-- Source: GitHub avatar URL format -->
<!-- Use GitHub's avatar CDN - auto-updates with profile changes -->
<img src="https://avatars.githubusercontent.com/justcarlson" alt="Just Carlson" />
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 20+ favicon PNG files | SVG + ICO + 180px Apple | 2021-2023 | Much simpler, smaller payload |
| Separate light/dark favicon files | Single SVG with media query | 2022+ | Single file, auto-adapts |
| Manual favicon.ico creation | Dynamic generation via Sharp | 2023+ | Build-time generation, consistent quality |
| Multiple social config arrays | Single source of truth | Best practice | Prevents sync issues |

**Deprecated/outdated:**
- Windows 8 tiles (msapplication-* meta tags): Still technically supported but rarely needed
- favicon-16x16.png, favicon-32x32.png separate files: Unnecessary with ICO multi-resolution support

## Open Questions

1. **Newsletter Form Handling**
   - What we know: Form currently hardcoded to Peter's Buttondown
   - What's unclear: Whether to disable entirely, make configurable, or leave placeholder
   - Recommendation: Make URL configurable in consts.ts, disable/hide form until service configured

2. **Border/Muted Colors for New Schemes**
   - What we know: Background and accent specified in requirements
   - What's unclear: Exact muted/border values for Leaf Blue and AstroPaper v4
   - Recommendation: Derive harmonious values from background/accent (research suggests darker variants of background)

3. **Apple Touch Icon Design**
   - What we know: Needs 180x180 PNG for iOS home screen
   - What's unclear: Whether to use JC monogram or different design
   - Recommendation: Use same JC monogram design, solid background (no transparency for Apple)

## Sources

### Primary (HIGH confidence)
- Codebase files: `src/consts.ts`, `src/constants.ts`, `src/styles/global.css`, `src/components/BaseHead.astro`
- [Evil Martians Favicon Guide](https://evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs) - Authoritative favicon strategy
- [sharp-ico GitHub](https://github.com/ssnangua/sharp-ico) - API documentation for ICO encoding

### Secondary (MEDIUM confidence)
- [kremalicious Astro favicon](https://kremalicious.com/favicon-generation-with-astro/) - Astro-specific pattern
- [Owen Conti SVG Dark Mode](https://owenconti.com/posts/supporting-dark-mode-with-svg-favicons) - SVG media query syntax
- [MDN PWA Icons](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/How_to/Define_app_icons) - PWA manifest requirements

### Tertiary (LOW confidence)
- Web search results on favicon best practices 2026 - Confirmed trends, general guidance

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Sharp already installed, sharp-ico is established
- Architecture: HIGH - Codebase patterns are clear, well-documented
- Pitfalls: HIGH - Based on direct codebase analysis
- Color application: MEDIUM - Border/muted values need derivation

**Research date:** 2026-01-28
**Valid until:** 2026-02-28 (stable domain, low change velocity)
