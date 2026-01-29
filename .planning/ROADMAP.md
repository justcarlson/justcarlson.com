# Roadmap: justcarlson.com

## Overview

Transform a forked Astro blog (steipete.me) into a clean personal space for Just Carlson. This roadmap follows a dependency-driven approach: configuration first (foundation), then assets and components (presentation layer), then infrastructure (deployment), and finally content (polish). Each phase delivers a coherent, testable capability that unblocks the next.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3, 4): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Configuration and visual assets updated
- [x] **Phase 2: Components** - Component layer references updated
- [x] **Phase 3: Infrastructure** - Build config and deployment ready
- [ ] **Phase 4: Content & Polish** - Content cleaned, final validation complete

## Phase Details

### Phase 1: Foundation
**Goal**: Core configuration and visual assets updated to Just Carlson identity
**Depends on**: Nothing (first phase)
**Requirements**: CFG-01, CFG-02, CFG-03, CFG-04, VIS-01, VIS-02, VIS-03, VIS-04
**Success Criteria** (what must be TRUE):
  1. Site config files reference justcarlson.com domain and Just Carlson author name
  2. Social links point to justcarlson GitHub and LinkedIn accounts
  3. Leaf Blue light theme and AstroPaper v4 dark theme colors applied site-wide
  4. Favicon displays JC monogram in browser tabs and PWA
**Plans:** 2 plans

Plans:
- [x] 01-01-PLAN.md — Update site configuration files with Just Carlson identity
- [x] 01-02-PLAN.md — Apply theme colors and implement JC monogram favicon

### Phase 2: Components
**Goal**: All components reference correct assets and config values
**Depends on**: Phase 1 (components import config and load assets)
**Requirements**: None directly (implements Phase 1 changes in presentation layer)
**Success Criteria** (what must be TRUE):
  1. Meta tags in page head show Just Carlson identity and justcarlson.com URLs
  2. Footer GitHub link points to justcarlson/justcarlson.com repository
  3. Newsletter form has Peter's Buttondown reference removed (configurable or removed)
  4. No hardcoded steipete.me URLs in component files
**Plans:** 2 plans

Plans:
- [x] 02-01-PLAN.md — Update StructuredData.astro to use config values for SEO
- [x] 02-02-PLAN.md — Update Sidebar and Footer with config-driven identity

### Phase 3: Infrastructure
**Goal**: Build configuration and deployment ready for production
**Depends on**: Phase 2 (infrastructure aggregates component output)
**Requirements**: INF-01, INF-02, INF-03, INF-04
**Success Criteria** (what must be TRUE):
  1. PWA manifest shows justcarlson.com branding and correct asset paths
  2. Vercel redirects updated (no steipete.me references)
  3. CSP headers updated with correct domain allowlist
  4. Production build succeeds with no broken references
**Plans:** 3 plans

Plans:
- [x] 03-01-PLAN.md — Update PWA manifest branding and generate icon sizes
- [x] 03-02-PLAN.md — Clean up Vercel redirects and CSP headers
- [x] 03-03-PLAN.md — Add build validation and fix 404 page

### Phase 4: Content & Polish
**Goal**: Content cleaned, tooling configured, final validation complete
**Depends on**: Phase 3 (content is presentation layer on top of working infrastructure)
**Requirements**: CNT-01, CNT-02, CNT-03, CNT-04, CLN-01, CLN-02, CLN-03, TLG-01
**Success Criteria** (what must be TRUE):
  1. All Peter Steinberger blog posts and images deleted
  2. Placeholder About page created with Just Carlson content
  3. README rewritten for justcarlson.com repository
  4. Final validation shows zero identity reference leaks (grep validation clean)
**Plans**: TBD

Plans:
- [ ] TBD (to be planned)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | Complete ✓ | 2026-01-29 |
| 2. Components | 2/2 | Complete ✓ | 2026-01-29 |
| 3. Infrastructure | 3/3 | Complete ✓ | 2026-01-29 |
| 4. Content & Polish | 0/TBD | Not started | - |

---
*Roadmap created: 2026-01-28*
*Coverage: 20/20 v1 requirements mapped*
