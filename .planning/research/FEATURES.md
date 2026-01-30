# Features Research: Publishing Workflow

**Domain:** justfile + Claude hooks publishing workflow for Obsidian-to-Astro blog
**Researched:** 2026-01-30
**Confidence:** HIGH (multiple authoritative sources, verified patterns)

---

## Table Stakes

Features users expect. Missing = workflow feels broken or incomplete.

### Justfile Commands

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `just publish` | Core workflow trigger | Medium | Single command to validate, copy, lint, build, commit, push |
| `just preview` | See changes before publishing | Low | Starts Astro dev server |
| `just list-drafts` | Know what's ready to publish | Low | Show `draft: false` posts from Obsidian vault |
| `just setup` | First-time configuration | Low | Prompts for Obsidian vault path, writes to config |

### Validation Steps

| Validation | Why Expected | Complexity | Notes |
|------------|--------------|------------|-------|
| Frontmatter presence | Posts without title/date/description fail silently | Low | Required: `title`, `pubDatetime`, `description` |
| Draft status check | Only publish `draft: false` posts | Low | Prevent accidental publishing |
| Biome lint | Catch code issues before deploy | Low | Already exists in project |
| Build check | Astro must compile successfully | Low | Already exists: `npm run build:check` |

### File Operations

| Operation | Why Expected | Complexity | Notes |
|-----------|--------------|------------|-------|
| Copy posts to year folder | Match existing `src/content/blog/YYYY/` structure | Medium | Extract year from `pubDatetime` |
| Copy referenced images | Posts need their images | Medium | Parse markdown for image refs, copy to `public/assets/blog/` |
| Preserve frontmatter | Schema must match `content.config.ts` | Low | Existing schema has 14 fields |

### Git Safety

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Block `git push --force` | Prevent history destruction | Low | PreToolUse hook with exit code 2 |
| Block `git reset --hard` | Prevent uncommitted work loss | Low | Same hook, pattern matching |
| Block `git checkout -- .` | Prevent file reversion | Low | Same hook |
| Conventional commit messages | Match project style (feat/fix) | Low | Already using commitizen |

---

## Differentiators

Features that make this better than manual publishing.

### Workflow Intelligence

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Validation status per post | See which posts are ready vs missing fields | Medium | `/list-drafts` shows "ready" vs "missing: title" |
| Automatic year folder detection | No manual folder creation | Low | Parse `pubDatetime`, create `YYYY/` if needed |
| Image reference detection | Never forget to copy images | Medium | Parse markdown for `![](...)` and wikilinks |
| Dry-run mode | Preview what would happen | Low | `just publish --dry-run` shows actions without executing |

### Claude Integration Modes

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Deterministic mode | `just publish` runs without AI | Low | Pure bash/script, CI-friendly |
| Agentic mode | `/publish-blog` skill with Claude oversight | Medium | Uses `disable-model-invocation: true` for manual-only |
| Interactive mode | Claude asks clarifying questions | High | Useful for first-time users or edge cases |

### Safety Hooks

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| PreToolUse Bash guard | Block dangerous commands before execution | Medium | JSON output with `permissionDecision: deny` |
| Suggested alternatives | Tell Claude what to do instead | Low | "Use `--force-with-lease` instead of `--force`" |
| Audit logging | Track blocked commands | Low | Append to `.claude/hooks/blocked.log` |

### Developer Experience

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Config storage in `.claude/settings.local.json` | Project-specific, gitignored | Low | Standard Claude Code pattern |
| Missing config detection | Skills prompt to run `/setup-blog` first | Low | Check file exists before proceeding |
| Progress reporting | Know what step is running | Low | Echo step names during execution |

---

## Anti-Features

Features to deliberately NOT build. Common mistakes in this domain.

