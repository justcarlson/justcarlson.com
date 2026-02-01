---
status: fixed
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

root_cause: |
  The commit_posts() function in scripts/publish.sh had `return $commit_count` on line 991.
  With `set -euo pipefail`, returning a non-zero value from a function is treated as an error.
  When committing 1 post, `commit_count=1`, so `return 1` caused the script to exit with code 1.
  The lint-staged warning was a red herring - the actual error was the function return value.

  The caller at line 1155 already gets the count from `${#PROCESSED_SLUGS[@]}`, making
  the return value completely unused.

fix: |
  1. Removed `return $commit_count` from commit_posts() - non-zero returns are errors with set -e
  2. Added no-changes handling in commit_posts() - shows "already up to date" instead of failing
  3. Rewrote posts_are_identical() to compare:
     - Content body (after frontmatter)
     - Key frontmatter: title, description, pubDatetime
     - Ignores author field (gets transformed from [[Me]] to plain name)
     - Ignores empty field removal

files_changed:
  - scripts/publish.sh

verification: |
  - `just publish --dry-run` completes successfully
  - Already-published posts with no changes are correctly skipped during discovery
  - Frontmatter transformations (author wiki-links) don't cause false updates
