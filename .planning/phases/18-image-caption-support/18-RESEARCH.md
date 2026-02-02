# Phase 18: Image & Caption Support - Research

**Researched:** 2026-02-02
**Domain:** Astro content collections schema, HTML figure/figcaption, Tailwind Typography
**Confidence:** HIGH

## Summary

This phase adds hero image alt text and optional caption support to the blog. The implementation is straightforward: add two new optional fields (`heroImageAlt`, `heroImageCaption`) to the Astro content collection schema, then update PostDetails.astro to wrap the hero image in a `<figure>` element with conditional `<figcaption>`.

The codebase already has:
1. **Tailwind Typography plugin** (v0.5.19) with `prose-figcaption:!text-foreground prose-figcaption:opacity-70` styling already configured in typography.css
2. **Zod schema patterns** established in content.config.ts for optional fields using `z.string().optional()`
3. **Hero image rendering** in PostDetails.astro (line 142-149) currently using an empty alt attribute

The primary technical challenge is ensuring backward compatibility: posts without the new fields should continue rendering correctly, and posts with empty heroImage fields should be handled gracefully.

**Primary recommendation:** Add `heroImageAlt: z.string().optional()` and `heroImageCaption: z.string().optional()` to content.config.ts, wrap hero image in `<figure>` with conditional `<figcaption>`, use title as fallback for alt text.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Astro | 5.x | Content collections with Zod schema | Already in use, provides type-safe frontmatter |
| @tailwindcss/typography | 0.5.19 | Prose styling including figcaption | Already installed and configured |
| Zod | 3.x (via astro:content) | Schema validation | Built into Astro content collections |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Tailwind CSS | 4.1.18 | Utility classes for styling | Custom spacing/layout if needed |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| z.string().optional() | z.string().nullable() | `.optional()` is cleaner - field can be absent vs explicitly null |
| Title fallback for alt | Required heroImageAlt | Fallback is more user-friendly for existing posts |

**Installation:** No new packages needed - all tools already in place.

## Architecture Patterns

### Recommended Changes
```
src/
├── content.config.ts    # Add heroImageAlt, heroImageCaption fields
└── layouts/
    └── PostDetails.astro # Wrap hero image in <figure>, add conditional <figcaption>
```

### Pattern 1: Optional Schema Fields with Defaults
**What:** Define optional frontmatter fields that have sensible fallbacks
**When to use:** New fields that shouldn't break existing content
**Example:**
```typescript
// Source: Established pattern in content.config.ts
z.object({
  heroImage: z.string().optional(),
  heroImageAlt: z.string().optional(),     // NEW
  heroImageCaption: z.string().optional(), // NEW
})
```

### Pattern 2: Semantic Figure/Figcaption Structure
**What:** Wrap image in `<figure>` with optional `<figcaption>` for accessibility and SEO
**When to use:** Any image that may have a caption or needs semantic grouping
**Example:**
```astro
// Source: MDN Web Docs, HTML5 accessibility best practices
{heroImage && (
  <figure class="mb-8">
    <img
      src={heroImage}
      alt={heroImageAlt || title}
      class="aspect-video w-full rounded-md object-cover"
      loading="lazy"
    />
    {heroImageCaption && (
      <figcaption class="mt-2 text-center text-sm">
        {heroImageCaption}
      </figcaption>
    )}
  </figure>
)}
```

### Pattern 3: Conditional Rendering with Short-Circuit
**What:** Render elements only when data exists
**When to use:** Optional content like captions
**Example:**
```astro
{heroImageCaption && <figcaption>{heroImageCaption}</figcaption>}
```

### Anti-Patterns to Avoid
- **Empty alt attributes:** Current code uses `alt=""` - should use meaningful alt text or title fallback
- **Non-semantic structure:** Using `<div>` instead of `<figure>` loses accessibility benefits
- **Redundant alt + figcaption:** If they contain identical text, screen readers announce it twice

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Figcaption styling | Custom CSS | prose-figcaption utilities | Already configured in typography.css |
| Schema validation | Manual checks | Zod z.string().optional() | Type-safe, build-time validation |
| Alt text fallback | Complex conditionals | `heroImageAlt \|\| title` | Simple JavaScript fallback |

**Key insight:** The Tailwind Typography plugin already provides styled figure/figcaption within `.prose` blocks. No custom CSS needed.

## Common Pitfalls

### Pitfall 1: Breaking Backward Compatibility
**What goes wrong:** Existing posts without new fields fail schema validation
**Why it happens:** Making new fields required instead of optional
**How to avoid:** Always use `.optional()` for new fields
**Warning signs:** Build fails after schema change with existing content

### Pitfall 2: Empty Alt Text for Accessibility
**What goes wrong:** Screen readers skip images or announce them incorrectly
**Why it happens:** Using `alt=""` or forgetting alt attribute entirely
**How to avoid:** Always provide alt text, use title as fallback: `alt={heroImageAlt || title}`
**Warning signs:** Lighthouse accessibility warnings, screen reader testing reveals issues

