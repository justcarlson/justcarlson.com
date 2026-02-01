---
name: blog:help
description: List all available blog publishing commands
disable-model-invocation: true
---

# Blog Publishing Commands

Available commands for the Obsidian-to-blog publishing workflow:

| Command | Description |
|---------|-------------|
| `/blog:install` | Set up Obsidian vault path and verify dependencies |
| `/blog:publish` | Publish posts marked as Published in Obsidian |
| `/blog:list-posts` | List posts with their validation status |
| `/blog:unpublish` | Remove a published post from the blog |
| `/blog:maintain` | Run maintenance checks on dependencies and content |
| `/blog:help` | Show this help message |

## Quick Start

1. Run `/blog:install` to configure your Obsidian vault
2. In Obsidian, set a post's status to "Published"
3. Run `/blog:publish` to publish it

## Getting Status

- Run `/blog:list-posts` to see all posts and their publication status
- Check `just list-posts` for command-line access
