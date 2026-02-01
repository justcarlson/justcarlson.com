# Requirements: justcarlson.com v0.3.0

**Defined:** 2026-01-31
**Core Value:** A clean, personal space to write — with a publishing workflow that just works.

## v0.3.0 Requirements

Requirements for Polish & Portability milestone. Focus: fix template bug, enable one-command bootstrap, add dev container support.

### Template & Content

- [x] **TMPL-01**: Obsidian Post Template removes duplicate `# title` heading from body
- [x] **TMPL-02**: Existing published posts have redundant H1 headings stripped
- [x] **TMPL-03**: Obsidian Post Template includes `tags` field for blog categorization
- [x] **TMPL-04**: Publish script converts Obsidian tags to Astro-compatible format

### Skills

- [x] **SKIL-01**: All skills renamed with `blog:` prefix (`/blog:publish`, `/blog:install`, etc.)
- [x] **SKIL-02**: SessionStart hook message updated to reference `/blog:install`

### Bootstrap & First-Run

- [x] **BOOT-01**: `just bootstrap` command installs dependencies and checks setup status
- [x] **BOOT-02**: `.nvmrc` pins Node.js 22.x LTS version
- [x] **BOOT-03**: README includes Quick Start section with justfile commands
- [x] **BOOT-04**: `just preview` works without vault configured (code exploration mode)

### Dev Container

- [x] **DEVC-01**: `.devcontainer/devcontainer.json` uses Node 22 image with just feature
- [x] **DEVC-02**: node_modules uses named volume for macOS/Windows performance
- [x] **DEVC-03**: postCreateCommand runs `just bootstrap` automatically

### Hook Infrastructure

- [x] **HOOK-01**: SessionStart hook is Python with uv, matching install-and-maintain pattern
- [x] **HOOK-02**: Hook loads .env variables into CLAUDE_ENV_FILE for bash persistence
- [x] **HOOK-03**: Hook logs to file (.claude/hooks/session_start.log) for debugging
- [x] **HOOK-04**: Hook checks vault configuration and posts-ready status

### CLI & Code Quality

- [x] **CLIX-01**: All scripts support `--help` flag for CLI discovery
- [x] **CLIX-02**: All scripts with prompts support non-interactive mode (no TTY required)
- [x] **CLIX-03**: `just publish --post <slug> --yes` and `just setup --vault <path>` work without TTY
- [x] **CLEAN-01**: No dead code or unused exports in src/ (verified via Knip)
- [x] **CLEAN-02**: Consistent error handling patterns across all scripts

## Future Requirements

Deferred to later milestones.

### Bootstrap Enhancements (v0.4.0+)

- **BOOT-05**: "What's next" guidance printed after setup completion
- **BOOT-06**: `just doctor` health check command

### Dev Container Enhancements (v0.4.0+)

- **DEVC-04**: Container-aware vault detection with graceful skip
- **DEVC-05**: Non-interactive setup mode via environment variable
- **DEVC-06**: Documentation for vault mounting (advanced users)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full dev container publishing | Vault access is local concern; container is for code work |
| Automatic vault mounting | Too complex, varies by host OS |
| Windows native support | WSL2 is recommended path |
| just doctor command | Polish, not essential for v0.3.0 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TMPL-01 | Phase 11 | Complete |
| TMPL-02 | Phase 11 | Complete |
| TMPL-03 | Phase 11 | Complete |
| TMPL-04 | Phase 11 | Complete |
| SKIL-01 | Phase 11 | Complete |
| SKIL-02 | Phase 11 | Complete |
| BOOT-01 | Phase 12 | Complete |
| BOOT-02 | Phase 12 | Complete |
| BOOT-03 | Phase 12 | Complete |
| BOOT-04 | Phase 12 | Complete |
| DEVC-01 | Phase 12 | Complete |
| DEVC-02 | Phase 12 | Complete |
| DEVC-03 | Phase 12 | Complete |
| HOOK-01 | Phase 13 | Complete |
| HOOK-02 | Phase 13 | Complete |
| HOOK-03 | Phase 13 | Complete |
| HOOK-04 | Phase 13 | Complete |
| CLIX-01 | Phase 14 | Complete |
| CLIX-02 | Phase 14 | Complete |
| CLIX-03 | Phase 14 | Complete |
| CLEAN-01 | Phase 14 | Complete |
| CLEAN-02 | Phase 14 | Complete |

**Coverage:**
- v0.3.0 requirements: 22 total
- Mapped to phases: 17
- Unmapped: 0

---
*Requirements defined: 2026-01-31*
*Last updated: 2026-02-01 after phase 14 completion*
