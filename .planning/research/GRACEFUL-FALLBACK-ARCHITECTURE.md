# Architecture: Graceful Fallback for Blocked External Services

**Domain:** Astro static site graceful degradation
**Researched:** 2026-02-02
**Confidence:** HIGH (established patterns, verified against codebase)

## Executive Summary

The justcarlson.com Astro site has three external dependencies that may be blocked by privacy tools, ad blockers, or network restrictions:

1. **Gravatar avatar** (gravatar.com) - User profile image on homepage
2. **Vercel Analytics** (@vercel/analytics) - Page view tracking
3. **GitHub contribution chart** (ghchart.rshah.org) - About page visualization

The recommended architecture uses **progressive enhancement with local fallbacks** - the site works completely without external services, and external content enhances when available. This aligns with Astro's static-first philosophy and the existing PWA infrastructure.

## Current State Analysis

### External Dependencies Inventory

| Service | Location | Current Behavior When Blocked | Impact |
|---------|----------|------------------------------|--------|
| Gravatar | `src/pages/index.astro:33` | Broken image icon | HIGH - Hero section looks broken |
| Vercel Analytics | `src/components/Analytics.astro` | Silent failure (dynamic import) | LOW - No visible impact |
| Vercel Speed Insights | `src/components/Analytics.astro` | Silent failure (dynamic import) | LOW - No visible impact |
| GitHub Chart | `src/pages/about.mdx:35` | Broken image | MEDIUM - About page incomplete |

### Existing Infrastructure

**PWA Service Worker (AstroPWA/Workbox):**
- Already configured in `astro.config.mjs`
- Has runtime caching for Google Fonts and images
- Uses CacheFirst strategy for images
- Configured `navigateFallback: "/404"` for navigation

**Image Assets:**
- Local about photo exists: `src/assets/images/about-photo.jpg`
- Icon assets in `src/assets/icons/`
- PWA icons in `public/` (icon-192.png, icon-512.png)

## Recommended Architecture

### Design Principle: Progressive Enhancement

```
┌─────────────────────────────────────────────────────────┐
│                    User Experience                       │
├─────────────────────────────────────────────────────────┤
│  Layer 3: External Services (Gravatar, Analytics)       │
│           → Enhances when available                      │
├─────────────────────────────────────────────────────────┤
│  Layer 2: Service Worker Cache                           │
│           → Serves cached external content offline       │
├─────────────────────────────────────────────────────────┤
│  Layer 1: Local Static Content (Base)                    │
│           → Always works, no network required            │
└─────────────────────────────────────────────────────────┘
```

### Component Boundaries

| Component | Responsibility | Location |
|-----------|---------------|----------|
| `FallbackImage.astro` | Image with local fallback via onerror | `src/components/` |
| `Avatar.astro` | Gravatar with local photo fallback | `src/components/` |
| `Analytics.astro` | Analytics with graceful failure | `src/components/` (existing) |
| Service Worker | Cache external images, serve fallback | `astro.config.mjs` (Workbox) |

## Integration Points

### 1. Gravatar Avatar (Homepage + Sidebar)

**Current implementation:**
```astro
<!-- src/pages/index.astro:31-37 -->
<img
  src="https://gravatar.com/avatar/ef133a0cc6308305d254916b70332b1a?s=400&d=identicon"
  alt={SITE.author}
  class="w-40 h-40 rounded-full..."
/>
```

**Recommended pattern:**
```astro
<!-- src/components/Avatar.astro -->
---
import { Image } from 'astro:assets';
import fallbackPhoto from '@/assets/images/about-photo.jpg';

interface Props {
  email?: string;
  size?: number;
  class?: string;
}

const { email, size = 400, class: className } = Astro.props;

// Hash is pre-computed at build time (MD5 of email)
const gravatarUrl = `https://gravatar.com/avatar/ef133a0cc6308305d254916b70332b1a?s=${size}&d=blank`;
---

<div class:list={["avatar-container relative", className]}>
  <!-- Local fallback renders underneath -->
  <Image
    src={fallbackPhoto}
    alt="Profile photo"
    width={size}
    height={size}
    class="absolute inset-0 w-full h-full object-cover rounded-full"
  />
  <!-- Gravatar overlays when loaded -->
  <img
    src={gravatarUrl}
    alt=""
    class="relative w-full h-full object-cover rounded-full"
    loading="lazy"
    onerror="this.style.display='none'"
  />
