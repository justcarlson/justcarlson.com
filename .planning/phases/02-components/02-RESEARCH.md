# Phase 2: Components - Research

**Researched:** 2026-01-29
**Domain:** Astro component patterns, AstroPaper theme, SEO/meta tags, codebase audit
**Confidence:** HIGH

## Summary

This phase updates presentation layer components in an AstroPaper-based Astro site to reference Justin Carlson identity instead of previous owner (Peter Steinberger). The work involves three main areas:

1. **Meta tags & SEO components**: Update BaseHead.astro and StructuredData.astro to consume SITE config values (already updated in Phase 1) and ensure proper OpenGraph/Schema.org markup
2. **Footer component**: Update GitHub repository link and license text to reference justcarlson/justcarlson.com
3. **Newsletter component**: Already provider-agnostic (uses NEWSLETTER_CONFIG), but needs Buttondown-specific references removed
4. **Codebase audit**: Find and replace ALL hardcoded references (steipete, Peter Steinberger, PSPDFKit, etc.) across the entire repository

**Primary recommendation:** This is straightforward component refactoring. The config-driven architecture from Phase 1 means most components already consume correct values via imports. Focus effort on the comprehensive codebase audit to catch all hardcoded references, not just in components.

## Standard Stack

### Core (Already in Use)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Astro | 5.16.6 | Static site framework | Build-time rendering, component-based |
| AstroPaper | v5+ | Blog theme | SEO-optimized, config-driven architecture |
| TailwindCSS | 4.1.18 | Styling | Utility-first CSS framework |
| TypeScript | 5.9.3 | Type safety | Static typing for components and config |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ripgrep (rg) | latest | Fast search tool | Finding all hardcoded references in codebase |
| @biomejs/biome | 2.3.10 | Linting/formatting | Already configured for code quality |

### No Additional Dependencies Needed
This phase modifies existing components and uses existing tools (ripgrep for audit). No new packages required.

**Installation:**
```bash
# No new packages needed - all dependencies already installed
# Verify ripgrep available (likely system-installed)
rg --version
```

## Architecture Patterns

### AstroPaper v5 Component Architecture

The codebase follows AstroPaper v5 patterns where configuration lives in centralized files and components import/consume those values:

```
src/
├── config.ts              # SITE object (updated in Phase 1)
├── constants.ts           # NEWSLETTER_CONFIG, SOCIALS (updated in Phase 1)
├── components/
│   ├── BaseHead.astro    # Meta tags - imports SITE
│   ├── Footer.astro      # Footer content - imports SITE for GitHub link
│   ├── NewsletterForm.astro # Newsletter - imports NEWSLETTER_CONFIG
│   └── StructuredData.astro # Schema.org JSON-LD - has hardcoded values
└── layouts/
    └── *.astro           # Layout components that compose above
```

### Pattern 1: Config-Driven Components

**What:** Components import from centralized config and use those values in templates
**When to use:** All components that need site-wide values (already implemented)
**Example:**
```typescript
// Source: Existing BaseHead.astro pattern
---
import { SITE } from "../consts";

const {
  title = SITE.title,
  description = SITE.desc,
  image = "/images/og.png",
} = Astro.props;

const fullTitle = title === SITE.title ? title : `${title} | ${SITE.title}`;
---

<title>{fullTitle}</title>
<meta name="description" content={description} />
<meta property="og:site_name" content={SITE.title} />
```

### Pattern 2: Conditional Rendering in Astro

**What:** JSX-style conditional rendering using logical operators and ternaries
**When to use:** Newsletter component visibility, optional UI elements
**Example:**
```astro
// Source: https://docs.astro.build/en/reference/astro-syntax/
---
const isEnabled = NEWSLETTER_CONFIG.enabled && NEWSLETTER_CONFIG.formAction;
---

{isEnabled ? (
  <div class="newsletter-box">
    <!-- Newsletter form -->
  </div>
) : null}
```

