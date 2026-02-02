# Research Summary: Graceful Fallback for Blocked Services

**Project:** justcarlson.com v0.5.0 Graceful Fallback
**Domain:** Static site graceful degradation for external service blocking
**Researched:** 2026-02-02
**Confidence:** HIGH

## Executive Summary

This milestone addresses graceful degradation when external services (Gravatar avatar, Vercel Analytics, GitHub contribution chart) are blocked by privacy tools, ad blockers, or network restrictions. Research confirms this is a solved problem using progressive enhancement patterns - the site should work completely without external services, with external content enhancing the experience when available.

The recommended approach requires no new dependencies. The existing Astro 5.x stack already provides all necessary infrastructure through native HTML/CSS patterns (onerror, CSS layering) and the existing @vite-pwa/astro service worker. Implementation is straightforward: add client-side onerror handlers to images, create local fallback assets, and optionally configure service worker caching for external images once loaded.

The key risk is infinite onerror loops if fallback images also fail to load. This is completely preventable by setting `this.onerror=null` before changing `src`. A secondary risk is Astro's static generation model - fallback logic must be client-side (onerror, JavaScript) not build-time (component frontmatter), as the build environment has full network access while end users may not.

## Key Findings

### Recommended Stack

**No new dependencies required.** The existing stack provides all necessary fallback infrastructure:

**Core technologies already in place:**
- **Astro 5.x (^5.16.6)** - Native HTML with onerror attributes, no framework overhead
- **@vite-pwa/astro (^1.2.0)** - Workbox runtime caching for external images after first successful load
- **Tailwind CSS 4 (^4.1.18)** - CSS pseudo-element fallback styling and layering
- **TypeScript (^5.9.3)** - Type-safe error handling if needed

Implementation uses three patterns:
1. **Image onerror attribute** - Native HTML fallback for Gravatar and GitHub chart
2. **Analytics catch handler** - Add `.catch()` to existing dynamic import (optional enhancement, current silent failure is already graceful)
3. **Service worker caching** - Add Gravatar/GitHub domains to existing Workbox runtimeCaching

**Confidence:** HIGH - Patterns verified via MDN, Chrome DevTools documentation, and Workbox official docs.

### Current State Analysis

External dependencies and their blocking impact:

| Service | Location | Current Behavior When Blocked | Impact |
|---------|----------|-------------------------------|--------|
| Gravatar | `src/pages/index.astro:33` | Broken image icon | HIGH - Hero section looks broken |
| Vercel Analytics | `src/components/Analytics.astro` | Silent failure (dynamic import) | LOW - No visible impact, already graceful |
| GitHub Chart | `src/pages/about.mdx:35` | Broken image | MEDIUM - About page incomplete |

**Local assets available:**
- `src/assets/images/about-photo.jpg` - Can serve as Gravatar fallback
- PWA icons in `public/` (icon-192.png, icon-512.png)
- Fonts already self-hosted in `/public/fonts/`

### Expected Features

**Must have (table stakes):**
- **No broken image icons** - Users expect professional appearance, broken images signal unmaintained site
- **Page loads without external dependencies** - Core content must work regardless of network restrictions
- **No console errors visible** - Silent degradation without spam
- **Consistent visual appearance** - Site should look complete even with degraded services
- **No layout shift** - CLS penalty hurts UX and SEO

**Should have (differentiators):**
- **Local avatar fallback** - Shows local photo when Gravatar blocked, completely offline-capable
- **Service worker caching** - Once external images load successfully, cache for offline/future blocks
- **Graceful chart degradation** - GitHub chart shows link fallback when blocked, not empty container

**Defer (v2+ / anti-features):**
- **Bypass ad blockers for analytics** - Disrespects user privacy choices, cat-and-mouse game with blockers
- **Multiple fallback chains** - Complexity for diminishing returns, one fallback is enough
- **Custom error boundaries** - React pattern overkill for static site, native HTML onerror is simpler
- **Server-side proxy** - Adds complexity, circumvents user intent

### Architecture Approach

**Design principle: Progressive enhancement with three layers**

1. **Layer 1 (Base):** Local static content always works, no network required
2. **Layer 2 (Cache):** Service worker serves cached external content when offline/blocked after first load
3. **Layer 3 (Enhancement):** External services enhance when available

