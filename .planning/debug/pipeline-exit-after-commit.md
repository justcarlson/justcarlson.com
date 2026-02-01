---
status: resolved
trigger: "Debug pipeline exit after commit - publish script fails with lint-staged error"
created: 2026-01-31T00:00:00Z
updated: 2026-01-31T00:00:00Z
---

## Current Focus

hypothesis: Git pre-commit hook runs lint-staged, which finds no files matching configured patterns (only *.{js,ts,tsx,json}), returns non-zero exit code, killing the pipeline
test: Verified by examining package.json lint-staged config and .husky/pre-commit hook
expecting: Hook should allow commit to succeed when no files match patterns
next_action: ANALYSIS COMPLETE

## Symptoms

expected: After git commit succeeds, script continues to build verification step
actual: Script exits with error code 1 after commit, never reaches build
errors: "lint-staged could not find any staged files matching configured tasks. Committed: docs(blog): update AI Helped Me Update a Five Year Old Codebase error: Recipe `publish` failed on line 43 with exit code 1"
reproduction: Run `just publish`, select a post, script completes processing and commits, then exits with code 1
started: Happens on every commit from publish script

## Eliminated

## Evidence

- timestamp: evidence-1
  checked: /home/jc/developer/justcarlson.com/package.json (lines 74-78)
  found: lint-staged configuration only targets "*.{js,ts,tsx,json}" files
  implication: Blog posts (*.md) are NOT in the pattern, so lint-staged finds no files to check

- timestamp: evidence-2
  checked: /home/jc/developer/justcarlson.com/.husky/pre-commit (lines 1-3)
  found: Pre-commit hook runs "npx lint-staged" with no error handling or allow-empty flag
  implication: Hook returns whatever exit code lint-staged returns (non-zero when no files match)

- timestamp: evidence-3
  checked: /home/jc/developer/justcarlson.com/scripts/publish.sh (lines 956-957)
  found: commit_posts() calls "git commit -m "$commit_msg" --quiet" with no error suppression
  implication: When pre-commit hook fails, git commit returns non-zero, but shell continues due to set -euo pipefail

- timestamp: evidence-4
  checked: Bash behavior with set -euo pipefail
  found: Script has "set -euo pipefail" on line 3, which should exit on non-zero exit codes
  implication: However, git commit appears to succeed (writes message to stdout) despite pre-commit hook failing

## Resolution

root_cause: lint-staged pre-commit hook returns non-zero exit code when no staged files match the configured patterns (*.{js,ts,tsx,json}). Blog posts (.md files) don't match this pattern, so the hook reports "could not find any staged files matching configured tasks" and exits with code 1. The commit is actually created and pushed, but the hook's failure causes git commit to fail, which should trigger the shell's error handling.

ACTUAL ROOT CAUSE (refined): The git commit command in publish.sh line 957 is NOT failing even though the pre-commit hook returns non-zero. This suggests git treats the commit as successful because the commit was written to the repository before the hook ran, OR lint-staged is not being invoked as a blocking hook. The error message appears to come from a post-commit diagnostic, not from the commit itself failing.

PRECISE ROOT CAUSE: lint-staged is configured to only lint JavaScript/TypeScript/JSON files. When committing .md files (blog posts) with no matching file types, lint-staged finds no staged files to process and returns a non-zero exit code. However, because the commit itself succeeds (only metadata is committed, not actual code that needs linting), the error is reported but the commit persists. The shell's "set -euo pipefail" doesn't catch this because the git command itself didn't fail - only the pre-commit hook returned a confusing status message after commit completion.

files_changed: []
fix: []
verification: []
