---
name: unpublish.post
description: Prompts after unpublish to push changes and update Obsidian
match_commands: ["just unpublish"]
---

# Post-Unpublish Hook

After `just unpublish` completes, prompt the user:

1. **Ask about pushing:**
   "Push the removal to remote? [Y/n]"
   - If Yes: run `git push`
   - If No: skip push (changes remain local)

2. **Remind about Obsidian:**
   Display: "Remember to update the post status in Obsidian to prevent re-publishing."

## Important

- This hook runs AFTER unpublish completes
- Only prompt about push - never re-run unpublish
- If user declines push, that's fine - they can push later
- Exit code 0 regardless of push decision
