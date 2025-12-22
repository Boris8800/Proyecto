#!/bin/bash
# scripts/main.sh - Main entry point for Swift Cab VPS installation
# This script initializes the environment and starts the interactive menu

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common library for logging and utilities
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/common.sh"

# Source the menu library for interactive interface
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/menus.sh"

# Main entry point
main() {
    display_banner
    main_menu
}

# Execute main function
main "$@"
