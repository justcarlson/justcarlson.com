---
name: unpublish
description: Remove a post from blog repo (keeps Obsidian source)
disable-model-invocation: true
---

# Unpublish Post

Remove a published post from the blog repo.

## Process

### Step 1: List Published Posts

First, show the user what posts are available to unpublish:

```bash
just list-posts --published
```

Present this list to the user and let them select which post to unpublish.

### Step 2: Confirm Intent

Once user selects a post, confirm the action:

"You want to unpublish [filename]. This will:
- Remove the post from src/content/blog/
- Create a commit (but not push)
- Leave your Obsidian source unchanged

Proceed? [y/n]"

### Step 3: Execute Unpublish

If user confirms:

```bash
just unpublish "[selected-file]"
```

### Step 4: Remind About Obsidian

After unpublishing, remind user:

"Done. The commit is ready for review.

Remember to update the post's status in Obsidian to prevent
re-publishing on the next `just publish`."

## Important Notes

- **Commits but does NOT push** - Creates a checkpoint for user review
- **Obsidian source unchanged** - Only removes from blog repo
- **Images left in repo** - Associated images are not removed (safer approach)

## Example

```
User: /unpublish

Claude: [runs just list-posts --published]
Here are your published posts:

1. hello-world.md (2026-01-15)
2. my-first-post.md (2026-01-20)
3. another-post.md (2026-01-25)

Which post would you like to unpublish?

User: 1

Claude: You want to unpublish hello-world.md. This will:
- Remove the post from src/content/blog/
- Create a commit (but not push)
- Leave your Obsidian source unchanged

Proceed? [y/n]

User: y

Claude: [runs just unpublish hello-world.md]
Done. The commit is ready for review.

Remember to update the post's status in Obsidian to prevent
re-publishing on the next `just publish`.
```
