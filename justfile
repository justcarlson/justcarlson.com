# justfile - Blog publishing workflow for justcarlson.com
# Usage: just <recipe> or just --list

set dotenv-load := true
set shell := ["bash", "-uc"]

# Default: show available commands
default:
    @just --list

# === Setup ===

# Configure Obsidian vault path (interactive)
setup:
    ./scripts/setup.sh

# === Development ===

# Start Astro dev server
preview:
    npm run dev

# Run Biome lint
lint:
    npm run lint

# Run full build with type checking
build:
    npm run build:check

# Format code with Biome
format:
    npm run format

# Sync Astro content collections
sync:
    npm run sync

# === Publishing ===

# Publish posts from Obsidian vault (use --dry-run to preview)
publish *args='':
    ./scripts/publish.sh {{args}}

# === Utilities ===

# List posts from Obsidian (default: unpublished, use --all or --published for more)
list-posts *args='':
    ./scripts/list-posts.sh {{args}}

# Remove a post from blog repo (keeps Obsidian source)
unpublish file *args='':
    ./scripts/unpublish.sh {{file}} {{args}}
