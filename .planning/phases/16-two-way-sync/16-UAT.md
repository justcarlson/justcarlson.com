---
status: diagnosed
phase: 16-two-way-sync
source: 16-01-SUMMARY.md, 16-02-SUMMARY.md, 16-03-SUMMARY.md
started: 2026-02-02T01:30:00Z
updated: 2026-02-02T01:45:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Publish Sets Draft False in Obsidian
expected: Running `just publish` on a post sets `draft: false` in the Obsidian source file. Check the source file in your vault after publishing.
result: issue
reported: "publish script still looks for status: Published instead of draft: false - shows 'No posts ready to publish' and tells user to set status field"
severity: major

### 2. Publish Sets pubDatetime in Obsidian
expected: Running `just publish` on a post sets `pubDatetime` (current timestamp) in the Obsidian source file frontmatter.
result: skipped
reason: Blocked by test 1 - publish discovery uses status: Published instead of draft: false

### 3. Unpublish Sets Draft True in Obsidian
expected: Running `just unpublish` on a post sets `draft: true` in the Obsidian source file, marking it as unpublished.
result: skipped
reason: Blocked by test 1 - no published posts to unpublish

### 4. Backup Created Before Modification
expected: Before modifying any Obsidian file, a `.bak` backup file is created (e.g., `filename.md.bak` appears next to original).
result: skipped
reason: Blocked by test 1 - can't test backup without working publish/unpublish

### 5. Unpublish Dry-Run Preview
expected: Running `just unpublish --dry-run` shows what would change (files to delete, Obsidian sync) without actually modifying any files.
result: pass

### 6. Author From Config
expected: Published posts use author from settings.local.json (if configured), not a hardcoded value. Check the author field in published post frontmatter matches your config.
result: pass

## Summary

total: 6
passed: 2
issues: 1
pending: 0
skipped: 3

## Gaps

- truth: "Running just publish sets draft: false in Obsidian source file"
  status: failed
  reason: "User reported: publish script still looks for status: Published instead of draft: false - shows 'No posts ready to publish' and tells user to set status field"
  severity: major
  test: 1
  root_cause: "publish.sh discover_posts() function uses status: Published pattern (line 420-436) instead of draft: false. Also user instructions (line 1061) reference old field."
  artifacts:
    - path: "scripts/publish.sh"
      issue: "discover_posts() uses status: Published pattern"
      lines: "420-436, 1061"
    - path: "scripts/list-posts.sh"
      issue: "Also uses status: Published pattern (same fix needed)"
      lines: "159-171"
  missing:
    - "Change discover_posts() to look for draft: false instead of status: Published"
    - "Update user instructions to reference draft field, not status"
    - "Update list-posts.sh discovery for consistency"
  debug_session: ""
