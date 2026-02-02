# Phase 21: Avatar Fallback - Research

**Researched:** 2026-02-02
**Domain:** Image fallback handling, HTML onerror, Vercel Image Optimization
**Confidence:** HIGH

## Summary

This phase implements resilient avatar loading for the homepage. The current implementation uses a plain `<img>` tag pointing directly to Gravatar. Phase 20 established the Vercel Image Optimization proxy configuration, so this phase wires the avatar to use the proxy URL (`/_vercel/image?url=...`) and adds an onerror handler for local fallback.

The implementation is straightforward: change the avatar src to use Vercel's proxy endpoint, add an onerror handler that swaps to a local fallback image, and add the local fallback image to the public directory. No Astro Image component needed since onerror handlers work naturally with plain `<img>` tags but require additional complexity with framework components.

**Primary recommendation:** Use plain `<img>` tag with onerror handler - simpler than Astro Image component and provides direct control over fallback behavior.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| HTML `<img>` | N/A | Image element with onerror | Native browser API, no dependencies |
| cwebp | Latest | Convert source image to WebP | Google's official WebP encoder |
| Vercel Image Optimization | N/A | Proxy external images | Already configured in Phase 20 |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Astro `<Image>` | astro@5.16.6 | Optimized local images | When optimization needed (not this case) |
| sharp | ^0.34.5 | Image processing | Already in devDependencies |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Plain `<img>` | Astro `<Image>` | Image component doesn't support onerror natively; would need React wrapper |
| onerror attribute | JavaScript event listener | Inline is simpler for single image, no hydration needed |
| WebP fallback | JPEG fallback | WebP is smaller, both work - user decided WebP |

**Installation:**
No additional packages needed. cwebp is a one-time CLI tool for converting the fallback image.

## Architecture Patterns

### Current Implementation (index.astro lines 32-37)
```astro
<img
  src="https://gravatar.com/avatar/ef133a0cc6308305d254916b70332b1a?s=400&d=identicon"
  alt={SITE.author}
  class="w-40 h-40 rounded-full object-cover flex-shrink-0 transition-all duration-300 group-hover:scale-105 group-hover:shadow-xl"
/>
```

### Recommended Pattern: Vercel Proxy + onerror Fallback

```html
<img
  src="/_vercel/image?url=https%3A%2F%2Fgravatar.com%2Favatar%2Fef133a0cc6308305d254916b70332b1a%3Fs%3D400&w=256&q=75"
  onerror="this.onerror=null; this.src='/avatar-fallback.webp';"
  alt="Justin Carlson"
  width="160"
  height="160"
  loading="eager"
  class="w-40 h-40 rounded-full object-cover ..."
/>
```

**Key elements:**
1. `/_vercel/image?url=...` - Uses Vercel proxy (configured in Phase 20)
2. `onerror="this.onerror=null; this.src='...'"` - Prevents infinite loop, swaps to local
3. `width` and `height` attributes - Prevents layout shift
4. `loading="eager"` - Above fold, part of first impression
5. Local fallback in `/public/` - Always available

### Project Structure for Fallback Image
```
public/
├── avatar-fallback.webp    # Local fallback image (160x160 or larger)
├── favicon.ico
└── ...
```

### Anti-Patterns to Avoid
- **Using Astro Image for external URLs with onerror:** Image component doesn't expose onerror easily; requires React wrapper or client-side JS
- **Remote fallback image:** If Gravatar is down, external fallback might also fail
- **Missing this.onerror=null:** Can cause infinite loop if fallback also fails
- **Dynamic src without URL encoding:** Vercel proxy requires properly encoded URLs

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image proxy | Custom proxy function | Vercel `/_vercel/image` | Edge CDN caching, optimization built-in |
| WebP conversion | Manual processing | cwebp CLI | Quality control, smaller file size |
| Fallback detection | Custom intersection/load observer | onerror attribute | Native browser API, no JS bundle |
| URL encoding | Manual string replacement | encodeURIComponent() | Handles all edge cases |

**Key insight:** The browser's native onerror event is the simplest and most reliable way to handle image fallback. Framework-level solutions add complexity without benefit for this use case.

## Common Pitfalls

### Pitfall 1: Infinite Loop on onerror
**What goes wrong:** If fallback image also fails, onerror fires again, creating infinite loop
**Why it happens:** onerror handler changes src, which triggers another load attempt
**How to avoid:** Set `this.onerror=null` before changing src
**Warning signs:** Browser becomes unresponsive, console floods with errors

### Pitfall 2: Unencoded URL in Vercel Proxy
**What goes wrong:** Vercel returns 400 Bad Request
**Why it happens:** The `url` parameter must be URL-encoded
**How to avoid:** Use `encodeURIComponent()` on the full external URL
**Warning signs:** Console shows 400 error from `/_vercel/image`

### Pitfall 3: Missing Width in Proxy URL
**What goes wrong:** Vercel rejects the request
**Why it happens:** The `w` parameter is required and must match a configured size
**How to avoid:** Use a width from vercel.json `images.sizes` array: [256, 640, 1080, 2048, 3840]
**Warning signs:** 400 error mentioning width parameter

### Pitfall 4: Layout Shift on Fallback
**What goes wrong:** Page jumps when fallback loads with different dimensions
**Why it happens:** Fallback image has different aspect ratio or browser reflows
**How to avoid:** Match fallback dimensions exactly (160x160 for w-40 h-40), set explicit width/height attributes
**Warning signs:** CLS score degradation, visual jump during fallback

