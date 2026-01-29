# Phase 4: Content & Polish - Research

**Researched:** 2026-01-29
**Domain:** Content management, file deletion workflows, identity cleanup, Obsidian templating
**Confidence:** HIGH

## Summary

Phase 4 focuses on removing the previous owner's content and creating clean placeholder content for Just Carlson. The core challenge is systematically deleting 107+ blog posts and their associated images while creating proper placeholder content (About page, Hello World post) and tooling (Obsidian template) for future content creation.

The research covered:
1. **Content deletion strategy** - Git bulk delete patterns, directory cleanup approaches
2. **Identity leak detection** - Existing validation infrastructure and grep patterns for source file cleanup
3. **Placeholder content creation** - About page structure analysis, blog post frontmatter schema requirements
4. **Obsidian template creation** - Templater plugin syntax for date/title variables and frontmatter generation

**Primary recommendation:** Delete content in logical groups (blog posts by year, then images, then identity files), create minimal placeholder content with clear [PLACEHOLDER] markers, leverage existing build-validator.ts for final verification, and create Templater-based Obsidian template matching the Astro content schema.

## Standard Stack

### Core Tools
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Git | 2.x | Version control for deletions | Standard for tracking file removal history |
| grep | GNU grep | Identity leak detection | Built into existing build-validator.ts |
| Astro Content Collections | 5.x | Content schema validation | Built into project, validates frontmatter |
| Templater | Latest | Obsidian template engine | User's existing Obsidian template system |

### Supporting Tools
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| find | GNU | Bulk file discovery | Counting/listing files before deletion |
| rm | GNU | File deletion | Direct deletion via git rm |
| markdown-lint | N/A | Optional validation | If ensuring placeholder content quality |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| git rm with commits | git filter-branch | Commits preserve history (decision: keep history) |
| grep validation | Custom build script | grep is simpler, already integrated |
| Templater | Obsidian core templates | Templater offers date formatting, already in use |

**Installation:**
```bash
# All core tools already available in project
# Templater plugin: Already installed in user's Obsidian vault
```

## Architecture Patterns

### Content Deletion Structure
```
Deletion sequence:
1. Blog posts (by year or all at once)
   └── src/content/blog/**/*.md
2. Blog images
   └── public/assets/img/**/*
3. Identity-specific assets
   └── public/peter-*.jpg
   └── src/styles/custom.css (references only)
```

### Placeholder Content Organization
```
New content:
src/content/blog/
  └── 2026/
      └── hello-world.md         # Minimal placeholder post
src/pages/
  └── about.mdx                  # Placeholder with [MARKERS]
~/notes/personal-vault/Templates/
  └── Blog Post.md               # Obsidian template
```

### Pattern 1: Bulk Deletion with Git History Preservation
**What:** Delete files in logical groups, commit each group separately
**When to use:** When you want to preserve deletion history (not rewriting history)
**Example:**
```bash
# Delete by category with descriptive commits
git rm -r src/content/blog/2012 src/content/blog/2013
git commit -m "chore(content): delete 2012-2013 blog posts"

git rm -r public/assets/img/2015 public/assets/img/2016
git commit -m "chore(content): delete 2015-2016 blog images"
```

### Pattern 2: Frontmatter Schema Compliance
**What:** Match Astro content collection schema for new posts
**When to use:** Creating any new blog post content
**Schema from src/content.config.ts:**
```typescript
{
  author: string (default: SITE.author),
  pubDatetime: Date (required),
  modDatetime?: Date | null,
  title: string (required),
  featured?: boolean,
  draft?: boolean,
  unlisted?: boolean,
  tags: string[] (default: ["others"]),
  ogImage?: image | string,
  heroImage?: string,
  description: string (required),
  canonicalURL?: string,
  hideEditPost?: boolean,
  timezone?: string,
  source?: string,
  AIDescription?: boolean
}
```

