# Phase 3: Infrastructure - Research

**Researched:** 2026-01-29
**Domain:** Vercel deployment configuration, PWA manifest, CSP headers, Astro build validation
**Confidence:** HIGH

## Summary

Phase 3 focuses on infrastructure configuration for production deployment: PWA manifest branding, Vercel configuration cleanup (redirects and CSP headers), and build-time validation. The codebase already uses @vite-pwa/astro (v1.2.0) for PWA functionality and has an established vercel.json configuration pattern.

The standard approach is:
1. **PWA Manifest**: Configure directly in `astro.config.mjs` using the `@vite-pwa/astro` integration's manifest option
2. **Vercel Config**: Modify `vercel.json` redirects and headers arrays using documented patterns
3. **Build Validation**: Use Astro integration hooks (`astro:build:start`, `astro:build:done`) for custom validation, or npm post-build scripts for simpler checks

Current codebase patterns show:
- PWA already configured with @vite-pwa/astro in `astro.config.mjs` (lines 100-172)
- Comprehensive vercel.json with redirects (8 rules), rewrites (3 rules), and headers (CSP + security headers)
- TypeScript strict mode enabled, biome for linting, husky + lint-staged for pre-commit hooks
- Simple middleware pattern for runtime redirects (src/middleware.js)

**Primary recommendation:** Update PWA manifest fields in astro.config.mjs, selectively remove redirects from vercel.json, update CSP directive allowlists, and add a simple Astro integration for build validation (warn-only for identity leaks, fail for TypeScript/lint errors).

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| @vite-pwa/astro | 1.2.0 | PWA manifest and service worker | Official Vite PWA plugin for Astro, zero-config with extensive customization |
| Vercel | Platform | Deployment and edge config | Native Astro support, vercel.json for declarative redirects/headers |
| Astro Integration API | Built-in | Build-time validation hooks | Native API, no external dependencies |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Zod | 3.x (shipped with Astro) | Integration options validation | When creating custom integrations with typed options |
| npm scripts | Built-in | Post-build validation | Simple grep/check tasks that don't need build context |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| @vite-pwa/astro | Manual manifest.webmanifest | Lose auto-injection, service worker generation, dev mode PWA testing |
| vercel.json redirects | Astro middleware | Runtime overhead vs build-time config; middleware better for dynamic logic |
| Astro integration hooks | npm postbuild scripts | Lose access to build artifacts/logger; scripts simpler for grep checks |

**Installation:**
```bash
# Already installed in this project
npm list @vite-pwa/astro  # v1.2.0
```

## Architecture Patterns

### Recommended Project Structure
```
├── astro.config.mjs         # PWA manifest, integrations, build hooks
├── vercel.json              # Redirects, headers, CSP policy
├── src/
│   ├── integrations/        # Custom Astro integrations (optional)
│   │   └── build-validator.ts
│   └── middleware.js        # Runtime redirects (already exists)
└── public/
    ├── favicon.ico          # PWA icons (already exists)
    └── apple-touch-icon.png
```

### Pattern 1: PWA Manifest Configuration in astro.config.mjs

**What:** Configure PWA manifest inline within the AstroPWA integration options
**When to use:** Always, for this stack (already in use)

**Example:**
```javascript
// Source: https://vite-pwa-org.netlify.app/frameworks/astro
import AstroPWA from '@vite-pwa/astro';

export default defineConfig({
  integrations: [
    AstroPWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.ico', 'apple-touch-icon.png'],
      manifest: {
        name: 'Full App Name',
        short_name: 'ShortName',
        description: 'App description text',
        theme_color: '#hexcolor',
        background_color: '#hexcolor',
        display: 'standalone',
        scope: '/',
        start_url: '/',
        icons: [
          { src: 'favicon.ico', sizes: '48x48', type: 'image/x-icon' },
          { src: 'icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: 'icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'any maskable' }
        ]
      },
      workbox: {
        navigateFallback: '/404',
        globPatterns: ['**/*.{css,js,html,svg,png,jpg,jpeg,gif,webp,woff,woff2,ttf,eot,ico}']
      }
    })
  ]
});
```

