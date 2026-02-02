# Phase 22: External Resilience - Research

**Researched:** 2026-02-02
**Domain:** External resource graceful degradation, image fallbacks, script error handling
**Confidence:** HIGH

## Summary

This phase implements graceful fallback for all external resources: the GitHub contribution chart, potential Twitter embeds, and analytics scripts. The primary pattern established in Phase 21 (onerror handler with `this.onerror=null`) applies directly to the GitHub chart. The user decision mandates re-adding Twitter widget script (removed in commit 0e234df) with proper error handling rather than avoiding it entirely.

The site already has shimmer CSS animations from Phase 20 (in `src/styles/custom.css`). Analytics scripts already use dynamic imports which fail gracefully. The main work involves: 1) GitHub chart onerror fallback with text link, 2) Twitter widget script re-addition with graceful failure, 3) optional `.catch()` enhancement on analytics, and 4) loading timeout for slow external resources.

**Primary recommendation:** Apply the Phase 21 onerror pattern to GitHub chart image, wrap Twitter widget loading in a try-catch with timeout, and add subtle shimmer placeholders during loading.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| HTML `<img>` onerror | N/A | Image fallback on load failure | Native browser API, zero JS overhead |
| CSS shimmer animation | N/A | Loading placeholder indicator | Already implemented in custom.css |
| JavaScript Promise | N/A | Async script loading with error handling | Native browser API |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| astro-embed | ^0.9.2 | Twitter embeds without client JS | When embedding tweets - renders server-side |
| @vercel/analytics | ^1.6.1 | Analytics with dynamic import | Already in use, graceful by default |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Twitter widget.js | astro-embed Tweet | astro-embed renders server-side without JS, but requires tweet URL at build time |
| Custom timeout logic | Intersection Observer | IO is for visibility, setTimeout is simpler for load timeout |
| Complex retry logic | Simple fallback | User decided: show fallback immediately, no retries |

**Installation:**
No additional packages needed. All functionality uses existing stack.

## Architecture Patterns

### Pattern 1: Image with onerror Fallback (GitHub Chart)

**What:** Same pattern from Phase 21 avatar, adapted for GitHub chart
**When to use:** External images that may be blocked
**Example:**
```html
<!-- Source: Phase 21 Research, MDN onerror documentation -->
<div class="github-chart-wrapper img-loading" style="min-height: 120px;">
  <img
    src="https://ghchart.rshah.org/justcarlson"
    alt="GitHub contribution graph"
    class="w-full"
    loading="lazy"
    onerror="this.onerror=null; this.style.display='none'; this.parentElement.classList.remove('img-loading'); this.parentElement.classList.add('img-fallback'); this.parentElement.innerHTML='<a href=\'https://github.com/justcarlson\' class=\'text-accent underline\'>View my contributions on GitHub</a>';"
  />
</div>
```

**Key elements:**
1. `this.onerror=null` prevents infinite loop
2. Container has min-height to prevent layout shift
3. `img-loading` class shows shimmer during load
4. On failure, replaces with text link per user decision

### Pattern 2: Image with Loading Timeout

**What:** Fallback for slow-loading images that never technically fail
**When to use:** External resources that may timeout without triggering onerror
**Example:**
```javascript
// Source: javaspring.net fallback image pattern, adapted
function setupImageTimeout(img, fallbackFn, timeoutMs = 5000) {
  let loadTimeout;

  const applyFallback = () => {
    clearTimeout(loadTimeout);
    img.onerror = null;
    fallbackFn(img);
  };

  img.addEventListener('error', applyFallback);
  img.addEventListener('load', () => clearTimeout(loadTimeout));

  loadTimeout = setTimeout(applyFallback, timeoutMs);
}
```

**User decision:** ~5 second timeout, then show fallback.

### Pattern 3: Graceful Twitter Widget Loading

