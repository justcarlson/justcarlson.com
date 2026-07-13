# AGENTS.md
## New Blog Post Workflow
- If user says “new blog post” without topic/title: ask for topic/title first.
- Create `agent/post-<slug>` from a single resolved `main` commit. Do not chase a moving `main` after work starts.
- Scaffold file: `src/content/blog/<year>/<slug>.md`.
- Frontmatter: only set `title` from user input; keep required placeholders minimal (`description: "TBD"`, `draft: true`, `pubDatetime: <today>`).
- No body content; no invented outline.
- Open a draft pull request and use its Vercel Preview deployment for review.
- Keep `draft: true` for all drafting, editing, and preview requests.
- Never publish, mark the PR ready, or merge unless the user explicitly requests publication.
- Before publication, require a final description, valid publication datetime, successful `npm run build:check`, and `draft: false`.
- Treat a merge to `main` as the production deployment boundary.
