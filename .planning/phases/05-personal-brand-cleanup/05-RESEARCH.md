# Phase 5: Personal Brand Cleanup - Research

**Researched:** 2026-01-29
**Domain:** Personal branding, identity management, favicon implementation, Gravatar integration
**Confidence:** HIGH

## Summary

Phase 5 addresses final branding inconsistencies discovered during UAT. The site currently uses "Just Carlson" (brand name) everywhere, but this creates a disconnect with external profiles that show "Justin Carlson" (person name). The challenge is implementing context-appropriate naming: "justcarlson" for brand contexts (domain, site title, usernames) and "Justin Carlson" for person contexts (social link text, About page attribution).

The technical work involves three distinct domains:
1. **Contextual naming** - Configuration changes to support different author displays
2. **Gravatar integration** - Replacing mystery person placeholder with real profile image
3. **Favicon replacement** - Ensuring favicon.ico matches the JC monogram SVG

The implementation is straightforward because the foundation already exists. Phase 1 created the JC monogram SVG (which is already theme-adaptive), and the site structure already separates configuration from presentation. No new libraries are needed - just configuration updates and asset regeneration.

**Primary recommendation:** Update config to separate brand name (`justcarlson`) from person name (`Justin Carlson`), update Gravatar URL with proper email hash, and regenerate favicon.ico from existing favicon.svg.

## Standard Stack

All required tools already exist in the codebase or as standard system utilities:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Astro | 5.x | Static site framework | Already in use, handles config/metadata |
| TypeScript | Latest | Type-safe configuration | Already in use for config files |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| ImageMagick | 7.x | SVG to ICO conversion | Favicon generation with multiple resolutions |
| Gravatar API | N/A | Avatar image service | Profile image retrieval via email hash |

### No New Dependencies Required

This phase requires **zero new npm packages**. All work is configuration changes and asset regeneration using existing tools:
- Config updates use existing TypeScript files
- Gravatar is a public HTTP API (no SDK needed)
- ImageMagick is typically system-installed on Linux
- SVG favicon already exists and is theme-adaptive

## Architecture Patterns

### Pattern 1: Separated Identity Configuration
**What:** Maintain separate config values for brand name and person name
**When to use:** When brand identity differs from legal/social identity
**Example:**
```typescript
// src/consts.ts
export const SITE: Site = {
  website: "https://justcarlson.com/",
  author: "justcarlson",        // Brand name for site identity
  authorFullName: "Justin Carlson",  // Person name for social contexts
  title: "justcarlson",
  desc: "Writing about things I find interesting.",
  // ... other config
};
```

**Consumption:**
- Use `SITE.author` (justcarlson) for site title, domain references
- Use `SITE.authorFullName` (Justin Carlson) for social link titles, About page attribution

### Pattern 2: Context-Aware Link Titles
**What:** Social link labels reflect the person, not the brand
**When to use:** External profile links that point to personal accounts
**Example:**
```typescript
// src/constants.ts
export const SOCIALS = [
  {
    name: "Github",
    href: "https://github.com/justcarlson",
    linkTitle: `Justin Carlson on Github`,  // Person name in link text
    icon: "github",
    active: true,
  },
  {
    name: "LinkedIn",
    href: "https://www.linkedin.com/in/justincarlson0/",
    linkTitle: `Justin Carlson on LinkedIn`,  // Person name in link text
    icon: "linkedin",
    active: true,
  },
];
```

**Why:** LinkedIn and GitHub profiles show "Justin Carlson" as the person name. Link titles should match what users see when they click through.

