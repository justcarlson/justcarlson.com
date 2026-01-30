# Architecture Research: Three-Layer Pattern

**Domain:** Publishing workflow for Astro blog
**Researched:** 2026-01-30
**Confidence:** HIGH (official docs verified via Claude Code documentation)

## Executive Summary

The three-layer architecture separates concerns into deterministic commands (justfile), automated safety (hooks), and intelligent oversight (skills). The key insight: **the script is the source of truth**. Both hooks and skills execute the same justfile commands, ensuring consistency whether invoked from terminal, automation, or Claude.

## Layer Overview

```
+------------------------------------------------------------------+
|                        USER INTERFACE                             |
+------------------------------------------------------------------+
|  Terminal          |  Claude --init    |  Claude /skill          |
|  $ just publish    |  (triggers Setup  |  (human-in-the-loop     |
|  $ just setup      |   hook)           |   via /publish-blog)    |
+---------+----------+---------+---------+-----------+-------------+
          |                    |                     |
          v                    v                     v
+------------------------------------------------------------------+
|                    LAYER 3: SKILLS (optional)                     |
|  .claude/skills/*/SKILL.md                                        |
|  - Human-in-the-loop oversight                                    |
|  - disable-model-invocation: true (user must invoke)              |
|  - Calls justfile commands with validation                        |
|  - allowed-tools restricts to safe operations                     |
+-----------------------------+------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                    LAYER 2: HOOKS (safety)                        |
|  .claude/settings.json (hooks section)                            |
|  - Setup hook: runs `just setup` on --init                        |
|  - PreToolUse/Bash: blocks dangerous git operations               |
|  - Automatic, no user action required                             |
+-----------------------------+------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                LAYER 1: JUSTFILE (deterministic)                  |
|  justfile (project root)                                          |
|  - Source of truth for all commands                               |
|  - Works standalone: `just publish` from terminal                 |
|  - Portable, repeatable, testable                                 |
|  - No Claude dependency                                           |
+------------------------------------------------------------------+
```

### Layer Responsibilities

| Layer | File | Responsibility | Invocation |
|-------|------|----------------|------------|
| **1. Justfile** | `justfile` | Deterministic commands | `just <recipe>` |
| **2. Hooks** | `.claude/settings.json` | Safety gates, automation triggers | Automatic on events |
| **3. Skills** | `.claude/skills/*/SKILL.md` | Intelligent oversight, user invocation | `/skill-name` |

### Key Principle: Script as Source of Truth

From [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery):

> "Hooks are thin wrappers. They parse incoming JSON, invoke core scripts, and return standardized responses. Scripts contain business logic."

Applied to this architecture:

```
Terminal:     $ just publish          -> runs justfile directly
Hook:         Setup hook              -> runs `just setup`
Skill:        /publish-blog           -> instructs Claude to run `just publish`
```

Same command, three entry points. The justfile is always the source of truth.

## File Structure

### Complete Directory Layout

```
justcarlson.com/
|-- justfile                          # LAYER 1: Source of truth
|
|-- .githooks/                        # Git hooks (not Claude hooks)
|   +-- pre-push                      # Block dangerous git operations
|
|-- .claude/
|   |-- settings.json                 # LAYER 2: Hook configuration (committed)
|   |-- settings.local.json           # User config: Obsidian path (gitignored)
|   |
|   +-- skills/                       # LAYER 3: Skills
|       |-- setup-blog/
|       |   +-- SKILL.md              # /setup-blog
|       |-- publish-blog/
|       |   +-- SKILL.md              # /publish-blog
|       |-- unpublish-blog/
|       |   +-- SKILL.md              # /unpublish-blog
|       |-- list-drafts/
|       |   +-- SKILL.md              # /list-drafts
|       +-- preview-blog/
|           +-- SKILL.md              # /preview-blog
|
|-- scripts/                          # Supporting scripts (if needed)
|   +-- find-obsidian-vaults.sh       # Helper for setup
|
+-- src/content/blog/                 # Astro content (existing)
    +-- YYYY/*.md
```

### File Purposes

| File | Purpose | Committed |
|------|---------|-----------|
| `justfile` | All publishing commands | Yes |
| `.githooks/pre-push` | Block dangerous git ops | Yes |
| `.claude/settings.json` | Hook configuration | Yes |
| `.claude/settings.local.json` | User's Obsidian vault path | No (gitignored) |
| `.claude/skills/*/SKILL.md` | Skill definitions | Yes |
| `scripts/*.sh` | Complex helper scripts | Yes |

## Data Flow

### Setup Flow

