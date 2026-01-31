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

# Publish posts from Obsidian vault (interactive)
publish *args='':
    ./scripts/publish.sh {{args}}
