# Technology Stack: Graceful Fallback Handling

**Project:** justcarlson.com - External Service Degradation
**Researched:** 2026-02-02
**Overall Confidence:** HIGH

## Executive Summary

This milestone addresses graceful degradation when external services (Gravatar, Vercel Analytics) are blocked by firewalls, VPNs, or ad blockers. **No new dependencies required** - the existing stack (Astro 5.x, @vite-pwa/astro with Workbox) provides all necessary infrastructure. Implementation uses native HTML/CSS/JS patterns.

## Current External Dependencies Analysis

| Service | Location | Block Risk | Current Impact |
|---------|----------|------------|----------------|
| Gravatar | `src/pages/index.astro:33` | HIGH (privacy extensions, corporate firewalls) | Broken image icon in hero |
| Vercel Analytics | `src/components/Analytics.astro` | HIGH (ad blockers, Brave) | Console errors |
| Vercel Speed Insights | `src/components/Analytics.astro` | HIGH (same as above) | Console errors |

## Stack Assessment: No Additions Needed

### Existing Infrastructure (Already Sufficient)

| Tool | Version | Fallback Use Case |
|------|---------|-------------------|
| Astro 5.x | ^5.16.6 | Native `<img>` with `onerror` attribute |
| @vite-pwa/astro | ^1.2.0 | Workbox runtime caching for external images |
| Tailwind CSS 4 | ^4.1.18 | CSS pseudo-element fallback styling |
| TypeScript | ^5.9.3 | Type-safe error handling |

**Rationale:** Adding dependencies to solve an external dependency problem creates circular complexity. Native browser APIs (`onerror`, CSS layering, service worker caching) handle all fallback scenarios.

## Recommended Implementation Patterns

### Pattern 1: Image Fallback with `onerror`

**For:** Gravatar avatar on homepage

**Current code (broken when blocked):**
```astro
<img
  src="https://gravatar.com/avatar/ef133a0cc6308305d254916b70332b1a?s=400&d=identicon"
  alt={SITE.author}
  class="w-40 h-40 rounded-full object-cover..."
/>
```

**Recommended pattern:**
```astro
<img
  src="https://gravatar.com/avatar/ef133a0cc6308305d254916b70332b1a?s=400&d=identicon"
  alt={SITE.author}
  class="w-40 h-40 rounded-full object-cover..."
  onerror="this.onerror=null; this.src='/avatar-fallback.png';"
/>
```

**Why this pattern:**
- Native HTML attribute - zero JavaScript framework overhead
- `this.onerror=null` prevents infinite loop if fallback also fails
- Build-time static asset guarantees fallback availability
- Zero runtime cost when image loads successfully

