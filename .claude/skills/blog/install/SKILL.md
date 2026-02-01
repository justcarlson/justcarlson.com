---
name: install
description: Guide setup of Obsidian vault path, dependencies, and build verification
disable-model-invocation: true
hooks:
  Stop:
    - hooks:
        - type: command
          command: "$CLAUDE_PROJECT_DIR/.claude/hooks/verify-install.sh"
          timeout: 60
---

# Install and Setup

Interactive setup guide for new developers working with justcarlson.com.

## Steps

### Step 0: Check Existing Configuration

First, check if vault is already configured:

```bash
cat .claude/settings.local.json 2>/dev/null | jq -r '.obsidianVaultPath // empty'
```

If the command outputs a valid path:
- Report to user: "Vault already configured at: [path]"
- Ask if they want to reconfigure or keep existing
- If keeping existing, skip to Step 2 (Verify Dependencies)

If empty or file missing, proceed to Step 1.

### Step 1: Configure Obsidian Vault

Run the setup script to configure your vault path:

```bash
just setup
```

This will:
- Search for Obsidian vaults in your home directory
- Let you select the correct vault
- Save the path to `.claude/settings.local.json`

### Step 2: Verify Dependencies

Check that npm packages are installed:

```bash
npm list --depth=0
```

If missing, install them:

```bash
npm install
```

### Step 3: Test Build

Verify everything compiles correctly:

```bash
npm run build
```

## Verification (Stop Hook)

The stop hook checks three things before allowing completion:
- Vault path configured in `.claude/settings.local.json`
- `node_modules` directory exists
- Build passes without errors

If any check fails, the stop hook blocks with exit code 2 and explains what's missing.

## Troubleshooting

**Vault not found?**
- Ensure your Obsidian vault contains a `Posts` folder
- Check vault path permissions

**Build fails?**
- Check for TypeScript errors in `src/` files
- Run `npm run lint` to see issues
