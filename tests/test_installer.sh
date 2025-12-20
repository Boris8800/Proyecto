#!/bin/bash
# tests/test_installer.sh
# Prueba básica para taxi-complete-install.sh

set -e

if [[ ! -f "./taxi-complete-install.sh" ]]; then
  echo "ERROR: taxi-complete-install.sh no encontrado en el directorio raíz." >&2
  exit 1
fi

echo "Probando sintaxis de taxi-complete-install.sh..."
bash -n ./taxi-complete-install.sh

echo "Prueba de sintaxis exitosa."
exit 0
