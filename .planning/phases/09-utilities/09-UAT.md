---
status: complete
phase: 09-utilities
source: [09-01-SUMMARY.md, 09-02-SUMMARY.md, 09-03-SUMMARY.md]
started: 2026-01-31T23:59:00Z
updated: 2026-02-01T00:10:00Z
---

## Current Test

[testing complete]

## Tests

### 1. List Unpublished Posts (Default)
expected: Running `just list-posts` shows only unpublished posts (have Published status in Obsidian but not in blog repo). Table format with title, date, status, errors.
result: pass

### 2. List All Posts
expected: Running `just list-posts --all` shows ALL posts with Published status in Obsidian, regardless of whether already in blog repo.
result: pass

### 3. List Published Posts Only
expected: Running `just list-posts --published` shows only posts that exist in src/content/blog/ directory. Works even without Obsidian vault configured.
result: pass

### 4. Unpublish a Post
expected: Running `just unpublish <slug>` shows post info, asks for confirmation (default: No), removes from repo on Y, commits with conventional message, and shows tip to update Obsidian status.
result: pass

### 5. Unpublish Non-Existent Post
expected: Running `just unpublish fake-post` shows clear error message and suggests `just list-posts --published` to see available posts.
result: pass

### 6. Unpublish Cancellation
expected: When prompted for confirmation and answering anything other than Y/y, script exits cleanly with no error message (exit code 0).
result: pass

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0

## Gaps

[none]