### Over-Engineering

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Obsidian plugin | Adds dependency on Obsidian ecosystem | Use file-based detection (read markdown files) |
| Real-time sync (file watcher) | Complexity for little gain in manual publish workflow | Batch publish on command |
| Database for post tracking | Overkill for personal blog | Use filesystem as source of truth |
| Custom frontmatter parser | Reinventing the wheel | Use `gray-matter` (already in project) |

### Premature Automation

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Auto-publish on save | Risk of publishing unfinished work | Require explicit `just publish` |
| Auto-linting hook on every session | Biome runs in publish pipeline already | Lint only during publish |
| Social auto-posting | API complexity, rate limits, auth tokens | Defer to v0.3.0+ |
| Newsletter integration | Separate concern from publishing | Defer to v0.3.0+ |

### Complexity Traps

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Wikilink conversion | Astro doesn't support wikilinks natively | Write standard markdown links |
| Backlink generation | Digital garden feature, not blog feature | Skip unless explicitly needed |
| Multiple vault support | YAGNI for personal blog | Single vault path in config |
| Template system | Obsidian already has Templater | Use Obsidian's tools |

### Security Theater

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Block ALL git commands | Overly restrictive, breaks normal workflow | Block only destructive patterns |
| Require confirmation for every file write | Claude Code already has permission system | Use PreToolUse for specific patterns |
| Paranoid mode by default | Slows down legitimate work | Offer as opt-in flag |

---

## Workflow Patterns

### Pattern 1: `just publish` (Deterministic)

Step-by-step flow for standalone execution:

```
1. Read config
   - Load Obsidian vault path from .claude/settings.local.json
   - Error if not configured: "Run `just setup` first"

2. Discover posts
   - Find all .md files in vault with `draft: false` frontmatter
   - Parse frontmatter with gray-matter

3. Validate posts
   - Required fields: title, pubDatetime, description
   - Fail with clear message: "Post 'my-post.md' missing: description"
   - Continue only if ALL posts valid

4. Copy posts
   - For each valid post:
     - Extract year from pubDatetime
     - Create src/content/blog/YYYY/ if needed
     - Copy .md file to destination

5. Copy images
   - Parse markdown for image references
   - Copy referenced images to public/assets/blog/
   - Update image paths in copied markdown (if relative)

6. Lint
   - Run: biome check src
   - Fail if lint errors

7. Build
   - Run: npm run build
   - Fail if build errors

8. Commit
   - Stage: src/content/blog/**/* public/assets/blog/*
   - Commit message: "feat(blog): publish [post-titles]" or "fix(blog): update [post-titles]"
   - Use feat for new posts, fix for updates

9. Push
   - Run: git push origin main
   - Success message: "Published N posts"
```

### Pattern 2: `/publish-blog` Skill (Agentic)

Claude Code skill with human oversight:

```yaml
---
name: publish-blog
description: Publish blog posts from Obsidian to Astro
disable-model-invocation: true  # Manual execution only
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
---

# Publish Blog Skill

## Prerequisites
- Obsidian vault path configured (run /setup-blog if not)
- Posts marked with `draft: false` in frontmatter

## Steps
1. Find publishable posts in configured Obsidian vault
2. Validate frontmatter (title, pubDatetime, description required)
3. Copy posts to src/content/blog/YYYY/
4. Copy referenced images to public/assets/blog/
5. Run Biome lint
6. Run Astro build
7. Commit with conventional message
8. Push to origin
```

### Pattern 3: `/setup-blog` Skill (Interactive)

First-time configuration:

```yaml
---
name: setup-blog
description: Configure Obsidian vault path for publishing
---

# Setup Blog Skill

## Steps
1. Ask user for Obsidian vault path containing blog posts
2. Validate path exists and contains .md files
3. Write path to .claude/settings.local.json:
   {
     "obsidianVaultPath": "/path/to/vault/blog"
   }
4. Confirm setup complete
```

### Pattern 4: Git Safety Hook (PreToolUse)

