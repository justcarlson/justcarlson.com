# Stack Research: justfile + Claude Hooks

**Milestone:** v0.2.0 Publishing Workflow
**Researched:** 2026-01-30
**Confidence:** HIGH

## Executive Summary

The publishing workflow requires three new components: justfile for deterministic commands, Claude Code hooks for safety gates, and minimal shell scripts. No new npm packages are needed — gray-matter (already installed at ^4.0.3) handles all markdown/frontmatter parsing. The stack additions are minimal and integrate cleanly with the existing Astro/npm toolchain.

## Recommended Additions

### 1. justfile (Command Runner)

| Tool | Version | Purpose | Status |
|------|---------|---------|--------|
| **just** | 1.46.0 | Command runner for deterministic scripts | Already installed on system |

**Why justfile over npm scripts:**
- **Clarity**: Recipes are explicit shell commands, not JSON-escaped strings
- **Composition**: Recipes can call other recipes with dependencies
- **Discoverability**: `just --list` shows all commands with descriptions
- **No node_modules**: Works standalone without Node.js for basic commands
- **Dotenv built-in**: Loads `.env` automatically

**Configuration for this project:**

```justfile
# justfile - Blog publishing workflow

set dotenv-load := true
set shell := ["bash", "-uc"]

# Default recipe shows available commands
default:
    @just --list

# One-time setup: configure Obsidian vault path
setup:
    ./scripts/setup.sh

# Find draft:false posts ready to publish
list-drafts:
    ./scripts/list-drafts.sh

# Full publish workflow: validate -> copy -> lint -> build -> commit -> push
publish:
    ./scripts/publish.sh

# Remove a published post (keeps Obsidian source)
unpublish file:
    ./scripts/unpublish.sh "{{file}}"

# Start Astro dev server for preview
preview:
    npm run dev

# Run Biome lint
lint:
    npm run lint

# Run full build with type check
build:
    npm run build:check
```

**Confidence:** HIGH — Verified just 1.46.0 installed, syntax from [Just Manual](https://just.systems/man/en/)

### 2. Claude Code Hooks (Safety Gates)

| Component | Location | Purpose |
|-----------|----------|---------|
| Project settings | `.claude/settings.json` | Shared hooks (git safety) |
| Local settings | `.claude/settings.local.json` | User-specific config (Obsidian path) |
| Hook scripts | `.claude/hooks/` | Validation logic |

**Setup Hook Configuration:**

```json
{
  "hooks": {
    "Setup": [
      {
        "matcher": "init",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/setup.sh"
          }
        ]
      }
    ]
  }
}
```

**Git Safety Hook Configuration:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/git-safety.sh"
          }
        ]
      }
    ]
  }
}
```

**Hook Exit Codes:**
- **Exit 0**: Allow the operation
- **Exit 2**: Block the operation, stderr shown to Claude

**Confidence:** HIGH — Verified from [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide) and [Hooks Reference](https://code.claude.com/docs/en/hooks)

### 3. Shell Scripts (Workflow Logic)

| Script | Purpose | Calls |
|--------|---------|-------|
| `scripts/setup.sh` | Interactive Obsidian path configuration | Writes to `.claude/settings.local.json` |
| `scripts/list-drafts.sh` | Find publishable posts | Node.js for frontmatter parsing |
| `scripts/publish.sh` | Full publish workflow | list-drafts, validate, copy, lint, build, commit, push |
| `scripts/unpublish.sh` | Remove published post | git rm, commit, push |
| `.claude/hooks/git-safety.sh` | Block dangerous git ops | jq to parse input JSON |

**Shell Script Best Practices:**
- Use `#!/usr/bin/env bash` for portability
- Set `set -euo pipefail` for strict error handling
- Quote all variables: `"$VAR"` not `$VAR`
- Use absolute paths via `$CLAUDE_PROJECT_DIR` in hooks

**Confidence:** HIGH — Standard bash practices

## Integration with Existing Stack

### Existing Infrastructure (No Changes)

| Technology | Version | Integration Point |
|------------|---------|-------------------|
| **Astro** | ^5.16.6 | justfile calls `npm run dev`, `npm run build:check` |
| **Biome** | ^2.3.10 | justfile calls `npm run lint` |
| **gray-matter** | ^4.0.3 | Scripts use for frontmatter parsing |
| **sharp** | ^0.34.5 | Available if image processing needed |
| **husky** | ^9.1.7 | Existing pre-commit hooks remain |

### gray-matter Usage (Already Installed)

gray-matter is already in package.json at ^4.0.3. Use it in Node.js helper scripts:

```javascript
#!/usr/bin/env node
import matter from 'gray-matter';
import { globSync } from 'node:fs';

// Parse frontmatter from file
const { data, content } = matter.read('./path/to/post.md');

// Check if ready to publish
if (data.draft === false && data.title && data.pubDatetime) {
  console.log('Ready to publish:', data.title);
}
```

