---
name: publish
description: Publish blog posts from Obsidian vault with human oversight
disable-model-invocation: true
hooks:
  Stop:
    - hooks:
        - type: command
          command: "$CLAUDE_PROJECT_DIR/.claude/hooks/verify-build.sh"
          timeout: 120
---

# Publish Blog Posts

Guide the user through publishing posts from Obsidian to the blog repo with oversight.

## Process

1. **Preview first** - Run `just publish --dry-run` to see what would be published
2. **Review each post** - For each post shown, display frontmatter preview (title, description, tags)
3. **Confirm selection** - Ask user which posts to publish (all, specific, or none)
4. **Execute publish** - Run `just publish` for confirmed posts
5. **Verify build** - Stop hook ensures build passes before finishing

## Important Notes

- Always start with `--dry-run` to preview changes
- Show frontmatter for each post before confirming
- The stop hook runs `npm run build` and blocks if it fails
- This wraps `just publish` - do not reimplement the publish logic

## Example Workflow

```
User: /publish

Claude: Let me preview what posts are ready to publish...
[runs just publish --dry-run]

Here are the posts ready to publish:

1. **New Post Title**
   - Description: A post about something
   - Tags: tech, coding
   - Status: new

Would you like to publish all of these, or select specific posts?
```
