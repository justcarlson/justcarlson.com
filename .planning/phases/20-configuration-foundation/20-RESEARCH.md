# Phase 20: Configuration Foundation - Research

**Researched:** 2026-02-02
**Domain:** Vercel Image Optimization, CSP Headers, CSS Fallback Animations, Playwright Testing
**Confidence:** HIGH

## Summary

This phase configures Vercel Image Optimization to proxy external images (Gravatar, GitHub chart) and updates CSP headers to enforce proxy-only image loading. The research confirms that Vercel's `images` configuration in `vercel.json` supports the `remotePatterns` property for allowlisting external domains, enabling the `/_vercel/image` endpoint to proxy and optimize images from specified origins.

The current site uses Gravatar (`gravatar.com`) on the homepage and GitHub chart (`ghchart.rshah.org`) on the about page. Both need to be added to `remotePatterns`. The CSP header currently has `img-src 'self' data: https: blob: https://ghchart.rshah.org` which must be tightened to `img-src 'self' data: blob:` once the proxy is configured.

CSS shimmer animations for loading states are well-established patterns using `@keyframes` with `transform: translateX()` for GPU-accelerated performance. Playwright testing can block images via route interception to verify fallback behavior.

**Primary recommendation:** Add `images.remotePatterns` to `vercel.json` for `gravatar.com` and `ghchart.rshah.org`, then update CSP `img-src` directive to proxy-only (`'self' data: blob:`).

## Standard Stack

### Core Configuration

| Component | Location | Purpose | Why Standard |
|-----------|----------|---------|--------------|
| vercel.json | Root | Image optimization config | Vercel's official configuration file for non-Next.js projects |
| CSS @keyframes | src/styles/ | Shimmer animation | Native CSS, GPU-accelerated, no JS dependencies |
| Playwright | tests/ | E2E testing | Industry-standard browser automation for Vercel projects |

### Supporting

| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| @playwright/test | 1.x | Test framework | All E2E tests including image blocking scenarios |
| Tailwind CSS | 4.x | Utility classes | Already in project for styling |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CSS shimmer | JavaScript skeleton loader | CSS is simpler, no hydration concerns for SSG |
| Playwright | Cypress | Playwright has better network interception API |
| vercel.json images | @astrojs/vercel imageService | vercel.json works without Astro adapter changes |

**No installation required** - Playwright will need to be added as a devDependency when implementing tests.

## Architecture Patterns

### Vercel Image Optimization Configuration

The `images` configuration in `vercel.json` controls the `/_vercel/image` endpoint.

**Configuration structure:**
```json
{
  "images": {
    "sizes": [256, 640, 1080, 2048, 3840],
    "remotePatterns": [
      {
        "protocol": "https",
        "hostname": "gravatar.com",
        "pathname": "/avatar/**"
      },
      {
        "protocol": "https",
        "hostname": "ghchart.rshah.org",
        "pathname": "/**"
      }
    ],
    "formats": ["image/webp", "image/avif"],
    "minimumCacheTTL": 60
  }
}
```

**Key properties:**
- `sizes` (required): Allowed image widths for the `w` parameter
- `remotePatterns` (optional): Allowlist of external domains
- `formats` (optional): Output formats - defaults include webp/avif
- `minimumCacheTTL` (optional): Cache duration in seconds

**RemotePattern object:**
- `protocol`: `"http"` or `"https"` (optional, defaults to both)
- `hostname`: Domain name (required)
- `port`: Port number (optional)
- `pathname`: Path pattern using `**` wildcards (optional)
- `search`: Query string restriction (optional)

### CSP Header Update Pattern

**Current CSP (problematic):**
```
img-src 'self' data: https: blob: https://ghchart.rshah.org
```

**Target CSP (proxy-only):**
```
img-src 'self' data: blob:
```

The `/_vercel/image` endpoint serves from the same origin (`'self'`), so no additional CSP entries are needed once images are proxied.

**Important:** The frame-src, connect-src, script-src directives for YouTube, Vimeo, Twitter embeds remain unchanged - only `img-src` becomes restrictive.

### Shimmer Animation Pattern

**What:** CSS-only loading placeholder with animated gradient
**When to use:** Any image that loads from external sources

