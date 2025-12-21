#!/bin/bash
################################################################################
# TAXI INSTALLER - Wrapper Script
# This is a compatibility wrapper that delegates to the consolidated installer
# The main installation logic has been moved to: ../install-taxi-system.sh
################################################################################

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The main installer is in the parent directory
MAIN_INSTALLER="$(dirname "$SCRIPT_DIR")/install-taxi-system.sh"

# Check if the main installer exists
if [ ! -f "$MAIN_INSTALLER" ]; then
    echo "ERROR: Main installer not found at $MAIN_INSTALLER"
    exit 1
fi

# Delegate all arguments to the main installer
exec bash "$MAIN_INSTALLER" "$@"
