#!/bin/bash
# install-taxi-system.sh - Taxi System Installation Script
# This script has been refactored and modularized for maintainability
# The actual installation logic is now in main.sh with modules in lib/

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the main installation script with all arguments
exec "$SCRIPT_DIR/main.sh" "$@"