**Major components:**
1. **Avatar with fallback** - Gravatar overlays local photo, onerror reveals fallback on failure
2. **GitHub chart with fallback** - Container with min-height prevents layout shift, onerror replaces with text link
3. **Analytics (already graceful)** - Current dynamic import handles blocking silently
4. **Service Worker extensions** - Add Gravatar and GitHub domains to Workbox runtimeCaching

**Key pattern:** Use Gravatar's `d=blank` parameter (transparent fallback) with local image layered underneath. When Gravatar fails, `onerror` hides it, revealing the local fallback without layout shift.

### Critical Pitfalls

1. **Infinite onerror loops** - If fallback image also fails, handler fires indefinitely, crashes browser. Prevention: Always set `this.onerror=null` before changing `src`. This is Day 1 code, not an afterthought.

2. **SSG build vs runtime detection mismatch** - Fallback logic in Astro component frontmatter runs at build time when network is available, not at user runtime. Prevention: Fallbacks MUST be client-side (onerror attribute, script tags) not build-time.

3. **Service worker caching stale fallback** - CacheFirst strategy can cache fallback state indefinitely, showing fallback even when service becomes available. Prevention: Use StaleWhileRevalidate for external images, separate cache names, shorter TTL.

4. **Fallback assets not in production build** - Fallback images exist in dev but aren't deployed. Prevention: Put assets in `public/` directory (always copied to dist/), test production build with blocked services.

5. **Analytics data loss not quantified** - 30-40% of users blocked by privacy tools, decisions made on partial data without awareness. Prevention: Document expected gap, compare analytics with server logs (Vercel edge logs show all requests).

## Implications for Roadmap

Based on research, suggested three-phase structure with progressive enhancement:

### Phase 1: Avatar Fallback (Gravatar)
**Rationale:** Most visible broken state (hero section on homepage). Simple implementation with highest user impact.

**Delivers:**
- Local fallback photo when Gravatar blocked
- No broken image icon on homepage
- Professional appearance regardless of network restrictions

**Implementation:**
- Add onerror handler to Gravatar img in `src/pages/index.astro`
- Create/copy fallback image to `public/images/avatar-fallback.png`
- Use CSS layering pattern or simple onerror src swap

**Addresses pitfalls:**
- Infinite loop prevention (onerror=null)
- Client-side handling (not build-time)
- Local asset in public/ directory

**Effort:** 30 minutes
**Risk:** LOW - well-documented pattern

### Phase 2: GitHub Chart Fallback
**Rationale:** Secondary visible breakage on About page. Similar pattern to Phase 1 but lower visibility.

**Delivers:**
- Text fallback with GitHub link when chart blocked
- Container with min-height prevents layout shift
- Consistent About page appearance

**Implementation:**
- Wrap GitHub chart img in container with min-height
- Add onerror handler that replaces with text + link
- Direct in `src/pages/about.mdx` (no component needed)

**Addresses pitfalls:**
- Layout shift prevention (fixed container height)
- Client-side handling

**Effort:** 15 minutes
**Risk:** LOW - same pattern as Phase 1

### Phase 3: Service Worker Caching (Optional Enhancement)
**Rationale:** Enhances Phases 1 and 2 by caching external images after first successful load. Enables offline/blocked scenarios to show cached content.

**Delivers:**
- Cached Gravatar and GitHub chart for offline viewing
- Faster loads on subsequent visits
- Fallback to cache when services become blocked after initial load

**Implementation:**
- Add Gravatar and GitHub domains to Workbox runtimeCaching in `astro.config.mjs`
- Use StaleWhileRevalidate strategy
- Configure cache expiration (7 days for Gravatar, 1 day for GitHub)

**Addresses pitfalls:**
- Stale cache prevention (StaleWhileRevalidate not CacheFirst)
- Opaque CORS response handling (statuses: [0, 200])

**Effort:** 20 minutes
**Risk:** LOW - additive configuration to existing Workbox setup

### Phase 4: Analytics Documentation (Non-code)
**Rationale:** Document expected analytics data loss (~30-40%) from ad blockers. No code changes, just awareness.

**Delivers:**
- Documented expected data gap
- Comparison methodology (analytics vs server logs)
- Decision framework for acceptable loss

**Implementation:**
- Add note to README or analytics documentation
- Set up periodic comparison between Vercel Analytics and edge logs
- Accept the gap (recommended) or plan server-side tracking (future)

**Effort:** 30 minutes
**Risk:** NONE - documentation only

### Phase Ordering Rationale

