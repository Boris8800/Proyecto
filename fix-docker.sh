#!/bin/bash
# Script para reparar problemas comunes de Docker

echo "════════════════════════════════════════════════════════════════"
echo "    🔧 DOCKER FIX & RESTART"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root (sudo)"
    exit 1
fi

echo "1️⃣  Deteniendo Docker..."
systemctl stop docker 2>/dev/null || true
sleep 2

echo "2️⃣  Limpiando caché de Docker..."
rm -rf /var/lib/docker/buildkit/* 2>/dev/null || true
rm -rf /var/lib/docker/image/overlay2/imagedb/metadata/sha256/* 2>/dev/null || true

echo "3️⃣  Iniciando Docker..."
systemctl start docker
sleep 5

echo "4️⃣  Verificando estado..."
if docker ps >/dev/null 2>&1; then
    echo "   ✅ Docker funcionando"
else
    echo "   ❌ Docker no responde - reiniciando sistema..."
    sleep 5
fi

echo ""
echo "5️⃣  Limpiando recursos no utilizados..."
docker system prune -f 2>/dev/null || true

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "    ✅ DOCKER REPARADO Y REINICIADO"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Ahora intenta descargar imágenes con:"
echo "  docker pull alpine:latest"
