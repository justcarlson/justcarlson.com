---
phase: 01-foundation
plan: 01
subsystem: config
tags: [astro, branding, identity, config]

# Dependency graph
requires: []
provides:
  - Site configuration with Just Carlson identity
  - Social links pointing to justcarlson GitHub and LinkedIn
  - Configurable newsletter form (disabled until service configured)
affects: [02-content-migration, 03-visual-identity, favicon-generation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Centralized config in consts.ts for site identity"
    - "Feature flags for optional components (NEWSLETTER_CONFIG.enabled)"

key-files:
  created: []
  modified:
    - src/consts.ts
    - src/constants.ts
    - src/components/NewsletterForm.astro

key-decisions:
  - "Keep newsletter component but disable via config (easier than removing)"
  - "Remove X/BlueSky/Mail from SOCIALS (user only uses GitHub/LinkedIn)"
  - "Keep SHARE_LINKS unchanged (generic share intents, not owner identity)"

patterns-established:
  - "Site identity defined in SITE object in consts.ts"
  - "Optional features controlled via config objects with enabled flag"

# Metrics
duration: 4min
completed: 2026-01-29
---

# Phase 1 Plan 1: Site Configuration Identity Summary

**Site config updated with justcarlson.com domain, Just Carlson author, GitHub/LinkedIn socials, and configurable newsletter form**

## Performance

- **Duration:** 4 min
- **Started:** 2026-01-29T11:25:00Z
- **Completed:** 2026-01-29T11:29:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Updated SITE object with justcarlson.com domain and Just Carlson identity
- Replaced Peter's social links with justcarlson GitHub and justincarlson0 LinkedIn
- Made newsletter form configurable via NEWSLETTER_CONFIG (currently disabled)
- Removed all steipete/peter/steinberger references from config files

## Task Commits

Each task was committed atomically:

1. **Task 1: Update site configuration in consts.ts** - `301851d` (feat)
2. **Task 2: Update social links in constants.ts** - `e8b7fe9` (feat)
3. **Task 3: Make newsletter form configurable** - `eea505b` (feat)

## Files Created/Modified

- `src/consts.ts` - Site identity (website, author, title, desc), SOCIAL_LINKS, ICON_MAP, NEWSLETTER_CONFIG
- `src/constants.ts` - SOCIALS array with GitHub and LinkedIn only
- `src/components/NewsletterForm.astro` - Config-driven form that renders nothing when disabled

## Decisions Made

- **Keep newsletter component disabled rather than removing:** Easier to re-enable later when newsletter service is configured. Form renders nothing when NEWSLETTER_CONFIG.enabled is false.
- **Remove X/BlueSky/Mail from SOCIALS:** User doesn't use these platforms. Only GitHub and LinkedIn remain.
- **Keep SHARE_LINKS unchanged:** These are generic share intents for readers to share posts on social platforms. They don't reference the site owner's identity.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Config foundation complete for rebrand
- All components reading from consts.ts will now show Just Carlson identity
- Newsletter form ready to enable once user configures Buttondown/ConvertKit/etc.

---
*Phase: 01-foundation*
*Completed: 2026-01-29*
