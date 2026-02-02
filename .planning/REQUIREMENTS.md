# Requirements: justcarlson.com

**Defined:** 2026-02-02
**Core Value:** A clean, personal space to write — with a publishing workflow that just works.

## v0.5.0 Requirements

Requirements for graceful fallback when external services are blocked.

### Avatar & Images

- [ ] **IMG-01**: Gravatar loads through Vercel Image Optimization proxy (served from justcarlson.com domain)
- [ ] **IMG-02**: Avatar has local fallback image when Vercel proxy also fails
- [ ] **IMG-03**: No broken image icon shown when external images blocked
- [ ] **IMG-04**: GitHub contribution chart has graceful fallback when blocked

### External Scripts

- [ ] **SCRIPT-01**: Analytics scripts fail silently without console errors
- [ ] **SCRIPT-02**: No external script blocks page rendering
- [ ] **SCRIPT-03**: Page loads fully even if all external scripts blocked

### Configuration

- [ ] **CONFIG-01**: Vercel Image Optimization configured with gravatar.com remote pattern
- [ ] **CONFIG-02**: CSP headers updated for Vercel image optimization endpoint

## Future Requirements

Deferred to later milestones.

### Social Embeds

- **EMBED-01**: Twitter/X embeds have graceful fallback with static preview
- **EMBED-02**: YouTube embeds have thumbnail fallback when blocked

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Analytics proxy/bypass | Disrespects user privacy choices — if blocked, accept data loss |
| Complex retry logic | Over-engineering — simple onerror fallback sufficient |
| Server-side proxy for all external services | Complexity — Vercel Image Optimization handles images |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| IMG-01 | TBD | Pending |
| IMG-02 | TBD | Pending |
| IMG-03 | TBD | Pending |
| IMG-04 | TBD | Pending |
| SCRIPT-01 | TBD | Pending |
| SCRIPT-02 | TBD | Pending |
| SCRIPT-03 | TBD | Pending |
| CONFIG-01 | TBD | Pending |
| CONFIG-02 | TBD | Pending |

**Coverage:**
- v0.5.0 requirements: 9 total
- Mapped to phases: 0
- Unmapped: 9 ⚠️

---
*Requirements defined: 2026-02-02*
*Last updated: 2026-02-02 after initial definition*