**Confidence:** HIGH — gray-matter verified in package.json, API from [GitHub](https://github.com/jonschlinkert/gray-matter)

### Directory Structure

```
justcarlson.com/
├── justfile                    # Command runner recipes
├── scripts/
│   ├── setup.sh               # Interactive vault path setup
│   ├── list-drafts.sh         # Find publishable posts
│   ├── publish.sh             # Full publish workflow
│   └── unpublish.sh           # Remove published post
├── .claude/
│   ├── settings.json          # Shared hooks (git safety)
│   ├── settings.local.json    # Local config (vault path) - gitignored
│   └── hooks/
│       └── git-safety.sh      # Block dangerous git commands
└── .env                       # Optional: OBSIDIAN_VAULT_PATH
```

## What NOT to Add

### Rejected: Additional npm Packages

| Package | Why Considered | Why Rejected |
|---------|----------------|--------------|
| **zx** | Shell scripting in JS | Overkill — bash scripts sufficient |
| **execa** | Better child processes | Not needed — direct bash |
| **glob** | File matching | Node.js `fs.globSync` built-in (Node 22+) |
| **front-matter** | Alternative to gray-matter | gray-matter already installed |
| **just-install** | npm wrapper for just | just already installed system-wide |
| **remark-frontmatter** | Remark plugin | Not using remark ecosystem |

### Rejected: Complex Automation

| Approach | Why Rejected |
|----------|--------------|
| **GitHub Actions for publishing** | Local workflow preferred for immediate feedback |
| **MCP server for Obsidian** | Adds complexity; file reading sufficient |
| **Obsidian plugin** | Maintains two codebases; scripts work directly |
| **Custom Astro integration** | Publishing is pre-build; not runtime |

### Rejected: Alternative Command Runners

| Tool | Why Rejected |
|------|--------------|
| **make** | `.PHONY` complexity, not cross-platform |
| **Task (taskfile.dev)** | YAML-based, less shell-native |
| **npm scripts only** | JSON escaping awkward, no dependencies |

## Configuration Examples

### justfile (Complete)

```justfile
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

# === Publishing ===

# List posts ready to publish (draft: false in frontmatter)
list-drafts:
    ./scripts/list-drafts.sh

# Full publish workflow: validate -> copy -> lint -> build -> commit -> push
publish:
    ./scripts/publish.sh

# Remove a published post by filename (keeps Obsidian source)
unpublish file:
    ./scripts/unpublish.sh "{{file}}"

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

# === Utilities ===

# Sync Astro content collections
sync:
    npm run sync

# Format code with Biome
format:
    npm run format
```

### .claude/settings.json (Git Safety Hook)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/git-safety.sh"
          }
        ]
      }
    ],
    "Setup": [
      {
        "matcher": "init",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/setup.sh"
          }
        ]
      }
    ]
  }
}
```

### .claude/hooks/git-safety.sh

```bash
#!/usr/bin/env bash
# Block dangerous git operations
# Exit 2 = block with feedback to Claude
# Exit 0 = allow

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Extract command from tool_input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Patterns to block
DANGEROUS_PATTERNS=(
    "git push --force"
    "git push -f"
    "git reset --hard"
    "git checkout \."
    "git restore \."
    "git clean -f"
    "git branch -D"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if [[ "$COMMAND" =~ $pattern ]]; then
        echo "BLOCKED: Dangerous git operation detected: $pattern" >&2
        echo "This operation could cause data loss. Use explicit flags if truly needed." >&2
        exit 2
    fi
done

# Allow all other commands
exit 0
```

### .claude/settings.local.json (User Config - gitignored)

```json
{
  "obsidianVaultPath": "/home/jc/Documents/Obsidian/Blog"
}
```

### scripts/list-drafts.sh (Example)

```bash
#!/usr/bin/env bash
# List posts ready to publish from Obsidian vault
set -euo pipefail

# Get vault path from local settings
VAULT_PATH=$(jq -r '.obsidianVaultPath // empty' .claude/settings.local.json 2>/dev/null)

if [[ -z "$VAULT_PATH" ]]; then
    echo "Error: Obsidian vault path not configured. Run 'just setup' first." >&2
    exit 1
fi

# Use Node.js script for frontmatter parsing
node --experimental-strip-types scripts/lib/find-publishable.ts "$VAULT_PATH"
```

## Confidence Assessment

| Area | Confidence | Rationale |
|------|------------|-----------|
| justfile syntax | HIGH | Verified 1.46.0 installed, official docs reviewed |
| Claude hooks structure | HIGH | Official docs comprehensive, settings.json format clear |
| gray-matter API | HIGH | Already in package.json, GitHub docs verified |
| Shell script patterns | HIGH | Standard bash, no exotic features |
| Integration approach | HIGH | justfile wraps npm scripts, no conflicts |

## Sources

### Official Documentation
- [Just Programmer's Manual](https://just.systems/man/en/) — Complete syntax reference
- [Just GitHub Repository](https://github.com/casey/just) — Shell settings, dotenv support
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide) — Getting started with hooks
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) — Complete hook events, matchers, exit codes
- [gray-matter GitHub](https://github.com/jonschlinkert/gray-matter) — API for frontmatter parsing

### Examples and Tutorials
- [TypeStrong ts-node justfile](https://github.com/TypeStrong/ts-node/blob/main/justfile) — Real-world Node.js project structure
- [nodejs-sample-justfile-build-system](https://github.com/kevinchar93/nodejs-sample-justfile-build-system) — npm + justfile integration
- [Claude Code Hooks Mastery](https://github.com/disler/claude-code-hooks-mastery) — Community examples
- [DataCamp: Claude Code Hooks Tutorial](https://www.datacamp.com/tutorial/claude-code-hooks) — Practical guide

### Reference Articles
- [Justfile became my favorite task runner](https://tduyng.medium.com/justfile-became-my-favorite-task-runner-7a89e3f45d9a) — Real-world adoption
- [Just use just](https://toniogela.dev/just/) — Best practices

## Open Questions

None. All stack decisions are clear:
- justfile for command orchestration
- Claude hooks for safety gates and setup triggers
- Shell scripts (bash) for workflow logic
- gray-matter (existing) for frontmatter parsing
- No new npm packages needed
