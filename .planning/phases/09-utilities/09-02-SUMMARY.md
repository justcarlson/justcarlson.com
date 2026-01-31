---
phase: 09-utilities
plan: 02
subsystem: blog-management
tags: [unpublish, git, cli, justfile]

dependencies:
  requires: [09-01]
  provides:
    - unpublish-command
    - post-removal-workflow
  affects: []

tech-stack:
  added: []
  patterns:
    - confirmation-prompts
    - git-rm-workflow

key-files:
  created:
    - scripts/unpublish.sh
    - .claude/hooks/unpublish.post.md
  modified:
    - justfile

decisions:
  - id: unpublish-no-push
    decision: "Unpublish commits but does not push automatically"
    rationale: "Creates natural checkpoint for user review before remote removal"
    file: scripts/unpublish.sh

  - id: leave-images
    decision: "Images left in repo when unpublishing"
    rationale: "Safer approach avoids orphan complexity; images may be shared"
    file: scripts/unpublish.sh

  - id: obsidian-untouched
    decision: "Obsidian source file is not modified by unpublish"
    rationale: "YAML list manipulation too risky; user updates manually"
    file: scripts/unpublish.sh

metrics:
  duration: 2 minutes
  completed: 2026-01-31
---

# Phase 09 Plan 02: Unpublish Command Summary

**One-liner:** Remove published posts from blog with confirmation, git commit, and Obsidian update reminder

## What Was Built

Created the `just unpublish` command for removing published posts from the blog repository:

**Core functionality:**
- Accepts file path or slug as argument
- Resolves slug and finds post in `src/content/blog/*/slug.md`
- Shows post info and prompts for confirmation (default: No)
- `--force` flag skips confirmation prompt
- Removes post with `git rm` and commits with conventional message
- Does NOT push automatically (manual step for safety)
- Displays tip to update Obsidian status

**Integration:**
- Added `unpublish` recipe to justfile Utilities section
- Created `.claude/hooks/unpublish.post.md` for post-removal prompts
- Reused color scheme, config loading, and slugify from publish.sh

## Deviations from Plan

None - plan executed exactly as written.

## Key Technical Details

**File resolution logic:**
1. Extract basename if input contains `/` or ends in `.md`
2. Slugify the basename (lowercase, hyphens, no special chars)
3. Search `src/content/blog/*/slug.md` using find
4. Return first match (should only be one)

**Safety features:**
- Confirmation prompt defaults to No (requires explicit Y)
- `--force` flag available for scripting
- Clear error messages when post not found
- Tip suggests using `just list-posts --published` to see options

**Git workflow:**
- `git rm <blog-path>` - only markdown file
- `git commit -m "docs(blog): unpublish <title>"`
- NO automatic push - user runs `git push` when ready

**Why images NOT removed:**
- Safer: avoids orphan asset complexity
- Images may be shared across multiple posts
- Blog images are small; cleanup can be separate if needed

## Testing Performed

**Verification checks:**
1. Script is executable: ✓
2. `--help` flag shows usage: ✓
3. Non-existent post shows clear error: ✓
4. `just --list` shows unpublish recipe: ✓
5. `just unpublish fake-post` errors gracefully: ✓
6. Git log shows conventional commit format: ✓
7. Hook file exists with correct structure: ✓

## Commits

1. `48ef5d3` - feat(09-02): create unpublish.sh script
   - Full bash script with arg parsing, confirmation, git operations

2. `96e1f77` - feat(09-02): wire unpublish recipe and create post-hook
   - Justfile integration and post-unpublish hook

## Files Created/Modified

**Created:**
- `scripts/unpublish.sh` (296 lines)
- `.claude/hooks/unpublish.post.md` (hook definition)

**Modified:**
- `justfile` (added unpublish recipe in Utilities section)

## Decisions Made

### 1. No Automatic Push (unpublish-no-push)

**Decision:** Unpublish commits locally but does NOT push to remote.

**Rationale:** Creates natural checkpoint for user to review removal before it goes live. Post removal is destructive, so extra caution warranted.

**Impact:** User sees tip to run `git push` when ready. Post-unpublish hook will prompt about pushing.

### 2. Leave Images in Repo (leave-images)

**Decision:** Images in `public/assets/blog/<slug>/` are NOT removed when unpublishing.

**Rationale:**
- Safer: avoids orphaned image detection complexity
- Images may be referenced by multiple posts
- Blog images are small; cleanup can be separate workflow if bloat becomes issue

**Impact:** Asset directory may contain orphaned images over time. Can address with future `just clean-images` if needed.

### 3. Obsidian Source Untouched (obsidian-untouched)

**Decision:** Unpublish does NOT modify the Obsidian source file's YAML frontmatter.

**Rationale:** YAML list syntax manipulation is error-prone. Risk of corrupting frontmatter outweighs convenience.

**Impact:** User must manually update status in Obsidian. Script shows clear tip about this. Future publish sync will prevent re-adding if status still shows Published.

## Integration Points

**With existing scripts:**
- Reuses color variables from publish.sh (RED, GREEN, YELLOW, CYAN, RESET)
- Reuses `load_config()` pattern for vault path loading
- Reuses `slugify()` function for slug normalization
- Reuses `extract_frontmatter_value()` for title extraction

**With justfile:**
- Added to Utilities section after `list-posts` recipe
- Uses same `file *args` pattern for argument passing

**With git:**
- Uses `git rm` for tracked file removal
- Creates conventional commit: `docs(blog): unpublish <title>`
- Does NOT push (user control)

## Next Phase Readiness

**Blocks:** None

**Concerns:** None

**Enables:**
- Phase 09 Plan 03 (Preview Command)
- Future publish-as-sync model (removal detection)

## Usage Examples

```bash
# Remove post by slug (with confirmation)
just unpublish my-post

# Remove post by filename
just unpublish my-post.md

# Remove post by full path
just unpublish ~/obsidian/jc/Blog/my-post.md

# Skip confirmation prompt
just unpublish my-post --force
just unpublish my-post -f

# See published posts
just list-posts --published

# After unpublish, push when ready
git push
```

## Lessons Learned

**What went well:**
- File resolution logic handles various input formats cleanly
- Confirmation prompt with safe default prevents accidents
- Clear error messages guide user to correct usage
- Code reuse from publish.sh kept implementation consistent

**What could improve:**
- Future: Add orphaned image detection/cleanup as separate command
- Future: When publish becomes sync, this command becomes less critical (just change status in Obsidian)

**Patterns established:**
- Confirmation prompts default to No for destructive operations
- `--force` flag available for scripting/automation
- Post-operation tips guide user to next steps

---

*Phase: 09-utilities*
*Completed: 2026-01-31*
*Duration: 2 minutes*
