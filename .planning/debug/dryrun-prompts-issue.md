---
status: gathering
trigger: "Debug Session: Dry-Run Prompts Instead of Auto-Continue"
created: 2026-01-31T13:45:00Z
updated: 2026-01-31T13:45:00Z
---

## Current Focus

hypothesis: CONFIRMED - validate_selected_posts() at line 347-349 prompts without checking DRY_RUN
test: examined scripts/publish.sh validate_selected_posts function
expecting: found prompt that doesn't check DRY_RUN flag
next_action: document root cause and missing fix

## Symptoms

expected: Dry-run should auto-continue through all prompts, showing what WOULD happen
actual: Dry-run stops and waits for user confirmation at partial-valid stage
errors: User sees "1 of 2 posts are valid. Publish the valid ones? [Y/n]"
reproduction: Run `just publish --dry-run` when only some posts are valid
started: Referenced in 08-03-SUMMARY.md context

## Eliminated

(none)

## Evidence

- timestamp: 2026-01-31
  checked: scripts/publish.sh lines 346-360 (validate_selected_posts function)
  found: prompt at line 349 "read -rp "Publish the valid ones? [Y/n]" response" has NO DRY_RUN check
  implication: The function checks DRY_RUN in other places (copy_images at 777, copy_post at 812, commit_posts at 943, push_commits at 976) but NOT in the partial-valid prompt

- timestamp: 2026-01-31
  checked: DRY_RUN handling pattern in script
  found: All other user-interaction points wrap prompts in "if [[ "$DRY_RUN" == "true" ]]" blocks
  implication: validate_selected_posts should follow same pattern for consistency and functionality

## Resolution

root_cause: "validate_selected_posts() function (line 347-349) shows partial-valid prompt without checking DRY_RUN flag. The prompt 'read -rp \"Publish the valid ones? [Y/n]\" response' always executes, blocking dry-run from auto-continuing."

fix: "Wrap the partial-valid prompt block (lines 347-360) in an 'if [[ \"$DRY_RUN\" == \"true\" ]]' check to auto-answer 'yes' and continue with valid files during dry-run mode. The validation error display (lines 339-344) should remain visible in both modes."

verification: "When run with --dry-run and some posts invalid, dry-run should display validation errors but skip the prompt and auto-continue with valid posts, showing the complete dry-run summary at the end."

files_changed:
  - scripts/publish.sh: Add DRY_RUN check around partial-valid prompt (lines 347-360)
