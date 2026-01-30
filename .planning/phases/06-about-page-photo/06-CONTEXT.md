# Phase 6: About Page Photo & Profile Images - Context

**Gathered:** 2026-01-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Add personal photo to the About page. Photo source is `~/Downloads/IMG_0251.jpg`. Store in correct asset directory, optimize for web, and integrate with existing About page layout.

</domain>

<decisions>
## Implementation Decisions

### Placement & Sizing
- Photo positioned beside intro text (not as hero, not below content)
- Right side of text column (opposite of steipete.me which uses left)
- ~40% width relative to content area (matching steipete.me proportions)
- Scrolls naturally with page content (not sticky/fixed)

### Image Treatment
- Keep original aspect ratio — no cropping
- Subtle border-radius on corners (soft, not sharp)
- No shadow, no border — clean presentation
- No hover effects — static image

### Responsive Behavior
- Mobile: Photo stacks above text, full-width
- Breakpoint: ~768px switches from stacked to side-by-side
- No lazy loading — photo is above the fold, load immediately

### Claude's Discretion
- Exact border-radius value (something subtle like 4-8px)
- Image optimization settings (format, quality, sizes)
- Astro image component configuration
- Exact responsive CSS implementation

</decisions>

<specifics>
## Specific Ideas

- Reference: steipete.me/about layout was reviewed for responsive behavior patterns
- User prefers right-side placement (opposite of reference) to differentiate
- Clean, minimal treatment aligns with existing site aesthetic

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-about-page-photo*
*Context gathered: 2026-01-29*
