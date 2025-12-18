#!/bin/bash
# ======================================================================
# TAXI SYSTEM - MINIMAL WORKING INSTALLER
# ======================================================================
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TAXI_USER="taxi"
TAXI_PASS="$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9')"
TAXI_HOME="/home/$TAXI_USER"
DOMAIN="${1:-$(hostname)}"

log_step()   { echo -e "${BLUE}[STEP]${NC} $1"; }
log_success(){ echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error()  { echo -e "${RED}[ERROR]${NC} $1"; }
log_info()   { echo -e "${YELLOW}[INFO]${NC} $1"; }

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root (use sudo)"
        exit 1
    fi
}

install_docker() {
    log_step "Installing Docker..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        systemctl enable docker
        systemctl start docker
        log_success "Docker installed"
    else
        log_info "Docker already installed"
    fi
}

install_docker_compose() {
    log_step "Installing Docker Compose..."
    if ! command -v docker-compose &> /dev/null; then
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
            -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        log_success "Docker Compose installed"
    else
        log_info "Docker Compose already installed"
    fi
}

create_taxi_user() {
    log_step "Creating taxi user..."
    if ! id "$TAXI_USER" &>/dev/null; then
        useradd -m -s /bin/bash "$TAXI_USER"
        echo "$TAXI_USER:$TAXI_PASS" | chpasswd
        usermod -aG docker "$TAXI_USER"
        echo "$TAXI_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/taxi
        chmod 440 /etc/sudoers.d/taxi
        log_success "User $TAXI_USER created with password: $TAXI_PASS"
    else
        log_info "User $TAXI_USER already exists"
    fi
}

create_structure() {
    log_step "Creating project structure..."
    mkdir -p "$TAXI_HOME"/{docker,config,data,logs,scripts}
    chown -R "$TAXI_USER":"$TAXI_USER" "$TAXI_HOME"
    log_success "Project structure created"
}

create_docker_compose() {
    log_step "Creating docker-compose.yml..."
    cat > "$TAXI_HOME/docker/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: taxi-postgres
    environment:
      POSTGRES_DB: taxi
      POSTGRES_USER: taxi_admin
      POSTGRES_PASSWORD: ${DB_PASSWORD:-TaxiDB123!}
    volumes:
      - ../data/postgres:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: taxi-redis
    command: redis-server --requirepass ${REDIS_PASSWORD:-RedisPass123!}
    volumes:
      - ../data/redis:/data
    ports:
      - "6379:6379"
    restart: unless-stopped

  mongodb:
    image: mongo:6
    container_name: taxi-mongodb
    environment:
      MONGO_INITDB_ROOT_USERNAME: mongo_admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD:-MongoPass123!}
    volumes:
      - ../data/mongodb:/data/db
    ports:
      - "27017:27017"
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    container_name: taxi-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ../config/nginx:/etc/nginx/conf.d
      - ../logs/nginx:/var/log/nginx
    restart: unless-stopped

  api:
    image: node:18-alpine
    container_name: taxi-api
    working_dir: /app
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://taxi_admin:${DB_PASSWORD:-TaxiDB123!}@postgres:5432/taxi
      REDIS_URL: redis://:${REDIS_PASSWORD:-RedisPass123!}@redis:6379
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
    restart: unless-stopped
    command: sh -c "npm install && npm start"

  admin-panel:
    image: nginx:alpine
    container_name: taxi-admin
    ports:
      - "8080:80"
    volumes:
      - ./admin-panel:/usr/share/nginx/html
    restart: unless-stopped
EOF
    chown "$TAXI_USER":"$TAXI_USER" "$TAXI_HOME/docker/docker-compose.yml"
    log_success "docker-compose.yml created"
}

create_env_file() {
    log_step "Creating environment file..."
    cat > "$TAXI_HOME/.env" << EOF
# Taxi System Environment Variables
DOMAIN=$DOMAIN

# Database
DB_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9!@#$%')
REDIS_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9!@#$%')
MONGO_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9!@#$%')

# API
JWT_SECRET=$(openssl rand -hex 32)
API_PORT=3000

# Nginx
NGINX_HOST=0.0.0.0
EOF
    chown "$TAXI_USER":"$TAXI_USER" "$TAXI_HOME/.env"
    log_success ".env file created with secure passwords"
}

