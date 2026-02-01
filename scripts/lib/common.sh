#!/usr/bin/env bash
# scripts/lib/common.sh - Shared library for blog publishing scripts
#
# This library provides common constants and utilities used across
# publish.sh, unpublish.sh, list-posts.sh, and other scripts.
#
# Usage:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "${SCRIPT_DIR}/lib/common.sh"
#
# Or for scripts in the same directory as lib/:
#   source "${SCRIPT_DIR}/../lib/common.sh"

# ============================================================================
# Source Guard (prevent double-sourcing)
# ============================================================================
[[ -n "${_COMMON_SH_LOADED:-}" ]] && return
readonly _COMMON_SH_LOADED=1

# ============================================================================
# Strict Mode
# ============================================================================
set -euo pipefail

# ============================================================================
# Color Constants
# ============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly BLUE='\033[0;34m'
readonly RESET='\033[0m'

# ============================================================================
# Configuration Constants
# ============================================================================
readonly CONFIG_FILE=".claude/settings.local.json"
readonly BLOG_DIR="src/content/blog"
readonly ASSETS_DIR="public/assets/blog"

# ============================================================================
# Exit Codes
# ============================================================================
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_CANCELLED=130