### Pattern 3: Gravatar Hash Generation
**What:** Generate MD5 hash of email for Gravatar avatar retrieval
**When to use:** Displaying user profile images via Gravatar service
**Implementation:**
```typescript
// Option 1: Pre-calculate hash offline and hardcode
// Most secure - email never in source code
const GRAVATAR_HASH = "e3b0c44298fc1c149afbf4c8996fb924";  // example hash

// Option 2: Environment variable (if needed)
// For dynamic generation, use env var with fallback
const email = import.meta.env.PUBLIC_GRAVATAR_EMAIL || "";
const hash = generateMD5(email.trim().toLowerCase());

// Gravatar URL structure
const gravatarUrl = `https://gravatar.com/avatar/${hash}?s=240&d=mp`;
```

**Parameters:**
- `s=240` - Size parameter (240px for 2x retina at 120px display)
- `d=mp` - Default image (mystery-person placeholder if hash not found)

**Source:** [Gravatar - Globally Recognized Avatars](https://gravatar.com/site/implement/hash/)

### Pattern 4: Favicon Multi-Resolution ICO
**What:** Bundle multiple PNG resolutions into single ICO file
**When to use:** Legacy browser support and PDF viewing (browsers look for favicon.ico when displaying PDFs)
**Example:**
```bash
# ImageMagick 7+ command
magick -density 384 public/favicon.svg \
  -background none \
  -define icon:auto-resize=48,32,16 \
  public/favicon.ico

# Verify all sizes embedded
identify public/favicon.ico
```

**Output:** Single ICO file containing 16x16, 32x32, and 48x48 PNG images

**Source:** [Convert SVG to ICO using ImageMagick](https://gist.github.com/azam/3b6995a29b9f079282f3), [How to Favicon in 2026](https://evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs)

### Anti-Patterns to Avoid

- **Don't use runtime MD5 hashing in browser** - Pre-calculate hash offline to keep email private
- **Don't skip ICO regeneration** - Current favicon.ico is 103KB (from forked site), should be ~3-5KB for JC monogram
- **Don't hardcode author name in components** - Always reference config values for consistency
- **Don't use Gravatar without size parameter** - Always specify `?s=240` for high-DPI displays

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| MD5 hashing for Gravatar | Custom crypto implementation | Pre-calculated hash or system md5sum | Security risk, email exposure, unnecessary complexity |
| SVG to ICO conversion | Custom PNG stitching | ImageMagick `icon:auto-resize` | Handles color profiles, transparency, multiple resolutions correctly |
| Gravatar URL construction | String templates with validation | Direct URL pattern `gravatar.com/avatar/{hash}?s={size}&d={default}` | Official API pattern, no library needed |
| Author name templating | Complex conditional logic | Simple config property (`authorFullName`) | Maintainable, readable, no edge cases |

**Key insight:** This phase requires configuration updates, not custom code. Use existing patterns and system tools.

## Common Pitfalls

### Pitfall 1: Email Exposure in Source Code
**What goes wrong:** Hardcoding email address to generate Gravatar hash exposes PII in git history
**Why it happens:** Developers forget source code is public and commit email directly
**How to avoid:** Pre-calculate MD5 hash offline and commit only the hash
**Warning signs:** Searching codebase finds email addresses in TypeScript/Astro files

**Prevention:**
```bash
# Generate hash offline (never commit this command)
echo -n "your.email@example.com" | md5sum | cut -d' ' -f1

# Commit only the hash
const GRAVATAR_HASH = "calculated_hash_here";
```

### Pitfall 2: Inconsistent Author References
**What goes wrong:** Some files show "justcarlson", others "Just Carlson", others "Justin Carlson"
**Why it happens:** Direct string usage instead of config references
**How to avoid:** Always import and use `SITE.author` or `SITE.authorFullName`
**Warning signs:** `grep -r "Just Carlson\|Justin Carlson" src/` finds hardcoded strings

**Prevention:**
```typescript
// BAD - hardcoded
<p>Written by Just Carlson</p>

