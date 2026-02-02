---
status: complete
phase: 19-justfile-hero-image-support
source: 19-01-SUMMARY.md
started: 2026-02-02T06:30:00Z
updated: 2026-02-02T06:48:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Hero Image Alt Change Detection
expected: Changing heroImageAlt in a published post triggers republish detection. The post should appear as "changed" in publish workflow when only alt text differs from published version.
result: issue
reported: "Build fails with YAML parse error. The heroImage: key is being stripped from frontmatter, leaving orphaned value 'Attachments/fresh-coat-on-solid-foundation.jpg' which breaks YAML parsing."
severity: blocker

### 2. Hero Image Caption Change Detection
expected: Changing heroImageCaption in a published post triggers republish detection. The post should appear as "changed" in publish workflow when only caption differs from published version.
result: skipped
reason: Blocked by blocker issue #1 - publish workflow broken

### 3. Empty Hero Image Fields Cleanup
expected: When publishing a post with empty heroImageAlt or heroImageCaption fields, those empty fields are stripped from the published frontmatter (not left as empty strings).
result: skipped
reason: Blocked by blocker issue #1 - same regex bug affects this feature

## Summary

total: 3
passed: 0
issues: 1
pending: 0
skipped: 2

## Gaps

- truth: "heroImage field preserved in published frontmatter when post has hero image"
  status: failed
  reason: "User reported: Build fails with YAML parse error. The heroImage: key is being stripped from frontmatter, leaving orphaned value."
  severity: blocker
  test: 1
  root_cause: "Shell variable interpolation bug in publish.sh lines 278, 281, 284. The regex pattern uses double quotes causing $\\n to be interpreted as shell variable expansion instead of Perl regex anchor+newline."
  artifacts:
    - path: "scripts/publish.sh"
      issue: "Lines 278, 281, 284 use double-quoted perl -pe with $\\n pattern which shell expands incorrectly"
  missing:
    - "Change double quotes to single quotes around perl regex patterns, or escape the $ as \\$"
  debug_session: ""
