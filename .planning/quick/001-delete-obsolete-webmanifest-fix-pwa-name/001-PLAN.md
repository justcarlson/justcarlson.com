# Quick Task 001: Delete obsolete webmanifest, fix PWA name

**Created:** 2026-01-29
**Status:** Complete

## Tasks

1. **Delete public/site.webmanifest**
   - File contains Peter Steinberger branding
   - Obsolete: AstroPWA generates manifest.webmanifest at build time
   - Action: Delete file

2. **Fix PWA manifest name in astro.config.mjs**
   - Line 105: `name: "Just Carlson"` → `name: "Justin Carlson"`
   - Aligns with SITE.author for consistent person naming