// GOOD - from config
<p>Written by {SITE.authorFullName}</p>
```

### Pitfall 3: Favicon ICO Bloat
**What goes wrong:** ICO file is 100KB+ instead of 3-5KB
**Why it happens:** Including too many sizes or not optimizing source
**How to avoid:** Use only 16x16, 32x32, 48x48 sizes from vector source
**Warning signs:** `ls -lh public/favicon.ico` shows >10KB file size

**Prevention:**
```bash
# Current favicon.ico is 103KB (from old site)
# Regenerated from JC monogram SVG should be ~3KB
magick public/favicon.svg -define icon:auto-resize=48,32,16 public/favicon.ico
```

### Pitfall 4: Gravatar Cache Issues
**What goes wrong:** Updated Gravatar doesn't appear after changing image
**Why it happens:** Aggressive browser and CDN caching (up to 24 hours)
**How to avoid:** Wait 24 hours or use cache-busting query string
**Warning signs:** URL is correct but old image still displays

**Prevention:**
```html
<!-- If needed for testing -->
<img src="https://gravatar.com/avatar/{hash}?s=240&d=mp&v=2" />
```

### Pitfall 5: Dark Mode Favicon Support
**What goes wrong:** Assuming ICO needs dark mode support like SVG
**Why it happens:** Misunderstanding browser favicon precedence
**How to avoid:** ICO is legacy fallback only - SVG handles dark mode
**Warning signs:** Trying to create two ICO files for themes

**Prevention:**
- `favicon.svg` - Theme-adaptive (already exists, has `@media (prefers-color-scheme: dark)`)
- `favicon.ico` - Legacy fallback (light mode only, used for PDFs)
- Modern browsers use SVG (dark mode works)
- Legacy browsers use ICO (dark mode not supported anyway)

## Code Examples

Verified patterns from existing codebase and official sources:

### Configuration Update (src/consts.ts)
```typescript
// Source: Existing pattern in codebase
interface Site {
  website: string;
  author: string;
  authorFullName: string;  // NEW: Person name for social contexts
  profile: string;
  desc: string;
  title: string;
  // ... rest of interface
}

export const SITE: Site = {
  website: "https://justcarlson.com/",
  author: "justcarlson",              // Brand name
  authorFullName: "Justin Carlson",   // Person name
  profile: "https://justcarlson.com/about",
  desc: "Writing about things I find interesting.",
  title: "justcarlson",
  // ... rest of config
};
```

### Social Link Updates (src/constants.ts)
```typescript
// Source: Existing pattern in codebase
import { SITE } from "./consts";

export const SOCIALS = [
  {
    name: "Github",
    href: "https://github.com/justcarlson",
    linkTitle: `${SITE.authorFullName} on Github`,  // Use person name
    icon: "github",
    active: true,
  },
  {
    name: "LinkedIn",
    href: "https://www.linkedin.com/in/justincarlson0/",
    linkTitle: `${SITE.authorFullName} on LinkedIn`,  // Use person name
    icon: "linkedin",
    active: true,
  },
] as const;
```

### Gravatar Integration (src/components/Sidebar.astro)
```astro
---
// Source: Gravatar API documentation
import { SITE } from "../consts";

// Pre-calculated MD5 hash of email (keep email private)
const GRAVATAR_HASH = "your_calculated_hash_here";
const gravatarUrl = `https://gravatar.com/avatar/${GRAVATAR_HASH}?s=240&d=mp`;
---

<div id="avatar" class="d-flex justify-content-center">
  <a href="/">
    <img
      src={gravatarUrl}
      alt={SITE.authorFullName + "'s avatar"}
    />
  </a>
</div>
```

### Favicon Generation (bash command)
```bash
# Source: ImageMagick documentation + favicon best practices
# https://gist.github.com/azam/3b6995a29b9f079282f3

# Generate multi-resolution ICO from existing SVG
magick -density 384 public/favicon.svg \
  -background none \
  -define icon:auto-resize=48,32,16 \
  public/favicon.ico

# Verify output contains all sizes
identify public/favicon.ico
# Expected output:
# public/favicon.ico[0] ICO 48x48 ...
# public/favicon.ico[1] ICO 32x32 ...
# public/favicon.ico[2] ICO 16x16 ...

