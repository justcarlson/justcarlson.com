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
| `just list-posts` | Know what's ready to publish | Low | Show posts with `status: - Published` from Obsidian vault |
| `just setup` | First-time configuration | Low | Prompts for Obsidian vault path, writes to config |

### Validation Steps

| Validation | Why Expected | Complexity | Notes |
|------------|--------------|------------|-------|
| Frontmatter presence | Posts without title/date/description fail silently | Low | Required: `title`, `pubDatetime`, `description` |
| Status check | Only publish posts with `status: - Published` | Low | Prevent accidental publishing |
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
   - Find all .md files in vault with `status: - Published` frontmatter
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
- Posts marked with `status: - Published` in frontmatter

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

---

# Addendum: First-Run Experience & Bootstrap UX

**Added:** 2026-01-31
**Focus:** Developer onboarding for a public blog repository
**Context:** Subsequent milestone - adding polish and portability to existing Astro blog

## Problem Statement

When a developer clones this public repo, they face:
1. Multiple manual steps with unclear ordering
2. No single "just works" command
3. Vault path configuration required but not obvious
4. Uncertainty about what to run first

The goal: Transform "clone, read docs, figure out steps, maybe it works" into "clone, run one command, start writing."

---

## First-Run Table Stakes

Features users expect from any developer-friendly open source project. Missing these creates friction and signals poor maintenance.

| Feature | Why Expected | Complexity | Current State |
|---------|--------------|------------|---------------|
| Single setup command | Every modern OSS project has `make setup`, `npm run setup`, or equivalent | Low | Exists: `just setup` |
| README quick start | 3-5 lines to go from zero to running dev server | Low | Partial: npm install + npm run dev documented |
| Dependency installation | Clear path to install required tools | Low | npm install works |
| Interactive prompts for config | Guide first-time users through required choices | Medium | Exists: vault path picker in setup.sh |
| Idempotent setup | Running setup twice doesn't break anything | Low | Exists: setup.sh checks for existing config |
| Error messages with solutions | Don't just fail; explain how to fix | Medium | Partial: validation exists, messages could improve |

### Already Built

- `just setup` - interactive vault path configuration
- `just publish` - full validation pipeline
- SessionStart hook warns if not configured
- `/install` skill for guided setup

### Gaps to Address

- No unified "bootstrap" command that does npm install + setup in one step
- README doesn't mention `just` or the justfile workflow
- No `.tool-versions` or version management for Node.js
- No guidance for contributors without Obsidian vault

---

## First-Run Differentiators

Features that set this project apart. Not expected, but create delight when present.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Zero-config instant start | Works without vault for exploration | Low | Let devs explore site without Obsidian setup |
| Devcontainer/Codespaces support | One-click cloud dev environment | Medium | Eliminates local setup entirely |
| Version file auto-detection | mise/asdf reads `.tool-versions` on cd | Low | Ensures correct Node.js version |
| Smart defaults with override | Works immediately, customize later | Low | Pattern from CLI guidelines |
| Progress indicators | Show what's happening during multi-step setup | Low | Currently silent in some scripts |
| Suggested next steps | After setup completes, show what to do next | Low | "Run `just preview` to start dev server" |
| Dry-run mode | Preview setup actions without executing | Medium | Useful for understanding workflow |
| Health check command | `just doctor` to diagnose issues | Medium | Common in mature CLI tools |

### Prioritization

**High value, low effort (do first):**
1. **Version file** (`.tool-versions` or `.nvmrc`) - 5 minutes, prevents Node version issues
2. **Zero-config preview** - Allow `just preview` without vault for site exploration
3. **Next steps in output** - Add "What to do next" to setup completion message
4. **README justfile section** - Document the `just` workflow for contributors

**High value, medium effort (consider for this milestone):**
1. **Devcontainer** - Eliminates "works on my machine" issues
2. **Health check** (`just doctor`) - Diagnoses missing tools, bad config

**Lower priority (defer):**
1. **Dry-run for setup** - Interactive prompts make this less useful
2. **Progress indicators** - Nice to have but setup is already fast

---

## First-Run Anti-Features

Features to explicitly NOT build. Common over-engineering mistakes in this domain.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Auto-install mise/asdf/nvm | Invasive; users have preferences | Document in README, let them choose |
| npm postinstall hook | Breaks library consumers; unexpected side effects | Use explicit `just setup` command |
| Required GUI for setup | Excludes CI, scripts, headless environments | Interactive prompts with flag overrides |
| Prompt-only config | Breaks automation | Always allow `--vault-path /path` flag |
| Hidden magic commands | Undiscoverable; confusing | All commands in justfile, `just --list` shows all |
| Setup that modifies shell config | Invasive; breaks dotfile management | Keep changes to project directory only |
| Required account/API key for local dev | Friction barrier for contributors | Mock/offline mode for exploration |
| Multi-repo setup | Complex dependencies, harder to test | Keep everything in one repo |

### Anti-Pattern: npm postinstall for Setup

