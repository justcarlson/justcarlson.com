# justcarlson.com

My personal website and blog, built with [Astro](https://astro.build) and deployed on [Vercel](https://vercel.com).

## Prerequisites

- [Node.js 22+](https://nodejs.org/) (or use [nvm](https://github.com/nvm-sh/nvm) / [fnm](https://github.com/Schniz/fnm) to auto-switch)
- [just](https://just.systems/man/en/) command runner
- npm (included with Node.js)
- [yq](https://github.com/mikefarah/yq) v4+ (mikefarah/yq, for YAML processing)
  - Arch Linux: `pacman -S go-yq`
  - macOS: `brew install yq`
  - Ubuntu: Download binary from [releases](https://github.com/mikefarah/yq/releases)

## Quick Start

```bash
git clone https://github.com/justcarlson/justcarlson.com.git
cd justcarlson.com
just bootstrap
just preview
```

Open http://localhost:4321 in your browser.

## Obsidian Integration

This blog supports publishing directly from an Obsidian vault.

```bash
just setup      # Configure your vault path (one-time)
just publish    # Publish posts marked with status: Published
just list-posts # List available posts in your vault
```

Run `just --list` to see all available commands.

## Development

| Command | Action |
|---------|--------|
| `just preview` | Start local dev server |
| `just build` | Build for production with type checking |
| `just lint` | Run Biome linter |
| `just format` | Format code with Biome |

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

## Common Issues

**Node version mismatch**
Run `nvm use` or `fnm use` to switch to the correct Node version. The project uses Node 22 (specified in `.nvmrc`).

**`just` command not found**
Install the just command runner from [just.systems](https://just.systems/man/en/chapter_4.html).

**Permission denied on scripts**
Run `chmod +x scripts/*.sh` to make scripts executable.

**Port 4321 already in use**
Another dev server is running. Kill it with `lsof -i :4321 | grep LISTEN | awk '{print $2}' | xargs kill` or use a different port.

**Build fails with type errors**
Run `npm run sync` to regenerate Astro types, then retry the build.

## Deployment

Deployed automatically on Vercel when changes are pushed to main.

## Credits

Built on the excellent [AstroPaper theme](https://github.com/satnaing/astro-paper) by [Sat Naing](https://github.com/satnaing).

Forked from [steipete.me](https://github.com/steipete/steipete.me) with gratitude for the thoughtful customizations.

## License

- **Blog content**: [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/)
- **Code**: [MIT License](LICENSE)