### Pitfall 5: Fallback in src/assets Instead of public/
**What goes wrong:** Fallback path changes on build, onerror handler can't find it
**Why it happens:** Astro hashes assets in src/assets, public/ stays stable
**How to avoid:** Always put onerror fallback images in `/public/`
**Warning signs:** 404 on fallback image in production

## Code Examples

Verified patterns from official sources:

### Complete Avatar Implementation
```astro
---
// src/pages/index.astro
import { SITE } from "@/config";

// Build Vercel proxy URL
const gravatarUrl = "https://gravatar.com/avatar/ef133a0cc6308305d254916b70332b1a?s=400";
const proxyUrl = `/_vercel/image?url=${encodeURIComponent(gravatarUrl)}&w=256&q=75`;
const fallbackUrl = "/avatar-fallback.webp";
---

<a href="/about" class="block mx-auto sm:mx-0 group">
  <img
    src={proxyUrl}
    onerror={`this.onerror=null; this.src='${fallbackUrl}';`}
    alt={SITE.author}
    width="160"
    height="160"
    loading="eager"
    class="w-40 h-40 rounded-full object-cover flex-shrink-0 transition-all duration-300 group-hover:scale-105 group-hover:shadow-xl"
  />
</a>
```
Source: [MDN img element](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/img), [Vercel Image Optimization](https://vercel.com/docs/image-optimization)

### onerror Handler Pattern (Canonical)
```html
<img
  src="primary-image.jpg"
  onerror="this.onerror=null; this.src='/fallback-image.jpg';"
  alt="Description"
/>
```
Source: [MDN img element](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/img)

**Why this.onerror=null:**
> "If you don't remove the img tag's onerror handler, and then change the img.src to another image that fails to load, most browsers get into a nasty loop."

### WebP Conversion Command
```bash
# Convert source JPEG to WebP with quality 80 (good balance)
cwebp -q 80 source-avatar.jpg -o public/avatar-fallback.webp

# Or use sharp (already in project) via Node script
node -e "require('sharp')('source.jpg').webp({quality: 80}).toFile('public/avatar-fallback.webp')"
```
Source: [Google WebP Documentation](https://developers.google.com/speed/webp/docs/cwebp)

### Vercel Proxy URL Format
```
/_vercel/image?url={encoded-external-url}&w={width}&q={quality}

Example:
/_vercel/image?url=https%3A%2F%2Fgravatar.com%2Favatar%2Fef133a0cc6308305d254916b70332b1a%3Fs%3D400&w=256&q=75
```
Source: [Vercel Image Optimization](https://vercel.com/docs/image-optimization)

**Width parameter must match configured sizes:**
- vercel.json has: `"sizes": [256, 640, 1080, 2048, 3840]`
- For 160px display (w-40), use w=256 (smallest available that covers 2x)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Direct external URL | Vercel proxy URL | Phase 20 (2026) | Edge CDN caching, CSP compliance |
| No fallback | onerror handler | This phase | Resilience to Gravatar downtime |
| JPEG fallback | WebP fallback | User decision | Smaller file size |
| Lazy loading for avatar | Eager loading | User decision | Above fold, immediate display |

**Current best practice:**
- Use proxy for all external images (CSP: `img-src 'self'`)
- Always have local fallback for critical images like avatar
- WebP format for optimal compression
- Explicit dimensions to prevent layout shift

## Open Questions

Things that couldn't be fully resolved:

1. **Source image for fallback**
   - What we know: Need same photo as Gravatar, WebP format
   - What's unclear: User needs to provide source image file
   - Recommendation: User should export their Gravatar source photo and place in project root for conversion

2. **Exact Gravatar hash verification**
   - What we know: Current hash is `ef133a0cc6308305d254916b70332b1a`
   - What's unclear: Whether this is the correct/current hash for user's email
   - Recommendation: Verify by visiting the Gravatar URL directly

## Sources

### Primary (HIGH confidence)
- [Vercel Image Optimization Documentation](https://vercel.com/docs/image-optimization) - Proxy URL format, caching behavior
- [MDN img element](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/img) - onerror event, loading attribute
- [Google WebP Documentation](https://developers.google.com/speed/webp/docs/cwebp) - cwebp conversion

### Secondary (MEDIUM confidence)
- [Phase 20 Research](/.planning/phases/20-configuration-foundation/20-RESEARCH.md) - vercel.json configuration verified
- Existing codebase patterns (Card.astro, about.mdx) - Image component usage

### Tertiary (LOW confidence)
- N/A - All critical findings verified with official documentation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Native HTML, Vercel docs verified
- Architecture: HIGH - onerror is standard browser API
- Pitfalls: HIGH - Well-documented in MDN and community sources

**Research date:** 2026-02-02
**Valid until:** 2026-03-02 (30 days - stable domain)

---

## Existing Infrastructure (from Phase 20)

The following is already configured and ready for this phase:

### vercel.json (lines 2-10)
```json
{
  "images": {
    "sizes": [256, 640, 1080, 2048, 3840],
    "remotePatterns": [
      { "protocol": "https", "hostname": "gravatar.com", "pathname": "/avatar/**" },
      { "protocol": "https", "hostname": "ghchart.rshah.org", "pathname": "/**" }
    ],
    "formats": ["image/webp", "image/avif"],
    "minimumCacheTTL": 3600
  }
}
```

### CSP Header (vercel.json line 120)
```
img-src 'self' data: blob:
```
- Proxy serves from 'self', so proxy URLs work
- Direct Gravatar URLs would be blocked (forcing proxy usage)

### Existing Test Infrastructure
- `tests/image-fallback.spec.ts` - Already tests blocked external images scenario
- Can be extended to verify avatar fallback specifically
