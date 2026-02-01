# Phase 13: Hook Infrastructure - Research

**Researched:** 2026-02-01
**Domain:** Python hooks with uv, python-dotenv, Claude Code SessionStart integration
**Confidence:** HIGH

## Summary

This phase converts the existing bash `blog-session-start.sh` to Python following the install-and-maintain reference implementation. The key technologies are well-documented and stable: uv (0.9.x) with PEP 723 inline dependencies, python-dotenv (1.2.x) for .env loading, and Claude Code's SessionStart hook API with `CLAUDE_ENV_FILE` for environment persistence.

The reference implementation at `/home/jc/developer/install-and-maintain/.claude/hooks/session_start.py` provides a complete, working pattern. The phase involves adapting this pattern to include blog-specific logic (vault checking, published post counting) while adding log rotation as specified in the context decisions.

**Primary recommendation:** Follow the install-and-maintain reference implementation exactly for structure, adding blog-specific logic and line-based log rotation.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| uv | 0.9.22+ | Python script runner with inline deps | Official Astral tool, PEP 723 reference implementation |
| python-dotenv | 1.2.x | .env file parsing | Most widely used, 12-factor app standard |
| Python | 3.11+ | Runtime | Matches install-and-maintain requires-python |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| json (stdlib) | - | JSON parsing/output | Hook input/output communication |
| pathlib (stdlib) | - | Path manipulation | File operations |
| datetime (stdlib) | - | Timestamps | Log entries |
| os (stdlib) | - | Environment vars | CLAUDE_ENV_FILE access |
| sys (stdlib) | - | stdin/stdout/stderr | Hook I/O |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| python-dotenv | environ-config | dotenv is simpler, no schema needed |
| uv | pip/pipx | uv is faster, inline deps are cleaner |
| pathlib | os.path | pathlib is more modern, cleaner API |

**Installation:**
No installation needed - uv handles dependencies automatically via PEP 723 inline metadata.

## Architecture Patterns

### Recommended Script Structure
```
.claude/hooks/
  session_start.py       # Main hook (replaces blog-session-start.sh)
  session_start.log      # Log output (auto-created)
  blog-session-start.sh  # Remove after migration
```

