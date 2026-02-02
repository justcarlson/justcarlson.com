# Domain Pitfalls: Graceful Fallback for Blocked External Services

**Domain:** Static site graceful degradation for blocked external services
**Researched:** 2026-02-02
**Context:** Adding fallbacks to existing Astro blog with Gravatar, Vercel Analytics, and PWA

---

## Critical Pitfalls

Mistakes that cause user-visible breakage or significant regressions.

### Pitfall 1: Image onerror Infinite Loop

**What goes wrong:** When implementing `onerror` fallback for images (like Gravatar), if the fallback image also fails to load, the onerror handler fires again, creating an infinite loop that crashes the browser tab or causes 100% CPU usage.

**Why it happens:** Developers set `this.src = fallbackImage` without clearing the error handler first. If the fallback is also unreachable (wrong path, also blocked, or missing), the browser keeps retrying.

**Consequences:**
- Browser tab freezes or crashes
- Users see nothing instead of graceful fallback
- Poor UX specifically for the users you're trying to help (those with blocked services)

**Warning signs:**
- Fallback image is also an external URL
- No `onerror=null` in the handler
- Fallback path uses relative URL that might resolve differently

**Prevention:**
```html
<!-- Always null the handler before changing src -->
<img
  src="https://gravatar.com/avatar/..."
  onerror="this.onerror=null; this.src='/fallback-avatar.png';"
/>
```

**Detection:** Test with network blocking enabled in DevTools. Block both primary and fallback URLs to verify no loop.

**Phase to address:** Initial implementation phase. This is Day 1 code, not an afterthought.

