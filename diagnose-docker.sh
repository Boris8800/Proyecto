#!/bin/bash
# Script para diagnosticar problemas de Docker

echo "════════════════════════════════════════════════════════════════"
echo "    🔍 DOCKER DIAGNOSTICS"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root (sudo)"
    exit 1
fi

# 1. Verificar Docker instalado
echo "1️⃣  Verificando Docker..."
if command -v docker &> /dev/null; then
    echo "   ✅ Docker instalado: $(docker --version)"
else
    echo "   ❌ Docker NO está instalado"
    exit 1
fi

# 2. Verificar daemon
echo ""
echo "2️⃣  Verificando Docker daemon..."
if docker ps >/dev/null 2>&1; then
    echo "   ✅ Docker daemon ejecutándose"
else
    echo "   ❌ Docker daemon NO está ejecutándose"
    echo "   Intentando iniciarlo..."
    systemctl start docker
    sleep 2
fi

# 3. Verificar conectividad a internet
echo ""
echo "3️⃣  Verificando conectividad a internet..."
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "   ✅ Internet accesible"
else
    echo "   ❌ SIN acceso a internet"
fi

# 4. Verificar acceso a Docker Hub
echo ""
echo "4️⃣  Verificando acceso a Docker Hub..."
if curl -s https://hub.docker.com/v2/repositories/library/postgres/ >/dev/null; then
    echo "   ✅ Docker Hub accesible"
else
    echo "   ❌ Docker Hub NO accesible"
fi

# 5. Intentar pull de imagen simple
echo ""
echo "5️⃣  Intentando descargar imagen de prueba (alpine)..."
if timeout 30 docker pull alpine:latest >/dev/null 2>&1; then
    echo "   ✅ Descarga de imágenes funciona"
    docker rmi alpine:latest 2>/dev/null || true
else
    echo "   ❌ No se pueden descargar imágenes"
    echo ""
    echo "   SOLUCIONES:"
    echo "   1. Verificar conexión a internet: ping 8.8.8.8"
    echo "   2. Reiniciar Docker: systemctl restart docker"
    echo "   3. Limpiar caché: docker system prune -f"
    echo "   4. Usar proxy si es necesario"
fi

# 6. Mostrar espacio en disco
echo ""
echo "6️⃣  Espacio en disco..."
docker system df

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "    ✅ DIAGNÓSTICO COMPLETADO"
echo "════════════════════════════════════════════════════════════════"
