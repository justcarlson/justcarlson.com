# Phase 10: Skills Layer - Context

**Gathered:** 2026-01-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Optional Claude oversight wrapping justfile commands. Skills provide human-in-the-loop interaction for publishing workflows, guided onboarding, and maintenance tasks. All skills wrap existing justfile recipes (no duplicated logic).

</domain>

<decisions>
## Implementation Decisions

### Skill Scope
- Full skill suite: `/publish`, `/install`, `/maintain`, `/list-posts`, `/unpublish`
- All skills use `disable-model-invocation: true` (manual invocation only)
- Skills wrap justfile recipes — no duplicated logic

### /install Skill
- Focused scope: Obsidian vault path config, npm dependencies, build verification
- Interactive Q&A mode — guide through setup step-by-step
- Stop hook verifies: vault configured, deps installed, build passes

### /maintain Skill
- Comprehensive checks: outdated npm packages, lint, build, content validation, link rot review
- Report-only mode — show issues, let user decide what to fix
- No auto-fixing; user controls all changes

### /publish Skill
- Confirm each post individually — show diff/preview, ask before committing
- Stop hook verifies: `npm run build` succeeds before Claude stops
- Wraps `just publish` with oversight layer

### /list-posts and /unpublish Skills
- Minimal oversight — these are simpler operations
- `/list-posts` is read-only, no confirmation needed
- `/unpublish` confirms before removing

### Stop Hooks
- Skill-scoped — each skill defines its own verification
- Command hooks (deterministic scripts), not prompt/agent hooks
- On failure: block + explain (tell Claude what failed, let Claude fix it)
- Exit code 2 blocks the stop

### Setup Hook Enhancement
- Runs on every startup (current behavior)
- Config check only — no health checks (keep startup fast)
- If vault not configured, output message suggesting `/install`
- Does NOT trigger /install automatically — user controls when to run it

### Claude's Discretion
- Exact diff/preview formatting for /publish
- How to present maintenance report (table vs list vs sections)
- Error message wording for stop hook failures

</decisions>

<specifics>
## Specific Ideas

- Pattern inspired by IndyDevDan's "Install and Maintain" approach (deterministic hooks + agentic prompts + interactive mode)
- Three-layer architecture: justfile (deterministic) → hooks (safety) → skills (optional oversight)
- Skills frontmatter can define hooks scoped to skill lifetime
- Link rot review uses external link checking for blog content health

</specifics>

<deferred>
## Deferred Ideas

- Scheduled/automated maintenance runs — could be cron + headless Claude
- Deploy preview verification in stop hooks — currently just build verification
- `/preview` skill wrapping `just preview` — probably not needed, simple command

</deferred>

---

*Phase: 10-skills-layer*
*Context gathered: 2026-01-31*
