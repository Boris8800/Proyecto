#!/bin/bash
# main.sh - Root wrapper script for Swift Cab installation
# This script delegates to the actual main.sh in the scripts/ directory

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the actual main.sh script with all arguments
bash "$SCRIPT_DIR/scripts/main.sh" "$@"