**What:** Load Twitter widget.js with error handling and console logging
**When to use:** When Twitter embeds exist in content
**Example:**
```javascript
// Source: Twitter Developer Platform, github.com/Prinzhorn/twitter-widgets
(function() {
  const script = document.createElement('script');
  script.src = 'https://platform.twitter.com/widgets.js';
  script.async = true;
  script.charset = 'utf-8';

  script.onerror = function() {
    console.log('Twitter widget script failed to load');
    // Fallback: blockquote content remains visible
  };

  script.onload = function() {
    if (window.twttr && window.twttr.widgets) {
      window.twttr.widgets.load();
    }
  };

  // Only load if Twitter embeds exist on page
  if (document.querySelector('.twitter-tweet, [data-twitter-embed]')) {
    document.head.appendChild(script);
  }
})();
```

**Key elements:**
1. Conditional loading - only if Twitter embeds exist
2. Console log on failure per user decision
3. Native blockquote fallback remains visible when script blocked

### Pattern 4: Analytics with Optional .catch()

**What:** Add explicit error handling to dynamic imports
**When to use:** When console should log analytics failures
**Example:**
```javascript
// Source: Current Analytics.astro with optional enhancement
if (typeof window !== 'undefined' && import.meta.env.PROD) {
  import('@vercel/analytics')
    .then(({ inject }) => inject())
    .catch(err => console.log('Analytics blocked or unavailable'));
}
```

**User decision:** Claude's discretion on whether to add `.catch()`. Current implementation fails silently (acceptable).

### Recommended Project Structure
```
src/
├── components/
│   └── Analytics.astro      # Already has dynamic import
├── layouts/
│   └── Layout.astro         # Twitter script re-add here (conditional)
├── pages/
│   └── about.mdx            # GitHub chart update here
└── styles/
    └── custom.css           # Shimmer already exists (line 546-604)
```

### Anti-Patterns to Avoid
- **Loading Twitter script unconditionally:** Only load if embeds exist on page
- **Silent failures for user-visible content:** GitHub chart failure should show link fallback
- **Missing this.onerror=null:** Causes infinite loop if fallback also fails
- **Blocking page render for external scripts:** Always use async attribute

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Twitter embeds without JS | Custom static rendering | astro-embed Tweet component | Handles API calls, caching, styling |
| Image loading placeholders | Custom CSS | Existing `.img-loading` class | Already themed for light/dark mode |
| Script error boundaries | Complex error tracking | Simple onerror/console.log | User decided: log to console, not silent |
| Image timeout detection | Complex observer | Simple setTimeout | 5 second fixed timeout per user |

**Key insight:** The existing patterns from Phase 21 and Phase 20 (shimmer CSS) cover most needs. Twitter widget has built-in fallback (blockquote content visible when script fails).

## Common Pitfalls

### Pitfall 1: Infinite onerror Loop
**What goes wrong:** Fallback image/content also fails, onerror fires repeatedly
**Why it happens:** onerror handler changes content, which triggers reload attempt
**How to avoid:** Set `this.onerror=null` as first action in handler
**Warning signs:** Browser becomes unresponsive, console floods with errors

### Pitfall 2: Layout Shift on Fallback
**What goes wrong:** Page jumps when fallback content has different dimensions
**Why it happens:** No reserved space for content
**How to avoid:** Use min-height on container, match aspect ratios
**Warning signs:** CLS score degradation, visible layout jump

### Pitfall 3: Loading Twitter Script on Every Page
**What goes wrong:** Wasted bandwidth, console errors on non-embed pages when blocked
**Why it happens:** Script loaded unconditionally (original bug in commit 0e234df debug)
**How to avoid:** Check for `.twitter-tweet` elements before loading script
**Warning signs:** syndication.twitter.com errors in console on pages without embeds

### Pitfall 4: Timeout Not Cleared on Success
**What goes wrong:** Fallback triggered even after successful load
**Why it happens:** setTimeout fires after slow but successful load
**How to avoid:** Clear timeout in both 'load' and 'error' handlers
**Warning signs:** Content flashes between loaded and fallback states