**Confidence:** HIGH - Verified via [MDN onerror documentation](https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/onerror) and [30 Seconds of Code CSS fallback](https://www.30secondsofcode.org/css/s/broken-image-fallback/)

### Pattern 2: Analytics Error Suppression

**For:** Vercel Analytics in `src/components/Analytics.astro`

**Current code (console errors when blocked):**
```astro
<script>
  if (typeof window !== 'undefined' && import.meta.env.PROD) {
    import('@vercel/analytics').then(({ inject }) => {
      inject();
    });
  }
</script>
```

**Recommended pattern:**
```astro
<script>
  if (typeof window !== 'undefined' && import.meta.env.PROD) {
    import('@vercel/analytics')
      .then(({ inject }) => inject())
      .catch(() => {
        // Silent fail - analytics is non-critical
      });
  }
</script>
```

**Why this pattern:**
- Dynamic import already non-blocking (existing code is good)
- Adding `.catch()` prevents uncaught promise rejection console noise
- Silent failure is correct behavior - user experience unaffected
- No user-visible errors

**Confidence:** HIGH - Standard promise error handling

### Pattern 3: Service Worker External Image Caching

**For:** Caching Gravatar via existing Workbox config in `astro.config.mjs`

**Current config:**
```javascript
workbox: {
  runtimeCaching: [
    {
      urlPattern: /\.(?:png|jpg|jpeg|svg|gif|webp)$/,
      handler: "CacheFirst",
      options: { cacheName: "images-cache", /* ... */ },
    },
  ],
}
```

**Recommended addition:**
```javascript
{
  urlPattern: /^https:\/\/gravatar\.com\/.*/i,
  handler: "StaleWhileRevalidate",
  options: {
    cacheName: "avatar-cache",
    expiration: {
      maxEntries: 10,
      maxAgeSeconds: 60 * 60 * 24 * 7, // 7 days
    },
    cacheableResponse: {
      statuses: [0, 200],
    },
  },
},
```

**Why this pattern:**
- Once loaded, Gravatar cached for offline/blocked scenarios
- `statuses: [0, 200]` handles opaque responses from CORS
- `StaleWhileRevalidate` shows cached immediately, updates in background
- Complements `onerror` fallback - SW tries cache first

**Confidence:** HIGH - Verified via [Workbox caching strategies](https://developer.chrome.com/docs/workbox/caching-strategies-overview/) and [Workbox fallback documentation](https://developer.chrome.com/docs/workbox/managing-fallback-responses)

## What NOT to Add (and Why)

### Do NOT Add: Image CDN or Proxy Service

**Temptation:** Use Cloudflare Images, imgix, or similar to proxy Gravatar
**Why avoid:**
- Adds external dependency to solve external dependency problem
- Monthly cost for single avatar image
- Local fallback is simpler, cheaper, and more reliable

### Do NOT Add: React Error Boundary

**Temptation:** Wrap images in React error boundaries
**Why avoid:**
- Site uses minimal React (islands architecture)
- Native HTML `onerror` is simpler and lighter
- No hydration needed for static image fallback
- Error boundaries require JavaScript execution

### Do NOT Add: Analytics Proxy/Rewrite

**Temptation:** Proxy Vercel Analytics through own domain to avoid blockers
**Why avoid:**
- Vercel explicitly states rewrites are "not recommended" ([Issue #137](https://github.com/vercel/analytics/issues/137))
- Violates user's explicit ad blocker intent
- Analytics loss is acceptable for personal blog
- Ethical consideration: respect user privacy choices

### Do NOT Add: Third-Party Image Component (@unpic/astro)

**Temptation:** Use specialized image component with built-in fallbacks
**Why avoid:**
- Single external image doesn't justify abstraction
- Native `onerror` is browser-native, zero-cost
- Adds bundle size for minimal benefit

### Do NOT Add: Service Worker Fallback Handler Override

**Temptation:** Custom service worker with complex fallback logic
**Why avoid:**
- Existing `generateSW` strategy is sufficient
- `runtimeCaching` configuration handles all cases
- Custom SW adds maintenance burden

## Asset Requirements

### Local Fallback Image

**Create:** `/public/avatar-fallback.png`

| Requirement | Value |
|-------------|-------|
| Size | 400x400px (matches Gravatar request) |
| Content | Initials "JC" or silhouette |
| Format | PNG (universal support) or WebP |
| File size | Under 10KB (critical path asset) |

**Generation options:**
1. Export from design tool (Figma, etc.)
2. Resize/crop existing `icon-512.png`
3. Generate with Satori (already in project for OG images)

## Files to Modify

| File | Change | Effort |
|------|--------|--------|
| `src/pages/index.astro` | Add `onerror` to Gravatar img | 5 min |
| `src/components/Analytics.astro` | Add `.catch()` to imports | 5 min |
| `astro.config.mjs` | Add Gravatar to Workbox runtimeCaching | 10 min |
| `public/avatar-fallback.png` | Create fallback image | 15 min |

## Files to NOT Create

- No new components (onerror is sufficient)
- No new utilities
- No new dependencies
- No service worker customization (use existing generateSW)

## Astro 5.x Compatibility Notes

All patterns verified compatible with Astro 5.x:

| Pattern | Astro 5 Status | Notes |
|---------|----------------|-------|
| Native `onerror` attribute | Compatible | Standard HTML, no framework involvement |
| Dynamic import `.catch()` | Compatible | Standard ES modules |
| @vite-pwa/astro workbox config | Compatible | v1.2.0 supports Astro 5 |
| Static asset in `/public` | Compatible | Standard Astro public folder |

## Integration with Existing PWA

The site already has `@vite-pwa/astro` configured:

```javascript
// Current astro.config.mjs
AstroPWA({
  registerType: "autoUpdate",
  workbox: {
    navigateFallback: "/404",
    runtimeCaching: [/* existing */],
  },
})
```

**Extension is additive:** Add Gravatar caching rule to existing `runtimeCaching` array. No architectural changes needed.

## Testing Strategy

### Manual Testing

```bash
# 1. Block Gravatar in DevTools
# Chrome: Network tab → Right-click request → "Block request URL"
# Verify: Local fallback displays, no broken image

# 2. Block Vercel Analytics
# Enable ad blocker or use DevTools
# Verify: No console errors, page loads normally

# 3. Test offline mode
# Load page, then DevTools → Network → Offline
# Verify: Cached Gravatar displays (if previously loaded)
```

### Automated Testing (Optional)

```javascript
// Playwright test example
test('fallback image when gravatar blocked', async ({ page }) => {
  await page.route('**/gravatar.com/**', route => route.abort());
  await page.goto('/');
  const avatar = page.locator('img[alt="Justin Carlson"]');
  await expect(avatar).toHaveAttribute('src', '/avatar-fallback.png');
});
```

## Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| Image onerror fallback | HIGH | Native HTML, extensively documented, universal support |
| Analytics catch handler | HIGH | Standard JavaScript promise handling |
| Workbox external image caching | HIGH | Documented pattern, existing infrastructure |
| Astro 5.x compatibility | HIGH | Patterns are framework-agnostic HTML/JS |

## Summary Recommendation

**Minimal viable solution (recommended):**
1. Add `onerror` to Gravatar image (5 min)
2. Add `.catch()` to analytics imports (5 min)
3. Create local fallback image (15 min)

**Full solution:**
- Above, plus Workbox caching for Gravatar (10 min)
- Enables cached avatar to work offline after first load

**Total implementation time:** 30-45 minutes

## Sources

### Authoritative (HIGH confidence)
- [Astro Images Documentation](https://docs.astro.build/en/guides/images/)
- [Workbox Caching Strategies](https://developer.chrome.com/docs/workbox/caching-strategies-overview/)
- [Workbox Managing Fallback Responses](https://developer.chrome.com/docs/workbox/managing-fallback-responses)
- [Vite PWA Astro Documentation](https://vite-pwa-org.netlify.app/frameworks/astro)

### Community/Tutorials (MEDIUM confidence)
- [30 Seconds of Code: CSS Broken Image Fallback](https://www.30secondsofcode.org/css/s/broken-image-fallback/)
- [DEV.to: HTML Fallback Images on Error](https://dev.to/dailydevtips1/html-fallback-images-on-error-1aka)

### Issue Discussions (Context)
- [Vercel Analytics Blocked by Ad Blockers #137](https://github.com/vercel/analytics/issues/137)
