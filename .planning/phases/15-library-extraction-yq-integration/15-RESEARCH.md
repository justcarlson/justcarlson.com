# Phase 15: Library Extraction + yq Integration - Research

**Researched:** 2026-02-01
**Domain:** Bash shell scripting, YAML processing, code deduplication
**Confidence:** HIGH

## Summary

This phase addresses significant code duplication across three shell scripts (publish.sh, unpublish.sh, list-posts.sh) and establishes reliable YAML frontmatter manipulation using mikefarah/yq v4. Current scripts contain ~280 lines of duplicated code including color constants (5 scripts), validation functions (2 scripts), utility functions (3 scripts), and configuration loading (3 scripts).

The standard approach is to create a `scripts/lib/common.sh` shared library that all scripts source using `BASH_SOURCE` for reliable path resolution. For YAML manipulation, mikefarah/yq v4 is the industry standard, offering a `--front-matter` flag specifically designed for Jekyll/Hugo-style markdown files with YAML headers.

**Primary recommendation:** Create `scripts/lib/common.sh` with extracted functions, install mikefarah/yq v4 via devcontainer feature `ghcr.io/eitsupi/devcontainer-features/jq-likes:2`, and replace all sed/grep-based YAML parsing with yq expressions.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| mikefarah/yq | v4.52.x | YAML/JSON processing | Industry standard CLI for YAML, has --front-matter flag for markdown files |
| shellcheck | latest | Shell script linting | De facto standard for bash linting, catches common errors |
| bash | 5.x | Shell interpreter | Available in devcontainer, supports arrays and associative arrays |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| jq | latest | JSON processing | Reading JSON config files (settings.local.json) |
| find | coreutils | File discovery | Batch processing markdown files with yq |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| mikefarah/yq | kislyuk/yq (Python) | Python yq is jq-wrapper, lacks --front-matter flag; Go yq is faster, self-contained |
| sed/grep YAML | yq | sed/grep is fragile for quoted values, multiline, arrays; yq understands YAML structure |
| single lib file | multiple lib files | Multiple files adds complexity; single file sufficient for this scope |

**Installation (devcontainer):**
```json
{
  "features": {
    "ghcr.io/eitsupi/devcontainer-features/jq-likes:2": {
      "yqVersion": "4"
    }
  }
}
```

**Installation (Arch Linux local):**
```bash
pacman -S go-yq  # installs mikefarah/yq as 'yq'
```

**Note:** System currently has kislyuk/yq (Python wrapper) installed as `yq 3.4.3`. This MUST be replaced with mikefarah/yq v4.x which has different syntax and the required `--front-matter` flag.

## Architecture Patterns

### Recommended Project Structure
```
scripts/
├── lib/
│   └── common.sh    # Shared functions (sourced, not executed)
├── publish.sh       # Sources lib/common.sh
├── unpublish.sh     # Sources lib/common.sh
├── list-posts.sh    # Sources lib/common.sh
├── setup.sh         # May source lib/common.sh for colors
└── bootstrap.sh     # May source lib/common.sh for colors
```

### Pattern 1: Reliable Library Sourcing
**What:** Use `BASH_SOURCE` to locate the library relative to the script, not the working directory
**When to use:** Always when sourcing libraries in portable scripts
**Example:**
```bash
# Source: https://tjelvarolsson.com/blog/using-relative-paths-in-linux-scripts/
# At top of each script that needs common.sh:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
```

### Pattern 2: Library Structure with Guards
**What:** Structure library with documentation, dependency checks, and idempotent sourcing
**When to use:** All shared libraries
**Example:**
```bash
#!/usr/bin/env bash
# scripts/lib/common.sh - Shared functions for blog scripts
# Source: https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/

# Guard against double-sourcing
[[ -n "${_COMMON_SH_LOADED:-}" ]] && return
readonly _COMMON_SH_LOADED=1

# Strict mode (inherited by sourcing scripts)
set -euo pipefail

# ============================================================================
# Color Constants
# ============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'

# ============================================================================
# Configuration Constants
# ============================================================================
readonly CONFIG_FILE=".claude/settings.local.json"
readonly BLOG_DIR="src/content/blog"
readonly ASSETS_DIR="public/assets/blog"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_CANCELLED=130

# ... functions follow
```

### Pattern 3: yq Frontmatter Operations
**What:** Use yq's `--front-matter` flag for reading/writing YAML in markdown files
**When to use:** Any frontmatter extraction or modification
**Example:**
```bash
# Source: https://mikefarah.gitbook.io/yq/usage/front-matter

# Extract a field value from frontmatter
title=$(yq --front-matter=extract '.title' "$file")

# Update frontmatter in-place (preserves non-YAML content)
yq --front-matter=process -i '.draft = false' "$file"

# Read multiple fields efficiently
read -r title pubDatetime description < <(
  yq --front-matter=extract '[.title, .pubDatetime, .description] | @tsv' "$file"
)
```

