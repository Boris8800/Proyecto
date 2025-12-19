#!/bin/bash
set -euo pipefail

# ===================== COLORES =====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===================== LOGGING =====================
log_step()    { echo -e "${BLUE}[STEP]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ===================== VALIDACIONES =====================
validate_env() {
  log_step "Validando variables de entorno..."
  [[ -z "${POSTGRES_PASSWORD:-}" ]] && export POSTGRES_PASSWORD="taxipass"
  [[ -z "${REDIS_PASSWORD:-}" ]] && export REDIS_PASSWORD="redispass"
  [[ -z "${API_PORT:-}" ]] && export API_PORT="3000"
  log_success "Variables de entorno listas."
}

check_root() {
  if [[ "$EUID" -ne 0 ]]; then
    log_error "Este script debe ejecutarse como root."
    exit 1
  fi
}

check_command() {
  command -v "$1" &>/dev/null || { log_error "Falta $1. Instalando..."; return 1; }
  return 0;
}

# ===================== INSTALACIÓN DEPENDENCIAS =====================
install_docker() {
  if ! check_command docker; then
    log_step "Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
    log_success "Docker instalado."
  else
    log_success "Docker ya está instalado."
  fi
}

install_docker_compose() {
  if ! check_command docker-compose; then
    log_step "Instalando Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    log_success "Docker Compose instalado."
  else
    log_success "Docker Compose ya está instalado."
  fi
}

install_nginx() {
  if ! check_command nginx; then
    log_step "Instalando Nginx..."
    apt-get update -qq
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    log_success "Nginx instalado y en ejecución."
  else
    log_success "Nginx ya está instalado."
  fi
}

# ===================== ARCHIVOS NECESARIOS =====================
create_env_file() {
  log_step "Creando archivo .env..."
  cat > .env <<EOF
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
REDIS_PASSWORD=$REDIS_PASSWORD
API_PORT=$API_PORT
EOF
  log_success ".env creado."
}

create_docker_compose() {
  log_step "Creando docker-compose.yml..."
  cat > docker-compose.yml <<EOF
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7
    command: ["redis-server", "--requirepass", "\${REDIS_PASSWORD}"]
    ports:
      - "6379:6379"

  api:
    image: node:18
    working_dir: /app
    command: bash -c "echo 'Hello Taxi API!' && npx http-server -p \${API_PORT}"
    ports:
      - "\${API_PORT}:\${API_PORT}"
    volumes:
      - ./api:/app

volumes:
  pgdata:
EOF
  log_success "docker-compose.yml creado."
}

create_api_stub() {
  log_step "Creando API de ejemplo..."
  mkdir -p api
  echo "<h1>Taxi API en funcionamiento</h1>" > api/index.html
  log_success "API de ejemplo lista."
}

configure_nginx() {
  log_step "Configurando Nginx como proxy reverso..."
  cat > /etc/nginx/sites-available/taxi <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:$API_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
  ln -sf /etc/nginx/sites-available/taxi /etc/nginx/sites-enabled/taxi
  rm -f /etc/nginx/sites-enabled/default
  nginx -t && systemctl reload nginx
  log_success "Nginx configurado."
}

# ===================== FLUJO PRINCIPAL =====================
main() {
  check_root
  validate_env
  install_docker
  install_docker_compose
  install_nginx
  create_env_file
  create_docker_compose
  create_api_stub
  configure_nginx

  log_step "Levantando servicios con Docker Compose..."
  docker-compose --env-file .env up -d
  log_success "Servicios levantados correctamente."

  log_step "Resumen de servicios:"
  docker-compose ps
  log_success "Instalación completa. Accede a http://localhost para ver la API."
}

main "$@"