```
claude --init
    |
    v
+---------------------------------------------------+
| Setup Hook (settings.json)                        |
| "matcher": "init"                                 |
| "command": "just setup"                           |
+------------------------+--------------------------+
                         |
                         v
+---------------------------------------------------+
| just setup                                        |
| 1. Find .obsidian folders                         |
| 2. Prompt user to select vault                    |
| 3. Validate blog/ subfolder exists                |
| 4. Write to .claude/settings.local.json           |
| 5. Configure git core.hooksPath -> .githooks      |
+---------------------------------------------------+
```

### Publish Flow (via Skill)

```
User: /publish-blog
    |
    v
+---------------------------------------------------+
| SKILL.md Instructions                             |
| disable-model-invocation: true                    |
| allowed-tools: Bash(just *), Read, Glob           |
|                                                   |
| 1. Read .claude/settings.local.json               |
| 2. If no config, prompt: "Run /setup-blog first"  |
| 3. Run: just publish                              |
| 4. Report results to user                         |
+------------------------+--------------------------+
                         |
                         v
+---------------------------------------------------+
| just publish                                      |
| 1. Read vault path from settings.local.json       |
| 2. Find draft: false posts in vault/blog/         |
| 3. Validate frontmatter                           |
| 4. Copy posts to src/content/blog/YYYY/           |
| 5. Copy referenced images                         |
| 6. Run biome lint                                 |
| 7. Run npm run build                              |
| 8. git commit (conventional message)              |
| 9. git push                                       |
+---------------------------------------------------+
```

### Safety Flow (Git Hooks)

```
Claude or User: git push --force
    |
    v
+---------------------------------------------------+
| .githooks/pre-push                                |
| Check for dangerous patterns:                     |
| - --force, -f                                     |
| - reset --hard                                    |
| - clean -f                                        |
| - stash drop, stash clear                         |
| - branch -D                                       |
|                                                   |
| Bypass: command contains "# UNSAFE" comment       |
+------------------------+--------------------------+
                         |
          +--------------+--------------+
          |                             |
     Dangerous                     Safe
          |                             |
          v                             v
    Exit code 1              Continue push
    (blocks operation)
```

## Configuration

### .claude/settings.json (Committed)

```json
{
  "hooks": {
    "Setup": [
      {
        "matcher": "init",
        "hooks": [
          {
            "type": "command",
            "command": "just setup",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

**Note:** Git safety is handled via `.githooks/` (committed to repo) rather than Claude hooks. This ensures protection works even when Claude Code is not involved.

### .claude/settings.local.json (Gitignored)

```json
{
  "blog": {
    "obsidianVault": "/home/jc/obsidian/personal",
    "blogSubfolder": "blog"
  }
}
```

**Key design decisions:**

1. **Separate namespace** (`blog`) to avoid conflicts with Claude settings
2. **Both vault and subfolder** stored for flexibility
3. **Gitignored** because paths are machine-specific

### Skill Frontmatter Pattern

All publishing skills use consistent frontmatter:

```yaml
---
name: publish-blog
description: Publish blog posts from Obsidian to Astro site
disable-model-invocation: true
allowed-tools: Bash(just *), Read, Glob, Grep
---
```

| Field | Value | Rationale |
|-------|-------|-----------|
| `disable-model-invocation` | `true` | User must explicitly invoke |
| `allowed-tools` | `Bash(just *)` | Only allow justfile commands |

### Justfile Structure

```just
# Default recipe shows help
default:
    @just --list

# === SETUP ===

# Interactive setup for Obsidian vault path
setup:
    #!/usr/bin/env bash
    # Find .obsidian folders, let user pick, validate, save config

# === PUBLISHING ===

# Publish all ready posts from Obsidian
publish: _check-config
    #!/usr/bin/env bash
    # Find, validate, copy, lint, build, commit, push

# Unpublish a post (remove from repo, keep in Obsidian)
unpublish file: _check-config
    #!/usr/bin/env bash
    # Remove from src/content/blog/, commit, push

# === UTILITIES ===

# List posts ready to publish
list-drafts: _check-config
    #!/usr/bin/env bash
    # Find draft: false posts, show validation status

# Start preview server
preview:
    npm run dev

# === PRIVATE RECIPES ===

# Check if setup has been run
_check-config:
    @test -f .claude/settings.local.json || \
      (echo "Setup required. Run: just setup" && exit 1)