### Pattern 3: Structured Data (Schema.org JSON-LD)

**What:** Add machine-readable metadata for search engines using JSON-LD format
**When to use:** BlogPosting, Person, WebSite schema types
**Example:**
```astro
// Source: https://johndalesandro.com/blog/astro-add-json-ld-structured-data-to-your-website-for-rich-search-results/
---
const structuredData = {
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  headline: data.title,
  author: {
    "@type": "Person",
    name: SITE.author,  // Use config value, not hardcoded
    url: SITE.profile,
  },
  // ... more fields
};
---

<script type="application/ld+json" set:html={JSON.stringify(structuredData)} />
```

**Security note:** Always use `set:html` with `JSON.stringify()` to avoid XSS vulnerabilities. Never use string interpolation for JSON-LD.

### Pattern 4: OpenGraph Meta Tags

**What:** Social media preview cards (Facebook, LinkedIn, Twitter)
**When to use:** Every page should have og:* tags for rich sharing
**Example:**
```astro
// Source: https://ogp.me/
<meta property="og:type" content={type} />
<meta property="og:site_name" content={SITE.title} />
<meta property="og:url" content={Astro.url} />
<meta property="og:title" content={fullTitle} />
<meta property="og:description" content={description} />
<meta property="og:image" content={new URL(image, Astro.site)} />
```

**Best practices:**
- Image URL must be absolute (use `new URL(image, Astro.site)`)
- Recommended dimensions: 1200x628px
- Supported formats: JPG, PNG (most compatible)
- Max file size: 8MB
- Include `og:image:alt` for accessibility

### Anti-Patterns to Avoid

- **Hardcoded values in templates:** ❌ `<meta name="author" content="Peter Steinberger" />` → ✅ `<meta name="author" content={SITE.author} />`
- **String interpolation in JSON-LD:** ❌ `<script>{"author": "${author}"}</script>` → ✅ `<script set:html={JSON.stringify(data)} />`
- **Relative URLs in og:image:** ❌ `<meta property="og:image" content="/og.png" />` → ✅ `<meta property="og:image" content={new URL(image, Astro.site)} />`
- **Provider-specific newsletter markup:** ❌ Hardcoded Buttondown HTML → ✅ Generic form that accepts any action URL

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Finding hardcoded strings | Manual file-by-file search | `ripgrep` (rg) | Regex support, .gitignore-aware, parallel search, 10-100x faster than grep |
| Meta tag management | Custom head components | Existing BaseHead.astro pattern | Already implements OpenGraph, Twitter cards, canonical URLs |
| Structured data | Manual JSON-LD strings | Component-based approach with JSON.stringify() | Type safety, XSS prevention, maintainability |
| Newsletter provider switching | Different form HTML per provider | Config-driven formAction pattern | Already implemented - just update NEWSLETTER_CONFIG.formAction |

**Key insight:** Astro's build-time rendering means you get full TypeScript checking at build time. Use this to your advantage - reference config values in components and let the build fail if they're missing.

## Common Pitfalls

### Pitfall 1: Incomplete Codebase Audit
**What goes wrong:** Finding obvious references (components) but missing edge cases (markdown content, scripts, package.json, documentation files)
**Why it happens:** Developers focus on src/ directory and skip public/, scripts/, docs/, config files
**How to avoid:**
- Use ripgrep to search entire repository: `rg 'steipete' .`
- Search multiple patterns: steipete, steipete.me, "Peter Steinberger", PSPDFKit
- Include commonly forgotten locations:
  - package.json (name, repository fields)
  - README.md, LICENSE, CHANGELOG.md
  - public/ directory (site.webmanifest, robots.txt)
  - astro.config.mjs (comments, site URL)
  - vercel.json or other deploy configs
  - .github/ workflows and templates
  - Scripts in scripts/ directory
**Warning signs:** Build succeeds but find "steipete" in deployed site HTML or URLs