Hook configuration in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/git-safety.sh"
          }
        ]
      }
    ]
  }
}
```

Git safety script pattern:

```bash
#!/bin/bash
# .claude/hooks/git-safety.sh

# Read input JSON from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Dangerous patterns
PATTERNS=(
  "git push.*--force[^-]"
  "git push.*-f[^o]"
  "git reset --hard"
  "git reset --merge"
  "git checkout -- ."
  "git checkout -- \*"
  "git clean -f"
  "git branch -D"
  "git stash drop"
  "git stash clear"
)

for PATTERN in "${PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$PATTERN"; then
    echo "Blocked: $PATTERN" >&2
    echo "Suggestion: Use safer alternatives like --force-with-lease" >&2
    exit 2
  fi
done

exit 0
```

### Pattern 5: `/unpublish-blog` Skill (Rollback)

Remove published post while keeping Obsidian source:

```yaml
---
name: unpublish-blog
description: Remove a published post from the blog
disable-model-invocation: true
allowed-tools:
  - Read
  - Bash
  - Glob
---

# Unpublish Blog Skill

## Usage
/unpublish-blog [filename]

## Steps
1. Find post in src/content/blog/**/ matching filename
2. Delete post file (keep Obsidian source untouched)
3. Optionally delete orphaned images
4. Commit with message: "chore(blog): unpublish [title]"
5. Push to origin
```

---

## Dependencies on Existing Features

| Existing Feature | How Publishing Uses It |
|------------------|------------------------|
| `src/content/blog/YYYY/` structure | Copy destination for posts |
| `content.config.ts` schema | Frontmatter validation reference |
| `public/assets/blog/` (if exists) | Image destination |
| Biome (`npm run lint`) | Pre-commit validation |
| Astro build (`npm run build`) | Pre-push validation |
| Husky + lint-staged | Pre-commit hooks (already configured) |
| Conventional commits (commitizen) | Commit message format |

---

## Sources

### Install-and-Maintain Pattern
- [IndyDevDan install-and-maintain](https://github.com/disler/install-and-maintain) - Deterministic/agentic/interactive execution modes

### Claude Code Hooks
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) - Official documentation for PreToolUse, matchers, exit codes
- [claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery) - 8 hook lifecycle events, safety patterns
- [destructive_command_guard](https://github.com/Dicklesworthstone/destructive_command_guard) - Git safety patterns, blocked commands list
- [claude-code-safety-net](https://github.com/kenryu42/claude-code-safety-net) - PreToolUse hook for destructive commands

### Obsidian-to-Astro Workflows
- [Automating Obsidian to Astro](https://rachsmith.com/automating-obsidian-to-astro/) - Vault scanning, link processing, frontmatter detection
- [Obsidian/Astro Workflow](https://walterra.dev/blog/2025-03-02-obsidian-astro-workflow) - Real-time preview, mobile capture, sync patterns
- [Astro Composer Plugin](https://github.com/davidvkimball/obsidian-astro-composer) - CTRL+S standardization, Git plugin integration

### Markdown Validation
- [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) - Pre-commit markdown linting with frontmatter support
- [Pre-commit hooks guide](https://gatlenculp.medium.com/effortless-code-quality-the-ultimate-pre-commit-hooks-guide-for-2025-57ca501d9835) - mdformat-frontmatter, lint-staged patterns

### Justfile
- [Just Manual](https://just.systems/man/en/) - Command runner documentation
- [Why Justfile over Makefile](https://suyog942.medium.com/why-justfile-outshines-makefile-in-modern-devops-workflows-a64d99b2e9f0) - Modern workflow benefits

---

**Research completed:** 2026-01-30
**Confidence assessment:**
- Table stakes: HIGH (verified against multiple workflows)
- Differentiators: HIGH (patterns from authoritative sources)
- Anti-features: MEDIUM (some based on domain experience)
- Workflow patterns: HIGH (official Claude Code docs + community examples)

**Downstream:** Requirements definition, roadmap phase structuring
