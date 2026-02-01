---
status: diagnosed
phase: 10-skills-layer
source: [10-01-SUMMARY.md]
started: 2026-01-31T10:00:00Z
updated: 2026-01-31T10:20:00Z
---

## Current Test

[testing complete]

## Tests

### 1. /publish skill invocation
expected: Typing `/publish` in Claude Code shows the skill and invokes it. Claude presents an overview of what will happen before executing.
result: pass

### 2. /install skill invocation
expected: Typing `/install` triggers interactive setup. If vault already configured, skill confirms current configuration.
result: issue
reported: "Skill ran just setup even though vault already configured at /home/jc/obsidian/jc. Should have confirmed existing config instead of re-running setup. Script also failed on interactive selection."
severity: major

### 3. /maintain skill invocation
expected: Typing `/maintain` runs health checks and displays a status report (read-only, no modifications).
result: pass

### 4. /list-posts skill invocation
expected: Typing `/list-posts` shows posts with their status (equivalent to `just list-posts`).
result: pass

### 5. /unpublish skill invocation
expected: Typing `/unpublish` prompts for post selection and confirms before removal.
result: issue
reported: "Skill asks user to type filename instead of presenting a list of published posts to choose from. User wants to see options."
severity: minor

### 6. Startup configuration check
expected: On fresh Claude session, if vault is not configured in `.claude/settings.local.json`, Claude suggests running `/install`.
result: issue
reported: "Started fresh session without settings.local.json - no suggestion to run /install appeared. Just showed normal startup prompt."
severity: major

### 7. Manual invocation only
expected: Skills do NOT auto-trigger. Claude does not spontaneously run /publish, /install, etc. without explicit user command.
result: issue
reported: "Typed 'publish' (no slash) and Claude started running 'just publish --dry-run' automatically. disable-model-invocation prevents skill invocation but Claude still ran the underlying command directly."
severity: major

## Summary

total: 7
passed: 3
issues: 4
pending: 0
skipped: 0

## Gaps

- truth: "/install confirms existing vault configuration instead of re-running setup"
  status: failed
  reason: "User reported: Skill ran just setup even though vault already configured at /home/jc/obsidian/jc. Should have confirmed existing config instead of re-running setup. Script also failed on interactive selection."
  severity: major
  test: 2
  root_cause: "SKILL.md has no pre-check for existing config; setup.sh has no idempotency check and always runs interactive flow which fails in non-terminal context"
  artifacts:
    - path: ".claude/skills/install/SKILL.md"
      issue: "No conditional logic to check existing config before running setup"
    - path: "scripts/setup.sh"
      issue: "No idempotency check; uses read -rp which fails non-interactively"
  missing:
    - "Add pre-check to SKILL.md to verify existing config"
    - "Add idempotency check to setup.sh"
    - "Handle non-interactive mode in setup.sh"
  debug_session: ""

- truth: "/unpublish presents list of published posts to select from"
  status: failed
  reason: "User reported: Skill asks user to type filename instead of presenting a list of published posts to choose from. User wants to see options."
  severity: minor
  test: 5
  root_cause: "SKILL.md assumes user provides filename via $ARGUMENTS; no instruction to first list available posts with just list-posts --published"
  artifacts:
    - path: ".claude/skills/unpublish/SKILL.md"
      issue: "Missing instruction to list published posts before asking for selection"
  missing:
    - "Add step to run just list-posts --published first"
    - "Present list to user as selection options"
  debug_session: ""

- truth: "Startup hook suggests /install when vault not configured"
  status: failed
  reason: "User reported: Started fresh session without settings.local.json - no suggestion to run /install appeared. Just showed normal startup prompt."
  severity: major
  test: 6
  root_cause: "Hook event name is wrong - uses 'Setup' but Claude Code has no such event. Correct event is 'SessionStart'. Claude silently ignores unknown hook events."
  artifacts:
    - path: ".claude/settings.json"
      issue: "'Setup' is not a valid hook event; should be 'SessionStart'"
  missing:
    - "Change event from 'Setup' to 'SessionStart'"
    - "Remove matcher - SessionStart fires on every session"
  debug_session: ""

- truth: "Claude does not auto-run publishing commands without explicit /publish invocation"
  status: failed
  reason: "User reported: Typed 'publish' (no slash) and Claude started running 'just publish --dry-run' automatically. disable-model-invocation prevents skill invocation but Claude still ran the underlying command directly."
  severity: major
  test: 7
  root_cause: "disable-model-invocation only prevents Skill tool invocation, not Bash tool. Claude reads justfile/SKILL.md and can run underlying commands directly via Bash."
  artifacts:
    - path: ".claude/skills/publish/SKILL.md"
      issue: "Correctly configured but Claude bypasses via Bash tool"
    - path: ".claude/settings.json"
      issue: "Missing deny rules for publish commands"
  missing:
    - "Add PreToolUse hook to intercept just publish commands"
    - "Or add deny rule for Bash(just publish:*)"
    - "Or document as expected behavior"
  debug_session: ""
