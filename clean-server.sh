#!/bin/bash
# Script para limpiar completamente el servidor antes de reinstalar

echo "════════════════════════════════════════════════════════════════"
echo "    🧹 LIMPIEZA COMPLETA DEL SERVIDOR UBUNTU"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root (sudo)"
    exit 1
fi

echo "⚠️  Esto eliminará TODAS las instalaciones del Taxi System."
read -r -p "¿Continuar? Escribe 'SI' para confirmar: " confirm

if [ "$confirm" != "SI" ]; then
    echo "Cancelado."
    exit 0
fi

echo ""
echo "🛑 Deteniendo todos los servicios..."
systemctl stop docker 2>/dev/null || true
systemctl stop taxi-system 2>/dev/null || true

echo "🧹 Eliminando usuario taxi..."
pkill -u taxi 2>/dev/null || true
sleep 1
userdel -f taxi 2>/dev/null || true
groupdel taxi 2>/dev/null || true

echo "🗑️  Eliminando directorios..."
rm -rf /home/taxi
rm -rf /root/Proyecto
rm -rf /root/web
rm -rf /var/log/taxi
rm -rf /var/lib/taxi
rm -rf /opt/taxi 2>/dev/null || true
rm -rf /srv/taxi 2>/dev/null || true

echo "🗑️  Eliminando servicios systemd..."
rm -f /etc/systemd/system/taxi*
systemctl daemon-reload 2>/dev/null || true

echo "🗑️  Eliminando configuración de nginx..."
rm -f /etc/nginx/sites-available/taxi*
rm -f /etc/nginx/sites-enabled/taxi*

echo "🗑️  Eliminando configuración de Docker..."
rm -rf /var/lib/docker/volumes/taxi* 2>/dev/null || true

echo "🧼 Limpiando caché del sistema..."
apt-get clean 2>/dev/null || true
apt-get autoclean 2>/dev/null || true
rm -rf /tmp/taxi*
rm -rf /var/tmp/*

echo "🔄 Recargando servicios..."
systemctl daemon-reload 2>/dev/null || true

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "    ✅ SERVIDOR COMPLETAMENTE LIMPIO"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🚀 El servidor está listo para una nueva instalación fresca."
echo ""
echo "Para reinstalar el Taxi System, ejecuta:"
echo "  sudo bash -c \"rm -rf /root/Proyecto && git clone https://github.com/Boris8800/Proyecto.git /root/Proyecto && chmod -R 755 /root/Proyecto && bash /root/Proyecto/main.sh --fresh\""
