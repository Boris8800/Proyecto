#!/bin/bash

# ===================== COLORS =====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# ===================== LOGGING FUNCTIONS =====================
log_step()    { echo -e "${BLUE}[STEP]${NC} $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_info()    { echo -e "${CYAN}[INFO]${NC} $1"; }

# ===================== ERROR HANDLING =====================
set -euo pipefail
trap 'log_error "Script failed at line $LINENO"; exit 1' ERR

# ===================== BANNER =====================
print_banner() {
    echo -e "${PURPLE}"
    echo "════════════════════════════════════════════════════════════════"
    echo "   TAXI SYSTEM - CLEAN INSTALL & SETUP"
    echo "════════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# ===================== CLEAN UP FUNCTION =====================
cleanup_system() {
    echo ""
    log_step "Starting system cleanup..."
    echo ""
    
    # Stop all running containers
    log_step "Stopping Docker containers..."
    docker-compose -f /home/taxi/app/docker-compose.yml down 2>/dev/null || true
    docker stop $(docker ps -q) 2>/dev/null || true
    log_ok "Containers stopped"
    
    # Remove containers
    log_step "Removing Docker containers..."
    docker rm $(docker ps -a -q) 2>/dev/null || true
    log_ok "Containers removed"
    
    # Remove images
    log_step "Removing Docker images..."
    docker rmi $(docker images -q) 2>/dev/null || true
    log_ok "Images removed"
    
    # Clean Docker system
    log_step "Cleaning Docker system..."
    docker system prune -a -f 2>/dev/null || true
    log_ok "Docker system cleaned"
    
    # Stop services
    log_step "Stopping system services..."
    systemctl stop nginx 2>/dev/null || true
    systemctl stop docker 2>/dev/null || true
    systemctl stop postgresql 2>/dev/null || true
    systemctl stop redis-server 2>/dev/null || true
    log_ok "Services stopped"
    
    # Remove installed packages
    log_step "Removing installed packages..."
    apt-get remove -y docker docker.io docker-compose 2>/dev/null || true
    apt-get remove -y nginx 2>/dev/null || true
    apt-get remove -y postgresql postgresql-contrib 2>/dev/null || true
    apt-get remove -y redis-server 2>/dev/null || true
    log_ok "Packages removed"
    
    # Clean package cache
    log_step "Cleaning package cache..."
    apt-get autoremove -y 2>/dev/null || true
    apt-get clean 2>/dev/null || true
    log_ok "Cache cleaned"
    
    # Remove taxi user and home directory
    log_step "Cleaning taxi user and directories..."
    userdel -r taxi 2>/dev/null || true
    rm -rf /home/taxi 2>/dev/null || true
    rm -rf /var/lib/docker 2>/dev/null || true
    rm -rf /etc/docker 2>/dev/null || true
    log_ok "User and directories cleaned"
    
    # Clean nginx config
    log_step "Cleaning nginx configuration..."
    rm -rf /etc/nginx/sites-available/taxi 2>/dev/null || true
    rm -rf /etc/nginx/sites-enabled/taxi 2>/dev/null || true
    log_ok "Nginx configuration cleaned"
    
    echo ""
    log_ok "System cleanup completed!"
    echo ""
}

# ===================== DOCKER PERMISSION CHECK =====================
check_docker_permissions() {
    local docker_user="${1:-taxi}"
    
    log_info "Checking Docker permissions for user: $docker_user"
    
    # Test if the user can access docker daemon
    if ! sudo -u "$docker_user" docker ps >/dev/null 2>&1; then
        log_warn "Docker permission issue detected for user: $docker_user"
        echo ""
        echo -e "${YELLOW}Docker Socket Permission Issue${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "The '$docker_user' user cannot access the Docker daemon socket."
        echo ""
        echo "Options:"
        echo "  ${GREEN}1)${NC} Auto-fix: Add $docker_user to docker group (RECOMMENDED)"
        echo "  ${YELLOW}2)${NC} Skip: Continue without fixing (may fail later)"
        echo "  ${RED}3)${NC} Exit: Stop installation"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        read -p "Choose option (1/2/3): " docker_option
        
        case "$docker_option" in
            1)
                log_step "Adding $docker_user to docker group..."
                if ! getent group docker >/dev/null; then
                    sudo groupadd docker
                fi
                sudo usermod -aG docker "$docker_user"
                log_ok "User $docker_user added to docker group"
                
                log_step "Verifying Docker access..."
                sleep 2
                if sudo -u "$docker_user" docker ps >/dev/null 2>&1; then
                    log_ok "Docker access verified for $docker_user"
                    return 0
                else
                    log_warn "Docker still not accessible. You may need to log out and back in."
                    log_info "Using 'newgrp docker' to activate group..."
                    if newgrp docker <<< "sudo -u $docker_user docker ps" >/dev/null 2>&1; then
                        log_ok "Docker access verified with newgrp"
                        return 0
                    fi
                    
                    read -p "Continue anyway? (y/n): " continue_opt
                    if [[ "$continue_opt" =~ ^[Yy]$ ]]; then
                        log_warn "Continuing despite permission issues..."
                        return 0
                    else
                        log_error "Installation cancelled"
                        exit 1
                    fi
                fi
                ;;
            2)
                log_warn "Skipping Docker permission fix"
                return 0
                ;;
            3)
                log_error "Installation cancelled by user"
                exit 0
                ;;
            *)
                log_error "Invalid option"
                exit 1
                ;;
        esac
    else
        log_ok "Docker permissions OK for user: $docker_user"
        return 0
    fi
}