### Pattern 1: PEP 723 Inline Dependencies
**What:** Embed script metadata including dependencies in comments at top of file
**When to use:** All standalone Python scripts that need external packages
**Example:**
```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["python-dotenv"]
# ///
```
Source: [PEP 723](https://peps.python.org/pep-0723/), [uv scripts guide](https://docs.astral.sh/uv/guides/scripts/)

### Pattern 2: Logger Class with Dual Output
**What:** Write to both stderr (for hook debugging) and log file (for persistence)
**When to use:** Hooks that need debugging visibility and persistent history
**Example:**
```python
# Source: install-and-maintain/.claude/hooks/session_start.py
class Logger:
    """Simple logger that writes to both stderr and a log file."""

    def __init__(self, log_path: Path):
        self.log_path = log_path
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.log_path, "a") as f:
            f.write(f"\n{'='*60}\n")
            f.write(f"=== SessionStart Hook: {datetime.now().isoformat()} ===\n")

    def log(self, message: str) -> None:
        print(message, file=sys.stderr)
        with open(self.log_path, "a") as f:
            f.write(message + "\n")
```

### Pattern 3: JSON Hook I/O
**What:** Read JSON from stdin, write JSON to stdout for Claude Code
**When to use:** All Claude Code hooks
**Example:**
```python
# Source: Claude Code hooks reference
# Input
hook_input = json.load(sys.stdin)
source = hook_input.get("source", "unknown")
session_id = hook_input.get("session_id", "unknown")

# Output with additionalContext
output = {
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": "Your message here"
    }
}
print(json.dumps(output))
```
Source: [Claude Code hooks reference](https://code.claude.com/docs/en/hooks)

### Pattern 4: CLAUDE_ENV_FILE Persistence
**What:** Write export statements to CLAUDE_ENV_FILE for environment variable persistence
**When to use:** Loading .env into session environment
**Example:**
```python
# Source: Claude Code hooks reference
env_file_path = os.environ.get("CLAUDE_ENV_FILE")
if env_file_path:
    with open(env_file_path, "a") as f:
        # Escape single quotes for shell safety
        escaped_value = value.replace("'", "'\"'\"'")
        f.write(f"export {key}='{escaped_value}'\n")
```

### Pattern 5: Line-Based Log Rotation
**What:** Keep only the last N lines of a log file to prevent unbounded growth
**When to use:** Log files that grow indefinitely
**Example:**
```python
def rotate_log(log_path: Path, max_lines: int = 500) -> None:
    """Keep only the last max_lines of the log file."""
    if not log_path.exists():
        return
    lines = log_path.read_text().splitlines()
    if len(lines) > max_lines:
        log_path.write_text("\n".join(lines[-max_lines:]) + "\n")
```

### Anti-Patterns to Avoid
- **Reading entire vault synchronously:** The bash script uses `find | perl` which can be slow; Python should use the same approach or optimize
- **Blocking on errors:** Hook errors should log and continue, not crash the session
- **Hardcoding paths:** Use `CLAUDE_PROJECT_DIR` and `Path(__file__).parent` for portability
- **Missing JSON output:** Always output valid JSON to stdout, even on error

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| .env parsing | Custom regex parser | python-dotenv `dotenv_values()` | Handles quotes, escapes, multiline, interpolation |
| Path handling | String concatenation | pathlib.Path | Cross-platform, safer, cleaner |
| JSON parsing | Manual string building | json module | Handles escaping, unicode, formatting |
| Shell quoting | Simple replace | `'`.replace("'", "'\"'\"'")` | Handles edge cases in shell escaping |

**Key insight:** The install-and-maintain reference already solves all these problems correctly. Copy the patterns, don't reinvent.

## Common Pitfalls

### Pitfall 1: Not Handling Missing CLAUDE_ENV_FILE
**What goes wrong:** Script crashes or writes to None path
**Why it happens:** `CLAUDE_ENV_FILE` is only set for SessionStart hooks, not all hook types
**How to avoid:** Always check `if env_file_path:` before writing
**Warning signs:** TypeError on file operations

### Pitfall 2: Not Escaping Single Quotes in Environment Values
**What goes wrong:** Malformed export statements break shell parsing
**Why it happens:** Values containing `'` aren't escaped for shell
**How to avoid:** Use `value.replace("'", "'\"'\"'")` pattern from reference
**Warning signs:** Env vars not loading, bash syntax errors

### Pitfall 3: Swallowing Errors Silently
**What goes wrong:** Hook appears to work but env isn't loaded
**Why it happens:** Empty try/except blocks hide failures
**How to avoid:** Log errors to file before continuing gracefully
**Warning signs:** Session works but env vars missing

### Pitfall 4: Invalid JSON Output
**What goes wrong:** Claude Code can't parse hook output
**Why it happens:** Exception before JSON output, or print() statements mixed in
**How to avoid:** Wrap main logic in try/finally with JSON output guaranteed
**Warning signs:** "Hook output was not valid JSON" errors

### Pitfall 5: uv Not Installed
**What goes wrong:** Script fails immediately with cryptic error
**Why it happens:** User hasn't installed uv
**How to avoid:** Document requirement; shebang will fail with clear-ish error
**Warning signs:** "uv: command not found"

### Pitfall 6: Log File Grows Unbounded
**What goes wrong:** Disk fills up over time
**Why it happens:** No rotation, append-only logging
**How to avoid:** Implement line-based rotation on startup
**Warning signs:** Log file exceeds expected size

## Code Examples

Verified patterns from official sources:

### Complete SessionStart Hook Structure
```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["python-dotenv"]
# ///
"""
Claude Code SessionStart Hook
"""
import json
import os
import sys
from datetime import datetime
from pathlib import Path

from dotenv import dotenv_values

SCRIPT_DIR = Path(__file__).parent
LOG_FILE = SCRIPT_DIR / "session_start.log"
MAX_LOG_LINES = 500


class Logger:
    def __init__(self, log_path: Path):
        self.log_path = log_path
        # Rotation and init...

    def log(self, message: str) -> None:
        print(message, file=sys.stderr)
        with open(self.log_path, "a") as f:
            f.write(message + "\n")


def main() -> None:
    try:
        hook_input = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        hook_input = {}

    # ... business logic ...

    output = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": "Your message"
        }
    }
    print(json.dumps(output))


if __name__ == "__main__":
    main()
```
Source: Adapted from [install-and-maintain session_start.py](/home/jc/developer/install-and-maintain/.claude/hooks/session_start.py)

### dotenv_values Usage
```python
# Source: python-dotenv documentation
from dotenv import dotenv_values

# Returns dict, doesn't modify os.environ
env_vars = dotenv_values(".env")

# Access values
for key, value in env_vars.items():
    if value is not None:  # dotenv_values returns None for empty values
        # Process...
```
Source: [python-dotenv GitHub](https://github.com/theskumar/python-dotenv)

### Vault Post Counting (Ported from Bash)
```python
def count_published_posts(vault_path: Path) -> int:
    """Count posts with Published status in vault."""
    import re
    count = 0
    pattern = re.compile(r"status:\s*\n\s*-\s*[Pp]ublished", re.MULTILINE)

    for md_file in vault_path.rglob("*.md"):
        try:
            content = md_file.read_text()
            if pattern.search(content):
                count += 1
        except Exception:
            pass  # Skip unreadable files
    return count
```
Note: This is equivalent to the bash `perl -0777 -ne` pattern

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| requirements.txt + venv | PEP 723 + uv | 2024-2025 | Single-file scripts are self-contained |
| load_dotenv() | dotenv_values() | Always available | Returns dict, doesn't pollute os.environ |
| Bash hooks | Python hooks | Project decision | Better error handling, logging |

**Deprecated/outdated:**
- Using `load_dotenv()` when you need to persist to CLAUDE_ENV_FILE: doesn't help, need to iterate manually anyway

## Open Questions

Things that couldn't be fully resolved:

1. **Timeout behavior with uv**
   - What we know: Claude Code has 10s timeout configured in settings.json
   - What's unclear: How does uv startup time factor in? First run caches deps.
   - Recommendation: Trust the reference implementation; 10s should be ample after first run

2. **Error behavior of dotenv_values with malformed .env**
   - What we know: Library exists and is stable
   - What's unclear: Exact exception types for syntax errors
   - Recommendation: Wrap in try/except, log warning, continue without env

## Sources

### Primary (HIGH confidence)
- [install-and-maintain session_start.py](/home/jc/developer/install-and-maintain/.claude/hooks/session_start.py) - Reference implementation, verified working
- [Claude Code hooks reference](https://code.claude.com/docs/en/hooks) - Official documentation for hook API
- [PEP 723](https://peps.python.org/pep-0723/) - Inline script metadata specification
- [uv scripts guide](https://docs.astral.sh/uv/guides/scripts/) - Official uv documentation

### Secondary (MEDIUM confidence)
- [python-dotenv GitHub](https://github.com/theskumar/python-dotenv) - Library documentation (v1.2.1)

### Tertiary (LOW confidence)
- None - all findings verified with primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Reference implementation exists and works
- Architecture: HIGH - Direct patterns from reference + official docs
- Pitfalls: HIGH - Derived from reference code + official docs

**Research date:** 2026-02-01
**Valid until:** 2026-03-01 (stable domain, 30 days)
