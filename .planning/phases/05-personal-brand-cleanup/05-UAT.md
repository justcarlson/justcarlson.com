---
status: complete
phase: 05-personal-brand-cleanup
source: [05-01-SUMMARY.md, 05-02-SUMMARY.md, 05-03-SUMMARY.md]
started: 2026-01-29T23:00:00Z
updated: 2026-01-29T23:10:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Browser Tab Shows Person Name
expected: Open the site in browser. Tab title should show "Justin Carlson" (person name), not "justcarlson" (brand name).
result: pass

### 2. Favicon Displays JC Monogram
expected: In browser tab, favicon shows JC monogram (blue "JC" letters). Not the old owner's icon.
result: pass

### 3. Social Links Show Person Name
expected: Hover over GitHub/LinkedIn links in sidebar or footer. Tooltips should show "Justin Carlson on GitHub" / "Justin Carlson on LinkedIn", not "justcarlson on GitHub".
result: pass

### 4. Sidebar Avatar Loads from Gravatar
expected: Homepage sidebar shows profile image loaded from Gravatar (gravatar.com). Should display an actual avatar photo or identicon geometric pattern if no Gravatar set.
result: issue
reported: "no"
severity: major

### 5. Blog Post Byline Shows Person Name
expected: On blog post page (e.g., /posts/hello-world/), author byline shows "Justin Carlson" (person name), not "justcarlson" (brand name).
result: pass

## Summary

total: 5
passed: 4
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Homepage sidebar shows profile image loaded from Gravatar"
  status: failed
  reason: "User reported: no"
  severity: major
  test: 4
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