# ===================== DOCKER-COMPOSE WRAPPER =====================
run_docker_compose() {
    local docker_user="${1:-taxi}"
    local compose_dir="${2:-.}"
    local compose_args="${@:3}"
    
    log_step "Starting Docker services..."
    
    # Check permissions before running
    check_docker_permissions "$docker_user"
    
    # Run docker-compose with error handling
    if cd "$compose_dir" && sudo -u "$docker_user" docker-compose $compose_args; then
        log_ok "Docker Compose executed successfully"
        return 0
    else
        local exit_code=$?
        log_error "Docker Compose failed with exit code: $exit_code"
        
        if [[ "$exit_code" == 126 ]] || [[ "$exit_code" == 127 ]]; then
            log_warn "Permission error detected. Retrying with permission check..."
            check_docker_permissions "$docker_user"
            
            if cd "$compose_dir" && sudo -u "$docker_user" docker-compose $compose_args; then
                log_ok "Docker Compose succeeded on retry"
                return 0
            fi
        fi
        
        log_error "Docker Compose failed. Check logs at /var/log/install-taxi.log"
        return 1
    fi
}

# ===================== INSTALLATION FUNCTION =====================
install_system() {
    echo ""
    log_step "Starting fresh Taxi System installation..."
    echo ""
    
    # Update package lists
    log_step "Updating system packages..."
    apt-get update -qq
    log_ok "System updated"
    
    # Install required packages
    log_step "Installing Docker and dependencies..."
    apt-get install -y \
        curl \
        git \
        wget \
        vim \
        build-essential \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release > /dev/null 2>&1
    log_ok "Dependencies installed"
    
    # Install Docker
    log_step "Installing Docker CE..."
    if command -v docker &> /dev/null; then
        log_info "Docker already installed, skipping..."
    else
        curl -fsSL https://get.docker.com -o get-docker.sh
        bash get-docker.sh > /dev/null 2>&1
        rm get-docker.sh
    fi
    systemctl enable --now docker
    log_ok "Docker installed and enabled"
    
    # Install Docker Compose
    log_step "Installing Docker Compose..."
    if command -v docker-compose &> /dev/null; then
        log_info "Docker Compose already installed, skipping..."
    else
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    log_ok "Docker Compose installed"
    
    # Install Nginx
    log_step "Installing Nginx..."
    apt-get install -y nginx > /dev/null 2>&1
    systemctl enable --now nginx
    log_ok "Nginx installed and enabled"
    
    # Create taxi user
    log_step "Creating taxi user..."
    if ! id taxi &>/dev/null; then
        useradd -m -s /bin/bash -d /home/taxi taxi
        log_ok "Taxi user created"
    else
        log_info "Taxi user already exists"
    fi
    
    # Create app directory
    log_step "Creating application directory..."
    mkdir -p /home/taxi/app
    chown -R taxi:taxi /home/taxi
    log_ok "Application directory created"
    
    # Check Docker permissions
    log_step "Checking Docker permissions..."
    check_docker_permissions "taxi"
    
    # Create docker-compose.yml
    log_step "Creating docker-compose configuration..."
    cat > /home/taxi/app/docker-compose.yml << 'DOCKER_COMPOSE_EOF'
version: '3.8'
services:
  postgres15:
    image: postgres:15
    container_name: postgres15
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: admin123
      POSTGRES_DB: taxi
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U admin"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis7:
    image: redis:7
    container_name: redis7
    ports:
      - "6379:6379"
    restart: always
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  api:
    image: node:18
    container_name: taxi-api
    working_dir: /app
    command: bash -c 'npx http-server -p 3000'
    ports:
      - "3000:3000"
    volumes:
      - ./api:/app
    restart: always
    depends_on:
      - postgres15
      - redis7

  admin:
    image: nginx:alpine
    container_name: taxi-admin
    ports:
      - "8080:80"
    volumes:
      - ./admin:/usr/share/nginx/html:ro
    restart: always
    depends_on:
      - api

volumes:
  pgdata:
DOCKER_COMPOSE_EOF
    chown taxi:taxi /home/taxi/app/docker-compose.yml
    log_ok "Docker Compose configuration created"
    
    # Create .env file
    log_step "Creating environment configuration..."
    cat > /home/taxi/app/.env << 'ENV_EOF'
POSTGRES_USER=admin
POSTGRES_PASSWORD=admin123
POSTGRES_DB=taxi
REDIS_HOST=redis7
REDIS_PORT=6379
API_PORT=3000
NODE_ENV=production
ENV_EOF
    chown taxi:taxi /home/taxi/app/.env
    chmod 600 /home/taxi/app/.env
    log_ok "Environment configuration created"
    
    # Create example API and Admin directories
    log_step "Creating example API and Admin panels..."
    mkdir -p /home/taxi/app/api /home/taxi/app/admin
    echo '<h1 style="text-align:center; margin-top:50px;">🚕 Taxi API - Running ✅</h1>' > /home/taxi/app/api/index.html
    echo '<h1 style="text-align:center; margin-top:50px;">📊 Taxi Admin Panel - Ready</h1>' > /home/taxi/app/admin/index.html
    chown -R taxi:taxi /home/taxi/app
    log_ok "Example files created"
    
    # Start Docker services
    log_step "Starting Docker services..."
    cd /home/taxi/app
    run_docker_compose "taxi" "/home/taxi/app" "--env-file .env up -d"
    log_ok "Docker services started"
    
    # Wait for services to be healthy
    log_step "Waiting for services to become healthy..."
    sleep 10
    
    # Verify services
    log_step "Verifying Docker services..."
    if docker ps | grep -q postgres15; then
        log_ok "PostgreSQL container is running"
    else
        log_error "PostgreSQL container failed to start"
    fi
    
    if docker ps | grep -q redis7; then
        log_ok "Redis container is running"
    else
        log_error "Redis container failed to start"
    fi
    
    if docker ps | grep -q taxi-api; then
        log_ok "API container is running"
    else
        log_error "API container failed to start"
    fi
    
    if docker ps | grep -q taxi-admin; then
        log_ok "Admin container is running"
    else
        log_error "Admin container failed to start"
    fi
    
    # Configure Nginx
    log_step "Configuring Nginx reverse proxy..."
    cat > /etc/nginx/sites-available/taxi << 'NGINX_EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /admin {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
    }
}
NGINX_EOF
    
    ln -sf /etc/nginx/sites-available/taxi /etc/nginx/sites-enabled/taxi
    rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    if nginx -t > /dev/null 2>&1; then
        systemctl reload nginx
        log_ok "Nginx configured and reloaded"
    else
        log_error "Nginx configuration failed"
    fi
    
    # Get server IP
    IP=$(hostname -I | awk '{print $1}')
    
    # Installation complete
    echo ""
    echo -e "${GREEN}"
    echo "════════════════════════════════════════════════════════════════"
    echo "   ✅ INSTALLATION COMPLETE!"
    echo "════════════════════════════════════════════════════════════════"
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}📊 Access Your Services:${NC}"
    echo "  🌐 Main API:      http://$IP:3000"
    echo "  📱 Admin Panel:   http://$IP:8080"
    echo "  🔗 Via Nginx:     http://$IP/"
    echo ""
    echo -e "${CYAN}🗄️  Database Access:${NC}"
    echo "  Host:     localhost"
    echo "  Port:     5432"
    echo "  User:     admin"
    echo "  Password: admin123"
    echo "  Database: taxi"
    echo ""
    echo -e "${CYAN}⚡ Cache Access:${NC}"
    echo "  Host:     localhost"
    echo "  Port:     6379"
    echo ""
    echo -e "${CYAN}📝 Useful Commands:${NC}"
    echo "  View containers:       docker ps"
    echo "  View logs:             docker logs <container_name>"
    echo "  Restart services:      cd /home/taxi/app && sudo -u taxi docker-compose restart"
    echo "  Stop services:         cd /home/taxi/app && sudo -u taxi docker-compose down"
    echo "  View system logs:      tail -f /var/log/install-taxi.log"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo ""
}

# ===================== MAIN FLOW =====================
main() {
    print_banner
    
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: This script will REMOVE all Docker containers, images,${NC}"
    echo -e "${YELLOW}    and Taxi System installation!${NC}"
    echo ""
    read -p "Do you want to continue? (yes/no): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
    
    echo ""
    read -p "Perform complete system cleanup? (yes/no): " cleanup_confirm
    
    if [[ "$cleanup_confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
        cleanup_system
        read -p "Press Enter to continue with fresh installation..." 
    fi
    
    install_system
}

# Run main function
main
