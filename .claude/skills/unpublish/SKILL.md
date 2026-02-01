---
name: unpublish
description: Remove a post from blog repo (keeps Obsidian source)
disable-model-invocation: true
---

# Unpublish Post

Remove a published post from the blog repo.

## Usage

The user provides the file to unpublish via `$ARGUMENTS`:

```bash
just unpublish "$ARGUMENTS"
```

## Process

1. **Confirm intent** - Verify user wants to unpublish the specified post
2. **Show what will happen** - The post will be removed from the blog repo
3. **Execute unpublish** - Run `just unpublish` with the file argument
4. **Remind about Obsidian** - Tell user to update Obsidian status to prevent re-publishing

## Important Notes

- **Commits but does NOT push** - Creates a checkpoint for user review
- **Obsidian source unchanged** - Only removes from blog repo
- **Images left in repo** - Associated images are not removed (safer approach)

## Example

```
User: /unpublish hello-world.md

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