**Key fields (per PWA Minimal Requirements):**
- `name`: Full application name
- `short_name`: Abbreviated name (under 12 chars recommended)
- `description`: Detailed description
- `theme_color`: Must match meta theme-color in HTML
- `icons`: Minimum 192x192 and 512x512 PNG images required

**Icon requirements (Lighthouse/PWA standards):**
- Minimum: 192x192 (required)
- Recommended: 512x512 (required)
- Additional: 144x144, 256x256, 384x384 for platform compatibility
- Purpose: `any` (default), `maskable` (for adaptive icons with safe zone)

**Sources:**
- [Vite PWA Astro Integration](https://vite-pwa-org.netlify.app/frameworks/astro)
- [PWA Minimal Requirements](https://vite-pwa-org.netlify.app/guide/pwa-minimal-requirements.html)
- [MDN: Define app icons](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/How_to/Define_app_icons)

### Pattern 2: Vercel.json Redirects Configuration

**What:** Declarative redirect rules with pattern matching and status codes
**When to use:** URL migrations, legacy path support, domain redirects

**Example:**
```json
// Source: https://vercel.com/docs/redirects
{
  "redirects": [
    {
      "source": "/:year(\\d{4})/:month(\\d{2})/:day(\\d{2})/:slug",
      "destination": "/posts/:slug",
      "permanent": true  // 301 redirect
    },
    {
      "source": "/blog/:slug",
      "destination": "/posts/:slug",
      "permanent": true
    }
  ]
}
```

**Redirect types:**
- `permanent: true` → 308 status (recommended for permanent redirects, preserves method)
- `permanent: false` → 307 status (temporary, preserves method)
- Legacy: 301 (permanent, may change method), 302 (temporary, may change method)

**Pattern matching:**
- Named parameters: `:slug`, `:id`
- Regex constraints: `:year(\\d{4})`
- Wildcards: `:path*` (matches segments), `/:path(.*)` (matches with slashes)

**Conditional redirects (has/missing):**
```json
{
  "source": "/:path*.md",
  "has": [{ "type": "host", "value": "example.com" }],
  "missing": [{ "type": "header", "key": "accept", "value": "(?i).*text/markdown.*" }],
  "destination": "https://example.md/:path*",
  "permanent": false
}
```

**Best practices (from research):**
- Use `permanent: true` (308) for permanent URL structure changes (SEO benefit)
- Use `permanent: false` (307) for temporary redirects
- Avoid redirect chains (max 1-2 hops for performance)
- Be specific with patterns to avoid unintended matches

**Sources:**
- [Vercel Redirects Documentation](https://vercel.com/docs/redirects)
- [Vercel: Does Vercel support permanent redirects?](https://vercel.com/kb/guide/does-vercel-support-permanent-redirects)

### Pattern 3: Content-Security-Policy Headers in vercel.json

**What:** Security headers that control resource loading sources
**When to use:** Always, for XSS protection and security hardening

**Example:**
```json
// Source: https://vercel.com/docs/headers/security-headers
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' blob:; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'; media-src 'self'; object-src 'none'; frame-ancestors 'none'; frame-src https://www.youtube.com; worker-src 'self' blob:"
        }
      ]
    }
  ]
}
```

**CSP Directive Reference:**

| Directive | Controls | Example Value |
|-----------|----------|---------------|
| `default-src` | Fallback for all fetch directives | `'self'` |
| `script-src` | JavaScript execution | `'self' 'unsafe-inline' 'unsafe-eval' blob:` |
| `style-src` | CSS stylesheets | `'self' 'unsafe-inline'` |
| `img-src` | Image sources | `'self' data: https: blob:` |
| `font-src` | Font resources | `'self' fonts.gstatic.com` |
| `connect-src` | XHR, WebSocket, fetch | `'self' api.example.com` |
| `media-src` | Audio/video | `'self' cdn.example.com` |
| `object-src` | `<object>`, `<embed>` | `'none'` (recommended) |
| `frame-ancestors` | Can embed this page | `'none'` (anti-clickjacking) |
| `frame-src` | Can embed these sources | `https://youtube.com` |
| `worker-src` | Web worker sources | `'self' blob:` |

**Keyword values:**
- `'self'`: Same origin as document
- `'none'`: Block all sources
- `'unsafe-inline'`: Allow inline scripts/styles (not recommended, but needed for some frameworks)
- `'unsafe-eval'`: Allow eval() (not recommended, but needed for some libraries)
- `blob:`: Allow blob: URLs (for dynamically generated content)
- `data:`: Allow data: URLs (for inline images, fonts)

**Domain patterns:**
- Specific domain: `https://example.com`
- Protocol + domain: `https://example.com`
- Wildcard subdomain: `https://*.example.com`
- Protocol wildcard: `https:`

**Best practices (from Vercel docs):**
- Start with `Content-Security-Policy-Report-Only` to test without breaking
- Avoid `'unsafe-inline'` and `'unsafe-eval'` when possible
- Use nonces or hashes for inline scripts (more complex setup)
- Set `object-src 'none'` to block dangerous embeds
- Set `frame-ancestors 'none'` for clickjacking protection
- Be specific with domains, avoid wildcard `*`

**Sources:**
- [Vercel: Content Security Policy](https://vercel.com/docs/headers/security-headers)
- [MDN: Content-Security-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)

### Pattern 4: Astro Build Validation Integration

**What:** Custom Astro integration using build hooks for validation
**When to use:** Need access to build context (files, logger, assets)

**Example:**
```typescript
// Source: https://docs.astro.build/en/reference/integrations-reference/
import type { AstroIntegration } from 'astro';

export default function buildValidator(): AstroIntegration {
  return {
    name: 'build-validator',
    hooks: {
      'astro:build:start': async ({ logger }) => {
        logger.info('Starting build validation...');
        // Pre-build checks (e.g., config validation)
      },
      'astro:build:done': async ({ dir, pages, logger }) => {
        logger.info('Post-build validation...');

        // Example: Check for identity leaks in build output
        const { execSync } = await import('child_process');
        try {
          const result = execSync(
            `grep -r "steipete\\|Peter Steinberger" ${dir.pathname}`,
            { encoding: 'utf-8' }
          );
          if (result) {
            logger.warn(`Identity leaks found:\n${result}`);
          }
        } catch (error) {
          // grep exits with 1 if no matches (expected)
          if (error.status === 1) {
            logger.info('No identity leaks found');
          } else {
            throw error;
          }
        }

        // Example: Verify critical pages exist
        const requiredPages = ['/', '/about', '/posts'];
        const pageUrls = pages.map(p => p.pathname);
        for (const required of requiredPages) {
          if (!pageUrls.includes(required)) {
            logger.error(`Missing required page: ${required}`);
            throw new Error(`Build validation failed: missing ${required}`);
          }
        }
      }
    }
  };
}
```

**Available hooks:**
- `astro:config:setup`: Modify config before build
- `astro:config:done`: After config resolved (read-only)
- `astro:build:start`: Before production build begins
- `astro:build:done`: After build completes (access to output)
- `astro:build:ssr`: Access SSR manifest

**astro:build:done options:**
```typescript
{
  pages: { pathname: string }[];  // All generated pages
  dir: URL;                        // Output directory
  assets: Map<string, URL[]>;      // Generated assets
  logger: AstroIntegrationLogger;  // Namespaced logger
}
```

**Logger methods:**
- `logger.info(msg)`: Informational
- `logger.warn(msg)`: Warnings (don't fail build)
- `logger.error(msg)`: Errors (throw to fail build)

**Integration registration:**
```javascript
// astro.config.mjs
import buildValidator from './src/integrations/build-validator';

export default defineConfig({
  integrations: [buildValidator(), /* other integrations */]
});
```

**Sources:**
- [Astro Integration API Reference](https://docs.astro.build/en/reference/integrations-reference/)
- [Understanding Astro integrations and hooks lifecycle](https://blog.logrocket.com/understanding-astro-integrations-hooks-lifecycle/)

### Pattern 5: npm Post-Build Scripts for Simple Validation

**What:** npm lifecycle hooks (postbuild) for validation without build context
**When to use:** Simple grep checks, file existence, no need for Astro logger/context

**Example:**
```json
// package.json
{
  "scripts": {
    "build": "astro build && pagefind --site dist",
    "postbuild": "node scripts/validate-build.mjs"
  }
}
```

```javascript
// scripts/validate-build.mjs
import { execSync } from 'child_process';

console.log('🔍 Running build validation...');

// Check for identity leaks (warn only)
try {
  const leaks = execSync(
    'grep -r "steipete\\|Peter Steinberger" dist/',
    { encoding: 'utf-8' }
  );
  console.warn('⚠️  Identity leaks found:\n', leaks);
} catch (error) {
  if (error.status === 1) {
    console.log('✅ No identity leaks detected');
  } else {
    throw error;
  }
}

// Check for broken internal links (warn only)
// ... additional checks ...

console.log('✅ Build validation complete');
```

**npm lifecycle hooks:**
- `prebuild`: Runs before `build`
- `build`: Main build command
- `postbuild`: Runs after `build` succeeds
- Pre/post hooks are exit-code-sensitive (non-zero stops chain)

**Best practices:**
- Use `.mjs` for ES modules (import/export)
- Exit with non-zero for hard failures
- Log warnings but don't exit for soft failures
- Keep scripts simple; use Astro integration for complex validation

**Sources:**
- [npm scripts documentation](https://docs.npmjs.com/misc/scripts)
- [Using npm pre and post hooks](https://www.yld.com/blog/using-npm-pre-and-post-hooks)

### Anti-Patterns to Avoid

- **Editing public/site.webmanifest directly**: @vite-pwa/astro auto-generates manifest; edit astro.config.mjs instead
- **Using both middleware and vercel.json for same redirects**: Duplication and potential conflicts; prefer vercel.json for static redirects (performance)
- **Overly broad CSP wildcards**: Using `*` or `https:` defeats purpose; be specific with domains
- **Using `'unsafe-inline'` without nonces**: Opens XSS vectors; acceptable for Astro (no nonces yet), but document why
- **Failing builds on warnings**: Identity leaks and broken links should warn, not fail (per requirements)
- **Complex validation in npm scripts**: Use Astro integration for access to build artifacts and better error reporting

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PWA manifest generation | Manual manifest.webmanifest with script injection | @vite-pwa/astro | Auto-injection, service worker generation, icon handling, dev mode support |
| Service worker | Custom SW with Workbox API | @vite-pwa/astro workbox config | Pre-configured strategies, auto-registration, updates |
| CSP nonces | Custom nonce generation per request | Accept 'unsafe-inline' for now, or wait for Astro CSP support | Astro 5.9+ has experimental CSP support; 6.0 makes it stable |
| Redirect validation | Parsing vercel.json and checking against routes | Manual review or simple grep | Low frequency of change, complexity not justified |
| Icon generation | Manual resizing with ImageMagick | PWA Assets Generator or Favicon.io | Handles all sizes, formats, safe zones for maskable icons |

**Key insight:** PWA tooling is mature and handles many edge cases (offline support, update strategies, platform differences). CSP with nonces is complex for static sites; accept 'unsafe-inline' or wait for framework support.

## Common Pitfalls

### Pitfall 1: Icon Size Mismatches
**What goes wrong:** PWA manifest references icons that don't exist or have wrong sizes; browser shows broken icons or default logo
**Why it happens:** Copied manifest from another project, didn't update icon sizes after regeneration
**How to avoid:**
- Verify icons exist in `public/` and match manifest `src` paths
- Use `npm run dev` to test PWA in dev mode (enabled in current config)
- Check browser DevTools → Application → Manifest for errors
**Warning signs:**
- Console errors: "Manifest: property 'icons[0].src' ignored, URL is invalid"
- Missing app icon when installing PWA

### Pitfall 2: CSP Breaking Embedded Content
**What goes wrong:** YouTube embeds, social media embeds stop working after CSP update; console shows blocked resource errors
**Why it happens:** Removed domain from `frame-src` or didn't include all required domains for embed (e.g., YouTube needs both youtube.com and youtube-nocookie.com)
**How to avoid:**
- Test all embed types after CSP changes (YouTube, Twitter/X, Vimeo)
- Check browser console for CSP violation reports
- Use `Content-Security-Policy-Report-Only` header during testing (Vercel supports this)
**Warning signs:**
- Console errors: "Refused to load the script/frame because it violates CSP directive"
- Blank embed containers

### Pitfall 3: Redirect Loops
**What goes wrong:** Browser shows "too many redirects" error; page never loads
**Why it happens:** Redirect chain (A → B → C → A) or conditional redirect with overlapping patterns
**How to avoid:**
- Test redirects in isolation (curl -I or browser network tab)
- Document redirect chains and ensure they terminate
- Avoid overlapping source patterns in vercel.json
- Use middleware for complex logic (can check if already redirected)
**Warning signs:**
- ERR_TOO_MANY_REDIRECTS in browser
- Vercel function logs show repeated requests

### Pitfall 4: Build Validation False Positives
**What goes wrong:** Build fails due to validation script matching legitimate content (e.g., grep finds "Peter" in a quote or citation)
**Why it happens:** Overly aggressive regex patterns, not accounting for valid mentions
**How to avoid:**
- Use warn-only for identity leak detection (per requirements)
- Consider context-aware checks (exclude specific files/paths)
- Test validation locally before committing
- Document known false positives
**Warning signs:**
- Build fails with identity leak warning on content that should pass
- Validation scripts have hardcoded exclusions growing over time

### Pitfall 5: Trailing Slash Inconsistency
**What goes wrong:** Redirects work locally but not in production, or some paths have trailing slashes and others don't
**Why it happens:** astro.config.mjs has `trailingSlash: 'never'` but vercel.json redirects include trailing slashes in destinations
**How to avoid:**
- Check astro.config.mjs trailingSlash setting (currently set to "never")
- Ensure vercel.json redirect destinations match (no trailing slash unless root `/`)
- Test redirects after deployment
**Warning signs:**
- Redirect destination has trailing slash but Astro config says "never"
- Inconsistent URL patterns in production

## Code Examples

### Example 1: Complete PWA Manifest Update

```javascript
// astro.config.mjs
import AstroPWA from "@vite-pwa/astro";

export default defineConfig({
  site: "https://justcarlson.com/",
  trailingSlash: "never",
  integrations: [
    AstroPWA({
      registerType: "autoUpdate",
      includeAssets: ["favicon.ico", "apple-touch-icon.png"],
      manifest: {
        name: "Just Carlson",
        short_name: "JustCarlson",
        description: "Writing about things I find interesting.",
        theme_color: "#006cac",  // Match your brand color
        background_color: "#fdfdfd",
        display: "standalone",
        orientation: "portrait",
        scope: "/",
        start_url: "/",
        icons: [
          {
            src: "favicon.ico",
            sizes: "48x48",
            type: "image/x-icon",
          },
          {
            src: "apple-touch-icon.png",  // Must exist in public/
            sizes: "192x192",
            type: "image/png",
            purpose: "any",
          },
          {
            src: "apple-touch-icon.png",  // Reuse if no 512x512 exists
            sizes: "512x512",
            type: "image/png",
            purpose: "any maskable",
          },
        ],
      },
      workbox: {
        navigateFallback: "/404",
        globPatterns: ["**/*.{css,js,html,svg,png,jpg,jpeg,gif,webp,woff,woff2,ttf,eot,ico}"],
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/fonts\.googleapis\.com\/.*/i,
            handler: "CacheFirst",
            options: {
              cacheName: "google-fonts-cache",
              expiration: {
                maxEntries: 10,
                maxAgeSeconds: 60 * 60 * 24 * 365,
              },
              cacheableResponse: { statuses: [0, 200] },
            },
          },
          {
            urlPattern: /\.(?:png|jpg|jpeg|svg|gif|webp)$/,
            handler: "CacheFirst",
            options: {
              cacheName: "images-cache",
              expiration: {
                maxEntries: 100,
                maxAgeSeconds: 60 * 60 * 24 * 30,
              },
            },
          },
        ],
      },
      devOptions: {
        enabled: true,
        suppressWarnings: true,
        navigateFallbackAllowlist: [/^\//],
      },
      experimental: {
        directoryAndTrailingSlashHandler: true,
      },
    }),
  ],
});
```

**Changes from current:**
- `name`: "Peter Steinberger" → "Just Carlson"
- `short_name`: "steipete" → "JustCarlson"
- `description`: Updated to match SITE.desc
- `includeAssets`: "peter-avatar.jpg" → "apple-touch-icon.png"
- `icons`: Reference correct files (no more peter-avatar.jpg)

### Example 2: Cleaned vercel.json Redirects

```json
{
  "redirects": [
    // Keep: Generic blog URL patterns (not Peter-specific)
    {
      "source": "/:year(\\d{4})/:month(\\d{2})/:day(\\d{2})/:slug",
      "destination": "/posts/:slug",
      "permanent": true
    },
    {
      "source": "/blog/:year(\\d{4})/:month(\\d{2})/:day(\\d{2})/:slug",
      "destination": "/posts/:slug",
      "permanent": true
    },
    {
      "source": "/blog/:slug([^\\/]+)$",
      "destination": "/posts/:slug",
      "permanent": true
    },
    {
      "source": "/categories/:category(.*)",
      "destination": "/tags/:category",
      "permanent": true
    },
    {
      "source": "/tag/:tag",
      "destination": "/tags/:tag",
      "permanent": true
    },
    {
      "source": "/20:year/:month/:day/:slug(.*)",
      "destination": "/posts/:slug",
      "permanent": true
    }
    // REMOVED: Peter-specific post redirects (lines 43-56 in original)
    // REMOVED: Catch-all domain redirect (lines 58-67 in original)
  ],
  "rewrites": [
    // Keep: Generic markdown content negotiation (not identity-specific)
    {
      "source": "/",
      "has": [
        { "type": "header", "key": "accept", "value": "(?i).*text/markdown.*" }
      ],
      "destination": "/index.md"
    },
    {
      "source": "/(about|archives|posts)",
      "has": [
        { "type": "header", "key": "accept", "value": "(?i).*text/markdown.*" }
      ],
      "destination": "/$1.md"
    },
    {
      "source": "/posts/:path*",
      "has": [
        { "type": "header", "key": "accept", "value": "(?i).*text/markdown.*" }
      ],
      "destination": "/posts/:path*.md"
    }
  ],
  "headers": [
    {
      "source": "/(.*).md",
      "headers": [{ "key": "Vary", "value": "Accept" }]
    },
    {
      "source": "/(|about|archives|posts|posts/.*)",
      "headers": [{ "key": "Vary", "value": "Accept" }]
    },
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        },
        {
          "key": "Referrer-Policy",
          "value": "strict-origin-when-cross-origin"
        },
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self' https://*.vercel.app; script-src 'self' 'unsafe-inline' 'unsafe-eval' blob: data: https://*.vercel.app https://platform.twitter.com https://cdn.syndication.twimg.com https://player.vimeo.com https://vercel.live https://va.vercel-scripts.com; style-src 'self' 'unsafe-inline' https://*.vercel.app https://platform.twitter.com; img-src 'self' data: https: blob: https://ghchart.rshah.org; font-src 'self' https://*.vercel.app; connect-src 'self' https://*.vercel.app https://platform.twitter.com https://player.vimeo.com https://vimeo.com https://vitals.vercel-insights.com https://va.vercel-scripts.com; media-src 'self' https://*.vercel.app https://player.vimeo.com https://vimeo.com; object-src 'none'; frame-ancestors 'none'; frame-src https://platform.twitter.com https://syndication.twitter.com https://player.vimeo.com https://vercel.live https://www.youtube.com https://youtube.com https://*.youtube.com https://www.youtube-nocookie.com https://*.youtube-nocookie.com; worker-src 'self' blob:"
        }
      ]
    }
  ]
}
```

**Changes from current:**
- Removed: Lines 43-56 (Peter-specific post redirects)
- Removed: Lines 58-67 (catch-all domain redirect to steipete.me)
- CSP removed: `https://steipete.me` and `https://*.sweetistics.com` from all directives
- CSP kept: YouTube, Vimeo, Twitter, GitHub chart, Vercel services (per requirements)

### Example 3: Build Validation Integration

```typescript
// src/integrations/build-validator.ts
import type { AstroIntegration } from 'astro';
import { execSync } from 'child_process';

export default function buildValidator(): AstroIntegration {
  return {
    name: 'build-validator',
    hooks: {
      'astro:build:done': async ({ dir, pages, logger }) => {
        logger.info('Running build validation...');

        // 1. Identity leak detection (WARN ONLY)
        try {
          const distPath = dir.pathname;
          const identityLeaks = execSync(
            `grep -r -i "steipete\\|peter steinberger" "${distPath}" --exclude-dir=node_modules || true`,
            { encoding: 'utf-8', maxBuffer: 1024 * 1024 }
          ).trim();

          if (identityLeaks) {
            logger.warn('⚠️  Identity leaks detected (not blocking build):');
            logger.warn(identityLeaks);
          } else {
            logger.info('✅ No identity leaks detected');
          }
        } catch (error) {
          logger.warn(`Identity leak check failed: ${error.message}`);
        }

        // 2. Smoke test: Verify critical pages exist (WARN ONLY)
        const requiredPages = ['/', '/about', '/posts'];
        const generatedPages = pages.map(p => p.pathname);
        const missingPages = requiredPages.filter(p => !generatedPages.includes(p));

        if (missingPages.length > 0) {
          logger.warn(`⚠️  Missing pages (not blocking build): ${missingPages.join(', ')}`);
        } else {
          logger.info(`✅ All critical pages generated: ${requiredPages.join(', ')}`);
        }

        // 3. Check for broken internal links (WARN ONLY)
        // Note: This is a simplified check; consider using a proper link checker
        try {
          const brokenLinks = execSync(
            `grep -r -E 'href="[^"]*404[^"]*"' "${dir.pathname}" || true`,
            { encoding: 'utf-8', maxBuffer: 1024 * 1024 }
          ).trim();

          if (brokenLinks) {
            logger.warn('⚠️  Potential broken links detected:');
            logger.warn(brokenLinks.substring(0, 500)); // Limit output
          }
        } catch (error) {
          logger.warn(`Link check failed: ${error.message}`);
        }

        logger.info('✅ Build validation complete (all checks passed or warned)');
      }
    }
  };
}
```

```javascript
// astro.config.mjs
import buildValidator from './src/integrations/build-validator.ts';

export default defineConfig({
  integrations: [
    mdx(),
    sitemap({ /* ... */ }),
    react(),
    AstroPWA({ /* ... */ }),
    buildValidator(), // Add validation integration
  ],
});
```

**Notes:**
- All checks use `logger.warn()` (not `logger.error()` or `throw`) to avoid failing builds
- TypeScript/lint errors still fail via `astro check` (separate from this)
- Grep uses `|| true` to avoid non-zero exit codes
- MaxBuffer set to prevent large output crashes

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual manifest.webmanifest | @vite-pwa/astro auto-generation | 2022+ | No manual JSON editing; manifest in config |
| X-Frame-Options header | frame-ancestors CSP directive | 2015+ (CSP2) | CSP provides more granular control |
| 'unsafe-inline' discouraged | Accepted for Astro static sites | Ongoing | Static sites can't easily use nonces; Astro 6.0 adds CSP support |
| 301/302 redirect status codes | 307/308 recommended | 2014 (RFC 7538) | Preserves HTTP method, clearer semantics |
| Service worker manual coding | Workbox strategies | 2017+ | Simpler config, battle-tested caching |

**Deprecated/outdated:**
- Manual service worker registration: Use @vite-pwa/astro `registerType: 'autoUpdate'`
- `X-Frame-Options` header: Superseded by CSP `frame-ancestors` (more flexible)
- Using 301/302 for permanent redirects: Prefer 308 (Vercel default with `permanent: true`)

**Astro 6.0 CSP Support (stable as of Jan 2026):**
- Experimental in 5.9, stable in 6.0
- Enables per-page nonces for inline scripts
- Potential future migration: Remove 'unsafe-inline' in favor of nonces
- Current project on Astro 5.16.6; consider upgrade for stricter CSP

## Open Questions

1. **Icon asset availability**
   - What we know: Current PWA config references "peter-avatar.jpg"; public/ has "apple-touch-icon.png" (3205 bytes)
   - What's unclear: Is apple-touch-icon.png 192x192? Do we have/need a 512x512 icon?
   - Recommendation: Verify icon sizes with `file public/apple-touch-icon.png` or image viewer; generate missing sizes if needed (use Favicon.io or similar)

2. **Custom 404 page branding**
   - What we know: 404.astro exists (src/pages/404.astro), still has "Peter Steinberger's blog" in description (line 9)
   - What's unclear: Is 404 page update in scope for Phase 3 or Phase 2 (components)?
   - Recommendation: Phase 2 likely handled it; double-check and update if missed (simple text change)

3. **Hardcoded URLs in StructuredData.astro**
   - What we know: INF-04 mentions fixing hardcoded URLs, but StructuredData.astro uses SITE.website and SITE.author (no hardcoded steipete.me)
   - What's unclear: What hardcoded URLs exist? Or is this resolved by Phase 1 config updates?
   - Recommendation: Grep for hardcoded steipete.me in src/components/StructuredData.astro; likely already resolved via SITE constant

4. **Trailing slash behavior for redirects**
   - What we know: astro.config.mjs has `trailingSlash: "never"`; some current redirects have trailing slash in source
   - What's unclear: Should redirect sources match this (no trailing slash)?
   - Recommendation: Follow Astro config; remove trailing slashes from redirect sources unless root `/`

5. **Middleware vs vercel.json for generic redirects**
   - What we know: Middleware handles /blog/* → /posts/* at runtime; vercel.json also has /blog/:slug → /posts/:slug
   - What's unclear: Is there duplication? Should middleware redirect be removed?
   - Recommendation: Middleware runs for all deployments (preview, dev); vercel.json only in production. Keep both or consolidate to vercel.json for performance

## Sources

### Primary (HIGH confidence)
- [Vite PWA Astro Framework Guide](https://vite-pwa-org.netlify.app/frameworks/astro) - PWA integration setup
- [PWA Minimal Requirements](https://vite-pwa-org.netlify.app/guide/pwa-minimal-requirements.html) - Manifest and icon requirements
- [Astro Integration API Reference](https://docs.astro.build/en/reference/integrations-reference/) - Build hooks documentation
- [Vercel Redirects Documentation](https://vercel.com/docs/redirects) - Redirect configuration patterns
- [Vercel Security Headers: CSP](https://vercel.com/docs/headers/security-headers) - Content-Security-Policy best practices
- [MDN: Content-Security-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) - CSP directive reference
- [MDN: Define app icons](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/How_to/Define_app_icons) - Icon requirements and formats

### Secondary (MEDIUM confidence)
- [Astro Middleware Documentation](https://docs.astro.build/en/guides/middleware/) - Middleware patterns (verified with official docs)
- [Understanding Astro integrations and hooks lifecycle](https://blog.logrocket.com/understanding-astro-integrations-hooks-lifecycle/) - Integration examples (verified with official docs)
- [Using npm pre and post hooks](https://www.yld.com/blog/using-npm-pre-and-post-hooks) - npm script lifecycle (verified with npm docs)
- [Vercel: Does Vercel support permanent redirects?](https://vercel.com/kb/guide/does-vercel-support-permanent-redirects) - Redirect status codes (official Vercel KB)

### Tertiary (LOW confidence)
- None - all findings verified with official sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - @vite-pwa/astro and Vercel are documented, stable, and already in use
- Architecture: HIGH - All patterns verified with official documentation and existing codebase
- Pitfalls: MEDIUM - Based on general web development experience and CSP/PWA common issues; not project-specific incidents

**Research date:** 2026-01-29
**Valid until:** 2026-02-28 (30 days - stable tech stack, no fast-moving changes expected)

**Codebase audit notes:**
- Current astro.config.mjs: Lines 100-172 (PWA config with Peter's branding)
- Current vercel.json: 149 lines (8 redirects, 3 rewrites, CSP with steipete.me and sweetistics.com)
- Build system: npm scripts with husky pre-commit hooks; no custom build validation
- TypeScript: Strict mode enabled (tsconfig.json)
- Linting: Biome (replaces ESLint/Prettier)