</div>
```

**Key decisions:**
- Use Gravatar's `d=blank` parameter for transparent fallback
- Layer local image underneath Gravatar
- `onerror` hides failed Gravatar, revealing local fallback
- Build-time image optimization for local fallback via `astro:assets`

### 2. Vercel Analytics (Global)

**Current implementation:**
```astro
<!-- src/components/Analytics.astro -->
<script>
  if (typeof window !== 'undefined' && import.meta.env.PROD) {
    import('@vercel/analytics').then(({ inject }) => {
      inject();
    });
  }
</script>
```

**Already graceful:** The dynamic import pattern already handles blocking gracefully:
- `import()` returns a rejected promise when blocked
- No `.catch()` needed - unhandled rejection in prod is silent
- No visible UI impact

**Optional enhancement (proxy pattern):**
If analytics data completeness matters, implement URL rewriting:

```javascript
// vercel.json (if using Vercel rewrites)
{
  "rewrites": [
    {
      "source": "/data/insights/:path*",
      "destination": "/_vercel/insights/:path*"
    }
  ]
}
```

```astro
<!-- Analytics.astro with custom endpoint -->
<script data-endpoint="/data/insights">
  // Script modified to use data-endpoint
</script>
```

**Recommendation:** Keep current implementation. Analytics data loss from ad blockers is acceptable for a personal blog. The rewrite pattern adds complexity for minimal gain.

### 3. GitHub Contribution Chart (About Page)

**Current implementation:**
```astro
<!-- src/pages/about.mdx:34-41 -->
<img
  src="https://ghchart.rshah.org/justcarlson"
  alt="Just Carlson's GitHub Contribution Graph"
  class="w-full"
  loading="lazy"
/>
```

**Recommended pattern:**
```astro
<!-- Direct in about.mdx or via component -->
<div class="github-chart-container bg-secondary rounded-lg min-h-[100px] flex items-center justify-center">
  <img
    src="https://ghchart.rshah.org/justcarlson"
    alt="GitHub contribution graph"
    class="w-full"
    loading="lazy"
    onerror="this.parentElement.innerHTML='<p class=\"text-sm text-gray-500 p-4\">GitHub activity chart unavailable. <a href=\"https://github.com/justcarlson\" class=\"underline\">View on GitHub</a></p>'"
  />
</div>
```

**Key decisions:**
- Container with minimum height prevents layout shift
- `onerror` replaces image with text + link fallback
- Link to GitHub provides alternative access to the data
- No local image cache - chart data is time-sensitive

### 4. Service Worker Enhancements

**Current Workbox configuration:**
```javascript
// astro.config.mjs
workbox: {
  runtimeCaching: [
    {
      urlPattern: /^https:\/\/fonts\.googleapis\.com\/.*/i,
      handler: "CacheFirst",
      // ...
    },
    {
      urlPattern: /\.(?:png|jpg|jpeg|svg|gif|webp)$/,
      handler: "CacheFirst",
      // ...
    },
  ],
}
```

**Recommended additions:**
```javascript
workbox: {
  runtimeCaching: [
    // Existing Google Fonts config...

    // Cache Gravatar images
    {
      urlPattern: /^https:\/\/gravatar\.com\/.*/i,
      handler: "StaleWhileRevalidate",
      options: {
        cacheName: "gravatar-cache",
        expiration: {
          maxEntries: 10,
          maxAgeSeconds: 60 * 60 * 24 * 7, // 7 days
        },
        cacheableResponse: {
          statuses: [0, 200],
        },
      },
    },

    // Cache GitHub chart (short TTL - data changes)
    {
      urlPattern: /^https:\/\/ghchart\.rshah\.org\/.*/i,
      handler: "StaleWhileRevalidate",
      options: {
        cacheName: "github-chart-cache",
        expiration: {
          maxEntries: 5,
          maxAgeSeconds: 60 * 60 * 24, // 1 day
        },
        cacheableResponse: {
          statuses: [0, 200],
        },
      },
    },

    // Existing image caching...
  ],
}
```

**Key decisions:**
- `StaleWhileRevalidate` for external images: serve cached, update in background
- Separate cache names for debugging/management
- `statuses: [0, 200]` - cache opaque responses from CORS requests
- Shorter TTL for GitHub chart (data freshness matters)

## Build-Time vs Runtime Handling

| Dependency | Build-Time | Runtime | Rationale |
|------------|------------|---------|-----------|
| Gravatar | Hash computed | onerror fallback | Hash stable, availability varies |
| Analytics | Script bundled | Dynamic import | Module available, execution blocked |
| GitHub Chart | N/A | onerror fallback | Data too dynamic for build-time |
| Local images | Optimized | Served from cache | Best of both worlds |

**Astro's static generation means:**
- Build-time: Generate HTML with both external URL and fallback structure
- Runtime: Browser handles success/failure, no server logic needed
- Service worker: Caches successful fetches for offline/blocked scenarios

## Anti-Patterns to Avoid

### 1. Server-Side Fetching of External Images

**Do not:**
```astro
---
// DON'T: Fetch at build time
const gravatarResponse = await fetch('https://gravatar.com/...');
const avatarData = await gravatarResponse.arrayBuffer();
---
```

**Why not:**
- Build-time fetch can fail, breaking builds
- Stale data baked into static output
- Adds build complexity and time

### 2. Complex Error Boundaries for Static Content

**Do not:**
```jsx
// DON'T: React error boundary for images
<ErrorBoundary fallback={<FallbackImage />}>
  <img src={external} />
