#!/bin/bash
set -euo pipefail

# Instalador manual paso a paso para Taxi System
# Ejecuta cada paso y confirma antes de continuar

step() {
    echo -e "\n\033[1;34m==> $1\033[0m"
    read -p "Presiona ENTER para continuar..." _
}

step "Actualizar repositorios y paquetes del sistema"
sudo apt-get update && sudo apt-get upgrade -y

step "Instalar dependencias: curl, git, nginx, docker.io, docker-compose, postgresql, redis-server"
sudo apt-get install -y curl git nginx docker.io docker-compose postgresql redis-server

step "Habilitar y arrancar servicios Docker, Redis, PostgreSQL y Nginx"
sudo systemctl enable --now docker
sudo systemctl enable --now redis-server
sudo systemctl enable --now postgresql
sudo systemctl enable --now nginx

step "Crear usuario taxi y directorio de aplicación"
id taxi &>/dev/null || sudo useradd -m -s /bin/bash taxi
sudo mkdir -p /home/taxi/app
sudo chown -R taxi:taxi /home/taxi

step "Crear archivo .env"
cat <<EOF | sudo tee /home/taxi/app/.env
POSTGRES_PASSWORD=taxipass
REDIS_PASSWORD=redispass
API_PORT=3000
EOF
sudo chown taxi:taxi /home/taxi/app/.env

step "Crear archivo docker-compose.yml"
cat <<EOF | sudo tee /home/taxi/app/docker-compose.yml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: taxipass
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: always
  redis:
    image: redis:7
    command: ["redis-server", "--requirepass", "redispass"]
    ports:
      - "6379:6379"
    restart: always
  api:
    image: node:18
    working_dir: /app
    command: bash -c "npx http-server -p 3000"
    ports:
      - "3000:3000"
    volumes:
      - ./api:/app
    restart: always
  admin:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./admin:/usr/share/nginx/html:ro
    restart: always
volumes:
  pgdata:
EOF
sudo chown taxi:taxi /home/taxi/app/docker-compose.yml

step "Crear carpetas y archivos de ejemplo para API y Admin"
sudo mkdir -p /home/taxi/app/api /home/taxi/app/admin
sudo bash -c "echo '<h1>Taxi API funcionando 🚕</h1>' > /home/taxi/app/api/index.html"
sudo bash -c "echo '<h1>Taxi Admin Panel</h1>' > /home/taxi/app/admin/index.html"
sudo chown -R taxi:taxi /home/taxi/app/api /home/taxi/app/admin

step "Configurar Nginx como proxy"
cat <<NGINX | sudo tee /etc/nginx/sites-available/taxi
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location /admin/ {
        proxy_pass http://localhost:8080/;
    }
}
NGINX
sudo ln -sf /etc/nginx/sites-available/taxi /etc/nginx/sites-enabled/taxi
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

step "Levantar servicios Docker"
cd /home/taxi/app
sudo -u taxi docker-compose --env-file .env up -d

step "Mostrar información de acceso"
IP=$(hostname -I | awk '{print $1}')
echo -e "\n\033[1;32m✅ INSTALACIÓN COMPLETA\033[0m"
echo "🌐 API:         http://$IP:3000"
echo "📊 Admin Panel: http://$IP:8080"
echo "🐘 PostgreSQL:  $IP:5432"
echo "🔴 Redis:       $IP:6379"
