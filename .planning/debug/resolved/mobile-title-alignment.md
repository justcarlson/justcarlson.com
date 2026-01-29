---
status: resolved
trigger: "mobile-title-alignment"
created: 2026-01-29T00:00:00Z
resolved: 2026-01-29T18:30:00Z
commits:
  - 545d124  # Initial responsive alignment restore
  - 87398c8  # Final fix with title update and narrow viewport centering
---

# Mobile Title Alignment Bug

## Symptoms

- **Expected:** Title and tagline center-aligned at mobile/narrow widths (like steipete.me reference)
- **Actual:** Title and tagline left-aligned when window width reduces
- **Timeline:** Started after phase 5 (personal-brand-cleanup)
- **Reproduction:** Open localhost:4321 and reduce window width

## Root Cause

Two issues:

1. **Responsive classes removed incorrectly:** Initial fix removed `sm:text-left` entirely, making everything centered at ALL widths. But reference site (steipete.me) uses left-aligned on desktop, centered on mobile.

2. **Flex container alignment:** Parent container had `items-start` which aligns children to the left on the cross-axis when in `flex-col` (mobile) mode, overriding `text-center`.

## Fix Applied

### 1. Responsive alignment (matching steipete.me)
- Mobile (<640px): Centered layout (stacked)
- Desktop (≥640px): Left-aligned (side-by-side with avatar)

### 2. Flex alignment fix
```diff
- <div class="flex flex-col sm:flex-row items-start gap-4">
+ <div class="flex flex-col sm:flex-row items-center sm:items-start gap-4">
```

### 3. Title and RSS restructure
- Changed title to "Hi, I'm @_justcarlson."
- Made RSS icon inline within h1 (flows naturally with text)
- Removed extra flex wrapper around title

## Files Changed

- `src/pages/index.astro`
  - Line 30: Added `items-center sm:items-start` for proper mobile centering
  - Line 39-55: Restructured h1 with inline RSS link
  - Line 40: Changed title to "@_justcarlson"

## Verification

Tested at three viewport widths:

| Viewport | Layout | Alignment | Status |
|----------|--------|-----------|--------|
| Desktop (1440px) | Side-by-side | Left-aligned | ✓ |
| Narrow (500px) | Stacked | Centered | ✓ |
| Mobile (375px) | Stacked | Centered | ✓ |

All match steipete.me reference behavior.
