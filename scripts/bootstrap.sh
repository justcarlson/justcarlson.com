#!/usr/bin/env bash
# Bootstrap development environment for justcarlson.com
# Idempotent - safe to run multiple times
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

printf "\n"
printf "${BLUE}=== Bootstrap: justcarlson.com ===${RESET}\n"
printf "\n"

# Read expected Node version from .nvmrc
EXPECTED_NODE_VERSION=""
if [[ -f "$PROJECT_DIR/.nvmrc" ]]; then
    EXPECTED_NODE_VERSION=$(< "$PROJECT_DIR/.nvmrc" tr -d '[:space:]')
fi

# Check Node.js
printf "${BLUE}Checking Node.js...${RESET}\n"
if ! command -v node &>/dev/null; then
    printf "${RED}Error: Node.js is not installed.${RESET}\n" >&2
    printf "Install from: https://nodejs.org/ or use nvm: https://github.com/nvm-sh/nvm\n" >&2
    exit 1
fi

CURRENT_NODE_VERSION=$(node -v | sed 's/v//' | cut -d'.' -f1)
printf "  Node.js: v$(node -v | sed 's/v//')\n"

if [[ -n "$EXPECTED_NODE_VERSION" && "$CURRENT_NODE_VERSION" != "$EXPECTED_NODE_VERSION" ]]; then
    printf "${YELLOW}Warning: Node version mismatch.${RESET}\n"
    printf "  Expected: Node ${EXPECTED_NODE_VERSION}.x (from .nvmrc)\n"
    printf "  Current:  Node ${CURRENT_NODE_VERSION}.x\n"
    printf "  Tip: Run 'nvm use' or 'fnm use' to switch versions.\n"
    printf "\n"
fi

# Check npm
printf "${BLUE}Checking npm...${RESET}\n"
if ! command -v npm &>/dev/null; then
    printf "${RED}Error: npm is not installed.${RESET}\n" >&2
    printf "npm comes with Node.js. Reinstall Node from: https://nodejs.org/\n" >&2
    exit 1
fi
printf "  npm: v$(npm -v)\n"
printf "\n"

# Install dependencies
printf "${BLUE}Installing dependencies...${RESET}\n"
cd "$PROJECT_DIR"
npm install
printf "\n"

# Run build check
printf "${BLUE}Running build validation...${RESET}\n"
npm run build:check
printf "\n"

# Start dev server briefly to confirm it works
printf "${BLUE}Verifying dev server starts...${RESET}\n"
DEV_SERVER_PID=""
DEV_SERVER_OK=false

# Start dev server in background
npm run dev &>/tmp/bootstrap-dev-server.log &
DEV_SERVER_PID=$!

# Wait for server to start (check for "Local" in output)
for i in {1..30}; do
    if grep -q "Local" /tmp/bootstrap-dev-server.log 2>/dev/null; then
        DEV_SERVER_OK=true
        break
    fi
    sleep 1
done

# Kill the dev server
if [[ -n "$DEV_SERVER_PID" ]]; then
    kill "$DEV_SERVER_PID" 2>/dev/null || true
    wait "$DEV_SERVER_PID" 2>/dev/null || true
fi

if [[ "$DEV_SERVER_OK" == "true" ]]; then
    printf "  ${GREEN}Dev server started successfully.${RESET}\n"
else
    printf "${YELLOW}Warning: Dev server did not start within 30 seconds.${RESET}\n"
    printf "  Check /tmp/bootstrap-dev-server.log for details.\n"
fi
printf "\n"

# Success message
printf "${GREEN}=== Bootstrap complete! ===${RESET}\n"
printf "\n"
printf "Run '${GREEN}just preview${RESET}' to start the dev server.\n"
printf "\n"