### Pitfall 5: Blocking Dynamic Import Errors
**What goes wrong:** Unhandled promise rejection warning in console
**Why it happens:** No `.catch()` on import() promise
**How to avoid:** Add `.catch()` with console.log per user decision
**Warning signs:** Red text in browser console about unhandled rejection

## Code Examples

Verified patterns from official sources:

### Complete GitHub Chart with Fallback
```astro
---
// Source: Phase 21 Research, MDN onerror, user decisions
const githubUrl = "https://github.com/justcarlson";
const chartUrl = "https://ghchart.rshah.org/justcarlson";
---

<h2>GitHub Activity</h2>
<div
  id="github-chart"
  class="bg-secondary p-0 rounded-lg img-loading"
  style="min-height: 120px;"
>
  <img
    src={chartUrl}
    alt="Just Carlson's GitHub Contribution Graph"
    class="w-full"
    style="max-width: 100%; height: auto;"
    loading="lazy"
  />
</div>

<script>
  function setupGitHubChartFallback() {
    const container = document.getElementById('github-chart');
    const img = container?.querySelector('img');
    if (!img || !container) return;

    const TIMEOUT_MS = 5000;
    let timeoutId;

    const showFallback = () => {
      clearTimeout(timeoutId);
      img.onerror = null;
      container.classList.remove('img-loading');
      container.innerHTML = `<p class="p-4 text-center"><a href="https://github.com/justcarlson" class="text-accent underline">View my contributions on GitHub</a></p>`;
    };

    img.onerror = showFallback;

    img.onload = () => {
      clearTimeout(timeoutId);
      container.classList.remove('img-loading');
    };

    // Timeout for slow loads
    timeoutId = setTimeout(showFallback, TIMEOUT_MS);
  }

  setupGitHubChartFallback();
  document.addEventListener('astro:page-load', setupGitHubChartFallback);
</script>
```
Source: [MDN img onerror](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/img), [javaspring.net fallback patterns](https://www.javaspring.net/blog/fallback-image-and-timeout-external-content-javascript/)

### Twitter Widget Conditional Loading
```astro
---
// Source: Twitter Developer Platform, Layout.astro context
---

<script is:inline>
  // Only load Twitter widget if embeds exist on this page
  (function() {
    if (!document.querySelector('.twitter-tweet, blockquote[data-twitter]')) {
      return;
    }

    const script = document.createElement('script');
    script.src = 'https://platform.twitter.com/widgets.js';
    script.async = true;
    script.charset = 'utf-8';

    script.onerror = function() {
      console.log('Twitter widget script blocked or unavailable');
      // Blockquote fallback remains visible
    };

    script.onload = function() {
      if (window.twttr && window.twttr.widgets) {
        window.twttr.widgets.load();
      }
    };

    document.head.appendChild(script);
  })();
</script>
```
Source: [Twitter Developer Platform - Scripting Loading](https://developer.x.com/en/docs/twitter-for-websites/javascript-api/guides/scripting-loading-and-initialization), [twitter-widgets npm](https://github.com/Prinzhorn/twitter-widgets)

### Analytics with Error Logging (Optional Enhancement)
```astro
---
// Source: Current Analytics.astro with optional .catch()
---

<script>
  if (typeof window !== 'undefined' && import.meta.env.PROD) {
    import('@vercel/analytics')
      .then(({ inject }) => inject())
      .catch(() => console.log('Vercel Analytics unavailable'));
  }
</script>

<script>
  if (typeof window !== 'undefined' && import.meta.env.PROD) {
    import('@vercel/speed-insights')
      .then(({ injectSpeedInsights }) => injectSpeedInsights())
      .catch(() => console.log('Vercel Speed Insights unavailable'));
  }
</script>
```
Source: [Dynamic imports error handling](https://javascript.info/modules-dynamic-imports), current Analytics.astro

### Shimmer Loading State (Already Exists)
```css
/* Source: src/styles/custom.css lines 546-604 */
/* Already implemented - use .img-loading class */

@keyframes shimmer {
  100% {
    transform: translateX(100%);
  }
}

.img-loading {
  position: relative;
  background-color: #e5e7eb;
  overflow: hidden;
}

.img-loading::after {
  content: '';
  position: absolute;
  inset: 0;
  transform: translateX(-100%);
  background-image: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0) 0,
    rgba(255, 255, 255, 0.2) 20%,
    rgba(255, 255, 255, 0.5) 60%,
    rgba(255, 255, 255, 0)
  );
  animation: shimmer 1.5s infinite;
}
```
Source: Existing codebase, Phase 20

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No onerror handler | onerror + this.onerror=null | Phase 21 (2026) | No more broken image icons |
| Unconditional script loading | Conditional on content presence | This phase | No errors on pages without embeds |
| Silent script failures | Console logging per user decision | This phase | Debuggability |
| Static loading indicators | Shimmer CSS animation | Phase 20 (2026) | Better perceived performance |

**Deprecated/outdated:**
- Removing Twitter script entirely (commit 0e234df) - was a workaround, need proper handling
- Loading widgets.js on every page unconditionally - only load when embeds exist

## Open Questions

Things that couldn't be fully resolved:

1. **Twitter embeds in current content**
   - What we know: No `.twitter-tweet` elements found in src/content/blog
   - What's unclear: Whether any content will use Twitter embeds in the future
   - Recommendation: Implement conditional loading now, ready for future embeds

2. **Content images in blog posts**
   - What we know: User decided "Claude's discretion on fallback approach (likely alt text)"
   - What's unclear: How many external images exist in content, their importance
   - Recommendation: Use alt text as fallback; scan content for external image URLs during implementation

3. **astro-embed vs widgets.js**
   - What we know: astro-embed renders tweets server-side without JS
   - What's unclear: Whether to use astro-embed exclusively or support both patterns
   - Recommendation: Use astro-embed for future embeds (zero-JS), widgets.js for legacy/dynamic

## Sources

### Primary (HIGH confidence)
- [MDN img onerror](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/img) - onerror handler patterns
- Phase 21 Research (.planning/phases/21-avatar-fallback/21-RESEARCH.md) - onerror implementation pattern
- Existing codebase (src/styles/custom.css) - Shimmer CSS already implemented

### Secondary (MEDIUM confidence)
- [Twitter Developer Platform](https://developer.x.com/en/docs/twitter-for-websites/javascript-api/guides/scripting-loading-and-initialization) - Widget script loading
- [javaspring.net fallback patterns](https://www.javaspring.net/blog/fallback-image-and-timeout-external-content-javascript/) - Timeout + error handling combo
- [astro-embed documentation](https://astro-embed.netlify.app/) - Twitter component (zero-JS embeds)

### Tertiary (LOW confidence)
- [twitter-widgets npm](https://github.com/Prinzhorn/twitter-widgets) - Error callback pattern (older library)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Native HTML/JS patterns, existing codebase patterns
- Architecture: HIGH - Extends Phase 21 proven patterns
- Pitfalls: HIGH - Documented in Phase 21 research and MDN

**Research date:** 2026-02-02
**Valid until:** 2026-03-04 (30 days - stable domain)

---

## Existing Infrastructure Summary

### From Phase 20 (already implemented)
- `src/styles/custom.css` lines 546-604: Shimmer CSS animations
- `.img-loading`, `.img-fallback` CSS classes
- Dark mode variants for loading states

### From Phase 21 (already implemented)
- onerror pattern with `this.onerror=null` in index.astro
- Avatar fallback working model

### Current CSP (vercel.json line 119-120)
```
script-src: ... https://platform.twitter.com https://cdn.syndication.twimg.com ...
frame-src: https://platform.twitter.com https://syndication.twitter.com ...
```
CSP already allows Twitter scripts - no changes needed.

### Current Test Infrastructure
- `tests/image-fallback.spec.ts` - Already blocks external images including ghchart.rshah.org
- Can be extended to verify GitHub chart fallback specifically
