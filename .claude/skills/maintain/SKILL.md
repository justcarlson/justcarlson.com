---
name: maintain
description: Check for outdated dependencies, lint issues, and content validation
disable-model-invocation: true
---

# Maintenance Checks

Run comprehensive health checks and report issues. User decides what to fix.

## Checks to Run

### 1. Outdated Packages

```bash
npm outdated
```

Show table of packages needing updates.

### 2. Lint Check

```bash
npm run lint
```

Report any linting errors or warnings.

### 3. Build Verification

```bash
npm run build
```

Ensure site builds without errors.

### 4. Content Validation

```bash
just list-posts --all
```

Review all posts for validation issues.

## Reporting Format

Present findings in priority sections:

**Critical** (blocks publishing)
- Build failures
- Missing required frontmatter

**Warning** (should address soon)
- Outdated major versions
- Lint errors

**Info** (nice to fix eventually)
- Outdated minor/patch versions
- Style suggestions

## Important

This is a **report-only** skill:
- Run all checks and show results
- Present findings clearly
- Let user decide which issues to address
- Do NOT auto-fix anything

The user maintains full control over what gets changed.