# Check file size (should be 3-5KB)
ls -lh public/favicon.ico
```

### BaseHead Meta Tag (already correct)
```astro
---
// Source: Existing codebase - NO CHANGES NEEDED
// Already references SITE.author correctly
---
<meta name="author" content={SITE.author} />
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single author name everywhere | Context-aware author display | 2024-2026 | Personal brands distinguish identity contexts |
| Gravatar email in frontend | Pre-calculated MD5 hash | 2015+ | Privacy protection for public repos |
| ICO only favicons | SVG primary + ICO fallback | 2021+ | Dark mode support, infinite scaling |
| Mystery person placeholder | Real Gravatar profile | N/A | Professional identity presentation |

**Deprecated/outdated:**
- **Multiple favicon sizes in HTML** (16x16, 32x32, 180x180 link tags) - Modern approach: SVG + ICO fallback + apple-touch-icon only
- **Gravatar using SHA256** - Still uses MD5 despite security concerns (official API has not changed)
- **ICO files >50KB** - Modern vector-based favicons should be 3-5KB

## Open Questions

1. **Gravatar Email Hash**
   - What we know: User needs to provide email associated with Gravatar account
   - What's unclear: Whether user wants email committed as constant or env variable
   - Recommendation: Ask user to generate hash offline, provide only hash for commit

2. **Person Name Capitalization**
   - What we know: LinkedIn shows "Justin Carlson", GitHub shows "justcarlson (Justin Carlson)"
   - What's unclear: Whether user prefers "Justin Carlson" or "Justin carlson" (lowercase surname)
   - Recommendation: Use "Justin Carlson" (title case) to match LinkedIn profile

3. **Favicon ICO Current State**
   - What we know: Current favicon.ico is 103KB (from forked site)
   - What's unclear: Whether it contains old site's branding or was already updated
   - Recommendation: Regenerate regardless - ensures JC monogram consistency and reduces file size

## Sources

### Primary (HIGH confidence)
- [Gravatar API - Hash Generation](https://gravatar.com/site/implement/hash/) - Official hash algorithm
- [Gravatar API - Images](https://docs.gravatar.com/sdk/images/) - URL parameters and defaults
- [ImageMagick Gist - SVG to ICO](https://gist.github.com/azam/3b6995a29b9f079282f3) - Multi-resolution conversion
- [How to Favicon in 2026](https://evilmartians.com/chronicles/how-to-favicon-in-2021-six-files-that-fit-most-needs) - Modern favicon best practices
- Existing codebase patterns (src/consts.ts, src/components/Sidebar.astro)

### Secondary (MEDIUM confidence)
- [Personal Brand vs Business Brand Name](https://diydreamsite.com/personal-brand-vs-business-brand-name/) - Branding strategy
- [How to Choose Between Personal or Brand Domain Name](https://www.youpreneur.com/how-to-choose-between-a-personal-or-brand-domain-name/) - Identity context
- [Astro Structured Data Examples](https://johndalesandro.com/blog/astro-add-json-ld-structured-data-to-your-website-for-rich-search-results/) - Author metadata patterns

### Tertiary (LOW confidence)
- Multiple favicon converter tool sites (educational reference only)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools already exist (Astro, TypeScript) or system utilities (ImageMagick)
- Architecture: HIGH - Config separation pattern already exists, Gravatar is simple HTTP API
- Pitfalls: HIGH - Common patterns well-documented, existing codebase provides verification

**Research date:** 2026-01-29
**Valid until:** 60 days (stable domain - Gravatar API unchanged since 2008, favicon standards stable since 2021)

**Dependencies:**
- Phase 1 (01-02) - Created favicon.svg with JC monogram (already theme-adaptive)
- Phase 4 (UAT) - Identified branding inconsistencies requiring this phase

**Artifacts already in place:**
- ✓ `public/favicon.svg` - JC monogram with dark mode support
- ✓ `public/apple-touch-icon.png` - 180x180 iOS icon with JC monogram
- ✓ `src/consts.ts` - Configuration structure with SITE object
- ✓ `src/constants.ts` - Social links with linkTitle pattern
- ✓ `src/components/Sidebar.astro` - Gravatar image display (needs hash update)

**Assets requiring regeneration:**
- ✗ `public/favicon.ico` - Currently 103KB from old site, needs regeneration at 3-5KB
