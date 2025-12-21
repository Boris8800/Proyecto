#!/bin/bash
# Script para limpiar descargas en root

echo "════════════════════════════════════════════════════════════════"
echo "    🧹 LIMPIAR DESCARGAS DE ROOT"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root (sudo)"
    exit 1
fi

echo "📂 Limpiando directorios de descargas..."

# Limpiar directorio Downloads
if [ -d "/root/Downloads" ]; then
    echo "  • Limpiando /root/Downloads..."
    rm -rf /root/Downloads/*
    echo "    ✅ Limpio"
fi

# Limpiar directorio home
if [ -d "/root" ]; then
    echo "  • Limpiando descargas en /root..."
    rm -f /root/*.tar.gz
    rm -f /root/*.zip
    rm -f /root/*.iso
    rm -f /root/*.deb
    rm -f /root/*.AppImage
    rm -f /root/*.exe
    echo "    ✅ Limpio"
fi

# Limpiar caché de apt
echo "  • Limpiando caché de apt..."
apt-get clean
apt-get autoclean
echo "    ✅ Limpio"

# Limpiar /tmp
echo "  • Limpiando /tmp..."
rm -rf /tmp/*
echo "    ✅ Limpio"

# Limpiar /var/tmp
echo "  • Limpiando /var/tmp..."
rm -rf /var/tmp/*
echo "    ✅ Limpio"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "    ✅ DESCARGAS LIMPIADAS"
echo "════════════════════════════════════════════════════════════════"