create_nginx_config() {
    log_step "Creating nginx configuration..."
    mkdir -p "$TAXI_HOME/config/nginx"
    cat > "$TAXI_HOME/config/nginx/default.conf" << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://api:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /admin {
        proxy_pass http://admin-panel:80;
        proxy_set_header Host \$host;
    }
}
EOF
    chown -R "$TAXI_USER":"$TAXI_USER" "$TAXI_HOME/config"
    log_success "nginx configuration created"
}

create_admin_panel() {
    log_step "Creating admin panel placeholder..."
    mkdir -p "$TAXI_HOME/docker/admin-panel"
    cat > "$TAXI_HOME/docker/admin-panel/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Taxi Admin Panel</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #333; }
        .status { color: green; font-weight: bold; }
    </style>
</head>
<body>
    <h1>🚕 Taxi System Admin Panel</h1>
    <p>System is running successfully!</p>
    <p class="status">✅ Status: Online</p>
    <p>API: <a href="/">http://$DOMAIN</a></p>
    <p>PostgreSQL: localhost:5432</p>
    <p>Redis: localhost:6379</p>
    <p>MongoDB: localhost:27017</p>
</body>
</html>
EOF
    log_success "Admin panel placeholder created"
}

start_system() {
    log_step "Starting Taxi System..."
    sudo -u "$TAXI_USER" bash << EOF
cd "$TAXI_HOME/docker"
docker-compose down 2>/dev/null || true
docker-compose up -d
EOF
    sleep 10
    log_success "Taxi System started successfully!"
}

show_summary() {
    local ip_address
    ip_address=$(hostname -I | awk '{print $1}')
    echo ""
    echo "${GREEN}=============================================${NC}"
    echo "${GREEN}      TAXI SYSTEM INSTALLATION COMPLETE     ${NC}"
    echo "${GREEN}=============================================${NC}"
    echo ""
    echo "${BLUE}📊 SYSTEM INFORMATION:${NC}"
    echo "  User:          $TAXI_USER"
    echo "  Password:      $TAXI_PASS"
    echo "  Home Directory: $TAXI_HOME"
    echo ""
    echo "${BLUE}🌐 ACCESS URLs:${NC}"
    echo "  Admin Panel:   http://$ip_address:8080"
    echo "  API:           http://$ip_address:3000"
    echo "  PostgreSQL:    $ip_address:5432"
    echo "  Redis:         $ip_address:6379"
    echo "  MongoDB:       $ip_address:27017"
    echo ""
    echo "${BLUE}🔧 MANAGEMENT COMMANDS:${NC}"
    echo "  View logs:     cd $TAXI_HOME/docker && docker-compose logs -f"
    echo "  Stop system:   cd $TAXI_HOME/docker && docker-compose down"
    echo "  Start system:  cd $TAXI_HOME/docker && docker-compose up -d"
    echo "  Restart:       cd $TAXI_HOME/docker && docker-compose restart"
    echo ""
    echo "${YELLOW}⚠ IMPORTANT NOTES:${NC}"
    echo "  1. Change default passwords in: $TAXI_HOME/.env"
    echo "  2. Configure your domain DNS to point to: $ip_address"
    echo "  3. Set up SSL certificates for production"
    echo ""
    echo "${GREEN}✅ Installation completed at: $(date)${NC}"
    echo "${GREEN}=============================================${NC}"
}

main_installation() {
    clear
    echo "${BLUE}=============================================${NC}"
    echo "${BLUE}        TAXI SYSTEM INSTALLER v1.0          ${NC}"
    echo "${BLUE}=============================================${NC}"
    echo ""
    check_root
    install_docker
    install_docker_compose
    create_taxi_user
    create_structure
    create_docker_compose
    create_env_file
    create_nginx_config
    create_admin_panel
    start_system
    show_summary
}

show_help() {
    echo "Usage: $0 [DOMAIN]"
    echo ""
    echo "Options:"
    echo "  DOMAIN    Your domain name (default: server hostname)"
    echo "  --help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                     # Use server hostname"
    echo "  $0 taxi.example.com    # Use custom domain"
    echo "  sudo $0 --help        # Show help"
}

case "${1:-}" in
    "--help"|"-h")
        show_help
        exit 0
        ;;
    *)
        main_installation
        ;;
esac