</ErrorBoundary>
```

**Why not:**
- Requires hydration for static content
- Adds JavaScript bundle size
- `onerror` attribute handles this natively

### 3. Blocking Analytics Scripts

**Do not:**
```html
<!-- DON'T: Inline blocking script -->
<script src="/_vercel/insights/script.js"></script>
```

**Why not:**
- Blocks rendering if script fails to load
- Current dynamic import is already correct

### 4. Over-Engineering Fallback Components

**Do not:**
- Create framework-specific (React/Vue) components for simple fallbacks
- Add state management for image loading
- Build complex retry logic

**Instead:**
- Use native HTML `onerror` attribute
- Use CSS to layer fallback content
- Keep fallback logic in Astro components (zero JS)

## Implementation Order

Based on user impact and dependencies:

### Phase 1: Avatar Fallback (Highest Impact)

**Files to modify:**
1. Create `src/components/Avatar.astro`
2. Update `src/pages/index.astro` to use Avatar component

**Why first:**
- Most visible broken state (hero section)
- Simple implementation (onerror + CSS layering)
- No service worker changes needed

### Phase 2: GitHub Chart Fallback

**Files to modify:**
1. Update `src/pages/about.mdx` with fallback container

**Why second:**
- Lower visibility than homepage
- Simple inline fix (no new component needed)
- Container already has `bg-secondary` class

### Phase 3: Service Worker Caching

**Files to modify:**
1. Update `astro.config.mjs` Workbox runtimeCaching

**Why third:**
- Enhances phases 1 and 2
- Provides offline support for cached external images
- Low risk (additive configuration)

### Phase 4: Analytics Proxy (Optional)

**Files to modify:**
1. Create `vercel.json` rewrites (if on Vercel)
2. Update `src/components/Analytics.astro` data-endpoint

**Why last (or skip):**
- Current implementation already graceful
- Complexity for marginal data gain
- Only matters if analytics completeness is priority

## Testing Strategy

### Manual Testing Checklist

1. **Block gravatar.com in browser DevTools → Network → Block request URL**
   - [ ] Homepage loads without broken image
   - [ ] Local fallback photo displays
   - [ ] No console errors

2. **Block ghchart.rshah.org**
   - [ ] About page loads
   - [ ] Fallback text with GitHub link displays
   - [ ] Layout doesn't shift

3. **Block Vercel Analytics (use ad blocker or DevTools)**
   - [ ] No visible page impact
   - [ ] No console errors (rejected promise is expected)

4. **Test service worker caching**
   - [ ] Load page with external services available
   - [ ] Go offline in DevTools
   - [ ] Cached external images still display

### Automated Testing

For CI, consider:
- Lighthouse accessibility audit (alt text present)
- Visual regression testing with external services mocked/blocked
- Build verification (no external fetch at build time)

## Confidence Assessment

| Area | Confidence | Rationale |
|------|------------|-----------|
| Avatar fallback pattern | HIGH | Standard onerror + CSS technique |
| Analytics graceful failure | HIGH | Current code already handles this |
| Service worker caching | HIGH | Well-documented Workbox patterns |
| GitHub chart fallback | MEDIUM | Inline HTML replacement less elegant |

## Sources

- [HTML fallback images on error - DEV Community](https://dev.to/dailydevtips1/html-fallback-images-on-error-1aka)
- [Gravatar Developer Documentation - Default Images](https://docs.gravatar.com/sdk/images/)
- [Vercel Analytics Blocked by AdBlockers - GitHub Issue](https://github.com/vercel/analytics/issues/137)
- [PWA, Service Workers & Astro](https://fcalo.com/blog/pwa-service-workers-astro/)
- [Astro Images Documentation](https://docs.astro.build/en/guides/images/)
- [Workbox Caching Strategies](https://www.educative.io/answers/5-service-worker-caching-strategies-for-your-next-pwa-app)
- [LogRocket - Guide to Graceful Degradation](https://blog.logrocket.com/guide-graceful-degradation-web-development/)

---

*Architecture research: 2026-02-02*
