---
status: complete
phase: 09-utilities
source: [09-01-SUMMARY.md, 09-02-SUMMARY.md]
started: 2026-01-31T22:45:00Z
updated: 2026-01-31T23:05:00Z
---

## Current Test

[testing complete]

## Tests

### 1. List posts shows unpublished by default
expected: Running `just list-posts` shows only unpublished posts (those with `status: Published` in Obsidian that are NOT yet in the blog repo)
result: pass

### 2. List posts --all flag shows all posts
expected: Running `just list-posts --all` shows ALL posts with `status: Published`, including those already published to blog
result: pass

### 3. List posts --published flag shows only in-repo posts
expected: Running `just list-posts --published` shows only posts that exist in `src/content/blog/` directory
result: issue
reported: "Shows 'No published posts found' but there are 2 posts in src/content/blog/2026/"
severity: major

### 4. List posts shows validation errors for invalid posts
expected: Posts with missing/invalid frontmatter (title, pubDatetime, description) show "Invalid" status with error messages indented below
result: pass

### 5. List posts table formatting
expected: Output displays as table with columns for title, date, status. ANSI colors used (green=Ready, red=Invalid)
result: pass

### 6. Unpublish finds post by slug
expected: Running `just unpublish <slug>` finds the post in `src/content/blog/*/slug.md` and shows confirmation prompt
result: pass

### 7. Unpublish confirmation defaults to No
expected: Confirmation prompt shows `[y/N]` with No as default. Pressing Enter without input cancels the operation
result: issue
reported: "Cancellation works but exits with code 130, causing justfile to show error message"
severity: minor

### 8. Unpublish --force skips confirmation
expected: Running `just unpublish <slug> --force` removes post without prompting for confirmation
result: pass

### 9. Unpublish commits but does not push
expected: After unpublish, post is removed via `git rm` and committed, but NOT pushed. Tip displayed about running `git push` manually
result: pass

### 10. Unpublish shows tip about Obsidian update
expected: After unpublish completes, message reminds user to update post status in Obsidian
result: pass

## Summary

total: 10
passed: 8
issues: 2
pending: 0
skipped: 0

## Gaps

- truth: "--published flag shows posts in src/content/blog/"
  status: failed
  reason: "User reported: Shows 'No published posts found' but there are 2 posts in src/content/blog/2026/"
  severity: major
  test: 3
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Cancellation exits cleanly without error"
  status: failed
  reason: "User reported: Cancellation works but exits with code 130, causing justfile to show error message"
  severity: minor
  test: 7
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "ANSI escape codes interpreted in unpublish tip"
  status: failed
  reason: "User reported: ANSI escape codes printed literally (\\033[0;36m) instead of showing as color"
  severity: cosmetic
  test: 6
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Documentation uses correct status field terminology"
  status: failed
  reason: "User reported: All draft: false/true references in codebase and documentation need updating to status: Published/Draft YAML list format"
  severity: major
  test: 2
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
