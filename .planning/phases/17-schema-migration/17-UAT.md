---
status: complete
phase: 17-schema-migration
source: 17-VERIFICATION.md (human verification items)
started: 2026-02-02T00:00:00Z
updated: 2026-02-02T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Draft Checkbox Display
expected: Open any post in Obsidian and check Properties panel. `draft` field should render as a checkbox (checked/unchecked), not as text input.
result: pass

### 2. Posts Base View
expected: Open Categories/Posts.md in Obsidian. Should see a table view with columns: Title, Draft (as checkbox), Created, Published (pubDatetime).
result: pass

### 3. New Post Creation from Template
expected: Create a new note from "Post Template" in Obsidian. Frontmatter should have: `draft: true` present, `created:` auto-filled with today's date, `pubDatetime:` empty, NO `status` or `published` fields.
result: pass

### 4. Published Post Filter
expected: In the Posts Base view, verify that posts with `draft: false` (like "Hello World") are distinguishable from draft posts (`draft: true`). The draft column should show the checkbox state clearly.
result: pass

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]
