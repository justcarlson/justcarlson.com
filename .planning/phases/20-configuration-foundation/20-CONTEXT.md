# Phase 20: Configuration Foundation - Context

**Gathered:** 2026-02-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Configure Vercel Image Optimization to proxy external images (Gravatar, GitHub chart) and update CSP headers to enforce proxy-only image loading. Infrastructure setup that enables graceful fallback in subsequent phases.

</domain>

<decisions>
## Implementation Decisions

### CSP Policy Approach
- Proxy-only for images: `img-src 'self' data: blob:` (remove current `https:` and `ghchart.rshah.org`)
- GitHub chart goes through `/_vercel/image` proxy like Gravatar — no exceptions
- Embeds (YouTube, Vimeo, Twitter) keep direct CSP entries — only `img-src` becomes proxy-only
- Roll out CSP change all at once with proxy setup (no report-only phase)

### Error Behavior
- Rely on GSD verification to catch Vercel Image config errors (no custom build validation)
- CSS-based fallbacks, not image files
- Loading state: shimmer animation
- Failure state: shimmer fades to solid color matching theme
- Console logging in dev mode only — silent in production
- Applies to all expected images (avatar, any post images that are set) — posts without images render no placeholder

### Testing Verification
- Test both scenarios: local browser blocking AND Vercel preview deploy
- Automated Playwright tests for blocking scenario
- Blocking test verifies: no broken image icons, fallback CSS renders, no console errors
- Preview test verifies: proxy URL works, full page renders correctly, no noticeable proxy latency

### Claude's Discretion
- Exact shimmer animation implementation (CSS keyframes, duration)
- Solid color choice for fallback (theme-aware)
- Playwright test structure and assertions
- Order of config changes within the phase

</decisions>

<specifics>
## Specific Ideas

- CSS placeholder approach preferred over shipping fallback image files
- Shimmer → fade transition should feel modern and intentional, not like an error state
- Performance matters: proxy shouldn't add noticeable latency

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 20-configuration-foundation*
*Context gathered: 2026-02-02*
