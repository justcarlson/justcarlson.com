---
status: testing
phase: 09-utilities
source: [09-01-SUMMARY.md, 09-02-SUMMARY.md, 09-03-SUMMARY.md]
started: 2026-01-31T22:45:00Z
updated: 2026-02-01T00:15:00Z
---

## Current Test

number: 1
name: --published flag scans blog directory directly
expected: |
  Running `just list-posts --published` shows posts in `src/content/blog/` without requiring Obsidian vault. Should show the 2 posts in src/content/blog/2026/
awaiting: user response

## Tests

### 1. --published flag scans blog directory directly
expected: Running `just list-posts --published` shows posts in `src/content/blog/` without requiring Obsidian vault. Should show the 2 posts in src/content/blog/2026/
result: [pending]

### 2. Unpublish cancellation exits cleanly
expected: Cancelling `just unpublish <slug>` (pressing Enter or 'n') exits with code 0, no error message from justfile
result: [pending]

### 3. ANSI colors display in unpublish tip
expected: After unpublish success, the tip about updating Obsidian status shows colored text (cyan) not literal escape codes
result: [pending]

### 4. Documentation uses status terminology
expected: ROADMAP.md line 67 now says `status: - Published` instead of `draft: false`
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0

## Gaps

[none yet]
