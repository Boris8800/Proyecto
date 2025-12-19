#!/bin/bash
# Versión sin chequeo falso de paquetes rotos
set -e

echo "=== INSTALACIÓN SIMPLIFICADA ==="

echo "Saltando chequeo de paquetes rotos..."

apt-get update
apt-get install -y docker.io docker-compose nginx postgresql redis-server

useradd -m taxi 2>/dev/null || true

echo "✅ Instalación básica completada"
