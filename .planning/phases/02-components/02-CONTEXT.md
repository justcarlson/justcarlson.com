# Phase 2: Components - Context

**Gathered:** 2026-01-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Update presentation layer components to reference Justin Carlson identity and justcarlson.com URLs. Meta tags, footer, newsletter form, and elimination of all hardcoded previous-owner references. Does not include content changes (Phase 4) or infrastructure/deployment config (Phase 3).

</domain>

<decisions>
## Implementation Decisions

### Meta tags & SEO
- Site title: "Justin Carlson" (full name, not domain-style)
- Page title format: "Post Title | Justin Carlson" (content-first)
- Site description tone: Thoughtful practitioner — "Thoughts on software, technology, and building things"
- OG images: Keep existing approach, update with Justin Carlson info

### Footer content
- Keep open-source spirit: CC BY 4.0 for content, MIT for code
- Link to justcarlson/justcarlson.com repository
- Minimal: social icons + license link only
- No additional elements (no RSS link in footer)

### Newsletter handling
- When disabled: completely invisible in UI
- When enabled: generic subscribe prompt ("Subscribe to get new posts" or similar)
- No provider preference yet — design for easy provider swap
- Buttondown reference removed, provider-agnostic approach

### URL audit approach
- Scope: Full repository scan (not just components)
- Patterns: All Peter references — steipete.me, steipete (username), "Peter Steinberger", Buttondown ID
- Include other artifacts: PSPDFKit, analytics IDs, any other identifiers
- Action: Replace with equivalents (steipete → justcarlson, Peter → Justin, etc.)

### Claude's Discretion
- Footer license link wording (keep playful or more understated)
- Newsletter component architecture (configurable provider vs placeholder)
- Which specific artifacts beyond the obvious ones are worth catching

</decisions>

<specifics>
## Specific Ideas

- Site is essentially a professional "proof of work" / CV — not explicitly disclosed, but builds credibility
- Core focus: Technology development and trends discussions (similar to Peter's format)
- Room for personal tangents — may deviate from pure tech
- Thoughtful practitioner voice, not corporate

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-components*
*Context gathered: 2026-01-29*