### Pitfall 2: Relative URLs in OpenGraph Images
**What goes wrong:** `og:image` shows broken images on social media platforms
**Why it happens:** Social platforms need absolute URLs to fetch images
**How to avoid:** Always use `new URL(imagePath, Astro.site)` for og:image
**Warning signs:** Facebook/LinkedIn debugger shows "Could not fetch image"

### Pitfall 3: Missing Structured Data Updates
**What goes wrong:** Search results and rich snippets show old author/site info
**Why it happens:** StructuredData.astro has hardcoded values that don't reference SITE config
**How to avoid:** Review StructuredData.astro carefully - replace ALL hardcoded strings:
  - Author name: "Peter Steinberger" → `SITE.author`
  - Author URL: "https://steipete.me/about" → `SITE.profile`
  - Publisher name: "Peter Steinberger" → `SITE.author`
  - Publisher logo URL: "https://steipete.me/peter-avatar.jpg" → Use new avatar path
  - Image URLs: Update to new domain
  - WebSite URL: "https://steipete.me" → `SITE.website`
  - sameAs links: Update social profile URLs
**Warning signs:** Google Rich Results Test shows old author info

### Pitfall 4: Newsletter Provider Lock-in
**What goes wrong:** Code assumes Buttondown-specific behavior (field names, response handling)
**Why it happens:** Copy-pasted from Buttondown documentation without abstracting
**How to avoid:**
- Generic field names: `<input name="email">` (not `name="email_address"`)
- Generic submit: `<button type="submit">Subscribe</button>` (no provider branding)
- Config-driven action: `action={NEWSLETTER_CONFIG.formAction}` already implemented
- Optional tag support: `{NEWSLETTER_CONFIG.tag && <input type="hidden" name="tag" value={tag} />}`
**Warning signs:** Component references "Buttondown" in UI text or has buttondown.email in action URL

### Pitfall 5: Title Tag Format Confusion
**What goes wrong:** Inconsistent title formats across pages (sometimes "Site | Page", sometimes "Page | Site")
**Why it happens:** Different components construct titles differently
**How to avoid:** Standardize on content-first format: `${pageTitle} | ${SITE.title}`
- Exception: Homepage can use just `SITE.title`
- BaseHead.astro already implements: `title === SITE.title ? title : ${title} | ${SITE.title}`
**Warning signs:** Browser tabs show inconsistent title patterns

### Pitfall 6: Case-Sensitive Search Missing Variants
**What goes wrong:** Search finds "steipete" but misses "Steipete" or "STEIPETE"
**Why it happens:** Default search is case-sensitive
**How to avoid:** Use case-insensitive search: `rg -i 'peter'` or search specific variants
**Warning signs:** Audit report shows "0 matches" for a pattern you know exists

## Code Examples

Verified patterns from the existing codebase and official sources:

### Meta Tags - Title Construction
```astro
// Source: Existing BaseHead.astro (verified pattern)
---
import { SITE } from "../consts";

interface Props {
  title?: string;
  description?: string;
}

const {
  title = SITE.title,
  description = SITE.desc,
} = Astro.props;

// Content-first format: "Post Title | Justin Carlson"
// Homepage exception: Just "Justin Carlson"
const fullTitle = title === SITE.title ? title : `${title} | ${SITE.title}`;
---

<title>{fullTitle}</title>
<meta name="title" content={fullTitle} />
<meta name="description" content={description} />
<meta name="author" content={SITE.author} />
```

### Meta Tags - OpenGraph Complete Set
```astro
// Source: Existing BaseHead.astro + https://ogp.me/
---
const canonicalURL = new URL(Astro.url.pathname, Astro.site);
const ogImageURL = new URL(image, Astro.site);
---

<!-- Open Graph / Facebook -->
<meta property="og:type" content={type} />
<meta property="og:site_name" content={SITE.title} />
<meta property="og:url" content={canonicalURL} />
<meta property="og:title" content={fullTitle} />
<meta property="og:description" content={description} />
<meta property="og:image" content={ogImageURL} />

<!-- Twitter -->
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content={fullTitle} />
<meta name="twitter:description" content={description} />
<meta name="twitter:image" content={ogImageURL} />

<!-- Canonical -->
<link rel="canonical" href={canonicalURL} />
```

