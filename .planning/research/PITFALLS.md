# Pitfalls Research: justfile + Hooks Publishing

**Domain:** Blog publishing workflow (Obsidian to Astro)
**Researched:** 2026-01-30
**Confidence:** HIGH (official docs verified)

## justfile Pitfalls

### Critical: Each Recipe Line Runs in a New Shell

**What goes wrong:** Commands that set environment variables or change directories don't persist to subsequent lines.

```just
# BROKEN - cd doesn't persist
build:
  cd src
  npm run build  # Still runs in original directory!
```

**Why it happens:** Just executes each recipe line in a fresh shell instance.

**Prevention:**
- Chain commands with `&&`: `cd src && npm run build`
- Use shebang recipes for complex scripts that need state

```just
# FIXED - shebang recipe keeps shell state
build:
  #!/usr/bin/env bash
  cd src
  npm run build  # Works - same shell instance
```

**Warning signs:** Commands appear to work but have no effect; build runs in wrong directory.

**Phase:** 7 (Setup & Safety) - Establish pattern in first justfile recipes

**Source:** [Just Programmer's Manual](https://just.systems/man/en/)

---

### Critical: Variable Syntax Confusion ({{var}} vs $VAR)

**What goes wrong:** Using shell variable syntax (`$VAR`) when just variable syntax (`{{var}}`) is needed, or vice versa.

```just
# BROKEN - mixing syntax incorrectly
vault_path := "/path/to/vault"
publish:
  cp $vault_path/posts/* ./src/content/  # Wrong! $vault_path is shell variable
```

**Why it happens:** Just uses `{{variable}}` for its own variables, `$VARIABLE` for shell/environment variables.

**Prevention:**
- Just variables: `{{variable_name}}` (defined in justfile)
- Environment variables: `$VARIABLE_NAME` (from .env or shell)
- Use `set dotenv-load` to enable .env file loading

```just
# CORRECT - proper variable syntax
vault_path := "/path/to/vault"
publish:
  cp "{{vault_path}}/posts/"* ./src/content/
```

**Warning signs:** "undefined variable" errors, empty strings where values expected.

**Phase:** 7 (Setup & Safety) - Document syntax in justfile comments

**Source:** [Just Programmer's Manual - Recipe Parameters](https://just.systems/man/en/recipe-parameters.html)

---

### Moderate: Nested Just Invocations Lose State

**What goes wrong:** Calling `just` from within a recipe recalculates assignments and loses CLI arguments.

```just
# PROBLEMATIC - nested just loses context
all:
  just build
  just test   # CLI arguments not propagated, assignments recalculated
```

**Why it happens:** Each `just` invocation is independent with fresh state.

**Prevention:**
- Use dependencies instead of nested calls
- Pass required values explicitly as arguments

```just
# BETTER - use dependencies
all: build test

# Or pass values explicitly
build-and-test target:
  just build {{target}} && just test {{target}}
```

**Warning signs:** Dependencies run twice; behavior differs when run directly vs nested.

**Phase:** 8 (Core Publishing) - Structure publish pipeline as dependencies

**Source:** [GitHub - casey/just](https://github.com/casey/just)

---

### Moderate: Cross-Platform Shell Compatibility

**What goes wrong:** Recipes use bash-specific features that fail on other shells or platforms.

**Why it happens:** Just defaults to `/bin/sh`, which may not support bash features.

**Prevention:**
- Explicitly set shell: `set shell := ["bash", "-cu"]`
- Test on target platforms
- Avoid bash-only features when possible

```just
set shell := ["bash", "-cu"]

# Now bash features work reliably
publish:
  if [[ -f "./config.json" ]]; then
    echo "Config found"
  fi
```

**Warning signs:** `[[` syntax errors; brace expansion fails.

**Phase:** 7 (Setup & Safety) - Set shell explicitly at top of justfile

**Source:** [Just Settings - Configuring the Shell](https://just.systems/man/en/settings.html)

---

### Minor: Indentation Must Be Consistent Within Recipe

**What goes wrong:** Mixing spaces and tabs in recipe lines causes parse errors.

**Prevention:**
- Use consistent indentation (tabs recommended by just)
- Different recipes can use different indentation, but each recipe must be internally consistent

**Warning signs:** Parse errors mentioning indentation; "unexpected character" errors.

**Phase:** 7 (Setup & Safety) - Establish editorconfig pattern

---

## Claude Hooks Pitfalls

### Critical: Exit Code 2 Ignores JSON Output

**What goes wrong:** Hook returns exit code 2 (blocking error) with JSON in stdout, but JSON is ignored. Only stderr is used.

```bash
# BROKEN - JSON ignored with exit code 2
echo '{"decision": "block", "reason": "Dangerous operation"}'
exit 2  # stderr used, stdout JSON ignored!
```

**Why it happens:** By design, exit code 2 means "blocking error" and uses stderr directly.

**Prevention:**
- For blocking with JSON control: exit 0 with `"decision": "block"` in JSON
- For simple blocking: exit 2 with error message in stderr

```bash
# CORRECT - JSON blocking (exit 0)
echo '{"decision": "block", "reason": "Dangerous operation"}'
exit 0

# CORRECT - simple blocking (exit 2)
echo "Dangerous operation blocked: force push not allowed" >&2
exit 2
```

**Warning signs:** Hook blocks operations but custom JSON reasons never appear.

**Phase:** 7 (Setup & Safety) - Use exit 2 + stderr for git safety hooks

**Source:** [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)

---

### Critical: PostToolUse JSON Not Processed (Known Bug)

**What goes wrong:** PostToolUse hooks can execute but their JSON output is not captured by Claude.

**Why it happens:** Bug in Claude Code (Issue #3983, July 2025). JSON communication documented but not working.

**Prevention:**
- For PostToolUse, use exit codes + stderr for critical blocking
- Write diagnostic data to external log files as workaround
- Consider PreToolUse hooks instead where possible

**Warning signs:** PostToolUse hooks run but Claude never receives feedback.

**Phase:** 8 (Core Publishing) - Prefer PreToolUse for validation

**Source:** [GitHub Issue #3983](https://github.com/anthropics/claude-code/issues/3983)

---

### Critical: Plugin Hooks vs Inline Hooks Behave Differently

**What goes wrong:** Hooks that work perfectly in `.claude/settings.json` fail when installed via plugins.

**Why it happens:** Plugin hooks' stdout not captured the same way (Issue #10875, November 2025).

**Prevention:**
- Use inline hooks in settings.json for critical safety hooks
- Test hooks in both plugin and inline configurations
- Don't rely on plugins for safety-critical hooks

**Warning signs:** Same hook script works inline but fails via plugin.

**Phase:** 7 (Setup & Safety) - Use inline hooks in settings.json, not plugins

**Source:** [GitHub Issue #10875](https://github.com/anthropics/claude-code/issues/10875)

---

### Moderate: Hook Configuration Changes Require Restart

**What goes wrong:** Edit hooks in settings file, but old behavior persists.

**Why it happens:** Claude Code captures hook snapshot at startup for security.

**Prevention:**
- After editing hooks, restart Claude Code
- Use `/hooks` command to verify configuration loaded correctly
- Changes to running session require explicit review in `/hooks` menu

**Warning signs:** New hook doesn't trigger; old (deleted) hook still runs.

**Phase:** 7 (Setup & Safety) - Document restart requirement

**Source:** [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)

---

### Moderate: 60-Second Default Timeout

**What goes wrong:** Long-running hooks (builds, linting) timeout before completion.

**Why it happens:** Default hook timeout is 60 seconds.

**Prevention:**
- Set explicit timeout per command: `"timeout": 300` (5 minutes for builds)
- Keep validation hooks fast; offload heavy work to justfile

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "./validate.sh",
        "timeout": 120
      }]
    }]
  }
}
```

**Warning signs:** Hook exits mid-execution; inconsistent behavior under load.

**Phase:** 8 (Core Publishing) - Set 300s timeout for build hooks

**Source:** [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)

---

### Minor: Matcher Patterns Are Case-Sensitive

**What goes wrong:** Hook matches "bash" but tool is "Bash".

**Prevention:**
- Tool names are case-sensitive: `Bash`, `Write`, `Edit`, `Read`
- Use regex for flexibility: `"matcher": "[Bb]ash"`
- Use `*` to match all tools

**Warning signs:** Hook never triggers despite correct event.

**Phase:** 7 (Setup & Safety) - Use exact tool names from documentation

---

### Minor: settings.local.json Must Be Created Carefully

**What goes wrong:** Creating `.claude/settings.local.json` doesn't auto-gitignore; sensitive paths committed.

**Why it happens:** Claude Code auto-configures gitignore only when it creates the file.

**Prevention:**
- Let Claude Code create the file via hooks/skills
- Or manually add to `.gitignore`: `.claude/settings.local.json`
- Never commit vault paths or personal paths

**Warning signs:** Local config appears in git status.

**Phase:** 7 (Setup & Safety) - Verify gitignore entry exists

**Source:** [Claude Code Settings](https://code.claude.com/docs/en/settings)

---

## Publishing Workflow Pitfalls

### Critical: Obsidian Image Syntax Not Standard Markdown

**What goes wrong:** Obsidian's `![[image.png]]` embed syntax doesn't render in Astro.

**Why it happens:** Obsidian uses proprietary wiki-link syntax for embeds.

**Prevention:**
- Configure Obsidian: Settings > Files & Links > New Link Format = "Relative path to file"
- Convert `![[image.png]]` to `![alt](./image.png)` during publishing
- Use Image Converter plugin in Obsidian

```bash
# Convert Obsidian syntax to standard markdown
sed -i 's/!\[\[\([^]]*\)\]\]/![\1](.\/\1)/g' "$post_file"
```

**Warning signs:** Images display in Obsidian but broken in Astro build.

**Phase:** 8 (Core Publishing) - Image syntax conversion in publish pipeline

**Source:** [Write Like a Pro with Astro and Obsidian](https://www.hungrimind.com/articles/obsidian-with-astro)

---

### Critical: Relative Image Paths Break in Astro Content Collections

**What goes wrong:** Image `![](./image.png)` in markdown causes build failure when Astro can't resolve the path.

**Why it happens:** Astro copies/optimizes images to `_astro/` folder, breaking relative references.

**Prevention:**
- Copy images to `public/assets/blog/` with absolute paths
- Update image references in markdown to `/assets/blog/image.png`
- Or use Astro's content collection image helper for type-safe image references

```just
# Copy images alongside posts
copy-images post:
  find "{{vault}}/{{post}}" -name "*.png" -o -name "*.jpg" | \
    xargs -I{} cp {} public/assets/blog/
```

**Warning signs:** Build fails with "could not find image" errors; images work in dev but fail in build.

**Phase:** 8 (Core Publishing) - Establish image copy + path update pattern

**Source:** [GitHub Issue #1188 - withastro/astro](https://github.com/withastro/astro/issues/1188)

---

### Critical: Special Characters in Image Filenames

**What goes wrong:** Images with spaces or special characters (`&`, `\`, etc.) break optimization.

**Why it happens:** Astro's image optimization escapes these characters, breaking paths.

**Prevention:**
- Validate image filenames during publish
- Reject or auto-rename files with spaces/special characters
- Use underscores: `my_image.png` not `my image.png`

```bash
# Check for problematic filenames
find ./posts -name "* *" -o -name "*&*" -o -name "*\\*" | head -1 && \
  echo "ERROR: Invalid image filename" && exit 1
```

**Warning signs:** Some images work, others 404; build completes but images broken.

**Phase:** 8 (Core Publishing) - Add filename validation to image copy

**Source:** [Configuring Obsidian and Astro Assets](https://www.anca.wtf/posts/configuring-obsidian-and-astro-assets-for-markdoc-content-in-an-astro-blog/)

---

### Critical: Partial Commits Leave Broken State

**What goes wrong:** Commit posts without images, or images without posts, leaving site broken.

**Why it happens:** Validation passes on markdown but images not copied; or script fails mid-execution.

**Prevention:**
- Atomic operations: copy all files, then validate all, then commit all
- Stage everything before committing
- Build check before commit catches missing images

```just
# Atomic publish - all or nothing
publish:
  # 1. Copy posts and images together
  ./scripts/copy-content.sh
  # 2. Validate everything
  npm run lint
  # 3. Build check (catches missing images)
  npm run build
  # 4. Only then commit
  git add src/content/blog/ public/assets/blog/
  git commit -m "feat(blog): publish new posts"
```

**Warning signs:** Site breaks after publish; images 404; build fails on Vercel but passed locally.

**Phase:** 8 (Core Publishing) - Atomic copy + build-before-commit

---

### Moderate: Frontmatter Validation Gaps

**What goes wrong:** Posts published with missing `pubDatetime`, empty `description`, or invalid `tags`.

**Why it happens:** Validation only checks required fields exist, not that they're valid.

**Prevention:**
- Validate field values, not just presence
- Check pubDatetime is valid ISO date
- Check description length (SEO: 50-160 chars)
- Check tags array contains valid strings

```bash
# Validate frontmatter values
yq '.pubDatetime' "$post" | grep -qE '^\d{4}-\d{2}-\d{2}' || \
  echo "ERROR: Invalid pubDatetime format"
```

**Warning signs:** Posts appear but SEO broken; date sorting wrong; OG images missing text.

**Phase:** 8 (Core Publishing) - Comprehensive frontmatter validation

---

### Moderate: Year Folder Mismatch

**What goes wrong:** Post with `pubDatetime: 2026-01-30` copied to `src/content/blog/2025/` manually.

**Why it happens:** Year extraction from pubDatetime not automated; manual copy to wrong folder.

**Prevention:**
- Extract year from pubDatetime programmatically
- Validate post path matches pubDatetime year

```just
# Extract year and copy to correct folder
copy-post post:
  year=$(yq '.pubDatetime' "{{post}}" | cut -d'-' -f1)
  mkdir -p "src/content/blog/$year"
  cp "{{post}}" "src/content/blog/$year/"
```

**Warning signs:** Archive pages show wrong years; RSS feed dates inconsistent.

**Phase:** 8 (Core Publishing) - Auto-extract year from pubDatetime

---

### Minor: Draft Flag Ambiguity

**What goes wrong:** Post with `draft: true` gets published; or `draft: false` post missed.

**Why it happens:** YAML boolean parsing varies (`true`/`True`/`"true"`/`yes`).

**Prevention:**
- Standardize on lowercase `true`/`false` in templates
- Parse with YAML-aware tool (yq), not grep

```bash
# CORRECT - use yq for boolean parsing
yq '.draft == false' "$post"

# WRONG - grep fails on boolean variations
grep 'draft: false' "$post"  # Misses "draft: False", "draft: no"
```

**Warning signs:** Some posts not discovered; unexpected posts published.

**Phase:** 9 (Utilities) - Use yq in list-drafts skill

---

## Git Safety Pitfalls

### Critical: --no-verify Bypasses All Hooks

**What goes wrong:** User runs `git commit --no-verify` or `git push --no-verify`, completely bypassing safety hooks.

**Why it happens:** Git provides escape hatch for legitimate edge cases; users discover and misuse it.

**Prevention:**
- Claude hooks run before git hooks, so Claude hooks aren't bypassed by --no-verify
- For additional protection: server-side hooks (branch protection rules)
- Education: document when --no-verify is acceptable

**Warning signs:** Dangerous operations succeed despite hooks.

**Phase:** 7 (Setup & Safety) - Document that Claude hooks can't be bypassed like git hooks

**Source:** [Git Documentation - githooks](https://git-scm.com/docs/githooks)

---

### Critical: Hooks Don't Block Pre-Existing Local State

**What goes wrong:** User already has destructive command in history; re-runs it outside Claude.

**Why it happens:** Claude hooks only protect operations routed through Claude.

**Prevention:**
- Server-side branch protection (force-push blocked at GitHub level)
- Training/documentation for safe git practices
- Consider global git hooks via `core.hooksPath` for additional protection

**Warning signs:** Destructive operations succeed when run directly in terminal.

**Phase:** 7 (Setup & Safety) - Recommend GitHub branch protection in documentation

---

### Moderate: Force Push Detection Pattern Gaps

**What goes wrong:** Hook blocks `git push --force` but not `git push -f` or `git push --force-with-lease`.

**Why it happens:** Pattern matching doesn't cover all force push variations.

**Prevention:**
- Match all variations: `--force`, `-f`, `--force-with-lease`, `+refs/`
- Parse git push arguments properly

```bash
# Comprehensive force push detection
if echo "$cmd" | grep -qE '(push.*(--force|-f|--force-with-lease|\+[a-zA-Z]))'; then
  echo "ERROR: Force push blocked" >&2
  exit 2
fi
```

**Warning signs:** Some force push commands succeed; inconsistent blocking.

**Phase:** 7 (Setup & Safety) - Comprehensive force push pattern

---

### Moderate: Reset Detection Must Include Variations

**What goes wrong:** Hook blocks `git reset --hard` but not `git reset --hard HEAD~1` or `git reset --hard origin/main`.

**Prevention:**
- Match pattern, not exact command
- Block: `reset --hard`, `checkout .`, `clean -f`, `restore .`

```bash
# Block dangerous reset variations
dangerous_patterns=(
  'reset --hard'
  'checkout \.'
  'clean -f'
  'restore \.'
  'branch -D'
)
```

**Warning signs:** Some destructive operations succeed.

**Phase:** 7 (Setup & Safety) - Pattern-based blocking

---

### Minor: Pre-Push vs Pre-Commit Hook Timing

**What goes wrong:** Validation runs at commit time, but problematic code already committed before push blocked.

**Prevention:**
- Run validation at commit time (pre-commit) to prevent bad commits
- Run safety checks at push time (pre-push) as final gate
- Claude PreToolUse hooks can intercept before either

**Warning signs:** Local repo has bad commits that can't be pushed.

**Phase:** 8 (Core Publishing) - Validate at commit time, not just push

---

## Prevention Checklist

### justfile Setup
- [ ] Set shell explicitly: `set shell := ["bash", "-cu"]`
- [ ] Use `{{variable}}` for just vars, `$VARIABLE` for env vars
- [ ] Chain dependent commands with `&&` or use shebang recipes
- [ ] Test recipes on target platform(s)
- [ ] Consistent indentation per recipe (tabs preferred)

### Claude Hooks Setup
- [ ] Use exit code 2 + stderr for simple blocking
- [ ] Use exit code 0 + JSON for structured control
- [ ] Set explicit timeouts for long-running hooks (builds: 300s)
- [ ] Use inline hooks in settings.json for critical safety
- [ ] Test hooks with `/hooks` command after configuration
- [ ] Restart Claude Code after changing hooks
- [ ] Verify .claude/settings.local.json is in .gitignore

### Publishing Pipeline
- [ ] Convert Obsidian `![[]]` syntax to standard markdown
- [ ] Copy images to public/ with absolute paths
- [ ] Validate image filenames (no spaces, no special chars)
- [ ] Validate frontmatter values, not just presence
- [ ] Extract year from pubDatetime for folder placement
- [ ] Use yq (not grep) for YAML boolean parsing
- [ ] Build check before commit (catches missing images)
- [ ] Atomic operations: copy all, validate all, commit all

### Git Safety
- [ ] Block all force push variations: `--force`, `-f`, `--force-with-lease`, `+ref`
- [ ] Block all destructive commands: `reset --hard`, `checkout .`, `clean -f`, `restore .`
- [ ] Document that Claude hooks work even when git --no-verify used
- [ ] Recommend GitHub branch protection as additional layer
- [ ] Validate at commit time, not just push time

## Sources

### Official Documentation (HIGH confidence)
- [Just Programmer's Manual](https://just.systems/man/en/)
- [Just Settings](https://just.systems/man/en/settings.html)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Claude Code Settings](https://code.claude.com/docs/en/settings)
- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [Astro Images Guide](https://docs.astro.build/en/guides/images/)
- [Astro Content Collections](https://docs.astro.build/en/guides/content-collections/)

### Known Issues (MEDIUM confidence)
- [PostToolUse JSON Bug - Issue #3983](https://github.com/anthropics/claude-code/issues/3983)
- [Plugin Hooks JSON Bug - Issue #10875](https://github.com/anthropics/claude-code/issues/10875)
- [Astro Relative Image Paths - Issue #1188](https://github.com/withastro/astro/issues/1188)

### Community Guides (MEDIUM confidence)
- [Write Like a Pro with Astro and Obsidian](https://www.hungrimind.com/articles/obsidian-with-astro)
- [Configuring Obsidian and Astro Assets](https://www.anca.wtf/posts/configuring-obsidian-and-astro-assets-for-markdoc-content-in-an-astro-blog/)
- [Claude Code Hooks Guide](https://claude.com/blog/how-to-configure-hooks)

---
*Research completed: 2026-01-30*
*Confidence: HIGH - Official documentation verified for all critical pitfalls*
