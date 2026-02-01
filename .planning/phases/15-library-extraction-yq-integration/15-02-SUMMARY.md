---
phase: 15-library-extraction-yq-integration
plan: 02
subsystem: scripts
tags: [bash, shell-library, frontmatter, yaml, yq, sed]

# Dependency graph
requires:
  - phase: 15-01
    provides: common.sh skeleton with constants
provides:
  - Validation functions (extract_frontmatter, get_frontmatter_field, validate_iso8601, validate_frontmatter)
  - Utility functions (slugify, load_config, extract_frontmatter_value)
  - All 5 scripts sourcing shared library
  - ~360 lines of duplicate code eliminated
affects: [16-two-way-sync, scripts]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - BASH_SOURCE-based library sourcing
    - yq/sed fallback for frontmatter parsing
    - Shared constants and utilities pattern

key-files:
  created: []
  modified:
    - scripts/lib/common.sh
    - scripts/publish.sh
    - scripts/unpublish.sh
    - scripts/list-posts.sh
    - scripts/setup.sh
    - scripts/bootstrap.sh

key-decisions:
  - "Used sed fallback when mikefarah/yq unavailable (go-yq not installed)"
  - "extract_frontmatter_value is alias to get_frontmatter_field for backward compat"
  - "Removed load_config call from unpublish.sh (doesn't need vault path)"

patterns-established:
  - "BASH_SOURCE sourcing: SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd); source ${SCRIPT_DIR}/lib/common.sh"
  - "yq detection: check for go-yq or mikefarah signature in yq --version"
  - "Missing field handling: || true in grep pipeline to prevent exit code 1"

# Metrics
duration: 18min
completed: 2026-02-01
---

# Phase 15 Plan 02: Library Extraction Summary

**Extracted validation and utility functions to common.sh, eliminated ~360 lines of duplicate code across 5 scripts**

## Performance

- **Duration:** 18 min
- **Started:** 2026-02-01T21:38:41Z
- **Completed:** 2026-02-01T21:56:XX
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added 8 functions to common.sh: extract_frontmatter, get_frontmatter_field, validate_iso8601, validate_frontmatter, slugify, load_config, extract_frontmatter_value, and yq detection helpers
- Migrated all 5 scripts (publish.sh, unpublish.sh, list-posts.sh, setup.sh, bootstrap.sh) to source common.sh
- Removed ~360 lines of duplicate code (180+ from publish.sh, ~130 from list-posts.sh, ~50 from unpublish.sh)
- Implemented sed-based fallback for frontmatter parsing when mikefarah/yq unavailable

## Task Commits

Each task was committed atomically:

1. **Task 1: Add validation and utility functions to common.sh** - `0301720` (feat)
2. **Task 2: Migrate scripts to source common.sh** - `ae556de` (refactor)
3. **Task 3: Verify yq frontmatter handling** - `266327f` (fix)

## Files Created/Modified

- `scripts/lib/common.sh` - Added 193 lines: validation functions, utility functions, yq detection
- `scripts/publish.sh` - Removed 180+ lines of duplicates, added sourcing
- `scripts/unpublish.sh` - Removed ~50 lines of duplicates, added sourcing
- `scripts/list-posts.sh` - Removed ~130 lines of duplicates, added sourcing
- `scripts/setup.sh` - Removed color constants, added sourcing
- `scripts/bootstrap.sh` - Removed color constants, added sourcing

## Decisions Made

1. **Used sed fallback instead of requiring yq installation** - System has kislyuk/yq (Python) not mikefarah/yq (Go). The sed fallback handles common cases correctly; yq provides better edge case handling when available.

2. **extract_frontmatter_value as alias** - Some scripts used different function names; aliasing maintains backward compatibility and makes migration simpler.

3. **Removed load_config from unpublish.sh** - This script only operates on the blog directory and doesn't need vault path validation.

4. **Added || true to grep pipeline** - Prevents exit code 1 when field is missing in sed fallback, ensuring empty string return.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed grep exit code on missing fields**
- **Found during:** Task 3 (yq edge case testing)
- **Issue:** get_frontmatter_field returned exit code 1 when field not found (grep behavior)
- **Fix:** Added `|| true` to end of sed/grep pipeline
- **Files modified:** scripts/lib/common.sh
- **Verification:** Test 3 passes - missing field returns empty string
- **Committed in:** 266327f

---

**Total deviations:** 1 auto-fixed (blocking issue)
**Impact on plan:** Essential fix for scripts with strict mode (set -euo pipefail)

## Issues Encountered

- **shellcheck not installed:** Could not run shellcheck verification. Scripts work correctly but shellcheck validation should be done manually: `shellcheck -x scripts/*.sh scripts/lib/*.sh`

- **mikefarah/yq not installed:** System has kislyuk/yq (Python wrapper for jq) instead of mikefarah/yq (Go). The sed-based fallback handles all test cases correctly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- common.sh library complete with all validation and utility functions
- All scripts source the shared library
- Foundation ready for Phase 16 (two-way sync) which can use these shared functions
- Optional: Install go-yq (`pacman -S go-yq`) for improved frontmatter parsing edge cases

---
*Phase: 15-library-extraction-yq-integration*
*Completed: 2026-02-01*