### Structured Data - BlogPosting
```astro
// Source: Existing StructuredData.astro (needs updating)
// BEFORE (hardcoded):
author: {
  "@type": "Person",
  name: data.author || "Peter Steinberger",
  url: "https://steipete.me/about",
}

// AFTER (config-driven):
---
import { SITE } from "@/consts";

author: {
  "@type": "Person",
  name: data.author || SITE.author,
  url: SITE.profile,
}
```

### Structured Data - Person Schema
```astro
// Source: Existing StructuredData.astro (needs complete replacement)
// BEFORE (hardcoded):
{
  "@context": "https://schema.org",
  "@type": "Person",
  name: "Peter Steinberger",
  url: "https://steipete.me",
  image: "https://steipete.me/peter-avatar.jpg",
  sameAs: [
    "https://github.com/steipete",
    "https://twitter.com/steipete",
    "https://bsky.app/profile/steipete.me",
  ],
  jobTitle: "Software Engineer",
  description: "AI-powered tools from Swift roots to web frontiers...",
}

// AFTER (config-driven):
---
import { SITE, SOCIAL_LINKS } from "@/consts";

const structuredData = {
  "@context": "https://schema.org",
  "@type": "Person",
  name: SITE.author,
  url: SITE.website,
  image: new URL("/avatar.jpg", SITE.website).href,  // Update path to actual avatar
  sameAs: SOCIAL_LINKS.filter(s => s.label !== "RSS").map(s => s.href),
  jobTitle: "Software Engineer",  // Could add to SITE config if needed
  description: SITE.desc,
};
---
```

### Newsletter Form - Provider Agnostic
```astro
// Source: Existing NewsletterForm.astro (already well-structured)
---
import { NEWSLETTER_CONFIG } from "@/consts";

const isEnabled = NEWSLETTER_CONFIG.enabled && NEWSLETTER_CONFIG.formAction;
---

{isEnabled ? (
  <div class="newsletter-box">
    <form
      action={NEWSLETTER_CONFIG.formAction}
      method="post"
      target="_blank"
    >
      {NEWSLETTER_CONFIG.tag && (
        <input type="hidden" name="tag" value={NEWSLETTER_CONFIG.tag} />
      )}
      <input
        type="email"
        name="email"
        placeholder="Your Email"
        required
      />
      <button type="submit">Subscribe</button>
    </form>
    <p>No spam, unsubscribe anytime.</p>
  </div>
) : null}
```

**Key**: This pattern already works with any provider (Buttondown, ConvertKit, Mailchimp) by just updating formAction. No code changes needed when switching providers.

### Footer - Repository Link
```astro
// Source: Existing Footer.astro (needs update)
// BEFORE:
<a href="https://github.com/steipete/steipete.me" target="_blank" rel="noopener noreferrer">
  Steal this post ➜ CC BY 4.0 · Code MIT
</a>

// AFTER:
---
import { SITE } from "@/consts";
---
<a href={SITE.editPost.url.replace('/edit/main/', '')} target="_blank" rel="noopener noreferrer">
  Steal this post ➜ CC BY 4.0 · Code MIT
</a>
// OR more direct:
<a href="https://github.com/justcarlson/justcarlson.com" target="_blank" rel="noopener noreferrer">
  Steal this post ➜ CC BY 4.0 · Code MIT
</a>
```

