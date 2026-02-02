---
phase: 18-image-caption-support
plan: 01
subsystem: ui
tags: [astro, accessibility, semantic-html, figure, figcaption]

# Dependency graph
requires:
  - phase: none
    provides: base blog schema and PostDetails layout
provides:
  - heroImageAlt schema field for custom alt text
  - heroImageCaption schema field for image captions
  - figure/figcaption semantic markup for hero images
  - alt text fallback to title for accessibility
affects: [content-authoring, any-phase-using-hero-images]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - semantic figure/figcaption for images with captions
    - alt text fallback pattern (specific || fallback)

key-files:
  created: []
  modified:
    - src/content.config.ts
    - src/layouts/PostDetails.astro

key-decisions:
  - "Alt text fallback to title ensures every hero image has meaningful alt text"
  - "Optional fields maintain backward compatibility with existing posts"

patterns-established:
  - "figure/figcaption: Use semantic markup for images with captions"
  - "Alt text fallback: heroImageAlt || title pattern"

# Metrics
duration: 2min
completed: 2026-02-02
---

# Phase 18 Plan 01: Image Caption Support Summary

**Hero image alt text and caption support using semantic figure/figcaption with title fallback for accessibility**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-02T05:27:41Z
- **Completed:** 2026-02-02T05:29:21Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added heroImageAlt and heroImageCaption optional schema fields
- Wrapped hero images in semantic `<figure>` element
- Implemented alt text with title fallback for accessibility compliance
- Added conditional figcaption rendering for captions

## Task Commits

Each task was committed atomically:

1. **Task 1: Add heroImageAlt and heroImageCaption to schema** - `2f31b1b` (feat)
2. **Task 2: Update PostDetails.astro hero image rendering** - `cf018cc` (feat)

## Files Created/Modified
- `src/content.config.ts` - Added heroImageAlt and heroImageCaption optional string fields
- `src/layouts/PostDetails.astro` - Updated hero image to use figure/figcaption with alt text fallback

## Decisions Made
- Used `heroImageAlt || title` pattern for alt text fallback - ensures every hero image has meaningful alt text for accessibility
- Added fields as `.optional()` to maintain backward compatibility with existing posts
- Moved mb-8 margin from img to figure to maintain proper spacing with figcaption

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Image caption support complete
- Existing posts render correctly (backward compatible)
- Ready for content authors to add heroImageAlt and heroImageCaption to posts
- Inline figure/figcaption in markdown body already styled via prose-figcaption in typography.css

---
*Phase: 18-image-caption-support*
*Completed: 2026-02-02*