**Recommended implementation:**
```css
/* Source: CSS best practices for skeleton loaders */
.image-loading {
  position: relative;
  background-color: var(--skeleton-base, #e8e8e8);
  overflow: hidden;
}

.image-loading::after {
  content: '';
  position: absolute;
  inset: 0;
  transform: translateX(-100%);
  background-image: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0) 0,
    rgba(255, 255, 255, 0.2) 20%,
    rgba(255, 255, 255, 0.5) 60%,
    rgba(255, 255, 255, 0)
  );
  animation: shimmer 1.5s infinite;
}

@keyframes shimmer {
  100% {
    transform: translateX(100%);
  }
}

/* Dark mode variant */
.dark .image-loading {
  --skeleton-base: #2d2d2d;
}
```

**Key principles:**
1. Use `transform` for GPU acceleration (not `background-position`)
2. Animation duration: 1.5-2s (not too fast, not too slow)
3. `overflow: hidden` prevents shimmer bleeding outside container
4. Theme-aware base color via CSS variable

### Fallback State Pattern

**What:** Solid color when image fails to load
**When to use:** After shimmer completes or on error

```css
.image-fallback {
  background-color: var(--fallback-color, #d1d5db);
}

.dark .image-fallback {
  --fallback-color: #374151;
}
```

The transition from shimmer to fallback should be smooth:
```css
.image-loading.failed::after {
  animation: shimmer-fade 0.5s forwards;
}

@keyframes shimmer-fade {
  to {
    opacity: 0;
  }
}
```

### Anti-Patterns to Avoid

- **JavaScript skeleton libraries:** Adds bundle size and complexity for what CSS does natively
- **Using `background-position` animation:** Not GPU-accelerated, causes jank
- **Hardcoded fallback colors:** Always use theme-aware CSS variables
- **Missing overflow:hidden:** Shimmer bleeds outside rounded corners
- **No onerror=null pattern:** Causes infinite loops if fallback also fails

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image proxy | Custom serverless function | Vercel Image Optimization | Built-in, cached, optimized, no code |
| Shimmer animation | JavaScript animation library | CSS @keyframes | Native, GPU-accelerated, no dependencies |
| E2E network blocking | Manual fetch mocking | Playwright route() API | Purpose-built for this exact use case |
| CSP header generation | String concatenation | vercel.json headers config | Validated, documented, consistent |

**Key insight:** Vercel's image optimization is a platform feature, not a library. It requires only configuration, not code.

## Common Pitfalls

### Pitfall 1: Missing remotePatterns Prevents Optimization

**What goes wrong:** Images from external domains return 400 Bad Request from `/_vercel/image` endpoint
**Why it happens:** Vercel validates that the requested URL matches `remotePatterns` before optimizing
**How to avoid:** Add each external domain to `remotePatterns` with appropriate `hostname` and `pathname`
**Warning signs:** Console errors showing 400 status from `/_vercel/image?url=...`

### Pitfall 2: sizes Array Must Include Requested Widths

**What goes wrong:** Image requests fail because `w` parameter not in allowed sizes
**Why it happens:** The `sizes` array is an allowlist, not a guide
**How to avoid:** Include all widths you'll request: `[256, 640, 1080, 2048, 3840]` covers most cases
**Warning signs:** 400 errors mentioning invalid `w` parameter

### Pitfall 3: CSP Blocks Proxy Images Before Config Deployed

**What goes wrong:** Tightening CSP before proxy is working breaks existing images
**Why it happens:** CSP change deployed before or without images config
**How to avoid:** Deploy vercel.json with images config first, verify proxy works, then tighten CSP
**Warning signs:** "Refused to load the image" CSP errors in console

### Pitfall 4: Shimmer Animation Causes Layout Shift

**What goes wrong:** When image loads, container resizes causing CLS
**Why it happens:** Shimmer placeholder has different dimensions than final image
**How to avoid:** Use `aspect-ratio` or explicit width/height on container
**Warning signs:** Layout shift visible when image appears

### Pitfall 5: Infinite onerror Loop

**What goes wrong:** Image error handler creates loop if fallback also fails
**Why it happens:** `onerror` fires repeatedly when `src` is changed but also fails
**How to avoid:** Always use `onerror="this.onerror=null; ..."` pattern
**Warning signs:** Browser tab freezes, CPU spikes, repeated network requests

### Pitfall 6: Playwright Tests Flaky Due to Timing

**What goes wrong:** Tests pass locally, fail in CI
**Why it happens:** Blocking images after page starts loading creates race conditions
**How to avoid:** Set up route interception BEFORE `page.goto()`
**Warning signs:** Intermittent test failures, especially in CI

## Code Examples

