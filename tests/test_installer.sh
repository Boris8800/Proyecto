#!/bin/bash
# tests/test_installer.sh
# Prueba básica para taxi-install.sh

set -e

if [[ ! -f "./taxi-install.sh" ]]; then
  echo "ERROR: taxi-install.sh no encontrado en el directorio raíz." >&2
  exit 1
fi

echo "Probando sintaxis de taxi-install.sh..."
bash -n ./taxi-install.sh

echo "Prueba de sintaxis exitosa."
exit 0
