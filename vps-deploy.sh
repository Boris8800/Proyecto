#!/bin/bash
# vps-deploy.sh - Root wrapper script for VPS deployment
# This script delegates to the actual vps-complete-setup.sh in the scripts/ directory

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the VPS complete setup script with all arguments
bash "$SCRIPT_DIR/scripts/vps-complete-setup.sh" "$@"
