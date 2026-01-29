# Requirements: justcarlson.com

**Defined:** 2025-01-28
**Core Value:** A clean, personal space to write — free of the previous owner's identity and content.

## v1 Requirements

Requirements for initial rebrand. Each maps to roadmap phases.

### Configuration

- [x] **CFG-01**: Update `src/consts.ts` with author (Just Carlson), URL (justcarlson.com), description
- [x] **CFG-02**: Update `src/consts.ts` edit post URL to point to justcarlson repo
- [x] **CFG-03**: Update `src/constants.ts` social links (GitHub: justcarlson, LinkedIn: justincarlson0)
- [x] **CFG-04**: Update newsletter form to remove Peter's Buttondown reference (keep component, make configurable)

### Visual Identity

- [x] **VIS-01**: Apply Leaf Blue light theme colors (`--background: #f2f5ec`, `--accent: #1158d1`)
- [x] **VIS-02**: Apply AstroPaper v4 dark theme colors (`--background: #000123`, `--accent: #617bff`)
- [ ] **VIS-03**: Replace avatar with GitHub profile image (justcarlson) *(deferred - avatar in content, not config)*
- [x] **VIS-04**: Implement favicon from `~/Downloads/favicon.svg` using manual generation with Sharp

### Content

- [ ] **CNT-01**: Delete all blog posts in `src/content/blog/`
- [ ] **CNT-02**: Delete all post images in `public/assets/img/`
- [ ] **CNT-03**: Create placeholder About page
- [ ] **CNT-04**: Rewrite README.md for justcarlson.com repo

### Infrastructure

- [ ] **INF-01**: Update `vercel.json` redirects (remove steipete.me references)
- [ ] **INF-02**: Update `vercel.json` CSP headers (update domain references)
- [ ] **INF-03**: Update PWA manifest in `astro.config.mjs`
- [ ] **INF-04**: Fix hardcoded URLs in `src/components/StructuredData.astro`

### Cleanup

- [ ] **CLN-01**: Audit and remove remaining "steipete/peter/steinberger" references
- [ ] **CLN-02**: Remove Peter's custom CSS overrides in `src/styles/custom.css`
- [ ] **CLN-03**: Delete Peter's avatar/office images (`peter-*.jpg`)

### Tooling

- [ ] **TLG-01**: Create Obsidian blog post template at `~/notes/personal-vault/Templates/` matching blog frontmatter schema

## v2 Requirements

Deferred to future. Tracked but not in current roadmap.

### Newsletter

- **NWS-01**: Set up Buttondown (or alternative) newsletter service
- **NWS-02**: Configure newsletter form with new service credentials

### Content

- **CNT-05**: Write actual About page content
- **CNT-06**: Write first blog post

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Writing blog posts | Focus is on making the blog "mine" first |
| Newsletter service setup | Will configure later when ready to collect subscribers |
| Custom domain DNS | Handled separately in Vercel dashboard |
| Comments system | Not in original, not adding now |
| New features/functionality | Rebranding only, not feature development |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CFG-01 | Phase 1 | Complete |
| CFG-02 | Phase 1 | Complete |
| CFG-03 | Phase 1 | Complete |
| CFG-04 | Phase 1 | Complete |
| VIS-01 | Phase 1 | Complete |
| VIS-02 | Phase 1 | Complete |
| VIS-03 | Phase 4 | Pending *(deferred - avatar in content)* |
| VIS-04 | Phase 1 | Complete |
| CNT-01 | Phase 4 | Pending |
| CNT-02 | Phase 4 | Pending |
| CNT-03 | Phase 4 | Pending |
| CNT-04 | Phase 4 | Pending |
| INF-01 | Phase 3 | Pending |
| INF-02 | Phase 3 | Pending |
| INF-03 | Phase 3 | Pending |
| INF-04 | Phase 3 | Pending |
| CLN-01 | Phase 4 | Pending |
| CLN-02 | Phase 4 | Pending |
| CLN-03 | Phase 4 | Pending |
| TLG-01 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0 ✓

---
*Requirements defined: 2025-01-28*
*Last updated: 2026-01-28 after roadmap creation*
