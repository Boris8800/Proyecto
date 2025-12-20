#!/bin/bash
# Wrapper para ejecutar el instalador principal del sistema Taxi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Script principal del instalador
INSTALL_SCRIPT="$PROJECT_ROOT/taxi-complete-install.sh"

if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "Error: No se encuentra $INSTALL_SCRIPT" >&2
    echo "El script de instalación debe estar en: $INSTALL_SCRIPT"
    exit 1
fi

bash -n "$INSTALL_SCRIPT"
