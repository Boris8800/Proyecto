#!/bin/bash
# Wrapper para ejecutar el instalador principal del sistema Taxi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Puedes cambiar el script principal aquí si lo deseas
INSTALL_SCRIPT="$PROJECT_ROOT/taxi-install.sh"

if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "Error: No se encuentra $INSTALL_SCRIPT" >&2
    exit 1
fi

bash -n "$INSTALL_SCRIPT"
