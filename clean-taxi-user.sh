#!/bin/bash
# Script para limpiar completamente el usuario 'taxi' del servidor

echo "════════════════════════════════════════════════════════════════"
echo "    🧹 LIMPIAR USUARIO TAXI - UBUNTU SERVER"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root (sudo)"
    exit 1
fi

echo "⚠️  Esto eliminará completamente el usuario 'taxi' y todos sus archivos."
read -r -p "¿Continuar? (s/n): " confirm

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Cancelado."
    exit 0
fi

echo ""
echo "🛑 Deteniendo servicios..."
systemctl stop taxi-system 2>/dev/null || true
systemctl stop taxi 2>/dev/null || true

echo "🧹 Eliminando procesos del usuario taxi..."
pkill -u taxi 2>/dev/null || true
sleep 2

echo "🗑️  Eliminando directorio /home/taxi..."
rm -rf /home/taxi

echo "🗑️  Eliminando usuario taxi..."
userdel -f taxi 2>/dev/null || true

echo "🗑️  Eliminando grupo taxi..."
groupdel taxi 2>/dev/null || true

echo "🗑️  Eliminando directorio /var/log/taxi..."
rm -rf /var/log/taxi

echo "🗑️  Eliminando archivos de cron..."
rm -f /etc/cron.d/taxi-*

echo "🗑️  Eliminando servicios systemd..."
rm -f /etc/systemd/system/taxi*
systemctl daemon-reload 2>/dev/null || true

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "    ✅ USUARIO TAXI ELIMINADO COMPLETAMENTE"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✨ El servidor está limpio y listo para una nueva instalación."