### Anti-Patterns to Avoid
- **Parsing YAML with sed/grep:** Fragile, breaks on quoted values, multiline strings, arrays. Use yq.
- **Hardcoding paths:** Use constants in common.sh, not scattered literals.
- **Using `source xxx.sh` with relative paths:** Breaks when script is run from different directories. Use `BASH_SOURCE`.
- **Duplicating validation logic:** Extract to library functions once, source everywhere.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML field extraction | sed/grep regexes | `yq '.field' file` | Handles quotes, arrays, multiline values |
| Frontmatter modification | sed -i with patterns | `yq --front-matter=process -i` | Preserves content after frontmatter |
| ISO8601 validation | Custom regex | yq date functions or bash [[ ]] with pattern | Standard patterns exist |
| JSON config reading | grep/sed | jq | Already using jq, consistent approach |
| Color output | ANSI escape literals | Constants in library | DRY, easy to change |

**Key insight:** The current sed-based YAML parsing (lines like `sed -n '/^---$/,/^---$/p' "$file" | grep -E "^${key}:"`) is fundamentally fragile. YAML values can be:
- Quoted: `title: "Hello: World"` (colon in value)
- Single-quoted: `title: 'It''s a test'` (escaped quotes)
- Multiline: `description: |` followed by indented lines
- Arrays: `tags:\n  - one\n  - two`

yq handles all these correctly; sed/grep cannot.

## Common Pitfalls

### Pitfall 1: Wrong yq Version
**What goes wrong:** Commands fail or behave unexpectedly
**Why it happens:** System has kislyuk/yq (Python) installed, not mikefarah/yq (Go)
**How to avoid:**
- Check version: `yq --version` should show `mikefarah/yq`
- Arch: `pacman -S go-yq` (not just `yq`)
- Devcontainer: Use feature with explicit version
**Warning signs:** Syntax errors, missing `--front-matter` flag, version shows "yq 3.x" or mentions Python

### Pitfall 2: shellcheck SC1091 Warnings
**What goes wrong:** shellcheck reports "Not following: lib/common.sh"
**Why it happens:** shellcheck can't resolve dynamic source paths
**How to avoid:** Run shellcheck with `-x` flag: `shellcheck -x scripts/*.sh scripts/lib/*.sh`
**Warning signs:** CI fails on shellcheck despite valid scripts

### Pitfall 3: Library Function Scope
**What goes wrong:** Variables from library pollute caller's namespace
**Why it happens:** Bash variables default to global scope
**How to avoid:** Use `local` keyword inside all functions; use `readonly` for constants
**Warning signs:** Unexpected variable values, functions overwriting each other

### Pitfall 4: set -e in Sourced Libraries
**What goes wrong:** Script exits unexpectedly on benign failures
**Why it happens:** `set -e` propagates from sourced library
**How to avoid:**
- Document that library uses strict mode
- Use `|| true` for commands expected to fail sometimes
- Use explicit return codes where needed
**Warning signs:** Scripts exit silently on first minor error

### Pitfall 5: yq --front-matter with Multiple Files
**What goes wrong:** Only first file processed correctly
**Why it happens:** Known limitation - `--front-matter` applies only to first file
**How to avoid:** Use `find -exec` or loop instead of passing multiple files
**Warning signs:** Second file in list has YAML parsing errors

## Code Examples

Verified patterns from official sources:

### Reading Frontmatter Fields
```bash
# Source: https://mikefarah.gitbook.io/yq/usage/front-matter

# Single field
title=$(yq --front-matter=extract '.title' "$file")

# Handle missing field (returns empty string, not "null")
description=$(yq --front-matter=extract '.description // ""' "$file")

# Check if field exists
if yq --front-matter=extract -e '.pubDatetime' "$file" >/dev/null 2>&1; then
  echo "Has pubDatetime"
fi
```

### Updating Frontmatter In-Place
```bash
# Source: https://mikefarah.gitbook.io/yq/usage/front-matter

# Set a boolean field
yq --front-matter=process -i '.draft = false' "$file"

# Set a string field with variable
yq --front-matter=process -i ".pubDatetime = \"$datetime\"" "$file"

# Using environment variable (safer for special characters)
export NEW_AUTHOR="Justin Carlson"
yq --front-matter=process -i '.author = strenv(NEW_AUTHOR)' "$file"
```

### Library Source Pattern
```bash
# Source: https://tjelvarolsson.com/blog/using-relative-paths-in-linux-scripts/

#!/usr/bin/env bash
set -euo pipefail

# Get directory containing this script (works with symlinks too)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared library
source "${SCRIPT_DIR}/lib/common.sh"
```