Many projects use `npm postinstall` to run setup scripts automatically. This is problematic because:

1. **Runs on every install** - Even when you just want to install a new dependency
2. **Confuses library consumers** - If this repo is ever used as a package, postinstall runs in their project
3. **Unexpected in CI** - CI environments may not have interactive TTY for prompts
4. **Hard to skip** - No clean way to skip when you know setup isn't needed

**Instead:** Use explicit `just setup` after `npm install`. Make it obvious and intentional.

### Anti-Pattern: Bundling Tool Installation

It's tempting to detect missing tools and auto-install them:
```bash
# DON'T DO THIS
if ! command -v just &> /dev/null; then
    brew install just  # What about Linux? Windows?
fi
```

Problems:
- Package managers vary by OS (brew, apt, pacman, choco)
- Users may prefer different versions or install locations
- Some users run in containers where they can't install globally

**Instead:** Check for required tools, provide clear error messages with install instructions for each platform.

---

## Real-World Patterns

### Pattern 1: Single Entry Point

From [Command Line Interface Guidelines](https://clig.dev/):
> "When users run your command without arguments but it requires them, display brief help text."

**Application:** Running bare `just` shows available commands via `just --list`. This is already implemented.

### Pattern 2: Tiered Onboarding

From developer experience research:
1. **Tier 1 (30 seconds):** Clone and view site without configuration
2. **Tier 2 (2 minutes):** Run setup, configure vault path
3. **Tier 3 (5 minutes):** Understand full workflow, customize

**Application:**
- Tier 1: `npm install && just preview` should work without vault
- Tier 2: `just setup` for full configuration
- Tier 3: CONTRIBUTING.md with detailed workflow

### Pattern 3: Non-Interactive Override

From [UX patterns for CLI tools](https://lucasfcosta.com/2022/06/01/ux-patterns-cli-tools.html):
> "If a user doesn't pass an argument or flag, prompt for it. Never require a prompt."

**Application:** `just setup` is interactive, but `just setup --vault-path /path` should work for automation.

### Pattern 4: Devcontainer for Zero Friction

From [GitHub Codespaces documentation](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers):
> "Want contributors to avoid long setup instructions? Just ship a .devcontainer folder. They'll launch the repo in GitHub Codespaces or locally and get working instantly."

**Application:** Add `.devcontainer/devcontainer.json` with Node.js, just, and npm install in postCreateCommand.

### Pattern 5: Version Pinning

From [mise documentation](https://mise.jdx.dev/dev-tools/):
> "Mise reads .tool-versions files in your project directories. When you enter a folder, mise automatically switches to the versions specified."

**Application:** Add `.tool-versions` or `.nvmrc` to pin Node.js version. Prevents "works on my machine" issues.

---

## Recommended Implementation

### MVP (This Milestone)

1. **Add `.nvmrc`** with Node.js LTS version (e.g., `22.14.0`)
2. **Update README** with justfile workflow:
   ```markdown
   ## Quick Start

   ```bash
   npm install
   just setup     # Configure Obsidian vault path
   just preview   # Start dev server at localhost:4321
   ```

   Don't have an Obsidian vault? You can still explore:
   ```bash
   npm install && npm run dev
   ```
   ```
3. **Add next steps to setup.sh output:**
   ```bash
   echo ""
   echo "What's next:"
   echo "  just preview   - Start dev server"
   echo "  just publish   - Publish posts from Obsidian"
   echo "  just --list    - See all available commands"
   ```
4. **Add `just bootstrap` recipe:**
   ```just
   # Full first-time setup (install dependencies + configure vault)
   bootstrap:
       npm install
       @just setup
   ```
5. **Allow zero-vault exploration:**
   - `just preview` should work without vault configured
   - Only `just publish` requires vault

### Post-MVP (Future Milestone)

1. **Devcontainer support:**
   ```json
   // .devcontainer/devcontainer.json
   {
     "name": "justcarlson.com",
     "image": "mcr.microsoft.com/devcontainers/javascript-node:22",
     "postCreateCommand": "npm install && just setup --vault-path /workspaces/vault",
     "customizations": {
       "vscode": {
         "extensions": ["astro-build.astro-vscode"]
       }
     }
   }
   ```
2. **Health check command:**
   ```just
   # Check development environment is properly configured
   doctor:
       @./scripts/doctor.sh
   ```
3. **Non-interactive setup flag:**
   ```bash
   just setup --vault-path /path/to/vault
   ```

---

## Complexity vs Benefit Matrix

| Feature | Effort | Benefit | Recommend |
|---------|--------|---------|-----------|
| .nvmrc file | 1 min | Prevents version issues | YES |
| README quick start | 10 min | Reduces onboarding friction | YES |
| Next steps in setup output | 5 min | Guides new users | YES |
| `just bootstrap` recipe | 5 min | Single command setup | YES |
| Zero-vault preview | 15 min | Allows exploration | YES |
| Devcontainer | 30 min | Eliminates setup entirely | MAYBE (post-MVP) |
| Health check | 1 hr | Diagnoses issues | MAYBE (post-MVP) |
| Non-interactive setup | 30 min | CI/automation support | LATER |
| Auto-install tools | 2 hr | Invasive | NO |
| npm postinstall | 10 min | Breaks consumers | NO |

---

## Success Criteria

A contributor cloning this repo should:

1. **See clear instructions** - README explains the 3 commands to run
2. **Get correct Node version** - .nvmrc/asdf/mise auto-switches
3. **Have one command option** - `just bootstrap` for full setup
4. **Explore without vault** - Site runs for browsing without Obsidian
5. **Know what's next** - Setup output suggests next steps
6. **Hit no surprises** - No hidden dependencies or magic steps

Time to first successful `just preview`: **Under 2 minutes** (excluding npm install download time)

---

## First-Run Sources

### Primary (HIGH confidence)
- [Command Line Interface Guidelines (clig.dev)](https://clig.dev/) - Authoritative CLI UX patterns
- [UX patterns for CLI tools](https://lucasfcosta.com/2022/06/01/ux-patterns-cli-tools.html) - Interactive vs non-interactive patterns
- [GitHub Codespaces Dev Containers](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers) - Devcontainer configuration
- [mise documentation](https://mise.jdx.dev/dev-tools/) - Version management auto-switching
- [Just Programmer's Manual](https://just.systems/man/en/) - Justfile patterns

### Secondary (MEDIUM confidence)
- [Thoughtworks CLI Design Guidelines](https://www.thoughtworks.com/insights/blog/engineering-effectiveness/elevate-developer-experiences-cli-design-guidelines) - Enterprise CLI patterns
- [getdx.com Developer Experience Guide](https://getdx.com/blog/developer-experience/) - DX measurement and improvement
- [ITHAKA Developer Onboarding](https://medium.com/build-smarter/onboarding-a-developer-fast-5017fac5ef28) - Bootstrap script patterns

### Existing Codebase (verified)
- `/home/jc/developer/justcarlson.com/justfile` - Current recipes
- `/home/jc/developer/justcarlson.com/scripts/setup.sh` - Interactive setup script
- `/home/jc/developer/justcarlson.com/README.md` - Current documentation

---

*First-run research added: 2026-01-31*
*Focus: First-run experience and bootstrap UX*

---

# Addendum: Two-Way Sync Workflow Behaviors

**Added:** 2026-02-01
**Focus:** CLI publishing workflow with two-way sync between Obsidian and blog
**Context:** Refactoring milestone - improving existing CLI publishing workflow

## Problem Statement

Current workflow has gaps in two-way synchronization:
1. **Unpublish doesn't update Obsidian** - After running `just unpublish`, user must manually update Obsidian to prevent re-publishing
2. **pubDatetime set at wrong time** - Template creation sets date, but it should be set when actually publishing
3. **Discovery uses array format** - Current `status: - Published` is unusual; standard is `draft: false`

The goal: Bidirectional metadata sync so Obsidian and blog stay consistent without manual intervention.

---

## Two-Way Sync Table Stakes

Features users expect from a two-way sync workflow. Missing = workflow feels broken.

| Feature | Why Expected | Complexity | Current Status |
|---------|--------------|------------|----------------|
| **Publish updates existing posts** | Users expect `publish` to work idempotently - running it again updates rather than fails | Low | Implemented (detects changes) |
| **Unpublish updates Obsidian source** | Two-way sync requires both sides stay consistent; manual Obsidian update is friction | Medium | Missing - current gap |
| **pubDatetime set at publish time** | Publication date should reflect when content went live, not when template was created | Low | Missing - set at template creation |
| **Confirmation before destructive actions** | Unpublish removes content; users expect a safety check | Low | Implemented (default N) |
| **Dry-run mode for all operations** | Users want to preview changes before committing | Low | Publish only, missing for unpublish |
| **Clear feedback on what changed** | CLI should report what files were modified, created, removed | Low | Implemented |
| **Rollback on failure** | If lint/build fails, don't leave partial state | Medium | Implemented |

---

## Two-Way Sync Behavior Specification

### Source of Truth Pattern

**Obsidian is the source of truth for:**
- Content body
- Title, description, tags
- Draft/publish intent (`draft` field)
- Whether post should be published

**Blog repo is the derived output:**
- Receives transformed content from Obsidian
- Gets normalized frontmatter (author array -> string, etc.)
- Contains computed `pubDatetime` (set once at first publish)
- May contain `modDatetime` for updates

**Conflict resolution:** If Obsidian and blog diverge, Obsidian wins. The publish operation is one-way content flow with two-way metadata sync.

### Publish Flow (Source -> Destination)

**First-time publish:**
1. Copy post from Obsidian to blog repo
2. Set `pubDatetime` to current timestamp (if not already set)
3. Update Obsidian source: change `draft: true` to `draft: false`
4. Commit blog changes
5. Report success with post URL

**Re-publish (update):**
1. Detect content/frontmatter differences between Obsidian and blog
2. If identical: skip with "already up to date" message
3. If different: copy updated content, preserve original `pubDatetime`
4. Update `modDatetime` in blog copy (optional)
5. Commit with "update" message
6. Report what changed

**Expected behaviors:**
- Idempotent: running publish multiple times has same effect
- Non-destructive: doesn't lose work in either location
- Atomic: either fully succeeds or fully rolls back

### Unpublish Flow (Destination -> Source)

**Standard unpublish:**
1. Confirm action (unless `--force`)
2. Remove post from blog repo
3. Update Obsidian source: change `draft: false` to `draft: true`
4. Preserve `pubDatetime` in Obsidian (for potential republish)
5. Commit blog removal
6. Report success

**Expected behaviors:**
- Confirmation required by default (destructive action)
- Source file preserved (never delete Obsidian content)
- Two-way: Obsidian reflects unpublished state
- Prevents accidental re-publish on next `just publish`

---

## pubDatetime Handling Options

**Option A: Set once, preserve forever (Recommended)**
- Set `pubDatetime` at first publish
- Never modify, even on unpublish
- On republish, reuse original date
- Rationale: Publication date is historical fact

**Option B: Clear on unpublish**
- Set `pubDatetime` at publish
- Clear on unpublish
- Set fresh timestamp on republish
- Rationale: Each publish is new publication event

**Option C: User choice**
- Flag `--preserve-date` or `--fresh-date` on republish
- Default to preserve
- Rationale: Flexibility for different use cases

**Recommendation:** Option A. Publication date should be stable for URLs, RSS feeds, and SEO. "Last updated" is a separate concern handled by `modDatetime`.

---

## Two-Way Sync Differentiators

Features that improve UX beyond basic expectations. Not required, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Batch unpublish** | Remove multiple posts at once | Low | Currently only single-post unpublish |
| **Dry-run for unpublish** | Preview what unpublish would do | Low | Matches publish --dry-run pattern |
| **Preserve pubDatetime on unpublish** | Keeps publication history for potential republish | Low | Allows "republish" without losing original date |
| **Interactive post selection for unpublish** | Use gum/fzf to select posts to unpublish | Medium | Matches publish selection pattern |
| **modDatetime tracking** | Track last modification date separately from publish date | Low | Good for SEO "last updated" display |
| **Validation before unpublish** | Warn if unpublishing breaks links from other posts | Medium | Prevents broken internal links |
| **Undo unpublish** | Quick republish of recently unpublished post | Medium | Requires tracking unpublish history |

---

## Two-Way Sync Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Auto-sync file watcher** | Complexity, battery drain, unintentional publishes | Explicit `just publish` command |
| **Delete Obsidian source on unpublish** | Data loss risk, against source-of-truth principle | Only update frontmatter |
| **Bi-directional content sync** | Blog edits should go in Obsidian first; prevents divergence | One-way content flow |
| **Silent unpublish (no confirmation)** | Destructive action needs friction | Default to confirmation prompt |
| **Multiple source of truth** | Leads to merge conflicts, confusion | Obsidian is always authoritative |
| **Auto-resolve conflicts by overwriting** | Data loss risk | Warn user, require explicit resolution |
| **Over-confirmation (confirm every step)** | Alert fatigue, users stop reading | Confirm once for batch, skip for non-destructive |

---

## Edge Cases

Scenarios that need explicit handling.

### Republish After Unpublish

**Scenario:** User unpublishes a post, then wants to republish it later.

**Expected behavior:**
1. Post still exists in Obsidian with `draft: true`
2. User changes to `draft: false` (or equivalent)
3. Running `just publish` discovers and republishes
4. Preserve original `pubDatetime` if it exists

**Recommendation:** Preserve original `pubDatetime` if it exists in Obsidian frontmatter, otherwise set new timestamp.

### Partial Failure During Publish

**Scenario:** Post copied to blog, but lint fails.

**Current behavior:** Rollback removes copied files, leaves Obsidian unchanged.

**Expected behavior:** Same - Obsidian source should not be modified until operation fully succeeds.

**Recommendation:** Update Obsidian frontmatter as final step, after commit. If any prior step fails, Obsidian remains unchanged.

### Partial Failure During Unpublish

**Scenario:** Post removed from blog, but Obsidian update fails.

**Expected behavior:**
1. Attempt to restore blog post (if possible)
2. If restore fails, warn user about inconsistent state
3. Provide manual recovery steps

**Recommendation:** Unpublish in this order:
1. Read and validate Obsidian file exists and is writable
2. Remove from blog repo
3. Update Obsidian frontmatter
4. Commit blog changes
5. If step 3 fails after step 2, restore blog file before commit

### Post Exists in Blog But Not Obsidian

**Scenario:** User deletes Obsidian source file but blog copy remains.

**Expected behavior:**
- `just list-posts --published` should still show it
- `just unpublish` should work (remove blog copy)
- No Obsidian update attempted (source missing)

**Recommendation:** Handle gracefully. Unpublish should succeed even without Obsidian source.

### Content Divergence

**Scenario:** User manually edits blog copy (not Obsidian).

**Expected behavior:**
- Next `just publish` would overwrite blog with Obsidian content
- This is correct - Obsidian is source of truth

**Recommendation:** Could add `--preserve-blog` flag for edge cases, but default should be Obsidian wins.

---

## Feature Dependencies

```
draft field in Obsidian
        |
        v
publish command -----> unpublish command
    |                       |
    v                       v
[sets draft: false]    [sets draft: true]
[sets pubDatetime]     [preserves pubDatetime]
    |                       |
    v                       v
blog copy created       blog copy removed
    |                       |
    v                       v
git commit              git commit
```

**Dependency chain:**
1. Obsidian template must support `draft` field
2. Publish must update `draft` field in Obsidian
3. Unpublish must update `draft` field in Obsidian
4. Both commands need write access to Obsidian vault

---

## Draft Field Semantics

### Current: `status: Published`

```yaml
status:
  - Published
```

**Issues:**
- Array format is unusual for boolean intent
- Mixes with other potential statuses
- Requires multiline YAML parsing

### Proposed: `draft: true/false`

```yaml
draft: false  # Published
draft: true   # Not published
```

**Benefits:**
- Standard pattern across static site generators (Hugo, Astro, Gatsby)
- Boolean is cleaner than array
- Single-line, easy to parse and update
- Matches Astro content collection schema

**Migration path:**
1. New template uses `draft: true`
2. Publish script sets `draft: false`
3. Keep backward compatibility for `status: Published` during transition
4. Eventually deprecate `status` field

---

## MVP Recommendation for Refactoring Milestone

Prioritize these features:

1. **Unpublish updates Obsidian** (Table stakes - closes the gap)
   - Set `draft: true` in Obsidian source
   - Prevents accidental re-publish

2. **pubDatetime at publish time** (Table stakes - fixes template issue)
   - Set timestamp when `just publish` runs (if not already set)
   - Preserve existing `pubDatetime` on updates

3. **Dry-run for unpublish** (Low effort, matches publish pattern)
   - `just unpublish <slug> --dry-run`

Defer to post-milestone:
- Batch unpublish: adds complexity, single post sufficient for now
- modDatetime tracking: nice-to-have, not blocking
- Interactive unpublish selection: polish feature
- Migration from `status` to `draft` field: can be separate task

---

## Two-Way Sync Sources

### Industry Patterns
- [Two-Way Sync Demystified: Key Principles And Best Practices](https://www.stacksync.com/blog/two-way-sync-demystified-key-principles-and-best-practices) - Source of truth patterns
- [Confirmation Dialogs Can Prevent User Errors - NN/g](https://www.nngroup.com/articles/confirmation-dialog/) - When to confirm destructive actions
- [How to Design Better Destructive Action Modals](https://uxpsychology.substack.com/p/how-to-design-better-destructive) - UX patterns for dangerous operations
- [Smashing Magazine: How To Manage Dangerous Actions](https://www.smashingmagazine.com/2024/09/how-manage-dangerous-actions-user-interfaces/) - Friction proportional to impact

### Static Site Publishing
- [Date and Time with a Static Site Generator](https://blog.jim-nielsen.com/2023/date-and-time-in-ssg/) - pubDatetime best practices
- [Published vs Last Updated Date: Which is Better for SEO?](https://www.contentpowered.com/blog/published-modified-date-seo/) - Date handling for SEO
- [Creating Markdown Drafts with Gatsby](https://tina.io/blog/creating-markdown-drafts) - Draft mode workflow patterns
- [Publishing from Obsidian](https://cassidoo.co/post/publishing-from-obsidian/) - Obsidian to blog workflow

### CLI Patterns
- [Introducing Idempotent Publishing](https://ably.com/blog/introducing-idempotent-publishing) - Idempotency in publishing
- [cfn-create-or-update](https://cloudonaut.io/painlessly-create-or-update-cloudformation-stack-idempotent/) - CLI idempotent patterns

---

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Two-way sync behavior | HIGH | Clear industry patterns, analyzed current implementation |
| pubDatetime handling | HIGH | Standard practice: set once, preserve |
| Unpublish UX | HIGH | Well-established destructive action patterns |
| Draft field semantics | HIGH | Matches Astro/Hugo/Gatsby conventions |
| Edge case handling | MEDIUM | Reasonable inference, needs validation in practice |

---

*Two-way sync research added: 2026-02-01*
*Focus: CLI publishing workflow behaviors for refactoring milestone*

---

# Addendum: Graceful Fallback for Blocked External Services

**Added:** 2026-02-02
**Focus:** Graceful degradation when external services are blocked
**Context:** Subsequent milestone - ensuring pages load fully when external services unavailable

## Problem Statement

Personal blog currently relies on external services that may be blocked:

1. **Gravatar** (`gravatar.com`) - Avatar image on homepage
2. **Vercel Analytics** (`vercel.com`) - Page view tracking
3. **Potential future additions:**
   - Twitter/X embeds
   - External fonts (currently self-hosted)
   - Social card previews

Users may have these services blocked due to:
- Corporate firewalls blocking social/tracking domains
- Privacy-focused browsers (Brave, Firefox with strict settings)
- Browser extensions (uBlock Origin, Privacy Badger)
- VPNs with built-in ad/tracker blocking
- Network-level Pi-hole or AdGuard configurations

**Goal:** Pages should load fully and look complete regardless of blocked services.

---

## Current State Analysis

### What's Currently in Place

| Service | Current Implementation | Fallback? |
|---------|------------------------|-----------|
| **Gravatar** | Direct `<img>` tag with `?d=identicon` parameter | Partial - Gravatar's server-side fallback works only if Gravatar is reachable |
| **Vercel Analytics** | Dynamic import in `Analytics.astro` | Yes - fails silently (script just doesn't load) |
| **Fonts** | Self-hosted in `/public/fonts/` with `font-display: swap` | Yes - system fonts show while loading, work if blocked |
| **Social embeds** | YouTube processing in `PostDetails.astro` | None currently implemented for Twitter/X |

### Current Issues

1. **Gravatar avatar shows broken image** when `gravatar.com` is blocked
   - Current: `src="https://gravatar.com/avatar/...?d=identicon"`
   - Problem: `?d=identicon` is server-side fallback - requires Gravatar to be reachable
   - Impact: Broken image icon displayed on homepage

2. **Analytics failure is silent but correct**
   - Current: `import('@vercel/analytics')` in production only
   - Works: If blocked, import fails, no analytics, page still works
   - No action needed

3. **Fonts work correctly**
   - Self-hosted `.woff` files in `/public/fonts/`
   - `font-display: swap` ensures text shows immediately
   - Falls back to system fonts if fonts blocked/slow
   - No action needed

---

## Graceful Fallback Table Stakes

Features users expect. Missing = page appears broken or unprofessional.

| Feature | Why Expected | Complexity | Current State |
|---------|--------------|------------|---------------|
| **No broken image icons** | Broken images signal unmaintained site | Low | Missing - Gravatar shows broken icon |
| **Page loads without network dependencies** | Core content shouldn't require external services | Low | Mostly working (fonts self-hosted) |
| **No console errors visible to users** | Errors suggest site is broken | Low | Analytics fails silently (good) |
| **Consistent visual appearance** | Site should look complete even with degradation | Medium | Missing - avatar hole when blocked |
| **No layout shift from failed resources** | CLS hurts UX and SEO | Low | Avatar has fixed dimensions (good) |

### Avatar Fallback Requirement

When Gravatar is blocked, users should see:
1. A visually complete avatar area (not a broken image icon)
2. Ideally: Initials or a local default image
3. No layout shift when fallback activates

---

## Graceful Fallback Differentiators

Features that exceed basic expectations. Not required, but create polish.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Initials avatar fallback** | Personal touch, feels intentional not broken | Low | CSS-only or minimal JS |
| **Local default avatar** | Completely offline-capable | Low | Single image in `/public/` |
| **Graceful embed degradation** | Twitter/X embeds show link card when blocked | Medium | Future-proofing for social embeds |
| **Service health indicators** | Debug mode showing what's blocked | High | Developer feature, not user-facing |
| **Lazy fallback (try external first)** | Prefer external when available, fall back gracefully | Medium | Best of both worlds |

### Differentiator Priority

**Implement now:**
1. **Local default avatar** - Simplest, always works
2. **Initials avatar** - More personal, still simple

**Implement later (when adding social embeds):**
3. **Graceful embed degradation** - Only needed if/when Twitter embeds added

---

## Graceful Fallback Anti-Features

Features to deliberately NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Bypass ad blockers for analytics** | Disrespects user privacy choices | Accept analytics gaps gracefully |
| **Retry loops for blocked resources** | Wastes bandwidth, battery | Fail once, show fallback |
| **Complex service health checking** | Over-engineering for personal blog | Simple onerror fallback |
| **Multiple fallback chains** | Complexity for diminishing returns | One fallback is enough |
| **Custom error boundary per resource** | React pattern, overkill for Astro static site | HTML/CSS fallbacks |
| **Server-side proxy for blocked services** | Circumvents user intent, adds complexity | Respect blocks, provide local fallback |

### Why NOT Bypass Ad Blockers

Some tutorials suggest proxying Vercel Analytics through your own domain to bypass blockers. This is an anti-feature because:

1. **Disrespects user choice** - They blocked tracking for a reason
2. **Cat and mouse game** - Blockers eventually catch proxied analytics
3. **Unnecessary for personal blog** - Analytics are nice-to-have, not critical
4. **Adds complexity** - Server configuration, maintenance burden

**Instead:** Accept that some users won't be tracked. Focus on content quality over metrics completeness.

---

## Implementation Patterns

### Pattern 1: Image Fallback with `onerror` (Recommended for Gravatar)

The standard pattern for handling broken images:

```html
<img
  src="https://gravatar.com/avatar/hash?s=400"
  alt="Author Name"
  onerror="this.onerror=null; this.src='/images/default-avatar.png';"
  class="avatar"
/>
```

**How it works:**
1. Browser attempts to load Gravatar
2. If blocked/fails, `onerror` fires
3. `this.onerror=null` prevents infinite loop if fallback also fails
4. `this.src` updates to local fallback

**Requirements:**
- Local fallback image at `/public/images/default-avatar.png`
- Same dimensions as expected Gravatar (160x160 or similar)

### Pattern 2: CSS-Only Initials Fallback with `<object>` Element

Uses HTML `<object>` element's built-in fallback behavior:

```html
<object
  type="image/jpeg"
  data="https://gravatar.com/avatar/hash?s=400"
  class="avatar"
  aria-label="Author Name"
>
  <div class="avatar-initials">JC</div>
</object>
```

```css
.avatar {
  width: 160px;
  height: 160px;
  border-radius: 50%;
  overflow: hidden;
}

.avatar-initials {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, var(--accent), var(--muted));
  color: var(--background);
  font-size: 3rem;
  font-weight: bold;
}
```

**How it works:**
1. `<object>` tries to load external image
2. If fails, renders inner content (initials div)
3. Pure HTML/CSS, no JavaScript required

**Benefits:**
- Works without JavaScript
- Graceful degradation is built into HTML spec
- Initials feel more personal than generic avatar

### Pattern 3: JavaScript with Graceful Enhancement

For more control over fallback timing:

```html
<img
  src="/images/default-avatar.png"
  data-src="https://gravatar.com/avatar/hash?s=400"
  alt="Author Name"
  class="avatar"
/>
```

```javascript
document.addEventListener('DOMContentLoaded', () => {
  const avatar = document.querySelector('.avatar[data-src]');
  if (avatar) {
    const img = new Image();
    img.onload = () => {
      avatar.src = img.src;
    };
    img.src = avatar.dataset.src;
  }
});
```

**How it works:**
1. Show local fallback immediately
2. Attempt to load Gravatar in background
3. If successful, swap in Gravatar
4. If fails, local fallback remains

**Benefits:**
- No flash of broken image
- Progressive enhancement
- Works even if JS fails

### Pattern 4: Social Embed Fallback (Future Use)

For Twitter/X embeds that may be blocked:

```html
<!-- Progressive enhancement: blockquote is fallback -->
<blockquote class="twitter-fallback">
  <p>Tweet content here...</p>
  <cite>
    <a href="https://twitter.com/user/status/123">
      @user - View on Twitter
    </a>
  </cite>
</blockquote>

<!-- Twitter widget attempts to replace with iframe -->
<script async src="https://platform.twitter.com/widgets.js"></script>
```

**How it works:**
1. Blockquote displays immediately with tweet text
2. If Twitter JS loads, it enhances to full embed
3. If blocked, blockquote remains as graceful fallback

**Benefits:**
- Content always visible
- No broken iframe/spinner
- Progressive enhancement pattern

---

## Recommended Implementation for This Milestone

### MVP: Simple `onerror` Fallback

**Files to modify:**
1. `src/pages/index.astro` - Add onerror handler to avatar
2. `/public/images/` - Add default avatar image

**Implementation:**

```astro
<!-- src/pages/index.astro -->
<img
  src="https://gravatar.com/avatar/ef133a0cc6308305d254916b70332b1a?s=400&d=identicon"
  alt={SITE.author}
  onerror="this.onerror=null; this.src='/images/default-avatar.png';"
  class="w-40 h-40 rounded-full object-cover flex-shrink-0 transition-all duration-300 group-hover:scale-105 group-hover:shadow-xl"
/>
```

**Fallback image options:**
1. **Generic avatar icon** - Simple, professional
2. **Initials image** - Pre-rendered "JC" in brand colors
3. **Photo** - Local copy of the Gravatar image (most seamless)

**Recommendation:** Use a local copy of the actual Gravatar image. This provides:
- Identical appearance when Gravatar blocked
- No visual difference for users
- Simple implementation

### Post-MVP: Initials Fallback (Optional Enhancement)

If wanting more dynamic fallback:

```astro
<object
  type="image/jpeg"
  data="https://gravatar.com/avatar/ef133a0cc6308305d254916b70332b1a?s=400"
  class="w-40 h-40 rounded-full overflow-hidden flex-shrink-0"
  aria-label={SITE.author}
>
  <div class="w-full h-full flex items-center justify-center bg-gradient-to-br from-accent to-muted text-background text-5xl font-bold">
    JC
  </div>
</object>
```

---

## UX Expectations by Scenario

| Scenario | Expected Behavior | Implementation |
|----------|-------------------|----------------|
| **Gravatar blocked** | Local avatar shows, identical or similar appearance | `onerror` or `<object>` fallback |
| **Gravatar slow** | Avatar area shows immediately (no spinner), loads when ready | Fixed dimensions prevent layout shift |
| **Analytics blocked** | Page works normally, no console errors | Current implementation sufficient |
| **All external blocked** | Page fully functional, content readable | Self-hosted fonts + local avatar |
| **JavaScript disabled** | Page renders with fallback avatar | `<object>` pattern works without JS |

---

## Dependencies on Existing Features

| Existing Feature | How Fallback Uses It |
|------------------|----------------------|
| Self-hosted fonts (`/public/fonts/`) | Already provides font fallback |
| `font-display: swap` in CSS | Ensures text visible while fonts load |
| PWA/offline support | Could cache fallback avatar |
| Fixed avatar dimensions | Prevents layout shift during fallback |
| Vercel Analytics dynamic import | Already fails gracefully |

---

## Testing Checklist

To verify fallback implementation:

1. **Block Gravatar in browser:**
   - Chrome: DevTools > Network > Block request URL containing "gravatar.com"
   - Firefox: uBlock Origin > Block gravatar.com

2. **Verify:**
   - [ ] No broken image icon displayed
   - [ ] Fallback avatar appears in correct position
   - [ ] No layout shift when fallback loads
   - [ ] No console errors related to failed image
   - [ ] Page remains fully functional

3. **Block all external:**
   - Use browser offline mode or firewall rules
   - Verify page content is readable and styled

---

## Sources

### Image Fallback Techniques
- [HTML fallback images on error - DEV Community](https://dev.to/dailydevtips1/html-fallback-images-on-error-1aka) - `onerror` pattern
- [HTML only image fallback - DEV Community](https://dev.to/albertodeago88/html-only-image-fallback-19im) - `<object>` element pattern
- [Fallbacks for HTTP 404 images - Sentry](https://blog.sentry.io/fallbacks-for-http-404-images-in-html-and-javascript/) - Comprehensive fallback strategies
- [Setting a Fallback Image in HTML - Codu](https://www.codu.co/niall/setting-a-fallback-image-in-html-for-broken-or-missing-images-otom_bhg) - Simple onerror implementation

### CSS Avatar Fallbacks
- [A CSS-only Avatar Fallback - LaunchScout](https://launchscout.com/blog/updated-avatar-fallback) - Object element with CSS
- [Avatar images with Initials fallback - CodePen](https://codepen.io/fuggfuggfugg/pen/zNPvma) - CSS initials pattern
- [Default Avatars With User Initials](https://ianwaldron.com/article/48/default-avatars-with-user-initials/) - Full implementation guide

### Graceful Degradation Best Practices
- [The Importance Of Graceful Degradation - Smashing Magazine](https://www.smashingmagazine.com/2024/12/importance-graceful-degradation-accessible-interface-design/) - Core principles
- [A guide to graceful degradation - LogRocket](https://blog.logrocket.com/guide-graceful-degradation-web-development/) - Implementation patterns
- [Progressive enhancement - MDN](https://developer.mozilla.org/en-US/docs/Glossary/Progressive_Enhancement) - Foundation concept

### Font Loading
- [Optimize WebFont loading - web.dev](https://web.dev/articles/optimize-webfont-loading) - Font-display and fallbacks
- [Improved font fallbacks - Chrome Blog](https://developer.chrome.com/blog/font-fallbacks) - Modern fallback techniques
- [CSS Fallback Fonts - W3Schools](https://www.w3schools.com/cssref/css_fonts_fallbacks.php) - Font stack basics

### Analytics and Blocking
- [Vercel Analytics Troubleshooting](https://vercel.com/docs/analytics/troubleshooting) - Official docs on blocked analytics
- [Understanding Corporate Firewall Policies - NameSilo](https://www.namesilo.com/blog/en/privacy-security/understanding-corporate-firewall-policies-why-some-domains-get-blocked) - Why services get blocked

### Social Embed Patterns
- [Static twitter embed - Ian Muchina](https://ianmuchina.com/blog/12-tweet-embed/) - No-JS Twitter fallback
- [Embedded Tweet CMS best practices - Twitter Docs](https://developer.twitter.com/en/docs/twitter-for-websites/embedded-tweets/guides/cms-best-practices) - Official fallback guidance

---

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Avatar fallback patterns | HIGH | Multiple verified implementations, standard HTML/CSS |
| Analytics handling | HIGH | Current implementation already correct |
| Font fallback | HIGH | Already implemented with `font-display: swap` |
| Social embed patterns | MEDIUM | Researched but not yet implemented in codebase |
| Corporate firewall scenarios | MEDIUM | Based on industry research, not directly tested |

---

*Graceful fallback research added: 2026-02-02*
*Focus: Graceful degradation for blocked external services*
