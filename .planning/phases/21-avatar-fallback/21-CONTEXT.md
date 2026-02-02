# Phase 21: Avatar Fallback - Context

**Gathered:** 2026-02-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Avatar loads reliably regardless of Gravatar availability. Primary source is Vercel Image Optimization proxy (cached at edge CDN). Local fallback image displays when proxy fails. No layout shift, no broken image icons.

</domain>

<decisions>
## Implementation Decisions

### Fallback Image
- Local headshot stored in /public — same photo as Gravatar
- WebP format for optimal file size
- Use Astro's image optimization for the fallback too
- Same dimensions as primary to prevent layout shift

### Transition Behavior
- Instant swap when fallback triggers — no animation or fade
- No loading state (skeleton/blur) — image just appears when ready
- No visual indication that fallback is showing — seamless experience
- Eager loading — avatar is above fold, part of first impression

### Avatar Sizing/Shape
- Circular shape (rounded-full) — keep current implementation
- CSS applied directly on img element — keep current approach
- Same size as current (w-40 h-40 = 160x160px) — don't resize
- Fallback dimensions match primary exactly

### Theme Handling
- Single image works for both light and dark themes
- No border or ring around avatar
- Shadow on hover only — keep current behavior
- No special background handling — circular crop handles edges

### Claude's Discretion
- onerror handler implementation pattern
- Exact file path for local fallback image
- Whether to use Astro Image component or plain img with fallback

</decisions>

<specifics>
## Specific Ideas

- Vercel caches Gravatar at edge CDN, so fallback is truly rare (only when cache expires AND Gravatar unreachable)
- Keep all current styling — this phase adds resilience, not redesign

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 21-avatar-fallback*
*Context gathered: 2026-02-02*
