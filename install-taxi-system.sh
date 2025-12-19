#!/bin/bash
# TAXI SYSTEM INSTALLER - VERSIÓN COMPLETA Y AUTOMÁTICA
set -euo pipefail

# 1. FUNCIONES BÁSICAS
log_step()   { echo -e "\033[1;34m[STEP]\033[0m $1"; }
log_ok()     { echo -e "\033[0;32m[OK]\033[0m $1"; }
log_error()  { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

# 2. INSTALAR DEPENDENCIAS (SIN INTERACCIÓN)
install_dependencies() {
    log_step "Instalando dependencias (Docker, Docker Compose, Nginx, PostgreSQL, Redis)..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y curl git nginx docker.io docker-compose postgresql redis-server > /dev/null
    systemctl enable --now docker
    systemctl enable --now redis-server
    systemctl enable --now postgresql
    systemctl enable --now nginx
    log_ok "Dependencias instaladas."
}

# 3. CONFIGURAR SISTEMA
configure_system() {
    log_step "Configurando usuario y directorios..."
    id taxi &>/dev/null || useradd -m -s /bin/bash taxi
    mkdir -p /home/taxi/app
    chown -R taxi:taxi /home/taxi

    log_step "Generando archivo .env..."
    cat > /home/taxi/app/.env <<EOF
POSTGRES_PASSWORD=taxipass
REDIS_PASSWORD=redispass
API_PORT=3000
EOF
    chown taxi:taxi /home/taxi/app/.env

    log_step "Generando docker-compose.yml..."
    cat > /home/taxi/app/docker-compose.yml <<EOF
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: [POSTGRES_PASSWORD]
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: always

  redis:
    image: redis:7
    command: ["redis-server", "--requirepass", "${REDIS_PASSWORD}"]
    ports:
      - "6379:6379"
    restart: always

  api:
    image: node:18
    working_dir: /app
    command: bash -c "npx http-server -p ${API_PORT}"
    ports:
      - "3000:${API_PORT}"
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
    chown taxi:taxi /home/taxi/app/docker-compose.yml

    log_step "Creando API y Admin de ejemplo..."
    mkdir -p /home/taxi/app/api /home/taxi/app/admin
    echo '<h1>Taxi API funcionando 🚕</h1>' > /home/taxi/app/api/index.html
    echo '<h1>Taxi Admin Panel</h1>' > /home/taxi/app/admin/index.html
    chown -R taxi:taxi /home/taxi/app/api /home/taxi/app/admin

    log_step "Configurando Nginx como proxy..."
    cat > /etc/nginx/sites-available/taxi <<NGINX
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
    ln -sf /etc/nginx/sites-available/taxi /etc/nginx/sites-enabled/taxi
    rm -f /etc/nginx/sites-enabled/default
    nginx -t && systemctl reload nginx
    log_ok "Sistema configurado."
}

# 4. INICIAR SERVICIOS
start_services() {
    log_step "Levantando servicios Docker..."
    cd /home/taxi/app
    sudo -u taxi docker-compose --env-file .env up -d
    log_ok "Servicios Docker en ejecución."
}

# 5. MOSTRAR RESULTADO
show_result() {
    IP=$(hostname -I | awk '{print $1}')
    echo -e "\n\033[1;32m✅ INSTALACIÓN COMPLETA\033[0m"
    echo "🌐 API:         http://$IP:3000"
    echo "📊 Admin Panel: http://$IP:8080"
    echo "🐘 PostgreSQL:  $IP:5432"
    echo "🔴 Redis:       $IP:6379"
}

# FLUJO PRINCIPAL
main() {
    install_dependencies
    configure_system
    start_services
    show_result
}

main