### vercel.json Images Configuration

```json
// Source: Vercel Build Output API & vercel.json documentation
{
  "images": {
    "sizes": [256, 640, 1080, 2048, 3840],
    "remotePatterns": [
      {
        "protocol": "https",
        "hostname": "gravatar.com",
        "pathname": "/avatar/**"
      },
      {
        "protocol": "https",
        "hostname": "ghchart.rshah.org",
        "pathname": "/**"
      }
    ],
    "formats": ["image/webp", "image/avif"],
    "minimumCacheTTL": 3600
  }
}
```

### Proxy Image URL Format

```
/_vercel/image?url={encoded-external-url}&w={width}&q={quality}

Examples:
/_vercel/image?url=https%3A%2F%2Fgravatar.com%2Favatar%2Fef133a0cc6308305d254916b70332b1a%3Fs%3D400&w=640&q=75
/_vercel/image?url=https%3A%2F%2Fghchart.rshah.org%2Fjustcarlson&w=1080&q=75
```

### CSP Header Configuration

```json
// Source: Vercel vercel.json documentation
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self' https://*.vercel.app; script-src 'self' 'unsafe-inline' 'unsafe-eval' blob: data: https://*.vercel.app https://platform.twitter.com https://cdn.syndication.twimg.com https://player.vimeo.com https://vercel.live https://va.vercel-scripts.com; style-src 'self' 'unsafe-inline' https://*.vercel.app https://platform.twitter.com; img-src 'self' data: blob:; font-src 'self' https://*.vercel.app; connect-src 'self' https://*.vercel.app https://platform.twitter.com https://player.vimeo.com https://vimeo.com https://vitals.vercel-insights.com https://va.vercel-scripts.com; media-src 'self' https://*.vercel.app https://player.vimeo.com https://vimeo.com; object-src 'none'; frame-ancestors 'none'; frame-src https://platform.twitter.com https://syndication.twitter.com https://player.vimeo.com https://vercel.live https://www.youtube.com https://youtube.com https://*.youtube.com https://www.youtube-nocookie.com https://*.youtube-nocookie.com; worker-src 'self' blob:"
        }
      ]
    }
  ]
}
```

### Shimmer CSS Component

```css
/* Source: CSS skeleton loading best practices */
/* Add to src/styles/custom.css or new file */

/* Base shimmer animation */
@keyframes shimmer {
  100% {
    transform: translateX(100%);
  }
}

@keyframes shimmer-fade {
  to {
    opacity: 0;
  }
}

/* Loading state - applied to image container */
.img-loading {
  position: relative;
  background-color: #e5e7eb; /* gray-200 */
  overflow: hidden;
}

.img-loading::after {
  content: '';
  position: absolute;
  inset: 0;
  transform: translateX(-100%);
  background-image: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0) 0,
    rgba(255, 255, 255, 0.2) 20%,
    rgba(255, 255, 255, 0.5) 60%,
    rgba(255, 255, 255, 0)
  );
  animation: shimmer 1.5s infinite;
}

/* Dark mode shimmer */
.dark .img-loading {
  background-color: #374151; /* gray-700 */
}

.dark .img-loading::after {
  background-image: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0) 0,
    rgba(255, 255, 255, 0.05) 20%,
    rgba(255, 255, 255, 0.1) 60%,
    rgba(255, 255, 255, 0)
  );
}

/* Fallback state - solid color after failure */
.img-fallback {
  background-color: #d1d5db; /* gray-300 */
}

.dark .img-fallback {
  background-color: #4b5563; /* gray-600 */
}

/* Transition from shimmer to fallback */
.img-loading.failed::after {
  animation: shimmer-fade 0.5s forwards;
}
```

### Playwright Image Blocking Test

