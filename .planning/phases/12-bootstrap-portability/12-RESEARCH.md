# Phase 12: Bootstrap & Portability - Research

**Researched:** 2026-02-01
**Domain:** Dev environment automation, devcontainers, bootstrap scripting
**Confidence:** HIGH

## Summary

This phase implements one-command bootstrap for fresh clones and dev container support for GitHub Codespaces. The research covers devcontainer.json configuration patterns, idempotent bash scripting for bootstrap, Node.js version management via .nvmrc, and VS Code extension configuration for the project's Astro/Tailwind/Biome stack.

The project currently uses npm (not pnpm) with Node.js, an Astro-based site with Tailwind CSS 4.x, and Biome for linting/formatting. The existing vault configuration uses `.claude/settings.local.json` for storing the Obsidian vault path - this pattern should be preserved for consistency.

**Primary recommendation:** Create a `.devcontainer/devcontainer.json` using the official Node.js devcontainer feature with Node 22, a named volume for node_modules performance, and postCreateCommand running `just bootstrap` to auto-setup the container.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| devcontainer.json | spec 0.200+ | Container configuration | Official VS Code/Codespaces standard |
| Node.js devcontainer feature | ghcr.io/devcontainers/features/node:1 | Node.js runtime in container | Official maintained feature, supports nvm |
| GitHub CLI feature | ghcr.io/devcontainers/features/github-cli:1 | gh CLI for PRs/issues | Official feature, enables terminal workflow |
| just feature | ghcr.io/guiyomh/features/just:0 | Command runner | Most popular community feature for just |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| .nvmrc | N/A | Pin Node version | All projects, read by nvm/fnm/mise |
| named Docker volumes | N/A | node_modules performance | macOS/Windows container development |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| guiyomh/features/just | jsburckhardt/devcontainer-features/just | guiyomh more actively maintained |
| npm | pnpm | Project already uses npm, no need to switch |
| .nvmrc | .node-version | .nvmrc more widely supported (nvm, fnm, mise all read it) |

**Note:** The project uses npm (see package.json), not pnpm. Bootstrap should install npm dependencies.

## Architecture Patterns

### Recommended Project Structure
```
.devcontainer/
    devcontainer.json    # Main config
.nvmrc                   # Node version pin (22.x)
justfile                 # Command recipes including bootstrap
scripts/
    bootstrap.sh         # Full bootstrap logic (called by justfile)
    setup.sh             # Existing vault config (keep as-is)
```

### Pattern 1: Devcontainer with Named Volume for node_modules
**What:** Mount node_modules as a named Docker volume for performance on macOS/Windows
**When to use:** Any Node.js project in devcontainers

**Example:**
```json
// Source: https://code.visualstudio.com/remote/advancedcontainers/improve-performance
{
  "name": "justcarlson.com",
  "image": "mcr.microsoft.com/devcontainers/javascript-node:22",
  "features": {
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/guiyomh/features/just:0": {}
  },
  "mounts": [
    "source=${localWorkspaceFolderBasename}-node_modules,target=${containerWorkspaceFolder}/node_modules,type=volume"
  ],
  "postCreateCommand": "sudo chown node node_modules && just bootstrap",
  "forwardPorts": [4321],
  "portsAttributes": {
    "4321": {
      "label": "Astro Dev",
      "onAutoForward": "openPreview"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "astro-build.astro-vscode",
        "bradlc.vscode-tailwindcss",
        "biomejs.biome",
        "eamodio.gitlens",
        "usernamehw.errorlens",
        "esbenp.prettier-vscode"
      ]
    }
  }
}
```

### Pattern 2: Idempotent Bootstrap Script
**What:** Script that can run multiple times safely, skipping already-completed steps
**When to use:** All setup/bootstrap scripts

**Example:**
```bash
#!/usr/bin/env bash
# Source: https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/
set -euo pipefail

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install node dependencies (idempotent - npm install checks package-lock.json)
echo "Installing dependencies..."
npm install

# Validate setup
echo "Validating..."
node --version
npm --version
npm run build:check
```

### Pattern 3: .nvmrc for Node Version Pinning
**What:** Single file specifying Node.js version, readable by nvm, fnm, and mise
**When to use:** All Node.js projects

**Example:**
```
# Source: https://github.com/nvm-sh/nvm
22
```
Note: Use major version only (22) to get latest patch, or pin exact version (22.20.0) for reproducibility.