### Codebase Audit - Ripgrep Commands
```bash
# Source: https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md

# Find all "steipete" references (case-insensitive)
rg -i 'steipete'

# Find exact domain references
rg 'steipete\.me'

# Find author name (case variations)
rg -i 'peter steinberger'

# Find company reference
rg -i 'pspdfkit'

# Show context (3 lines before/after)
rg -C 3 'steipete'

# Search specific file types only
rg --type js --type ts --type astro 'steipete'

# Exclude certain directories
rg 'steipete' --glob '!.planning/' --glob '!node_modules/'

# Count matches per file
rg 'steipete' --count

# List files with matches (no content)
rg 'steipete' --files-with-matches
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded meta tags | Config-driven components | AstroPaper v4-v5 | Easier personalization, single source of truth |
| LOGO_IMAGE config object | Direct SVG/Image imports | AstroPaper v5 | Simpler, more flexible |
| Manual JSON-LD strings | Component with JSON.stringify() | Industry standard 2024+ | Type safety, XSS prevention |
| grep for search | ripgrep (rg) | 2020+ adoption | 10-100x faster, gitignore-aware |
| Provider-specific newsletter forms | Generic form with config action | Modern practice | Easy provider switching |

**Deprecated/outdated:**
- LOGO_IMAGE object: Removed in AstroPaper v5, use direct imports
- Hardcoded social links in components: Use SOCIALS array from config
- Multiple meta tag components: Consolidate in BaseHead.astro

## Open Questions

None - the research is complete and confidence is high. The existing codebase already follows best practices from Phase 1 configuration work.

## Sources

### Primary (HIGH confidence)
- Existing codebase components (BaseHead.astro, Footer.astro, NewsletterForm.astro, StructuredData.astro, consts.ts)
- [AstroPaper GitHub repository](https://github.com/satnaing/astro-paper) - Official theme source
- [AstroPaper configuration guide](https://astro-paper.pages.dev/posts/how-to-configure-astropaper-theme/) - Official documentation
- [Astro template expressions reference](https://docs.astro.build/en/reference/astro-syntax/) - Official Astro docs
- [The Open Graph protocol](https://ogp.me/) - Official OG specification
- [Schema.org](https://schema.org/) - Official structured data spec
- [ripgrep GUIDE.md](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md) - Official documentation

### Secondary (MEDIUM confidence)
- [Astro SEO Optimization Guide](https://astrojs.dev/articles/astro-seo-optimization/) - Third-party but comprehensive
- [Add JSON-LD Structured Data in Astro](https://johndalesandro.com/blog/astro-add-json-ld-structured-data-to-your-website-for-rich-search-results/) - Developer blog (2025)
- [Adding structured data to blog posts using Astro](https://frodeflaten.com/posts/adding-structured-data-to-blog-posts-using-astro/) - Developer blog
- [Open Graph Image Guide](https://www.opengraph.xyz/blog/the-ultimate-guide-to-open-graph-images) - Third-party guide
- [Fast Searching with ripgrep](https://mariusschulz.com/blog/fast-searching-with-ripgrep) - Developer blog
- [Optimizing Astro.js Websites for SEO](https://medium.com/@aisyndromeart/optimizing-astro-js-websites-for-seo-a-guide-for-developers-25fcd20c8e30) - Medium article (2025)

### Tertiary (LOW confidence)
- [Newsletter signup form component examples](https://nicelydone.club/components/newsletter-signup-form) - Design inspiration only
- Various web search results about meta tags best practices - Used for context, cross-verified with primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries already in use, versions verified from package.json
- Architecture: HIGH - Patterns verified from existing codebase and official Astro/AstroPaper docs
- Pitfalls: HIGH - Based on common issues in similar migrations and structured data implementation
- Code examples: HIGH - Taken from existing codebase or official documentation

**Research date:** 2026-01-29
**Valid until:** 2026-02-28 (30 days - stable domain, Astro/AstroPaper patterns unlikely to change)

**Special notes:**
- This phase benefits from excellent Phase 1 foundation work - config already updated
- Most components already follow best practices (config-driven, conditional rendering)
- Main work is systematic audit and surgical updates to hardcoded values
- No complex technical challenges - straightforward find/replace with verification
