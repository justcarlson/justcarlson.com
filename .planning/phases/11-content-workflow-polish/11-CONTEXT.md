# Phase 11: Content & Workflow Polish - Context

**Gathered:** 2026-01-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix title duplication bug in templates, add proper tag support, and rename skills for discoverability. The Obsidian→blog publishing workflow should be complete and correct after this phase.

</domain>

<decisions>
## Implementation Decisions

### Title handling
- Title lives in frontmatter only, no H1 in body
- Fix existing published posts to remove duplicate H1s
- Obsidian template auto-populates title from filename
- Keep current blog title rendering (it already works well)

### Tags display
- Tags are clickable, linking to tag pages (e.g., /tags/[tag-name])
- Keep current placement: bottom of post, before share buttons
- Keep current styling: pill/badge style with # prefix
- Fix bug: investigate why "others" tag appeared (likely stray parsing issue)

### Skill naming
- Use `/blog:` prefix for all blog-related skills
- Main publishing skill: `/blog:publish`
- Add `/blog:help` skill that lists all /blog: commands
- SessionStart hook should auto-detect state and suggest appropriate next action (not just prompt for /blog:install)

### Template defaults
- New posts default to `draft: true`
- Keep current date format: full ISO datetime with timezone (`2026-01-31T19:07:56.000-0500`)
- Description field required in template
- Maintain compatibility with Kepano's Obsidian vault template (Bases, Categories, status fields)

### Claude's Discretion
- How to handle Kepano-style frontmatter fields during publish (ignore silently vs transform to blog equivalents)
- Exact approach to stripping/handling `[[Posts]]` category links
- How SessionStart hook detects current state

</decisions>

<specifics>
## Specific Ideas

- "I like how it works and is styled already" — referring to tag display and tag pages
- "I like how it rendered by default" — referring to title rendering on blog
- Kepano vault template compatibility is a hard constraint — don't break Bases/Categories/status workflow

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 11-content-workflow-polish*
*Context gathered: 2026-01-31*