```typescript
// Source: Playwright network documentation
// tests/image-fallback.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Image fallback behavior', () => {
  test('shows fallback when external images blocked', async ({ page }) => {
    // CRITICAL: Set up route BEFORE navigation
    await page.route('**/*.{png,jpg,jpeg,gif,webp}', route => {
      const url = route.request().url();
      // Block external images only
      if (!url.includes('localhost') && !url.includes('vercel.app')) {
        return route.abort();
      }
      return route.continue();
    });

    await page.goto('/');

    // Avatar container should have fallback styling
    const avatar = page.locator('img[alt="Justin Carlson"]').first();

    // Verify no broken image icon (naturalWidth > 0 means loaded)
    // If blocked, image will have naturalWidth of 0 but should show fallback CSS
    const parent = avatar.locator('..');
    await expect(parent).toBeVisible();

    // No console errors about image loading
    const errors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') errors.push(msg.text());
    });

    // Wait for potential errors
    await page.waitForTimeout(1000);

    // Filter out expected blocked resource messages
    const unexpectedErrors = errors.filter(
      e => !e.includes('net::ERR_FAILED') && !e.includes('blocked')
    );
    expect(unexpectedErrors).toHaveLength(0);
  });

  test('proxy URLs work on Vercel preview', async ({ page }) => {
    // This test should run against actual Vercel preview deployment
    const previewUrl = process.env.VERCEL_PREVIEW_URL;
    if (!previewUrl) {
      test.skip();
      return;
    }

    await page.goto(previewUrl);

    const avatar = page.locator('img[alt="Justin Carlson"]').first();
    await expect(avatar).toBeVisible();

    // Check image actually loaded
    const naturalWidth = await avatar.evaluate(
      (img: HTMLImageElement) => img.naturalWidth
    );
    expect(naturalWidth).toBeGreaterThan(0);
  });
});
```

### HTML Image with Fallback Handler

```html
<!-- Source: Graceful fallback research -->
<div class="img-loading rounded-full w-40 h-40">
  <img
    src="/_vercel/image?url=https%3A%2F%2Fgravatar.com%2Favatar%2F...&w=640&q=75"
    alt="Justin Carlson"
    class="w-full h-full object-cover"
    onload="this.parentElement.classList.remove('img-loading')"
    onerror="this.onerror=null; this.style.display='none'; this.parentElement.classList.remove('img-loading'); this.parentElement.classList.add('img-fallback');"
  />
</div>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `domains` array in images config | `remotePatterns` with hostname/pathname | 2023 | More granular security, `domains` deprecated |
| CSS background-position animation | CSS transform animation | Always preferred | GPU acceleration, smoother animation |
| JavaScript skeleton libraries | Pure CSS shimmer | Always preferred for SSG | No bundle size, no hydration |
| Test image loading with naturalWidth only | Check both complete and naturalWidth | Always | Handles 404s correctly |

**Deprecated/outdated:**
- `images.domains` property: Use `remotePatterns` instead for better security
- JavaScript-based skeleton loaders for SSG sites: CSS is simpler and works without hydration

## Open Questions

1. **Exact shimmer timing for this site's design**
   - What we know: 1.5-2s is standard, ease-in-out is recommended
   - What's unclear: What feels right for this specific design
   - Recommendation: Start with 1.5s, adjust during implementation if needed

2. **Fallback color exact value**
   - What we know: Should be theme-aware (gray-200/gray-700 range)
   - What's unclear: Exact shade that matches site aesthetic
   - Recommendation: Use Tailwind's gray-300/gray-600, adjust if needed

3. **Playwright CI integration**
   - What we know: Tests can block images and verify fallback
   - What's unclear: How to run against Vercel preview deployments in CI
   - Recommendation: Use `VERCEL_PREVIEW_URL` env var, skip test if not set

## Sources

### Primary (HIGH confidence)
- [Vercel vercel.json Documentation](https://vercel.com/docs/project-configuration/vercel-json) - images configuration
- [Vercel Build Output API](https://vercel.com/docs/build-output-api/v3/configuration#images) - ImagesConfig schema
- [Vercel Image Optimization](https://vercel.com/docs/image-optimization) - How /_vercel/image works
- [Playwright Network Documentation](https://playwright.dev/docs/network) - Route interception API

### Secondary (MEDIUM confidence)
- [CSS Skeleton Loading Best Practices](https://www.matsimon.dev/blog/simple-skeleton-loaders) - Animation patterns
- [freeCodeCamp Skeleton Loader Guide](https://www.freecodecamp.org/news/how-to-build-skeleton-screens-using-css-for-better-user-experience/) - CSS implementation
- [Graceful Fallback Pitfalls Research](/.planning/research/GRACEFUL-FALLBACK-PITFALLS.md) - Project-specific pitfalls

### Tertiary (LOW confidence)
- Various CSS animation tutorials for shimmer timing (consistent across sources)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Vercel official documentation, Build Output API spec
- Architecture: HIGH - Official docs, verified configuration format
- Pitfalls: HIGH - Project-specific research already completed, official CSP documentation

**Research date:** 2026-02-02
**Valid until:** 2026-03-02 (30 days - Vercel configuration is stable)
