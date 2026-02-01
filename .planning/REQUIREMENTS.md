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

- [ ] **BOOT-01**: `just bootstrap` command installs dependencies and checks setup status
- [ ] **BOOT-02**: `.nvmrc` pins Node.js 22.x LTS version
- [ ] **BOOT-03**: README includes Quick Start section with justfile commands
- [ ] **BOOT-04**: `just preview` works without vault configured (code exploration mode)

### Dev Container

- [ ] **DEVC-01**: `.devcontainer/devcontainer.json` uses Node 22 image with just feature
- [ ] **DEVC-02**: node_modules uses named volume for macOS/Windows performance
- [ ] **DEVC-03**: postCreateCommand runs `just bootstrap` automatically

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
| BOOT-01 | Phase 12 | Pending |
| BOOT-02 | Phase 12 | Pending |
| BOOT-03 | Phase 12 | Pending |
| BOOT-04 | Phase 12 | Pending |
| DEVC-01 | Phase 12 | Pending |
| DEVC-02 | Phase 12 | Pending |
| DEVC-03 | Phase 12 | Pending |

**Coverage:**
- v0.3.0 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0

---
*Requirements defined: 2026-01-31*
*Last updated: 2026-01-31 after roadmap creation*