### Anti-Patterns to Avoid
- **Installing dependencies in Dockerfile:** Use postCreateCommand instead so the container image stays generic and reusable
- **Using `mkdir` without `-p` flag:** Non-idempotent, fails if directory exists
- **Checking commands with `which`:** Use `command -v` for POSIX portability
- **Using `onAutoForward: "openBrowser"`:** Opens new browser on every rebuild; use `"openPreview"` instead

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Node version in container | Custom Dockerfile | ghcr.io/devcontainers/features/node:1 | Handles nvm, version switching, dependencies |
| Installing just | Manual curl/install | ghcr.io/guiyomh/features/just:0 | Automatic updates, cross-platform |
| GitHub CLI | apt-get install | ghcr.io/devcontainers/features/github-cli:1 | Automatic auth, updates |
| node_modules performance | Symlinks, custom mounts | Named Docker volume | Built-in Docker feature, well-tested |
| Command existence check | Custom function | `command -v "$cmd" >/dev/null 2>&1` | POSIX built-in, portable |

**Key insight:** Devcontainer features are maintained packages that handle cross-platform concerns, dependency installation, and configuration. Custom installation scripts require ongoing maintenance.

## Common Pitfalls

### Pitfall 1: node_modules Bind Mount Performance
**What goes wrong:** npm install takes 5x longer, file watching is slow, CPU spikes
**Why it happens:** macOS/Windows run containers in a VM; bind mounts have filesystem overhead
**How to avoid:** Use named volumes for node_modules: `"source=${localWorkspaceFolderBasename}-node_modules,target=${containerWorkspaceFolder}/node_modules,type=volume"`
**Warning signs:** npm install >2 minutes, dev server sluggish, high CPU during file saves

### Pitfall 2: Port Forwarding Without --host Flag
**What goes wrong:** Dev server starts but browser shows nothing at forwarded port
**Why it happens:** Astro/Vite bind to localhost by default, which is container-local
**How to avoid:** Run dev server with `--host` flag: `astro dev --host`
**Warning signs:** "Connection refused" in browser despite server running

### Pitfall 3: Volume Ownership Mismatch
**What goes wrong:** Permission denied errors when npm tries to write to node_modules
**Why it happens:** Named volumes are initially owned by root
**How to avoid:** Add `sudo chown node node_modules` to postCreateCommand (before npm install)
**Warning signs:** EACCES errors during npm install

### Pitfall 4: Non-Idempotent Bootstrap
**What goes wrong:** Script fails on second run with "directory exists" or similar
**Why it happens:** Using `mkdir` instead of `mkdir -p`, or not checking if step completed
**How to avoid:** Every step should check current state before acting
**Warning signs:** "File exists" errors, script only works on fresh machines

### Pitfall 5: Multiple Browser Windows Opening
**What goes wrong:** Every container rebuild opens a new browser tab
**Why it happens:** Using `"onAutoForward": "openBrowser"` triggers on each port detection
**How to avoid:** Use `"onAutoForward": "openPreview"` which opens VS Code's Simple Browser instead
**Warning signs:** Many browser tabs after container operations

## Code Examples

Verified patterns from official sources:

### devcontainer.json - Complete Configuration
```json
// Source: https://containers.dev/implementors/json_reference/
{
  "name": "justcarlson.com",
  "image": "mcr.microsoft.com/devcontainers/javascript-node:22",
  "features": {
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/guiyomh/features/just:0": {}
  },
  "mounts": [
    "source=${localWorkspaceFolderBasename}-node_modules,target=${containerWorkspaceFolder}/node_modules,type=volume"
  ],
  "postCreateCommand": "sudo chown node node_modules && just bootstrap",
  "forwardPorts": [4321],
  "portsAttributes": {
    "4321": {
      "label": "Astro Dev Server",
      "onAutoForward": "openPreview"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "astro-build.astro-vscode",
        "bradlc.vscode-tailwindcss",
        "biomejs.biome",
        "eamodio.gitlens",
        "usernamehw.errorlens",
        "esbenp.prettier-vscode"
      ],
      "settings": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "biomejs.biome"
      }
    }
  }
}
```

### .nvmrc Format
```
# Source: https://github.com/nvm-sh/nvm
# Supported by nvm, fnm, mise
22
```

### Idempotent Command Check
```bash
# Source: https://samanpavel.medium.com/bash-fail-fast-on-missing-dependencies-b7560bf143e8
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Usage
if ! command_exists npm; then
    echo "Error: npm not found" >&2
    exit 1
fi
```