### Validation Function Pattern
```bash
# Refactored validate_iso8601 using yq for consistent approach
validate_iso8601() {
  local datetime="$1"

  # Full datetime: YYYY-MM-DDTHH:MM:SS (with optional timezone)
  if [[ "$datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
    return 0
  fi

  # Date only: YYYY-MM-DD
  if [[ "$datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    return 0
  fi

  return 1
}
```

### Slugify Function (Reusable)
```bash
# Current implementation is correct, just needs to be centralized
slugify() {
  local name="$1"
  name="${name%.md}"                              # Remove .md extension
  name=$(echo "$name" | tr '[:upper:]' '[:lower:]')  # Lowercase
  name=$(echo "$name" | tr ' ' '-')               # Spaces to hyphens
  name=$(echo "$name" | sed 's/[^a-z0-9-]//g')    # Remove special chars
  name=$(echo "$name" | sed 's/-\+/-/g')          # Collapse hyphens
  name=$(echo "$name" | sed 's/^-//' | sed 's/-$//')  # Trim hyphens
  echo "$name"
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| sed/grep YAML parsing | yq --front-matter | yq v4 (2020+) | Reliable quoted values, arrays, multiline |
| kislyuk/yq (Python wrapper) | mikefarah/yq (Go) | mikefarah established ~2016 | Standalone binary, native YAML, faster |
| Duplicated functions | Sourced library | Best practice always | Maintainability, consistency |

**Deprecated/outdated:**
- kislyuk/yq: Still maintained but different tool; mikefarah/yq is more feature-complete for YAML
- yq v3.x syntax: v4 uses jq-like syntax; migration guide exists for v3->v4

## Open Questions

Things that couldn't be fully resolved:

1. **Should setup.sh and bootstrap.sh also use common.sh?**
   - What we know: They duplicate color constants but don't use validation/config functions
   - What's unclear: Whether adding the dependency is worth it for just colors
   - Recommendation: Yes, include them for consistency; color constants are the most duplicated code (5 files)

2. **Error handling strategy in library functions**
   - What we know: Using `set -euo pipefail` in library affects all sourcing scripts
   - What's unclear: Whether to return error codes or rely on set -e exit
   - Recommendation: Use explicit return codes for validation functions, let set -e handle unexpected errors

## Sources

### Primary (HIGH confidence)
- [mikefarah/yq GitHub](https://github.com/mikefarah/yq) - Current version v4.52.2, installation methods
- [yq Front Matter documentation](https://mikefarah.gitbook.io/yq/usage/front-matter) - --front-matter flag usage
- [eitsupi/devcontainer-features](https://github.com/eitsupi/devcontainer-features) - jq-likes feature for devcontainer
- [containers.dev/features](https://containers.dev/features) - Official devcontainer features registry

### Secondary (MEDIUM confidence)
- [ShellCheck SC1091 documentation](https://www.shellcheck.net/wiki/SC1091) - Handling source file paths
- [Bash library patterns](https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/) - Modular bash design
- [BASH_SOURCE path resolution](https://tjelvarolsson.com/blog/using-relative-paths-in-linux-scripts/) - Script directory detection

### Tertiary (LOW confidence)
- None - all findings verified with primary or secondary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - mikefarah/yq is well-documented with official docs; devcontainer feature exists
- Architecture: HIGH - bash library sourcing is well-established pattern with clear documentation
- Pitfalls: HIGH - shellcheck warnings and yq version confusion are documented issues

**Research date:** 2026-02-01
**Valid until:** 2026-03-01 (30 days - stable domain, tools change slowly)

---

## Appendix: Current Duplication Analysis

Duplicated code identified across scripts:

### Color Constants (5 files)
- publish.sh: lines 6-10
- unpublish.sh: lines 6-10
- list-posts.sh: lines 6-10
- setup.sh: lines 6-9
- bootstrap.sh: lines 7-11

### Configuration Constants (3 files)
- CONFIG_FILE: publish.sh:13, unpublish.sh:13, list-posts.sh:13
- BLOG_DIR: publish.sh:16, unpublish.sh:16, list-posts.sh:16
- ASSETS_DIR: publish.sh:17

### Functions Duplicated
| Function | publish.sh | unpublish.sh | list-posts.sh |
|----------|------------|--------------|---------------|
| extract_frontmatter | line 276 | - | line 102 |
| get_frontmatter_field | line 282 | - | line 108 |
| validate_iso8601 | line 295 | - | line 120 |
| validate_frontmatter | line 312 | - | line 137 |
| load_config | line 448 | line 92 | line 70 |
| slugify | line 482 | line 110 | line 197 |
| extract_frontmatter_value | line 500 | line 128 | line 188 |

**Total estimated duplicated lines:** ~280