### Pattern 3: Obsidian Templater Syntax
**What:** Use Templater plugin syntax for dynamic template variables
**When to use:** Creating Obsidian templates for blog posts
**Example:**
```markdown
---
title: "<% tp.file.title %>"
pubDatetime: <% tp.date.now("YYYY-MM-DDTHH:mm:ss.000ZZ") %>
description: ""
tags: []
draft: true
---

# <% tp.file.title %>

[Your content here]
```
**Source:** [Templater Date Module Documentation](https://silentvoid13.github.io/Templater/internal-functions/internal-modules/date-module.html)

### Anti-Patterns to Avoid
- **Mass deletion without commits:** Creates unclear history. Always commit logical groups.
- **Deleting without verification:** Count files first with `find` to verify scope.
- **Creating complex About page:** Decision specifies [PLACEHOLDER] markers, not final content.
- **Obsidian template misalignment:** Must match Astro schema exactly or builds will fail.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Date formatting in Obsidian | Custom date picker | Templater `tp.date.now()` | Handles timezones, ISO formats, built-in |
| Frontmatter validation | Custom validator script | Astro content collections | Type-safe, build-time validation |
| Identity leak detection | New grep script | Existing build-validator.ts | Already integrated into build pipeline |
| File deletion tracking | Custom deletion script | Git rm with commits | Git tracks moves/deletes automatically |

**Key insight:** Astro's content collection system already validates frontmatter at build time. The Obsidian template just needs to match the schema—no custom validation needed.

## Common Pitfalls

### Pitfall 1: Deleting Too Much
**What goes wrong:** Accidentally delete theme documentation or AstroPaper structural files
**Why it happens:** Broad glob patterns like `src/**/*.md` can catch theme docs
**How to avoid:**
- Explicitly target `src/content/blog/**/*.md` only
- Preserve any AstroPaper theme documentation
- Decision specifies: "Preserve AstroPaper theme documentation files"
**Warning signs:** Build fails with missing layouts or components after deletion

### Pitfall 2: Incomplete Identity Cleanup
**What goes wrong:** References to "steipete/peter/steinberger" remain in generated files
**Why it happens:** Searching only dist/ folder, not source files
**How to avoid:**
- Decision specifies: "Focus on source files (.astro, .ts, .md), skip generated/build output"
- Run grep on src/ directory: `grep -ri "steipete\|peter\|steinberger" src/`
- Ignore matches in node_modules, dist, .astro directories
**Warning signs:** Build validator still shows leaks after cleanup

### Pitfall 3: Timezone Issues in Obsidian Template
**What goes wrong:** Blog post dates appear wrong or cause build errors
**Why it happens:** Templater date formatting doesn't match Astro's expected ISO 8601 format
**How to avoid:**
- Use exact format: `<% tp.date.now("YYYY-MM-DDTHH:mm:ss.000ZZ") %>`
- The ZZ token gives timezone offset like "+01:00"
- Test template by creating a post and running `npm run build`
**Warning signs:** Astro throws date parsing errors during build

### Pitfall 4: Empty Blog Breaking Build
**What goes wrong:** After deleting all posts, blog list page breaks or looks broken
**Why it happens:** Some blog templates assume at least one post exists
**How to avoid:**
- Create Hello World post BEFORE deleting all posts
- Or delete posts THEN immediately create Hello World
- Decision specifies: "Create a simple placeholder post so blog isn't empty"
**Warning signs:** 404 errors or empty blog index page

### Pitfall 5: Incorrect Git Commit Messages
**What goes wrong:** Conventional Commit format violated, inconsistent with project history
**Why it happens:** Not checking existing commit message patterns
**How to avoid:**
- Check recent commits: `git log --oneline -20`
- Project uses: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`
- Content deletions should use `chore(content):` prefix
- README/docs changes should use `docs:` prefix
**Warning signs:** Commits look inconsistent with project history

## Code Examples

Verified patterns from codebase and official sources:

### Blog Post Frontmatter (Minimal)
```markdown
---
title: "Hello World"
pubDatetime: 2026-01-29T14:00:00.000+00:00
description: "A brief introduction to this blog."
tags: ["meta"]
---

Welcome! This is a placeholder post while I get things set up.
```

### About Page Structure (From src/pages/about.mdx)
```markdown
---
layout: ../layouts/AboutLayout.astro
title: "About"
description: "[YOUR BRIEF BIO - 1-2 sentences]"
---

import NewsletterForm from '../components/NewsletterForm.astro';

<div class="flex flex-col md:flex-row gap-8 items-start">
  <div class="w-full md:w-auto md:flex-shrink-0 md:max-w-[281px]">
    <img src="/[YOUR PHOTO]" alt="[YOUR NAME] photo" class="w-full h-auto rounded-lg" />
  </div>
  <div class="flex-1 min-w-0">
    <p>[YOUR BACKGROUND]</p>
    <p>[YOUR CURRENT WORK]</p>
    <p>[YOUR INTERESTS]</p>
  </div>
</div>

## [SECTION HEADING]

[PLACEHOLDER CONTENT]

## Stay Connected

<NewsletterForm />

[ADDITIONAL CONTENT]
```

### Obsidian Blog Post Template
```markdown
---
title: "<% tp.file.title %>"
pubDatetime: <% tp.date.now("YYYY-MM-DDTHH:mm:ss.000ZZ") %>
description: ""
tags: []
draft: true
heroImage:
---

# <% tp.file.title %>

[Your content here]
```
**Source:** [Templater Date Module](https://silentvoid13.github.io/Templater/internal-functions/internal-modules/date-module.html), [Templater Frontmatter Module](https://silentvoid13.github.io/Templater/internal-functions/internal-modules/frontmatter-module.html)

### Identity Leak Grep Pattern (From build-validator.ts)
```typescript
// Source: src/integrations/build-validator.ts
const grepResult = execSync(
  `grep -rli "steipete\\|peter steinberger" "${distPath}" 2>/dev/null || true`,
  { maxBuffer: 10 * 1024 * 1024, encoding: "utf-8" }
);
```

### Bulk File Deletion
```bash
# Count first to verify
find src/content/blog -name "*.md" | wc -l

# Delete by year (preserves git history)
git rm -r src/content/blog/2012
git rm -r src/content/blog/2013
git commit -m "chore(content): delete 2012-2013 blog posts"

# Or delete all at once
git rm -r src/content/blog/20??
git commit -m "chore(content): delete all previous blog posts"
```

### Custom CSS Comment-Only Cleanup
```css
/* From src/styles/custom.css - Line 1 */
/* Custom styles for steipete.me-like layout */
/* ^ Change to: Custom styles for layout */
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual file deletion | git rm with commits | Always standard | Tracked history, reversible |
| Grep in build scripts | Astro integration hooks | Astro 3.0+ (2023) | Clean integration, automatic |
| Basic date insertion | ISO 8601 with timezone | Modern web standard | Proper date handling globally |
| Obsidian core templates | Templater plugin | Community standard | More powerful, date formatting |

**Deprecated/outdated:**
- **git filter-branch**: Replaced by git filter-repo for history rewriting (not needed here per decision)
- **Moment.js direct usage**: Astro uses native Date, Templater still uses Moment internally but abstracts it

## Open Questions

1. **Should blog posts be deleted year-by-year or all at once?**
   - What we know: 107 posts across 2012-2025
   - What's unclear: Whether one big commit or multiple year-based commits is preferred
   - Recommendation: All at once (`git rm -r src/content/blog`) for simplicity, matches "delete all" decision

2. **Should custom.css be deleted or just updated?**
   - What we know: Contains "steipete.me-like layout" comment on line 1
   - What's unclear: Whether entire file is Peter's custom work or contains site-essential styles
   - Recommendation: Update comment only (requirement CLN-02 says "remove Peter's custom CSS overrides" but file contains essential layout styles used by site)

3. **Exact wording for Hello World post**
   - What we know: "Brief intro placeholder", "short paragraph", not final
   - What's unclear: Exact tone/content
   - Recommendation: Marked as "Claude's discretion" in CONTEXT.md—planner should create minimal, friendly placeholder

## Sources

### Primary (HIGH confidence)
- **Astro Content Collections Schema**: /home/jc/developer/justcarlson.com/src/content.config.ts - Verified frontmatter requirements
- **Build Validator Integration**: /home/jc/developer/justcarlson.com/src/integrations/build-validator.ts - Verified grep patterns
- **Existing About Page**: /home/jc/developer/justcarlson.com/src/pages/about.mdx - Verified structure
- **Templater Date Module**: https://silentvoid13.github.io/Templater/internal-functions/internal-modules/date-module.html - Date formatting syntax
- **Templater Frontmatter Module**: https://silentvoid13.github.io/Templater/internal-functions/internal-modules/frontmatter-module.html - Frontmatter access

### Secondary (MEDIUM confidence)
- [Astro Content Collections Guide (2026)](https://inhaq.com/blog/getting-started-with-astro-content-collections/) - Content management patterns
- [Markdown Frontmatter Schema Best Practices](https://www.markdownlang.com/advanced/frontmatter.html) - Common field patterns
- [Git File Deletion Best Practices](https://www.git-tower.com/learn/git/commands/git-rm) - git rm usage patterns

### Tertiary (LOW confidence)
- Web search results on bulk deletion strategies - Multiple sources, general patterns only
- Obsidian forum discussions on Templater - Community knowledge, syntax verified against official docs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools verified in codebase or user's existing setup
- Architecture: HIGH - Patterns extracted from existing codebase and official docs
- Pitfalls: MEDIUM-HIGH - Based on Astro content collection behavior (HIGH) and common git mistakes (MEDIUM)

**Research date:** 2026-01-29
**Valid until:** 2026-02-28 (30 days - stable tooling, Astro 5.x content collections unlikely to change)