**Why this order:**
1. Phases 1-2 address visible breakage with highest user impact
2. Phase 3 enhances 1-2 after core functionality proven
3. Phase 4 is documentation-only, can run in parallel
4. Total implementation time: ~90 minutes for all phases
5. Each phase independently testable and deployable

**Dependencies:**
- Phase 3 depends on Phases 1-2 (no point caching without fallbacks)
- All phases can be tested with DevTools network blocking
- No external research needed - patterns are well-documented

### Research Flags

**Phases with standard patterns (skip research-phase):**
- **All phases** - This domain has established patterns with high-quality documentation from MDN, Chrome DevTools docs, and Workbox. No niche integrations or undocumented APIs.

**No additional research needed for:**
- Image onerror pattern (HIGH confidence - native HTML)
- Service worker caching (HIGH confidence - Workbox official docs)
- Graceful degradation principles (HIGH confidence - web standards)

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | No new dependencies, existing Astro/Workbox patterns |
| Features | HIGH | Clear table stakes vs differentiators based on UX research |
| Architecture | HIGH | Progressive enhancement is well-established pattern |
| Pitfalls | HIGH | Verified against official docs, MDN, and codebase analysis |

**Overall confidence:** HIGH

### Gaps to Address

**No significant gaps.** Research covered all implementation concerns with authoritative sources.

**Minor validation needed:**
- Test production build with Brave browser + uBlock Origin (standard privacy stack)
- Verify Vercel edge logs accessible for analytics comparison (Phase 4)
- Confirm fallback image dimensions match Gravatar request (400x400 per current src)

**During implementation:**
- Verify about-photo.jpg is suitable as avatar fallback (dimensions, quality)
- Consider whether to generate new fallback or reuse existing photo
- Test both "service blocked" and "service slow" scenarios (onerror doesn't fire on timeout)

## Implementation Files Summary

| Phase | Files to Modify | Files to Create | Effort |
|-------|----------------|-----------------|--------|
| 1 - Avatar | `src/pages/index.astro` | `public/images/avatar-fallback.png` | 30 min |
| 2 - Chart | `src/pages/about.mdx` | None | 15 min |
| 3 - Service Worker | `astro.config.mjs` | None | 20 min |
| 4 - Documentation | README or docs | None | 30 min |

**Total effort:** 90 minutes

**What NOT to create:**
- No new components (onerror is sufficient)
- No new utilities or helper functions
- No new dependencies
- No custom service worker code (use existing generateSW strategy)

## Sources

### Primary (HIGH confidence)
- [MDN HTMLImageElement onerror](https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/onerror) - Native onerror documentation
- [Astro Images Guide](https://docs.astro.build/en/guides/images/) - Astro 5 image handling
- [Workbox Caching Strategies](https://developer.chrome.com/docs/workbox/caching-strategies-overview/) - Service worker patterns
- [Workbox Managing Fallback Responses](https://developer.chrome.com/docs/workbox/managing-fallback-responses/) - Fallback configuration
- [Vite PWA Astro Documentation](https://vite-pwa-org.netlify.app/frameworks/astro) - @vite-pwa/astro configuration
- [Gravatar API Documentation](https://docs.gravatar.com/sdk/images/) - Default image parameters

### Secondary (MEDIUM confidence)
- [30 Seconds of Code: CSS Broken Image Fallback](https://www.30secondsofcode.org/css/s/broken-image-fallback/) - CSS fallback patterns
- [DEV.to: HTML Fallback Images on Error](https://dev.to/dailydevtips1/html-fallback-images-on-error-1aka) - onerror implementation examples
- [LogRocket: Guide to Graceful Degradation](https://blog.logrocket.com/guide-graceful-degradation-web-development/) - Progressive enhancement principles
- [Smashing Magazine: Importance of Graceful Degradation](https://www.smashingmagazine.com/2024/12/importance-graceful-degradation-accessible-interface-design/) - UX patterns

### Community (Context)
- [Vercel Analytics Blocked by Ad Blockers #137](https://github.com/vercel/analytics/issues/137) - Known issue with workarounds
- [Service Worker Caching: 5 Offline Fallback Strategies](https://www.zeepalm.com/blog/service-worker-caching-5-offline-fallback-strategies) - Strategy comparison

---

*Research completed: 2026-02-02*
*Ready for roadmap: yes*
*Estimated total implementation time: 90 minutes across 4 phases*
