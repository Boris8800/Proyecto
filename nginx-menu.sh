#!/bin/bash
set +u
opc=""
while true; do
    clear
    echo "=== MENÚ GESTIÓN NGINX ==="
    echo "1. Ver puertos en uso"
    echo "2. Ver configuraciones nginx"
    echo "3. Cambiar puerto 80 → 8080"
    echo "4. Deshabilitar nginx temporalmente"
    echo "5. Forzar liberar puerto 80"
    echo "6. Continuar instalación taxi."
    echo "7. Salir"
    echo ""
    read -p "Opción [1-7]: " opc
    case $opc in
        1)
            echo "=== PUERTOS EN USO ==="
            ss -tulpn | grep ":80\|:443"
            lsof -i :80
            read -p "Enter para continuar..."
            ;;
        2)
            echo "=== CONFIGURACIONES NGINX ==="
            sudo chown taxi:taxi /home/taxi/app/docker-compose.yml
            grep -n "listen" /etc/nginx/sites-enabled/* 2>/dev/null || echo "No hay configuraciones"
            read -p "Enter para continuar..."
            ;;
        3)
            echo "Cambiando puerto 80 a 8080..."
            sed -i 's/listen 80/listen 8080/g' /etc/nginx/sites-enabled/* 2>/dev/null
            nginx -t && systemctl restart nginx
            echo "Hecho. Nginx ahora en puerto 8080"
            sleep 2
            ;;
        4)
            echo "Deshabilitando nginx..."
            systemctl stop nginx
            systemctl disable nginx
            echo "Nginx deshabilitado temporalmente"
            sleep 2
            ;;
        5)
            echo "Forzando liberación puerto 80..."
            fuser -k 80/tcp
            systemctl stop nginx
            echo "Puerto 80 liberado"
            sleep 2
            ;;
        6)
            echo "Continuando con instalación taxi..."
            break
            ;;
        7)
            echo "Saliendo..."
            exit 0
            ;;
        *)
            echo "Opción inválida"
            sleep 1
            ;;
    esac
done
