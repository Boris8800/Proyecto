#!/bin/bash
# prepare-environment.sh - Prepare environment for Taxi System installation
# This script ensures all necessary paths are set up correctly

set -euo pipefail

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find the web directory - check multiple locations
find_web_dir() {
    # Check in the same directory as this script
    if [ -d "$SCRIPT_DIR/web" ]; then
        echo "$SCRIPT_DIR/web"
        return 0
    fi
    
    # Check in parent directory
    if [ -d "$SCRIPT_DIR/../web" ]; then
        echo "$SCRIPT_DIR/../web"
        return 0
    fi
    
    # Check in /root/web (common location when running as root)
    if [ -d "/root/web" ]; then
        echo "/root/web"
        return 0
    fi
    
    # Check in /workspaces/Proyecto/web (development location)
    if [ -d "/workspaces/Proyecto/web" ]; then
        echo "/workspaces/Proyecto/web"
        return 0
    fi
    
    # Not found
    return 1
}

# Main preparation
echo "[INFO] Preparing environment for Taxi System installation..."

# Find and export WEB_DIR
WEB_DIR=$(find_web_dir) || WEB_DIR=""

if [ -n "$WEB_DIR" ]; then
    echo "[OK] Web directory found: $WEB_DIR"
    export WEB_DIR="$WEB_DIR"
else
    echo "[WARN] Web directory not found in standard locations"
fi

# Export SCRIPT_DIR and PROJECT_ROOT for use by main.sh
export SCRIPT_DIR="$SCRIPT_DIR"
export PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "[INFO] Environment prepared"
echo "[INFO] Script dir: $SCRIPT_DIR"
echo "[INFO] Project root: $PROJECT_ROOT"
[ -n "$WEB_DIR" ] && echo "[INFO] Web dir: $WEB_DIR"

# Run main.sh with all arguments
exec "$SCRIPT_DIR/main.sh" "$@"
