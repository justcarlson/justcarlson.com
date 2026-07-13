# Publishing workflow

The site supports three authoring paths. They all produce the same Astro Markdown files and use `draft` as the publication switch.

## 1. Obsidian

This is the primary local writing workflow.

One-time setup:

```bash
just setup
```

Normalize existing blog notes and install the canonical Obsidian template:

```bash
just migrate-vault --dry-run
just migrate-vault
just migrate-vault --verify
```

The migration detects notes in `Blog Posts` and notes with legacy blog metadata. It maps `status: Published` to `draft: false`, moves `published` to `pubDatetime` when necessary, maps `topics` to `tags` when necessary, adds missing canonical fields, and removes the deprecated `status` and `published` keys. Existing files are backed up under `.blog-migration-backups/<timestamp>` before modification. Other vault notes are left alone unless `--all` is supplied.

It also writes `Blog Post.md` into the folder configured by Obsidian’s Templates core plugin, defaulting to `Templates` when no folder is configured.

Create a draft:

```bash
just draft "Post title"
```

The draft is created in the `Blog Posts` folder of the configured Obsidian vault with `draft: true`. Write and revise it there. When it is ready, add the final description, set `draft: false`, and publish it:

```bash
just publish --post post-title
```

Use `just publish --dry-run --post post-title` to validate the operation without changing files or pushing commits.

## 2. Pages CMS

Use [Pages CMS](https://app.pagescms.org) for browser or phone editing.

1. Sign in with GitHub.
2. Install the Pages CMS GitHub App for `BrightEra/justcarlson.com`.
3. Open the repository and select **Blog posts**.
4. Create or edit a post. New posts default to `draft: true`.
5. Save the draft as often as needed.
6. When ready to publish, clear **Draft** and save again.

Pages CMS writes directly to the GitHub repository. A save to `main` triggers Vercel automatically. Uploaded images are stored in `public/assets/blog` and referenced as `/assets/blog/...`.

The collection path contains the current publication year. At the beginning of a new year, update `path` in `.pages.yml` from the previous year to the new one.

## 3. ChatGPT or Codex

Use this when drafting collaboratively with an agent.

1. Ask for a new blog post and provide at least a topic or title.
2. The agent creates `agent/post-<slug>` from the latest fixed `main` commit.
3. It scaffolds `src/content/blog/<year>/<slug>.md` with `draft: true` and opens a draft pull request.
4. Draft branches receive a Vercel Preview deployment. Draft posts are rendered in local development and Vercel Preview only.
5. Review and revise the article through the PR.
6. Explicitly ask to publish. The agent completes the metadata, changes `draft` to `false`, validates the build, and marks the PR ready.
7. Merge the PR to deploy the post to production.

An agent must never interpret “draft,” “revise,” or “preview” as permission to publish or merge.

## Publication state

| State | Frontmatter | Production | Local/Vercel Preview |
| --- | --- | --- | --- |
| Draft | `draft: true` | Hidden | Visible |
| Published | `draft: false` | Visible after its publication date | Visible |
| Unlisted | `draft: false`, `unlisted: true` | Direct URL only | Direct URL only |
