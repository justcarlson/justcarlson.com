# Phase 12: Bootstrap & Portability - Context

**Gathered:** 2026-02-01
**Status:** Ready for planning

<domain>
## Phase Boundary

One-command bootstrap for fresh clones and dev container support for instant contribution. Users can spin up the project without friction, whether locally or in Codespaces.

</domain>

<decisions>
## Implementation Decisions

### Bootstrap behavior
- Auto-install missing dependencies (pnpm, etc.) rather than failing with instructions
- Fully idempotent — always safe to re-run, skips what's already done
- Full verbose output by default — show everything including command output
- Full validation after install: check Node version, pnpm, deps installed, build compiles, dev server starts

### Vault-optional mode
- Preview and build work without vault configured — show empty blog
- Console message only when no vault ("No vault configured") — site looks normal, just empty
- Build also works without vault for testing build process

### Dev container
- Codespaces-ready — container config enables GitHub Codespaces workflow
- Include GitHub CLI (gh) for PRs and issues from terminal
- Auto-bootstrap on container start — ready to go immediately
- Full productivity VS Code extensions: Astro, Tailwind, ESLint, Prettier, GitLens, error highlighting
- Auto-forward ports and open preview in browser when dev server starts

### README structure
- Assume nothing — link to prerequisites for everything (most accessible)
- Local setup only — no Codespaces quick-start in README
- Common issues section with 3-5 known gotchas and solutions
- Dedicated section explaining Obsidian vault connection and configuration

### Claude's Discretion
- Vault path configuration approach (env var vs config file)
- Specific VS Code extensions beyond the essentials mentioned
- Troubleshooting content specifics

</decisions>

<specifics>
## Specific Ideas

- Codespaces as the "work from anywhere" enabler — container starts ready, just run `just preview`
- Bootstrap should feel like a single command that "just works"

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 12-bootstrap-portability*
*Context gathered: 2026-02-01*
