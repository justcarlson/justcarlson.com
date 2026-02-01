#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["python-dotenv"]
# ///
"""
Claude Code SessionStart Hook: Environment & Vault Status

Triggered by: Session start, resume, clear, or compact
Purpose: Load environment variables from .env file into CLAUDE_ENV_FILE
         and report Obsidian vault status with published post count.
"""

import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

from dotenv import dotenv_values

# Log file in the same directory as this script
SCRIPT_DIR = Path(__file__).parent
LOG_FILE = SCRIPT_DIR / "session_start.log"
MAX_LOG_LINES = 500


def rotate_log(log_path: Path, max_lines: int = MAX_LOG_LINES) -> None:
    """Keep only the last max_lines in the log file."""
    if not log_path.exists():
        return
    try:
        lines = log_path.read_text().splitlines()
        if len(lines) > max_lines:
            # Keep last max_lines
            log_path.write_text("\n".join(lines[-max_lines:]) + "\n")
    except Exception:
        pass  # Don't fail on rotation issues


class Logger:
    """Simple logger that writes to both stderr and a log file (appends)."""

    def __init__(self, log_path: Path):
        self.log_path = log_path
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.log_path, "a") as f:
            f.write(f"\n{'='*60}\n")
            f.write(f"=== SessionStart Hook: {datetime.now().isoformat()} ===\n")
            f.write(f"{'='*60}\n")

    def log(self, message: str) -> None:
        """Print to stderr and append to log file."""
        print(message, file=sys.stderr)
        with open(self.log_path, "a") as f:
            f.write(message + "\n")


def count_published_posts(vault_path: Path) -> int:
    """Count markdown files with Published status in vault."""
    count = 0
    # Pattern matches YAML frontmatter status field with Published value
    # e.g., status:\n  - Published
    pattern = re.compile(r"status:\s*\n\s*-\s*[Pp]ublished", re.IGNORECASE)

    try:
        for md_file in vault_path.rglob("*.md"):
            try:
                content = md_file.read_text(encoding="utf-8")
                if pattern.search(content):
                    count += 1
            except Exception:
                continue  # Skip files we can't read
    except Exception:
        pass  # Skip on directory traversal errors

    return count


def main() -> None:
    # Rotate log before starting (keep last ~100 sessions)
    rotate_log(LOG_FILE)

    logger = Logger(LOG_FILE)

    try:
        # Read hook input from stdin
        try:
            hook_input = json.load(sys.stdin)
        except (json.JSONDecodeError, EOFError):
            hook_input = {}

        logger.log("")
        logger.log("HOOK INPUT (JSON received via stdin from Claude Code):")
        logger.log("-" * 60)
        logger.log(json.dumps(hook_input, indent=2) if hook_input else "{}")
        logger.log("")

        project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
        env_file_path = os.environ.get("CLAUDE_ENV_FILE")
        source = hook_input.get("source", "unknown")
        session_id = hook_input.get("session_id", "unknown")

        logger.log("Claude Code SessionStart Hook: Loading Environment")
        logger.log("-" * 60)
        logger.log(f"Source: {source}")
        logger.log(f"Session ID: {session_id}")
        logger.log(f"Project directory: {project_dir}")
        logger.log(f"CLAUDE_ENV_FILE: {env_file_path or 'not set'}")
        logger.log(f"Log file: {LOG_FILE}")

        # Track what we loaded
        loaded_vars = []
        context_parts = [f"SessionStart hook ran (source: {source})."]

        # Load .env if present and CLAUDE_ENV_FILE is available
        dotenv_path = Path(project_dir) / ".env"
        if env_file_path:
            if dotenv_path.exists():
                logger.log(f"\n>>> Loading variables from {dotenv_path}...")
                try:
                    env_vars = dotenv_values(dotenv_path)
                    with open(env_file_path, "a") as f:
                        for key, value in env_vars.items():
                            if value is not None:
                                # Escape any single quotes in the value
                                escaped_value = value.replace("'", "'\"'\"'")
                                f.write(f"export {key}='{escaped_value}'\n")
                                loaded_vars.append(key)
                                logger.log(f"  Loaded: {key}")
                except Exception as e:
                    logger.log(f"  Error loading .env: {e}")
            else:
                logger.log(f"\n>>> No .env file found at {dotenv_path}")
        else:
            logger.log("\n>>> CLAUDE_ENV_FILE not available - cannot persist variables")

        if loaded_vars:
            context_parts.append(f"Loaded environment variables: {', '.join(loaded_vars)}")

        # Check vault configuration
        logger.log("\n>>> Checking vault configuration...")
        settings_local_path = Path(project_dir) / ".claude" / "settings.local.json"

        vault_message = None
        if not settings_local_path.exists():
            vault_message = "No vault configured. Run /blog:install to set up publishing."
            logger.log(f"  {vault_message}")
        else:
            try:
                settings = json.loads(settings_local_path.read_text())
                vault_path_str = settings.get("obsidianVaultPath")

                if not vault_path_str:
                    vault_message = "No vault configured. Run /blog:install to set up publishing."
                    logger.log(f"  {vault_message}")
                else:
                    vault_path = Path(vault_path_str)
                    if not vault_path.is_dir():
                        vault_message = f"Vault path configured but not found: {vault_path_str}"
                        logger.log(f"  {vault_message}")
                    else:
                        # Count published posts
                        post_count = count_published_posts(vault_path)
                        if post_count > 0:
                            vault_message = f"Ready: {post_count} post(s) with Published status. Run /blog:publish to continue."
                        else:
                            vault_message = "Vault connected. No posts ready to publish."
                        logger.log(f"  Vault: {vault_path}")
                        logger.log(f"  Published posts: {post_count}")
                        logger.log(f"  {vault_message}")
            except json.JSONDecodeError as e:
                vault_message = f"Error reading vault config: {e}"
                logger.log(f"  {vault_message}")
            except Exception as e:
                vault_message = f"Error checking vault: {e}"
                logger.log(f"  {vault_message}")

        if vault_message:
            context_parts.append(vault_message)

        logger.log("\n" + "-" * 60)
        logger.log("SessionStart Complete!")
        logger.log("-" * 60)

        # Build output
        output = {
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": " ".join(context_parts),
            }
        }

        logger.log("")
        logger.log("HOOK OUTPUT (JSON returned via stdout to Claude Code):")
        logger.log("-" * 60)
        logger.log(json.dumps(output, indent=2))

        # Log completion timestamp
        with open(LOG_FILE, "a") as f:
            f.write(f"\n=== SessionStart Hook Completed: {datetime.now().isoformat()} ===\n")

        print(json.dumps(output))
        sys.exit(0)

    except Exception as e:
        # On any unhandled error, still output valid JSON and don't block session
        error_output = {
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": f"SessionStart hook error: {e}",
            }
        }
        try:
            logger.log(f"\n!!! ERROR: {e}")
        except Exception:
            pass
        print(json.dumps(error_output))
        sys.exit(0)


if __name__ == "__main__":
    main()
