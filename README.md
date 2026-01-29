# justcarlson.com

My personal website and blog, built with [Astro](https://astro.build) and deployed on [Vercel](https://vercel.com).

## Overview

This site is a personal space for writing about software development, technology, and whatever else catches my interest.

## Setup

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

The dev server runs at `localhost:4321`.

## Development

| Command | Action |
|---------|--------|
| `npm run dev` | Start local dev server |
| `npm run build` | Build for production |
| `npm run preview` | Preview production build locally |

### Adding Blog Posts

Blog posts live in `src/content/blog/` organized by year. Create a new markdown file with frontmatter:

```markdown
---
title: "Post Title"
pubDatetime: 2026-01-29T12:00:00.000+00:00
description: "Brief description"
tags: ["tag1", "tag2"]
draft: false
---

Your content here.
```

## Deployment

Deployed automatically on Vercel when changes are pushed to main.

## Credits

Built on the excellent [AstroPaper theme](https://github.com/satnaing/astro-paper) by [Sat Naing](https://github.com/satnaing).

Forked from [steipete.me](https://github.com/steipete/steipete.me) with gratitude for the thoughtful customizations.

## License

- **Blog content**: [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/)
- **Code**: [MIT License](LICENSE)