### Bootstrap Recipe in Justfile
```just
# Bootstrap development environment
bootstrap:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "=== Bootstrap ==="

    # Install dependencies
    echo "Installing npm dependencies..."
    npm install

    # Validate
    echo "Validating setup..."
    node --version
    npm run build:check

    echo ""
    echo "Bootstrap complete! Run 'just preview' to start dev server."
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom Dockerfile | Devcontainer features | 2022 | No custom image maintenance |
| Mount all files as bind | Named volume for node_modules | 2020 | 5x faster npm install on macOS/Windows |
| nvm only | nvm/fnm/mise all read .nvmrc | 2023 | Developer choice of version manager |
| openBrowser port forward | openPreview | 2023 | Single tab instead of many |

**Deprecated/outdated:**
- `docker-compose.yml` for dev containers: Replaced by devcontainer.json spec
- Custom node version install scripts: Use devcontainer features instead
- `.node-version` alone: Use `.nvmrc` for broader tool compatibility

## VS Code Extensions Recommendation (Claude's Discretion)

Based on the project stack (Astro, Tailwind CSS 4.x, Biome, TypeScript) and user requirements:

### Recommended Extensions
| Extension ID | Purpose | Why Include |
|--------------|---------|-------------|
| `astro-build.astro-vscode` | Astro language support | Required for .astro files |
| `bradlc.vscode-tailwindcss` | Tailwind IntelliSense | Required for Tailwind class completion |
| `biomejs.biome` | Linting/formatting | Project uses Biome, not ESLint/Prettier |
| `eamodio.gitlens` | Git visualization | User requested, enhances git workflow |
| `usernamehw.errorlens` | Inline error display | User requested "error highlighting" |
| `esbenp.prettier-vscode` | Fallback formatter | For non-JS files Biome doesn't handle |

### Optional Extensions (Not Including by Default)
| Extension ID | Purpose | Why Optional |
|--------------|---------|--------------|
| `unifiedjs.vscode-mdx` | MDX support | Already in .vscode/extensions.json |
| `GitHub.copilot` | AI assistance | Requires subscription, user choice |

## Vault Configuration Recommendation (Claude's Discretion)

The project already uses `.claude/settings.local.json` for vault path configuration (see existing `scripts/setup.sh`). This approach should be preserved for consistency.

**Recommendation: Keep existing config file approach**
- Path: `.claude/settings.local.json`
- Key: `obsidianVaultPath`
- Already gitignored, already implemented in setup.sh

**Why not env var:**
- Would require `.env` file (another file to manage)
- Existing scripts already read from settings.local.json
- Config file allows future extension (additional settings)

**Vault-optional behavior:**
- Preview/build work without vault configured
- Console message when no vault: "No vault configured - running in code exploration mode"
- Blog pages show empty content, site renders normally

## Open Questions

Things that couldn't be fully resolved:

1. **Exact Node 22.x version to pin**
   - What we know: Node 22.20.0 is latest as of Jan 2026, 22.x LTS until Apr 2027
   - What's unclear: Whether to pin exact (22.20.0) or major (22)
   - Recommendation: Use `22` in .nvmrc for automatic patch updates; GitHub Actions can pin exact version for reproducibility

2. **GitHub workflows Node version alignment**
   - What we know: Current workflows use Node 20, phase requires Node 22
   - What's unclear: Whether to update workflows in this phase or separately
   - Recommendation: Update workflows to read from .nvmrc or pin to 22 to match

## Sources

### Primary (HIGH confidence)
- [VS Code Advanced Containers - Improve Performance](https://code.visualstudio.com/remote/advancedcontainers/improve-performance) - Named volume pattern
- [Dev Container JSON Reference](https://containers.dev/implementors/json_reference/) - Full spec
- [Node.js devcontainer feature](https://github.com/devcontainers/features/blob/main/src/node/devcontainer-feature.json) - Feature options
- [GitHub CLI devcontainer feature](https://github.com/devcontainers/features/tree/main/src/github-cli) - Feature ID and options
- [Astro official devcontainer](https://github.com/withastro/astro/blob/main/.devcontainer/basics/devcontainer.json) - Port forwarding pattern
- [nvm .nvmrc documentation](https://github.com/nvm-sh/nvm) - File format

### Secondary (MEDIUM confidence)
- [Idempotent bash scripts](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/) - Scripting patterns
- [fnm .nvmrc compatibility](https://github.com/Schniz/fnm) - Version manager compatibility
- [mise .nvmrc reading](https://betterstack.com/community/guides/scaling-nodejs/nvm-vs-mise/) - Cross-tool support
- [Node 22 LTS status](https://nodejs.org/en/about/previous-releases) - Version timeline

### Tertiary (LOW confidence)
- [guiyomh/features/just](https://github.com/guiyomh/features/tree/main/src/just) - Community feature, verify still maintained
- [VS Code extension IDs](https://marketplace.visualstudio.com/) - Marketplace lookup

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official devcontainer spec and features well-documented
- Architecture: HIGH - Patterns verified against official docs and Astro repo
- Pitfalls: HIGH - Common issues documented in official troubleshooting guides
- VS Code extensions: MEDIUM - Extension IDs verified, selection is opinionated
- Vault config: HIGH - Based on existing project implementation

**Research date:** 2026-02-01
**Valid until:** 2026-03-01 (30 days - devcontainer ecosystem stable)
