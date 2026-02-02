---
status: diagnosed
phase: 22-external-resilience
source: [22-01-SUMMARY.md]
started: 2026-02-02T23:45:00Z
updated: 2026-02-02T23:55:00Z
---

## Current Test

[testing complete]

## Tests

### 1. GitHub chart displays with shimmer loading
expected: About page shows shimmer animation while GitHub contribution chart loads
result: issue
reported: "chart loaded instantly. wait 5 seconds. disappeared. now look at it."
severity: major

### 2. GitHub chart fallback when image blocked
expected: When GitHub chart image is blocked or takes >5s, shows clickable link "View on GitHub" instead of broken image
result: pass

### 3. Analytics scripts fail silently
expected: With analytics blocked, page loads normally without console errors (check browser console - may see a console.log but no unhandled rejection errors)
result: pass

### 4. Twitter widget conditional loading
expected: On pages without Twitter embeds, Twitter widget.js does not load. On pages with Twitter embeds, it loads and renders them.
result: pass
note: No Twitter embeds on site currently; verified script doesn't load on pages without embeds

### 5. Page loads completely with all external scripts blocked
expected: With all external scripts blocked (analytics, Twitter, etc.), page renders correctly with no broken functionality
result: pass

## Summary

total: 5
passed: 4
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "GitHub chart remains visible after successful load"
  status: failed
  reason: "User reported: chart loaded instantly. wait 5 seconds. disappeared. now look at it."
  severity: major
  test: 1
  root_cause: "Script sets 5s timeout unconditionally. If image is cached/already loaded when script runs, onload never fires (already happened), so timeout triggers fallback even though image loaded successfully."
  artifacts:
    - path: "src/components/GitHubChart.astro"
      issue: "Missing img.complete check before setting timeout"
  missing:
    - "Check img.complete && img.naturalHeight > 0 before setting timeout"
    - "If already loaded, remove loading class and skip timeout"
  debug_session: "inline diagnosis during UAT"
