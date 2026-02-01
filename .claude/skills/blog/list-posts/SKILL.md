---
name: list-posts
description: List blog posts from Obsidian vault with validation status
disable-model-invocation: true
---

# List Posts

Display blog posts from Obsidian vault with their validation status.

## Usage

Run the list-posts command with optional filters:

**Default (unpublished only):**
```bash
just list-posts
```

**All posts:**
```bash
just list-posts --all
```

**Published only:**
```bash
just list-posts --published
```

## Output

The command shows:
- Post filename
- Title from frontmatter
- Publication status (Published/Not Published)
- Validation status (valid/invalid with reason)

## Notes

- This is a read-only operation - no confirmation needed
- Wraps `just list-posts` which runs `./scripts/list-posts.sh`
- Present output clearly to the user
- Default filter (unpublished) is most useful for publishing workflow
