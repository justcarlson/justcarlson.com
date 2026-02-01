#!/usr/bin/env bash
# Interactive setup for Obsidian vault path configuration
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# Config file location
CONFIG_DIR=".claude"
CONFIG_FILE="$CONFIG_DIR/settings.local.json"

# Non-interactive mode
VAULT_ARG=""
FORCE_MODE=false

# ============================================================================
# Argument Parsing
# ============================================================================

print_usage() {
    echo "Usage: $0 [--vault <path>] [--force|-f]"
    echo ""
    echo "Configure Obsidian vault path for blog publishing."
    echo ""
    echo "Options:"
    echo "  --vault <path>  Set vault path directly (non-interactive)"
    echo "  --force, -f     Overwrite existing config without prompting"
    echo "  --help, -h      Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Interactive mode"
    echo "  $0 --vault ~/notes/my-vault          # Non-interactive"
    echo "  $0 --vault ~/notes/my-vault --force  # Overwrite existing"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --vault)
            VAULT_ARG="$2"
            shift 2
            ;;
        --force|-f)
            FORCE_MODE=true
            shift
            ;;
        --help|-h)
            print_usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${RESET}" >&2
            print_usage
            ;;
    esac
done

echo ""
echo "=== Obsidian Vault Setup ==="
echo ""

# Check for existing config (idempotency)
if [[ -f "$CONFIG_FILE" && "$FORCE_MODE" != "true" ]]; then
    EXISTING_PATH=$(jq -r '.obsidianVaultPath // empty' "$CONFIG_FILE" 2>/dev/null)
    if [[ -n "$EXISTING_PATH" && -d "$EXISTING_PATH/.obsidian" ]]; then
        echo ""
        echo -e "${GREEN}Already configured.${RESET}"
        echo -e "Vault path: ${GREEN}$EXISTING_PATH${RESET}"
        echo ""
        echo "To reconfigure, use --force or delete $CONFIG_FILE and run again."
        exit 0
    fi
fi

# Non-interactive mode: use provided vault path
if [[ -n "$VAULT_ARG" ]]; then
    # Expand ~ if present
    VAULT_ARG="${VAULT_ARG/#\~/$HOME}"

    # Validate the path
    if [[ ! -d "$VAULT_ARG" ]]; then
        echo -e "${RED}Error: Directory does not exist: $VAULT_ARG${RESET}" >&2
        exit 1
    fi
    if [[ ! -d "$VAULT_ARG/.obsidian" ]]; then
        echo -e "${RED}Error: Not an Obsidian vault (no .obsidian directory): $VAULT_ARG${RESET}" >&2
        exit 1
    fi

    VAULT_PATH="$VAULT_ARG"
    echo -e "Using vault: ${GREEN}$VAULT_PATH${RESET}"
else
    # Interactive mode continues below
    VAULT_PATH=""
fi

# Interactive vault selection (only if --vault not provided)
if [[ -z "$VAULT_PATH" ]]; then
    # Auto-detect Obsidian vaults in home directory
    echo "Searching for Obsidian vaults..."
    mapfile -t VAULTS < <(find "$HOME" -maxdepth 4 -type d -name ".obsidian" 2>/dev/null | while read -r obsidian_dir; do
        dirname "$obsidian_dir"
    done | sort -u)

    if [[ ${#VAULTS[@]} -eq 0 ]]; then
        # No vaults found - prompt for manual entry
        echo -e "${YELLOW}No Obsidian vaults found.${RESET}"
        echo ""
        read -rp "Enter the path to your Obsidian vault: " VAULT_PATH

        # Validate the path
        if [[ ! -d "$VAULT_PATH" ]]; then
            echo -e "${RED}Error: Directory does not exist: $VAULT_PATH${RESET}" >&2
            exit 1
        fi
        if [[ ! -d "$VAULT_PATH/.obsidian" ]]; then
            echo -e "${RED}Error: Not an Obsidian vault (no .obsidian directory): $VAULT_PATH${RESET}" >&2
            exit 1
        fi

    elif [[ ${#VAULTS[@]} -eq 1 ]]; then
        # Single vault found - confirm
        echo -e "Found vault: ${GREEN}${VAULTS[0]}${RESET}"
        echo ""
        read -rp "Use this vault? [Y/n] " CONFIRM
        CONFIRM=${CONFIRM:-Y}

        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
            VAULT_PATH="${VAULTS[0]}"
        else
            read -rp "Enter the path to your Obsidian vault: " VAULT_PATH

            # Validate the path
            if [[ ! -d "$VAULT_PATH" ]]; then
                echo -e "${RED}Error: Directory does not exist: $VAULT_PATH${RESET}" >&2
                exit 1
            fi
            if [[ ! -d "$VAULT_PATH/.obsidian" ]]; then
                echo -e "${RED}Error: Not an Obsidian vault (no .obsidian directory): $VAULT_PATH${RESET}" >&2
                exit 1
            fi
        fi

    else
        # Multiple vaults found - show numbered list
        echo "Found ${#VAULTS[@]} Obsidian vaults:"
        echo ""
        for i in "${!VAULTS[@]}"; do
            echo "  $((i + 1)). ${VAULTS[$i]}"
        done
        echo ""
        read -rp "Select vault (1-${#VAULTS[@]}) or 0 for manual entry: " SELECTION

        if [[ "$SELECTION" =~ ^[0-9]+$ ]]; then
            if [[ "$SELECTION" -eq 0 ]]; then
                read -rp "Enter the path to your Obsidian vault: " VAULT_PATH

                # Validate the path
                if [[ ! -d "$VAULT_PATH" ]]; then
                    echo -e "${RED}Error: Directory does not exist: $VAULT_PATH${RESET}" >&2
                    exit 1
                fi
                if [[ ! -d "$VAULT_PATH/.obsidian" ]]; then
                    echo -e "${RED}Error: Not an Obsidian vault (no .obsidian directory): $VAULT_PATH${RESET}" >&2
                    exit 1
                fi
            elif [[ "$SELECTION" -ge 1 && "$SELECTION" -le ${#VAULTS[@]} ]]; then
                VAULT_PATH="${VAULTS[$((SELECTION - 1))]}"
            else
                echo -e "${RED}Error: Invalid selection${RESET}" >&2
                exit 1
            fi
        else
            echo -e "${RED}Error: Please enter a number${RESET}" >&2
            exit 1
        fi
    fi
fi

# Ensure we have a vault path
if [[ -z "$VAULT_PATH" ]]; then
    echo -e "${RED}Error: No vault path selected${RESET}" >&2
    exit 1
fi

# Create config directory if needed
mkdir -p "$CONFIG_DIR"

# Write config file
# Use jq if available, otherwise fallback to echo
if command -v jq &>/dev/null; then
    jq -n --arg path "$VAULT_PATH" '{"obsidianVaultPath": $path}' > "$CONFIG_FILE"
else
    echo "{\"obsidianVaultPath\": \"$VAULT_PATH\"}" > "$CONFIG_FILE"
fi

echo ""
echo -e "${GREEN}Setup complete.${RESET}"
echo -e "Vault path: ${GREEN}$VAULT_PATH${RESET}"
echo ""
echo "Config saved to: $CONFIG_FILE (gitignored - local to this machine)"
echo ""