**Sources:**
- [HTML fallback images on error - DEV Community](https://dev.to/dailydevtips1/html-fallback-images-on-error-1aka)
- [Mozilla Bug 494377 - infinite loop when changing image src in onerror](https://bugzilla.mozilla.org/show_bug.cgi?id=494377)

---

### Pitfall 2: Gravatar d= Fallback Not Publicly Accessible

**What goes wrong:** When using Gravatar's `d=` (default) parameter for server-side fallback, the fallback URL must be publicly accessible. Local development images, staging-only assets, or authenticated URLs silently fail.

**Why it happens:** Gravatar's `d=` parameter tells Gravatar's servers to fetch and serve your fallback. If Gravatar can't reach it (private network, localhost, auth-required), you get no fallback.

**Consequences:**
- Works in development, breaks in production (or vice versa)
- Shows Gravatar's default (mystery person or identicon) instead of your custom fallback
- Inconsistent avatar display across environments

**Warning signs:**
- Using `d=` parameter with a localhost URL
- Fallback URL requires authentication
- Different behavior between dev and prod environments

**Prevention:**
1. Use Gravatar's built-in fallbacks (`identicon`, `mp`, `retro`, `wavatar`) for simple cases
2. For custom fallback: use `d=404` and handle with client-side `onerror`
3. Never use `d=` with non-public URLs

**Current implementation uses:** `d=identicon` (safe - Gravatar's built-in geometric pattern)

**Detection:** Test Gravatar URL directly in browser: `https://gravatar.com/avatar/invalid-hash?d=YOUR_FALLBACK_URL`

**Phase to address:** Research/design phase - decide strategy before implementation.

**Sources:**
- [Gravatar API - Default Images](https://docs.gravatar.com/sdk/images/)
- [BuddyPress Trac #4571 - Gravatar API fallback failures](https://buddypress.trac.wordpress.org/ticket/4571)

---

### Pitfall 3: Analytics Rewrites Breaking or Not Working

**What goes wrong:** Developers implement Vercel Analytics rewrites to bypass ad blockers, but the rewrite path conflicts with existing routes, doesn't work with the analytics library configuration, or breaks after a Vercel deployment update.

**Why it happens:**
- `@vercel/analytics` npm package doesn't expose configuration for custom script URLs
- Rewrite paths might match existing content paths
- Using recognizable names like "analytics" triggers ad blockers anyway

**Consequences:**
- Analytics silently stop working (no errors, just no data)
- False confidence that tracking is working
- Weeks of missing analytics data discovered too late
- ~30-40% of traffic blocked by privacy tools never tracked

**Warning signs:**
- Using `@vercel/analytics` npm package (doesn't support custom paths easily)
- Rewrite path uses recognizable words like "analytics", "tracking", "metrics"
- No verification that analytics actually loads post-deployment

**Prevention:**
1. **Accept graceful degradation:** Analytics blocked = silent failure (current approach)
2. **Or use HTML method:** Replace npm package with manual script injection to control paths
3. Choose obscure, non-content paths if rewriting (e.g., `/mt-demo` not `/analytics`)
4. Verify in production with Brave browser + uBlock Origin after each deploy
5. Set up monitoring for analytics data flow

**Your implementation:** Currently uses `@vercel/analytics` npm package with dynamic import. This already handles blocking gracefully (try-catch wrapping). If bypassing blockers becomes a goal, requires switching to HTML injection method.

**Detection:** Open deployed site in Brave with Shields up, check Network tab for blocked requests.

**Phase to address:** If bypassing blockers is a goal, address in analytics phase. If silent degradation is acceptable (recommended), document the expected data loss (~20-40%).

**Sources:**
- [Vercel Analytics being blocked by AdBlockers - GitHub Issue #137](https://github.com/vercel/analytics/issues/137)
- [Bypass ad blockers for Vercel Analytics in Next.js](https://stepanpavlov.com/writing/bypass-vercel-analytics-block-nextjs)
- [Solving Vercel Analytics Blocked by AdBlock Issue](https://kai.bi/post/vercel-kill-adblock)

---

### Pitfall 4: SSG Build vs Runtime Detection Mismatch

**What goes wrong:** Fallback logic assumes it runs at request time, but Astro SSG renders at build time. The build environment has full network access, so no fallback is triggered during build, but the static HTML has no runtime fallback mechanism.

**Why it happens:** Developers write fallback logic thinking it executes when users visit. In SSG, it executed once during `npm run build` on a server with no firewall restrictions.

**Consequences:**
- Fallback code never runs in production
- External resources appear to work (they did, at build time)
- Users on restricted networks see broken images/content

**Warning signs:**
- Fallback logic in Astro component script (frontmatter section - runs at build)
- No client-side `<script>` or `onerror` attributes
- Testing only with `npm run dev` (similar environment to build)

**Prevention:**
1. Image fallbacks MUST use client-side mechanisms (`onerror`, JavaScript)
2. Analytics fallbacks must be in client-side script (your `Analytics.astro` does this correctly)
3. Test the built site, not dev server, with network restrictions
4. Anything that needs to react to blocked services MUST be client-side JavaScript

**Your implementation status:**
- Gravatar: Uses inline URL (build-time resolved) - **needs client-side onerror**
- Analytics: Uses client-side dynamic import (correct approach)
- GitHub Chart: Uses inline URL - **needs client-side onerror**

**Detection:** Build the site, serve static files, then test with network blocking.

**Phase to address:** Core implementation phase - fundamental architecture decision.

**Sources:**
- [Astro On-demand Rendering](https://docs.astro.build/en/guides/on-demand-rendering/)
- [Astro Images Guide](https://docs.astro.build/en/guides/images/)

---

## Moderate Pitfalls

Mistakes that cause inconsistent behavior or technical debt.

### Pitfall 5: Service Worker Caching Stale Fallback

**What goes wrong:** PWA service worker caches the fallback image/response, but when the external service becomes available again, users continue seeing the cached fallback indefinitely.

**Why it happens:** CacheFirst strategy serves cached content without checking network. Fallback gets cached as the "normal" response.

**Consequences:**
- Users with service worker see perpetual fallback even when service is available
- Different users see different content based on their cache state
- Hard to debug - works for some users, not others

**Warning signs:**
- Using CacheFirst for external service URLs
- No cache invalidation strategy for fallback vs real content
- Long maxAgeSeconds for image caches (your config: 30 days)

**Prevention:**
1. Use NetworkFirst or StaleWhileRevalidate for external resources
2. Don't cache the fallback with the same cache key as the original
3. Implement version-based cache invalidation
4. Exclude external domains from aggressive caching

**Your current config:**
```javascript
// astro.config.mjs - images use CacheFirst with 30-day max age
urlPattern: /\.(?:png|jpg|jpeg|svg|gif|webp)$/,
handler: "CacheFirst",
options: {
  cacheName: "images-cache",
  expiration: { maxAgeSeconds: 60 * 60 * 24 * 30 }
}
```

This pattern matches local AND external images. External images from `gravatar.com` could be cached for 30 days, including fallback states.

**Detection:** Test by blocking external service, loading site, unblocking service, and verifying cache updates.

**Phase to address:** PWA/Service Worker configuration phase.

**Sources:**
- [Service Worker Caching: 5 Offline Fallback Strategies](https://www.zeepalm.com/blog/service-worker-caching-5-offline-fallback-strategies)
- [Service Worker Development Best Practices](https://love2dev.com/serviceworker/development-best-practices/)

---

### Pitfall 6: CSP Blocking Fallback Resources

**What goes wrong:** Content Security Policy blocks the fallback resource because it's from a different origin than what was whitelisted for the primary resource.

**Why it happens:** CSP img-src might allow `gravatar.com` but not the fallback image if it's a data URI, blob, or different domain.

**Consequences:**
- Primary resource blocked: expected
- Fallback also blocked: unexpected
- Double failure with no visible content

**Warning signs:**
- Strict CSP with explicit domain lists
- Using data URIs for fallback (`data:image/...`)
- Different hosting for fallback assets

**Prevention:**
1. Audit CSP rules for fallback resources before implementation
2. Use local fallback images (same-origin) when possible
3. If using data URIs, ensure `data:` is in img-src
4. Test with CSP Report-Only mode first

**Your current state:** No explicit CSP headers found in config (Vercel may add defaults). When adding CSP, remember to include fallback origins.

**Detection:** Browser console shows "Refused to load the image because it violates Content Security Policy directive"

**Phase to address:** Security hardening phase, or address when CSP is introduced.

**Sources:**
- [CSP img-src Explained](https://content-security-policy.com/img-src/)
- [Content Security Policy - MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP)

---

### Pitfall 7: Hydration Mismatch with Fallback State

**What goes wrong:** If using React/interactive islands with fallback logic, the server-rendered HTML differs from client-rendered state, causing hydration errors or visual flicker.

**Why it happens:** Server renders with external URL (assumes success), client detects failure and swaps to fallback. HTML mismatch triggers React hydration warning.

**Consequences:**
- Console warnings about hydration mismatch
- Visual flicker as content re-renders
- Poor Core Web Vitals (CLS issues)

**Warning signs:**
- Using React/interactive components for images with fallback
- Fallback logic in component render path
- SSR/SSG rendering different content than client

**Prevention:**
1. Use pure HTML `onerror` for image fallbacks (no React needed)
2. If using React, use `suppressHydrationWarning` on fallback elements
3. Or use `useEffect` to handle fallback client-side only
4. Astro islands: prefer static HTML approach for simple fallbacks

**Your implementation:** Current avatar uses plain `<img>` tag (not React), so no hydration concerns. Keep it this way.

**Detection:** React DevTools console warnings about hydration.

**Phase to address:** Only relevant if introducing React components for images.

**Sources:**
- [Next.js Hydration Error Docs](https://nextjs.org/docs/messages/react-hydration-error)
- [Vue.js SSR Hydration](https://vuejs.org/guide/scaling-up/ssr.html)

---

### Pitfall 8: Silent Analytics Data Loss Not Quantified

**What goes wrong:** Analytics are blocked for 30-40% of users, but this loss is never quantified or reported. Business decisions are made on partial data without awareness.

**Why it happens:** Analytics failures are silent by design (graceful degradation). No monitoring of the "untracked" segment.

**Consequences:**
- Decisions based on 60-70% of actual traffic
- Privacy-conscious users systematically underrepresented
- True conversion rates unknown
- Campaign optimization on incomplete data

**Warning signs:**
- No comparison between analytics data and server logs
- No monitoring of analytics script load failures
- Assuming analytics data represents 100% of traffic

**Prevention:**
1. **Document expected data loss:** "Analytics capture ~60-70% of traffic due to ad blockers"
2. **Compare with server-side metrics:** Vercel edge logs show all requests
3. **Periodically audit:** Check analytics vs server logs monthly
4. **Accept or address:** Either accept the gap or invest in server-side tracking

**Your recommendation:** Document the expected gap. For a personal blog, accepting ~30% untracked traffic is reasonable. For e-commerce, it would be critical.

**Detection:** Compare Vercel Analytics pageviews with Vercel edge logs (available in dashboard).

**Phase to address:** Documentation/monitoring phase.

**Sources:**
- [How much data is missing from your Google Analytics dashboard?](https://towardsdatascience.com/how-much-data-is-missing-from-your-google-analytics-dashboard-20506b26e6d/)
- [SiteCatalyst Alerts for Data Quality](https://analyticsdemystified.com/adobe-analytics/data-quality-the-silent-killer/)

---

## Minor Pitfalls

Mistakes that cause annoyance but are quickly fixable.

### Pitfall 9: Visible Flash During Fallback Load

**What goes wrong:** User briefly sees broken image icon or empty space before fallback loads, creating a jarring visual experience.

**Why it happens:** onerror fires after browser determines image failed, then fallback loads. Network latency creates visible gap.

**Consequences:**
- Unprofessional appearance during fallback
- Layout shift when images resize (CLS penalty)
- Users notice the degradation explicitly

**Prevention:**
1. Use CSS to hide images until load confirmed
2. Pre-define fallback dimensions matching primary
3. Use CSS `background-image` with fallback in same declaration
4. Consider placeholder/skeleton states

```css
/* Hide image until loaded or errored */
img[data-fallback] {
  opacity: 0;
  transition: opacity 0.2s;
}
img[data-fallback].loaded,
img[data-fallback].fallback {
  opacity: 1;
}
```

```html
<img
  data-fallback
  src="external.jpg"
  onload="this.classList.add('loaded')"
  onerror="this.onerror=null; this.src='/local.png'; this.classList.add('fallback')"
/>
```

**Detection:** Throttle network in DevTools, block external resource, observe loading behavior.

**Phase to address:** Polish/UX phase after core functionality works.

---

### Pitfall 10: Hardcoded Fallback Paths

**What goes wrong:** Fallback paths are hardcoded in multiple places. When structure changes, some references break while others work.

**Why it happens:** Copy-paste implementation without centralized configuration.

**Consequences:**
- Inconsistent fallback images across components
- Broken fallbacks in some views but not others
- Maintenance burden when changing fallback assets

**Prevention:**
1. Define fallback paths in central config (e.g., `src/config.ts`)
2. Use TypeScript to ensure fallback references are valid
3. Include fallback assets in build validation

```typescript
// src/config.ts
export const FALLBACKS = {
  avatar: '/images/default-avatar.png',
  postImage: '/images/default-post.png',
  chart: '/images/chart-placeholder.svg',
} as const;
```

**Detection:** Grep codebase for fallback image paths, verify consistency.

**Phase to address:** Initial implementation phase - set up config first.

---

### Pitfall 11: No Timeout for Slow External Services

**What goes wrong:** External service responds slowly instead of failing outright. Browser waits indefinitely, no error fires, no fallback loads.

**Why it happens:** onerror only fires on failure, not on "taking too long". A 30-second timeout on Gravatar looks like a broken page.

**Consequences:**
- Users stare at loading spinner
- No fallback despite poor experience
- Timeout not equal to failure in JavaScript

**Warning signs:**
- Only onerror handling, no timeout logic
- External services known for variable latency
- No loading states for external resources

**Prevention:**
```javascript
// Set timeout for external images
const img = document.querySelector('[data-external-src]');
const timeout = setTimeout(() => {
  img.onerror = null;
  img.src = '/fallback.png';
  img.classList.add('fallback');
}, 5000); // 5 second timeout

img.onload = () => clearTimeout(timeout);
img.onerror = () => {
  clearTimeout(timeout);
  img.onerror = null;
  img.src = '/fallback.png';
  img.classList.add('fallback');
};
```

**Detection:** Use DevTools network throttling to simulate slow (not blocked) connections.

**Phase to address:** Enhancement phase after basic fallback works.

**Sources:**
- [Best Way to Set Up Local Fallback Images for External Content in JavaScript](https://www.javaspring.net/blog/fallback-image-and-timeout-external-content-javascript/)

---

### Pitfall 12: Fallback Assets Not in Build/Deploy

**What goes wrong:** Fallback images exist in development but aren't included in production build, causing 404s when fallback is triggered.

**Why it happens:**
- Fallback assets in wrong directory (not copied to dist/)
- Gitignored accidentally
- Build process excludes certain file types

**Consequences:**
- Fallback works in dev, fails in production
- Users see 404 instead of fallback image
- Double failure: external service blocked AND fallback missing

**Prevention:**
1. Put fallback assets in `public/` directory (always copied)
2. Add build validation that checks fallback assets exist
3. Test production build with blocked external services
4. Include fallback asset verification in CI

**Detection:** Run `npm run build`, then serve from `dist/` and verify fallback assets load.

**Phase to address:** Implementation phase - verify assets exist before deploying fallback code.

---

## Phase-Specific Warnings

| Phase/Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Gravatar fallback | Infinite loop (#1), no client-side handling (#4) | Use `onerror=null` pattern, test with blocked network |
| Vercel Analytics | Silent data loss (#8), ~30% blocked traffic | Accept loss and document, or switch to HTML injection |
| Service Worker | Stale cache serving fallback (#5) | Review cache strategies for external URLs, consider NetworkFirst |
| Local avatar storage | Path hardcoding (#10), missing assets (#12) | Central config, build validation |
| UX polish | Flash of broken content (#9), slow load timeout (#11) | CSS transitions, timeout handlers |
| CSP addition | Fallback blocked (#6) | Include fallback origins in CSP rules |
| React components | Hydration mismatch (#7) | Use plain HTML onerror, not React state |

---

## Integration Considerations for Existing System

Your site already has:
- **PWA with service worker** - Cache strategies need review for fallback compatibility
- **Vercel Analytics via npm** - Already handles blocking gracefully via dynamic import
- **Gravatar with identicon fallback** - Server-side fallback works, but client-side handling needed for blocked Gravatar entirely
- **GitHub contribution chart** - External image needing fallback

**Current graceful degradation status:**

| Service | Current Behavior | Needed |
|---------|-----------------|--------|
| Gravatar | Shows broken image if entirely blocked | Add client-side onerror |
| Vercel Analytics | Silent failure (good) | Document expected data loss |
| GitHub Chart | Shows broken image | Add client-side onerror |

**Recommended implementation order:**
1. Local fallback assets first (images in public/)
2. Gravatar client-side onerror handling
3. GitHub chart client-side onerror handling
4. Service worker cache strategy review for external images
5. Analytics data loss documentation
6. Timeout handling for slow loads (enhancement)

---

## Testing Checklist

Before declaring graceful fallback complete:

### Fallback Functionality
- [ ] Block Gravatar in DevTools Network tab - local fallback appears
- [ ] Block Vercel Analytics - page loads normally, no console errors
- [ ] Block GitHub Chart - local fallback appears
- [ ] Test in Brave browser with Shields enabled
- [ ] Test with uBlock Origin enabled
- [ ] Test on corporate VPN/firewall (if accessible)

### No Regressions
- [ ] Normal operation still works (nothing blocked)
- [ ] Fallback doesn't trigger when services are available
- [ ] No infinite loops (block both primary and fallback)
- [ ] No layout shift during fallback transition
- [ ] Service worker doesn't cache fallback as permanent

### Build/Deploy
- [ ] Fallback assets included in production build
- [ ] Fallback works on Vercel deployment, not just local
- [ ] No new CSP violations in console

---

## Sources Summary

**HIGH Confidence (Official Documentation):**
- [Astro Images Guide](https://docs.astro.build/en/guides/images/)
- [Gravatar API Documentation](https://docs.gravatar.com/sdk/images/)
- [MDN Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP)
- [Vercel Analytics Troubleshooting](https://vercel.com/docs/analytics/troubleshooting)

**MEDIUM Confidence (Verified Community Sources):**
- [Service Worker Caching Strategies](https://www.zeepalm.com/blog/service-worker-caching-5-offline-fallback-strategies)
- [Vercel Analytics Ad Blocker Issue #137](https://github.com/vercel/analytics/issues/137)
- [Graceful Degradation Guide - LogRocket](https://blog.logrocket.com/guide-graceful-degradation-web-development/)
- [HTML fallback images on error - DEV Community](https://dev.to/dailydevtips1/html-fallback-images-on-error-1aka)
- [Graceful Degradation in UX - Medium](https://medium.com/design-bootcamp/graceful-degradation-in-ux-9dde610d58ff)
- [AWS Graceful Degradation Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_graceful_degradation.html)

**LOW Confidence (Single Source/Blog):**
- Various blog posts on specific implementation patterns (use as starting points, verify with testing)

---

*Research completed: 2026-02-02*
*Confidence: HIGH for critical pitfalls (verified against official docs and codebase)*
