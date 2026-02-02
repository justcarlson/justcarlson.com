# Roadmap: justcarlson.com v0.5.0

## Overview

This milestone delivers graceful degradation when external services (Gravatar, analytics, GitHub chart) are blocked by privacy tools or network restrictions. The site will load fully without external dependencies, with external content enhancing the experience when available. Three phases: configure Vercel Image Optimization, implement avatar fallback with proxy, then harden all external images and scripts.

## Milestones

- v0.1.0 MVP - Phases 1-6 (shipped 2026-01-30)
- v0.2.0 Publishing Workflow - Phases 7-10 (shipped 2026-01-31)
- v0.3.0 Polish & Portability - Phases 11-14 (shipped 2026-02-01)
- v0.4.0 Obsidian Integration - Phases 15-17 (shipped 2026-02-02)
- v0.4.1 Image & Caption Support - Phases 18-19 (shipped 2026-02-02)
- **v0.5.0 Graceful Fallback** - Phases 20-22 (current)

## Phases

**Phase Numbering:**
- Integer phases (20, 21, 22): Planned milestone work
- Decimal phases (20.1, 20.2): Urgent insertions (marked with INSERTED)

- [x] **Phase 20: Configuration Foundation** - Vercel Image Optimization and CSP setup
- [x] **Phase 21: Avatar Fallback** - Gravatar proxy with local fallback
- [x] **Phase 22: External Resilience** - GitHub chart and script hardening

## Phase Details

### Phase 20: Configuration Foundation
**Goal**: Infrastructure enables proxied Gravatar and updated security headers
**Depends on**: Nothing (first phase of milestone)
**Requirements**: CONFIG-01, CONFIG-02
**Success Criteria** (what must be TRUE):
  1. vercel.json contains images.remotePatterns for gravatar.com
  2. CSP headers allow img-src from /_vercel/image endpoint
  3. Production build succeeds with new configuration
**Plans**: 2 plans

Plans:
- [x] 20-01-PLAN.md — Vercel Image Optimization config and CSS loading/fallback styles
- [x] 20-02-PLAN.md — Playwright testing infrastructure for image blocking verification

### Phase 21: Avatar Fallback
**Goal**: Avatar loads reliably regardless of Gravatar availability
**Depends on**: Phase 20
**Requirements**: IMG-01, IMG-02
**Success Criteria** (what must be TRUE):
  1. Homepage avatar uses Vercel Image Optimization proxy URL (/_vercel/image?url=...)
  2. When proxy fails, local fallback image displays (no broken image icon)
  3. No layout shift when fallback triggers
  4. Avatar renders correctly in both light and dark themes
**Plans**: 1 plan

Plans:
- [x] 21-01-PLAN.md — Avatar proxy URL with onerror fallback and Playwright tests

### Phase 22: External Resilience
**Goal**: All external images and scripts fail gracefully without breaking page
**Depends on**: Phase 21
**Requirements**: IMG-03, IMG-04, SCRIPT-01, SCRIPT-02, SCRIPT-03
**Success Criteria** (what must be TRUE):
  1. GitHub contribution chart shows link fallback when image blocked
  2. No broken image icons appear anywhere on site when external images blocked
  3. Analytics scripts fail silently without console errors
  4. Page loads completely and renders correctly with all external scripts blocked
  5. No external script blocks page rendering (async/defer pattern verified)
**Plans**: 2 plans

Plans:
- [x] 22-01-PLAN.md — GitHub chart fallback, Analytics error handling, conditional Twitter widget
- [x] 22-02-PLAN.md — Fix GitHub chart disappearing when image cached (gap closure)

## Progress

**Execution Order:**
Phases execute in numeric order: 20 -> 20.1 -> 20.2 -> 21 -> 21.1 -> 22

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 20. Configuration Foundation | 2/2 | Complete | 2026-02-02 |
| 21. Avatar Fallback | 1/1 | Complete | 2026-02-02 |
| 22. External Resilience | 2/2 | Complete | 2026-02-02 |

---
*Roadmap created: 2026-02-02*
*Milestone: v0.5.0 Graceful Fallback for Blocked Services*
