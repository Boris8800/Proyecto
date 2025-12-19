#!/bin/bash

# === MENÚ INSTALACIÓN TAXI ===
echo "====================================="
echo "      MENÚ INSTALACIÓN TAXI        "
echo "====================================="
echo "1. Instalar dependencias completas"
echo "2. Saltar instalación de dependencias"
echo "3. Verificar sistema solamente"
echo "4. Salir"
echo
read -p "Seleccione opción (1-4): " opcion

case $opcion in
    1)
        echo "Instalando dependencias..."
        apt-get update
        apt-get install -y docker.io docker-compose nginx curl git postgresql redis-server
        ;;
    2)
        echo "Saltando instalación de dependencias..."
        ;;
    3)
        echo "Verificando sistema..."
        echo "Disco:"
        df -h
        echo "Memoria:"
        free -h
        echo "Usuarios relevantes:"
        id taxi 2>/dev/null || echo "Usuario taxi no existe"
        echo "Servicios:"
        systemctl status docker || echo "Docker no instalado"
        systemctl status nginx || echo "Nginx no instalado"
        systemctl status postgresql || echo "PostgreSQL no instalado"
        systemctl status redis-server || echo "Redis no instalado"
        ;;
    4)
        echo "Saliendo..."
        exit 0
        ;;
    *)
        echo "Opción inválida"
        exit 1
        ;;
esac

echo "Continuando con instalación..."
# Aquí puedes agregar el resto del flujo de instalación