```

## Build Order

Implementation should follow dependency order:

### Phase 1: Foundation (Layer 1 first)

| Order | Component | Rationale |
|-------|-----------|-----------|
| 1 | `justfile` skeleton | Source of truth must exist first |
| 2 | `just setup` recipe | Other commands depend on config |
| 3 | `.claude/settings.local.json` format | Setup writes this, others read it |

### Phase 2: Safety (Layer 2)

| Order | Component | Rationale |
|-------|-----------|-----------|
| 4 | `.githooks/pre-push` | Git safety independent of Claude |
| 5 | `.claude/settings.json` (Setup hook) | Triggers `just setup` on `--init` |
| 6 | Test: `claude --init` | Verify hook to justfile flow |

### Phase 3: Publishing (Layer 1 expansion)

| Order | Component | Rationale |
|-------|-----------|-----------|
| 7 | `just list-drafts` | Non-destructive, good for testing |
| 8 | `just publish` | Core publishing logic |
| 9 | `just unpublish` | Rollback capability |
| 10 | `just preview` | Simple wrapper, low risk |

### Phase 4: Skills (Layer 3)

| Order | Component | Rationale |
|-------|-----------|-----------|
| 11 | `/setup-blog` skill | Wraps `just setup` |
| 12 | `/list-drafts` skill | Wraps `just list-drafts` |
| 13 | `/publish-blog` skill | Wraps `just publish` |
| 14 | `/unpublish-blog` skill | Wraps `just unpublish` |
| 15 | `/preview-blog` skill | Wraps `just preview` |

**Rationale:** Layer 1 must be complete and testable before Layer 3 wraps it. This allows:
- Terminal testing without Claude
- Incremental verification
- Rollback to justfile-only if skills have issues

## Integration Points

### Existing Structure Integration

| Existing | Integration |
|----------|-------------|
| `src/content/blog/YYYY/` | `just publish` writes here |
| `public/assets/blog/` | `just publish` copies images here |
| `package.json` scripts | `just preview` calls `npm run dev` |
| `biome.json` | `just publish` runs `npx biome check` |
| `.gitignore` | Already ignores `settings.local.json` pattern |

### Settings Precedence

Claude Code merges settings in this order (highest priority first):

1. Managed (enterprise) - N/A for personal project
2. Command line arguments
3. `.claude/settings.local.json` - User's Obsidian path
4. `.claude/settings.json` - Hook configuration
5. `~/.claude/settings.json` - Global user settings

For this project, `settings.local.json` stores user config, `settings.json` stores hooks.

## Anti-Patterns to Avoid

### 1. Logic in Hooks

**Bad:**
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "command": "if echo '$INPUT' | grep -q 'git push --force'; then exit 2; fi"
      }]
    }]
  }
}
```

**Good:** Use `.githooks/` for git safety (works without Claude).

### 2. Duplicated Logic

**Bad:** Skill contains full publishing logic separate from justfile.

**Good:** Skill instructs Claude to run `just publish`.

### 3. Skill Without disable-model-invocation

**Bad:**
```yaml
---
name: publish-blog
description: Publish blog posts
---
```

Claude might auto-invoke publishing when user mentions "post".

**Good:**
```yaml
---
name: publish-blog
description: Publish blog posts
disable-model-invocation: true
---
```

User must explicitly type `/publish-blog`.

### 4. Hardcoded Paths

**Bad:** Justfile contains `/home/jc/obsidian/personal`.

**Good:** Justfile reads from `.claude/settings.local.json`.

## Scalability Considerations

| Concern | Current Scale | Future Scale |
|---------|---------------|--------------|
| Multiple vaults | Single vault path | Could add vault selection to `just publish` |
| Multiple blogs | Single blog | Could add blog parameter to recipes |
| Team usage | Single user | `settings.local.json` per user works |
| CI/CD | Not needed | Justfile works in CI without Claude |

## Sources

### Official Documentation (HIGH confidence)

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) - Hook events, configuration, JSON output
- [Claude Code Skills](https://code.claude.com/docs/en/skills) - Skill structure, frontmatter, invocation control
- [Claude Code Settings](https://code.claude.com/docs/en/settings) - Settings hierarchy, merging behavior
- [Just Manual](https://just.systems/man/en/) - Recipe syntax, parameters, modules

### Community Patterns (MEDIUM confidence)

- [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery) - Script-as-source-of-truth pattern
- [ChrisWiles/claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) - Directory structure reference
- [just skill on claude-plugins.dev](https://claude-plugins.dev/skills/@lanej/dotfiles/just) - Justfile + Claude integration patterns

### WebSearch (LOW confidence, verified against official docs)

- Setup hook uses `"matcher": "init"` for `--init` flag
- Skills merged with slash commands as of Claude Code 2.1.3
- `settings.local.json` auto-gitignored by Claude Code

---

*Architecture research completed: 2026-01-30*
*Confidence: HIGH - all critical patterns verified against official Claude Code documentation*