### Pitfall 3: Redundant Alt Text and Caption
**What goes wrong:** Screen reader users hear the same description twice
**Why it happens:** Copying caption text into alt text
**How to avoid:** Alt text should be functional (describe what's in image), caption should be editorial (provide context)
**Warning signs:** User testing reveals redundancy

### Pitfall 4: CSS Specificity Conflicts
**What goes wrong:** figcaption styling doesn't apply
**Why it happens:** Tailwind Typography plugin uses specific selectors that may override custom classes
**How to avoid:** Use `prose-figcaption:` modifier classes or let default prose styling work
**Warning signs:** Caption text appears unstyled or wrong color

### Pitfall 5: Figure Margin/Spacing Issues
**What goes wrong:** Hero image inside figure has different spacing than before
**Why it happens:** `<figure>` has default browser margins, prose plugin may add different styles
**How to avoid:** Keep existing margin classes (`mb-8`) on figure, test visual regression
**Warning signs:** Layout shifts after wrapping in figure

## Code Examples

Verified patterns from official sources and existing codebase:

### Schema Field Addition
```typescript
// Source: content.config.ts existing pattern
// Add after heroImage field
heroImageAlt: z.string().optional(),
heroImageCaption: z.string().optional(),
```

### PostDetails.astro Hero Image Update
```astro
// Source: Current PostDetails.astro lines 142-149, upgraded
{heroImage && (
  <figure class="mb-8">
    <img
      src={heroImage}
      alt={heroImageAlt || title}
      class="aspect-video w-full rounded-md object-cover"
      loading="lazy"
    />
    {heroImageCaption && (
      <figcaption class="mt-2 text-center text-sm">
        {heroImageCaption}
      </figcaption>
    )}
  </figure>
)}
```

### Extracting New Props
```astro
// Source: PostDetails.astro destructuring pattern
const {
  title,
  // ... existing fields ...
  heroImage,
  heroImageAlt,      // NEW
  heroImageCaption,  // NEW
} = post.data;
```

### Test Frontmatter (New Post)
```yaml
---
title: "My Post with Hero Image"
description: "A test post"
pubDatetime: 2026-02-02T10:00:00-06:00
heroImage: "/assets/blog/my-image.jpg"
heroImageAlt: "A descriptive alt text for accessibility"
heroImageCaption: "Photo by Someone on Unsplash"
---
```

### Test Frontmatter (Existing Post - No New Fields)
```yaml
---
title: "Older Post"
description: "A post without new caption fields"
pubDatetime: 2026-01-15T10:00:00-06:00
heroImage: "/assets/blog/old-image.jpg"
---
```

### Inline Figure/Figcaption in Markdown
```markdown
<figure>
  <img src="/assets/blog/inline-image.jpg" alt="Inline image description" />
  <figcaption>This caption will be styled by prose-figcaption</figcaption>
</figure>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `alt=""` (empty) | `alt={heroImageAlt \|\| title}` | Phase 18 | Better accessibility |
| `<img>` alone | `<figure><img><figcaption></figure>` | Phase 18 | Semantic HTML, caption support |

**Deprecated/outdated:**
- None - this is a new feature addition

## Open Questions

Things that couldn't be fully resolved:

1. **Obsidian Template Update**
   - What we know: Template should include heroImageAlt and heroImageCaption fields
   - What's unclear: Whether to update the template as part of this phase or defer
   - Recommendation: Include in phase scope if Obsidian workflow is affected, otherwise defer

2. **Default Figcaption Styling Adequacy**
   - What we know: `prose-figcaption:!text-foreground prose-figcaption:opacity-70` is configured
   - What's unclear: Whether visual appearance meets design expectations
   - Recommendation: Test with real content, adjust if needed (likely fine as-is)

## Sources

### Primary (HIGH confidence)
- `/home/jc/developer/justcarlson.com/src/content.config.ts` - existing schema patterns
- `/home/jc/developer/justcarlson.com/src/layouts/PostDetails.astro` - current hero image implementation
- `/home/jc/developer/justcarlson.com/src/styles/typography.css` - existing prose-figcaption styling
- [Astro Content Collections Docs](https://docs.astro.build/en/guides/content-collections/) - z.optional() pattern

### Secondary (MEDIUM confidence)
- [Tailwind Typography Plugin](https://github.com/tailwindlabs/tailwindcss-typography) - prose-figcaption modifier
- [MDN figure element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/figure) - semantic HTML
- [Alt vs Figcaption - Thoughtbot](https://thoughtbot.com/blog/alt-vs-figcaption) - accessibility guidance

### Tertiary (LOW confidence)
- WebSearch results for best practices - cross-verified with MDN

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - using existing tools already in codebase
- Architecture: HIGH - minimal changes to existing patterns
- Pitfalls: HIGH - verified against accessibility best practices and existing code

**Research date:** 2026-02-02
**Valid until:** 2026-03-02 (30 days - stable domain, HTML/CSS standards don't change rapidly)
