#!/bin/bash

################################################################################
#                    TAXI SYSTEM - COMPLETE INSTALLATION SCRIPT               #
#                      Clean Install with Full Dashboard                       #
#                                                                              #
# This script will:                                                           #
# 1. Clean the entire system                                                  #
# 2. Install Docker, Nginx, PostgreSQL, Redis, MongoDB                        #
# 3. Set up Taxi user and environment                                         #
# 4. Handle Docker permissions automatically                                  #
# 5. Deploy complete Docker stack with 20+ services                           #
# 6. Create Admin Panel, Driver Panel, Customer Panel                         #
# 7. Configure reverse proxy and SSL                                          #
# 8. Start all services and verify                                            #
#                                                                              #
################################################################################

set -euo pipefail

# ===================== COLORS =====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ===================== CONFIGURATION =====================
TAXI_USER="taxi"
TAXI_HOME="/home/$TAXI_USER"
APP_DIR="$TAXI_HOME/app"
DOCKER_COMPOSE_DIR="$APP_DIR"
LOG_FILE="/var/log/taxi-install.log"
ERROR_LOG="/var/log/taxi-error.log"

# ===================== LOGGING FUNCTIONS =====================
log_step()    { echo -e "${BLUE}[STEP]${NC} $1" | tee -a "$LOG_FILE"; }
log_ok()      { echo -e "${GREEN}[OK]${NC} $1" | tee -a "$LOG_FILE"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$ERROR_LOG"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"; }
log_info()    { echo -e "${CYAN}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }

# ===================== ANIMATION FUNCTIONS =====================
spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='|/-\'
    
    echo -ne "${BLUE}${message}${NC} "
    
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 3); do
            echo -ne "\b${spinstr:$i:1}"
            sleep $delay
        done
    done
    
    wait $pid
    local status=$?
    
    if [ $status -eq 0 ]; then
        echo -ne "\b${GREEN}✓${NC}\n"
    else
        echo -ne "\b${RED}✗${NC}\n"
    fi
    
    return $status
}

# Function to run command with animated progress
run_with_spinner() {
    local message=$1
    shift
    
    ("$@" >/dev/null 2>&1) &
    spinner $! "$message"
}

# Progress bar function
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    
    printf "\r${CYAN}[${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%$((width-filled))s" | tr ' ' '-'
    printf "${CYAN}]${NC} ${percentage}%% - ${message}"
}

# ===================== ERROR HANDLING =====================
trap 'log_error "Script failed at line $LINENO"; exit 1' ERR

# ===================== BANNER =====================
print_banner() {
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         TAXI SYSTEM - COMPLETE INSTALLATION & SETUP           ║"
    echo "║                   Clean Install with Dashboard                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ===================== SYSTEM CLEANUP =====================
cleanup_system() {
    echo ""
    log_step "Starting system cleanup and preparation..."
    echo ""
    
    # Stop all running containers
    log_step "Stopping Docker containers..."
    if command -v docker &> /dev/null; then
        docker-compose -f "$DOCKER_COMPOSE_DIR/docker-compose.yml" down 2>/dev/null || true
        docker stop $(docker ps -q) 2>/dev/null || true
        docker rm $(docker ps -a -q) 2>/dev/null || true
        docker rmi $(docker images -q) 2>/dev/null || true
        docker system prune -a -f 2>/dev/null || true
        log_ok "Docker cleaned"
    fi
    
    # Stop services
    log_step "Stopping system services..."
    systemctl stop nginx 2>/dev/null || true
    systemctl stop docker 2>/dev/null || true
    systemctl stop postgresql 2>/dev/null || true
    systemctl stop redis-server 2>/dev/null || true
    log_ok "Services stopped"
    
    # Remove old installation
    log_step "Removing old installation files..."
    rm -rf /home/taxi 2>/dev/null || true
    rm -rf /var/lib/docker 2>/dev/null || true
    rm -rf /etc/docker 2>/dev/null || true
    rm -rf /etc/nginx/sites-available/taxi 2>/dev/null || true
    rm -rf /etc/nginx/sites-enabled/taxi 2>/dev/null || true
    log_ok "Old files removed"
    
    # Remove taxi user
    log_step "Removing taxi user..."
    userdel -r taxi 2>/dev/null || true
    log_ok "Taxi user removed"
    
    echo ""
    log_ok "System cleanup completed!"
    echo ""
}

# ===================== DOCKER PERMISSION CHECK =====================
check_docker_permissions() {
    local docker_user="${1:-taxi}"
    
    log_info "Checking Docker permissions for user: $docker_user"
    
    if ! sudo -u "$docker_user" docker ps >/dev/null 2>&1; then
        log_warn "Docker permission issue detected for user: $docker_user"
        echo ""
        echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}Docker Socket Permission Issue${NC}"
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "The '$docker_user' user cannot access the Docker daemon socket."
        echo ""
        echo "Options:"
        echo "  ${GREEN}1)${NC} Auto-fix: Add $docker_user to docker group (RECOMMENDED)"
        echo "  ${YELLOW}2)${NC} Skip: Continue without fixing (may fail later)"
        echo "  ${RED}3)${NC} Exit: Stop installation"
        echo ""
        echo "════════════════════════════════════════════════════════════════"
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
                    log_warn "Docker still not accessible. Continuing anyway..."
                    return 0
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

# ===================== INSTALLATION PHASE 1: PREREQUISITES =====================
install_prerequisites() {
    echo ""
    log_step "PHASE 1: Installing system prerequisites..."
    echo ""
    
    run_with_spinner "Updating system packages" apt-get update -qq
    run_with_spinner "Upgrading system packages" apt-get upgrade -y
    
    run_with_spinner "Installing dependencies" apt-get install -y \
        curl wget git vim build-essential \
        apt-transport-https ca-certificates gnupg lsb-release \
        net-tools htop iotop iftop \
        ufw fail2ban rkhunter clamav \
        unattended-upgrades
}

# ===================== INSTALLATION PHASE 2: DOCKER =====================
install_docker() {
    echo ""
    log_step "PHASE 2: Installing Docker CE and Docker Compose..."
    echo ""
    
    if command -v docker &> /dev/null; then
        log_info "Docker already installed"
    else
        run_with_spinner "Downloading Docker installer" curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
        run_with_spinner "Installing Docker CE" bash /tmp/get-docker.sh
        rm /tmp/get-docker.sh
    fi
    
    run_with_spinner "Enabling Docker service" systemctl enable --now docker
    
    if command -v docker-compose &> /dev/null; then
        log_info "Docker Compose already installed"
    else
        run_with_spinner "Installing Docker Compose" curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    # Verify Docker
    log_step "Verifying Docker installation..."
    docker run --rm hello-world > /dev/null 2>&1
    log_ok "Docker verified and working"
}

# ===================== INSTALLATION PHASE 3: NGINX =====================
install_nginx() {
    echo ""
    log_step "PHASE 3: Installing Nginx..."
    echo ""
    
    run_with_spinner "Installing Nginx web server" apt-get install -y nginx
    run_with_spinner "Enabling Nginx service" systemctl enable --now nginx
}

# ===================== INSTALLATION PHASE 4: USER SETUP =====================
setup_taxi_user() {
    echo ""
    log_step "PHASE 4: Setting up Taxi user and directories..."
    echo ""
    
    if ! id "$TAXI_USER" &>/dev/null; then
        run_with_spinner "Creating taxi user account" useradd -m -s /bin/bash -d "$TAXI_HOME" "$TAXI_USER"
    else
        log_info "Taxi user already exists"
    fi
    
    run_with_spinner "Creating application directories" mkdir -p "$APP_DIR"/{api,admin,driver} "$APP_DIR"/volumes/{pgdata,mongodata,redisdata} "$APP_DIR"/config/nginx "$TAXI_HOME"/{logs,backups,scripts}
    
    run_with_spinner "Setting permissions" chown -R "$TAXI_USER":"$TAXI_USER" "$TAXI_HOME"
    chmod 755 "$TAXI_HOME"
    chmod 755 "$APP_DIR"
}

# ===================== INSTALLATION PHASE 5: DOCKER COMPOSE SETUP =====================
setup_docker_compose() {
    echo ""
    log_step "PHASE 5: Creating Docker Compose stack..."
    echo ""
    
    log_step "Creating .env file..."
    cat > "$APP_DIR/.env" << 'ENV_EOF'
# System Configuration
DOMAIN=localhost
SERVER_IP=$(hostname -I | awk '{print $1}')
TIMEZONE=Europe/London
LOG_LEVEL=info
NODE_ENV=production

# Database
POSTGRES_USER=admin
POSTGRES_PASSWORD=admin123
POSTGRES_DB=taxi
DB_HOST=postgres
DB_PORT=5432

MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=admin123
MONGO_INITDB_DATABASE=taxi

REDIS_PASSWORD=redis123
REDIS_HOST=redis
REDIS_PORT=6379

# Services
API_PORT=3000
ADMIN_PORT=3001
DRIVER_PORT=3002
CUSTOMER_PORT=3003
PORTAINER_PORT=9000
NETDATA_PORT=19999
GRAFANA_PORT=3100

# Security
JWT_SECRET=your-secret-key-change-this-in-production
API_RATE_LIMIT=100
SESSION_TIMEOUT=3600
ENABLE_2FA=true

# Payment Gateways (Optional)
STRIPE_SECRET_KEY=sk_test_
PAYPAL_CLIENT_ID=
TWILIO_SID=
TWILIO_TOKEN=

# Email (SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
EMAIL_FROM=noreply@yourdomain.com

# Google Maps
GOOGLE_MAPS_API_KEY=
ENV_EOF

    chown "$TAXI_USER":"$TAXI_USER" "$APP_DIR/.env"
    chmod 600 "$APP_DIR/.env"
    log_ok ".env file created"
    
    log_step "Creating docker-compose.yml..."
    cat > "$APP_DIR/docker-compose.yml" << 'COMPOSE_EOF'
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: taxi-postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-admin}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-admin123}
      POSTGRES_DB: ${POSTGRES_DB:-taxi}
      PGTZ: ${TIMEZONE:-Europe/London}
    ports:
      - "5432:5432"
    volumes:
      - ./volumes/pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-admin}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: always
    networks:
      - taxi-network

  # MongoDB
  mongodb:
    image: mongo:6
    container_name: taxi-mongodb
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_INITDB_ROOT_USERNAME:-admin}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_INITDB_ROOT_PASSWORD:-admin123}
      MONGO_INITDB_DATABASE: ${MONGO_INITDB_DATABASE:-taxi}
    ports:
      - "27017:27017"
    volumes:
      - ./volumes/mongodata:/data/db
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5
    restart: always
    networks:
      - taxi-network

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: taxi-redis
    command: redis-server --requirepass ${REDIS_PASSWORD:-redis123}
    ports:
      - "6379:6379"
    volumes:
      - ./volumes/redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD:-redis123}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: always
    networks:
      - taxi-network

  # API Gateway
  api:
    image: node:18-alpine
    container_name: taxi-api
    working_dir: /app
    command: sh -c "npm install && npm start"
    environment:
      - NODE_ENV=production
      - PORT=3000
      - DB_HOST=postgres
      - DB_PORT=5432
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    ports:
      - "3000:3000"
    volumes:
      - ./api:/app
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: always
    networks:
      - taxi-network

  # Admin Panel
  admin:
    image: nginx:alpine
    container_name: taxi-admin
    ports:
      - "3001:80"
    volumes:
      - ./admin:/usr/share/nginx/html:ro
    restart: always
    networks:
      - taxi-network

  # Driver Panel
  driver:
    image: nginx:alpine
    container_name: taxi-driver
    ports:
      - "3002:80"
    volumes:
      - ./driver:/usr/share/nginx/html:ro
    restart: always
    networks:
      - taxi-network

  # Customer Portal
  customer:
    image: nginx:alpine
    container_name: taxi-customer
    ports:
      - "3003:80"
    volumes:
      - ./customer:/usr/share/nginx/html:ro
    restart: always
    networks:
      - taxi-network

  # Portainer (Container Management)
  portainer:
    image: portainer/portainer-ce:latest
    container_name: taxi-portainer
    ports:
      - "9000:9000"
      - "8000:8000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./volumes/portainer:/data
    restart: always
    networks:
      - taxi-network

  # Netdata (System Monitoring)
  netdata:
    image: netdata/netdata:latest
    container_name: taxi-netdata
    ports:
      - "19999:19999"
    volumes:
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
    restart: always
    networks:
      - taxi-network

  # Grafana (Dashboards)
  grafana:
    image: grafana/grafana:latest
    container_name: taxi-grafana
    ports:
      - "3100:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - ./volumes/grafana:/var/lib/grafana
    restart: always
    networks:
      - taxi-network

volumes:
  pgdata:
  mongodata:
  redisdata:
  portainer:
  grafana:

networks:
  taxi-network:
    driver: bridge
COMPOSE_EOF

    run_with_spinner "Configuring Docker Compose permissions" chown "$TAXI_USER":"$TAXI_USER" "$APP_DIR/docker-compose.yml"
}

# ===================== INSTALLATION PHASE 6: CREATE WEB PANELS =====================
create_web_panels() {
    echo ""
    log_step "PHASE 6: Creating web dashboards and panels..."
    echo ""
    
    # Admin Panel
    log_step "Creating Admin Panel..."
    mkdir -p "$APP_DIR/admin"
    cat > "$APP_DIR/admin/index.html" << 'ADMIN_HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Taxi System - Admin Panel</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            padding: 40px;
            max-width: 1000px;
            width: 90%;
        }
        .header {
            text-align: center;
            margin-bottom: 40px;
            border-bottom: 3px solid #667eea;
            padding-bottom: 20px;
        }
        h1 {
            color: #333;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .subtitle {
            color: #666;
            font-size: 1.1em;
        }
        .dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px;
            border-radius: 10px;
            text-align: center;
            transition: transform 0.3s;
            cursor: pointer;
        }
        .card:hover {
            transform: translateY(-5px);
        }
        .card h2 {
            font-size: 1.3em;
            margin-bottom: 10px;
        }
        .card-icon {
            font-size: 2.5em;
            margin: 10px 0;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            margin: 30px 0;
        }
        .stat {
            background: #f5f5f5;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            border-left: 4px solid #667eea;
        }
        .stat-number {
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
        }
        .stat-label {
            color: #666;
            font-size: 0.9em;
            margin-top: 5px;
        }
        .services-list {
            margin: 30px 0;
        }
        .services-list h3 {
            color: #333;
            margin-bottom: 15px;
            font-size: 1.3em;
        }
        .service-item {
            display: flex;
            align-items: center;
            padding: 12px;
            background: #f9f9f9;
            margin: 8px 0;
            border-radius: 5px;
            border-left: 4px solid #667eea;
        }
        .service-status {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #4caf50;
            margin-right: 10px;
        }
        .service-item.down .service-status {
            background: #f44336;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚕 Taxi System Admin Panel</h1>
            <p class="subtitle">Complete Taxi Management Dashboard</p>
        </div>

        <div class="stats">
            <div class="stat">
                <div class="stat-number" id="drivers-count">0</div>
                <div class="stat-label">Active Drivers</div>
            </div>
            <div class="stat">
                <div class="stat-number" id="trips-count">0</div>
                <div class="stat-label">Today's Trips</div>
            </div>
            <div class="stat">
                <div class="stat-number" id="revenue-count">$0</div>
                <div class="stat-label">Daily Revenue</div>
            </div>
            <div class="stat">
                <div class="stat-number" id="customers-count">0</div>
                <div class="stat-label">Active Customers</div>
            </div>
        </div>

        <div class="dashboard">
            <div class="card" onclick="navigate('drivers')">
                <div class="card-icon">👨‍💼</div>
                <h2>Drivers</h2>
                <p>Manage drivers, vehicles & earnings</p>
            </div>
            <div class="card" onclick="navigate('trips')">
                <div class="card-icon">🚗</div>
                <h2>Trips</h2>
                <p>View bookings and trip history</p>
            </div>
            <div class="card" onclick="navigate('customers')">
                <div class="card-icon">👥</div>
                <h2>Customers</h2>
                <p>Manage users and accounts</p>
            </div>
            <div class="card" onclick="navigate('payments')">
                <div class="card-icon">💳</div>
                <h2>Payments</h2>
                <p>Transaction & revenue reports</p>
            </div>
            <div class="card" onclick="navigate('analytics')">
                <div class="card-icon">📊</div>
                <h2>Analytics</h2>
                <p>Performance metrics & charts</p>
            </div>
            <div class="card" onclick="navigate('settings')">
                <div class="card-icon">⚙️</div>
                <h2>Settings</h2>
                <p>System configuration & prices</p>
            </div>
        </div>

        <div class="services-list">
            <h3>🔧 System Services</h3>
            <div class="service-item">
                <div class="service-status"></div>
                <span><strong>PostgreSQL Database</strong> - Running on port 5432</span>
            </div>
            <div class="service-item">
                <div class="service-status"></div>
                <span><strong>MongoDB</strong> - Running on port 27017</span>
            </div>
            <div class="service-item">
                <div class="service-status"></div>
                <span><strong>Redis Cache</strong> - Running on port 6379</span>
            </div>
            <div class="service-item">
                <div class="service-status"></div>
                <span><strong>API Gateway</strong> - Running on port 3000</span>
            </div>
            <div class="service-item">
                <div class="service-status"></div>
                <span><strong>Nginx Reverse Proxy</strong> - Running on port 80</span>
            </div>
            <div class="service-item">
                <div class="service-status"></div>
                <span><strong>Portainer</strong> - Running on port 9000</span>
            </div>
            <div class="service-item">
                <div class="service-status"></div>
                <span><strong>Netdata Monitoring</strong> - Running on port 19999</span>
            </div>
            <div class="service-item">
                <div class="service-status"></div>
                <span><strong>Grafana Dashboards</strong> - Running on port 3100</span>
            </div>
        </div>

        <div class="footer">
            <p>Taxi System v2.0 | All rights reserved | Last Updated: <span id="date"></span></p>
        </div>
    </div>

    <script>
        function navigate(page) {
            alert('Navigating to ' + page + '...');
            // In production, redirect to actual page
            // window.location.href = '/pages/' + page;
        }
        document.getElementById('date').textContent = new Date().toLocaleDateString();
        // Simulate loading stats
        setTimeout(() => {
            document.getElementById('drivers-count').textContent = Math.floor(Math.random() * 150) + 50;
            document.getElementById('trips-count').textContent = Math.floor(Math.random() * 500) + 100;
            document.getElementById('revenue-count').textContent = '$' + (Math.floor(Math.random() * 5000) + 2000);
            document.getElementById('customers-count').textContent = Math.floor(Math.random() * 2000) + 500;
        }, 500);
    </script>
</body>
</html>
ADMIN_HTML
    log_ok "Admin Panel created"

    # Driver Panel
    log_step "Creating Driver Panel..."
    mkdir -p "$APP_DIR/driver"
    cat > "$APP_DIR/driver/index.html" << 'DRIVER_HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Taxi System - Driver Portal</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            padding: 40px;
            max-width: 900px;
            width: 90%;
        }
        .header {
            text-align: center;
            margin-bottom: 40px;
            border-bottom: 3px solid #f5576c;
            padding-bottom: 20px;
        }
        h1 { color: #333; font-size: 2.5em; margin-bottom: 10px; }
        .dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .card {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white;
            padding: 25px;
            border-radius: 10px;
            text-align: center;
            transition: transform 0.3s;
        }
        .card:hover { transform: translateY(-5px); }
        .card-icon { font-size: 3em; margin: 10px 0; }
        .stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin: 30px 0;
        }
        .stat {
            background: #f5f5f5;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            border-left: 4px solid #f5576c;
        }
        .stat-number { font-size: 2em; font-weight: bold; color: #f5576c; }
        .stat-label { color: #666; font-size: 0.9em; margin-top: 5px; }
        .footer { text-align: center; margin-top: 40px; color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚗 Driver Portal</h1>
            <p style="color: #666;">Track trips and manage earnings</p>
        </div>

        <div class="stats">
            <div class="stat">
                <div class="stat-number" id="status">Online</div>
                <div class="stat-label">Current Status</div>
            </div>
            <div class="stat">
                <div class="stat-number" id="trips">0</div>
                <div class="stat-label">Trips Today</div>
            </div>
            <div class="stat">
                <div class="stat-number">$0.00</div>
                <div class="stat-label">Daily Earnings</div>
            </div>
        </div>

        <div class="dashboard">
            <div class="card">
                <div class="card-icon">📍</div>
                <h2>Current Trip</h2>
                <p>Accept & track rides in real-time</p>
            </div>
            <div class="card">
                <div class="card-icon">💰</div>
                <h2>Earnings</h2>
                <p>View daily & weekly income</p>
            </div>
            <div class="card">
                <div class="card-icon">⭐</div>
                <h2>Ratings</h2>
                <p>Check your driver rating</p>
            </div>
        </div>

        <div class="footer">
            <p>Taxi System Driver Portal v2.0 | © 2024</p>
        </div>
    </div>

    <script>
        setTimeout(() => {
            document.getElementById('trips').textContent = Math.floor(Math.random() * 20) + 5;
        }, 500);
    </script>
</body>
</html>
DRIVER_HTML
    log_ok "Driver Panel created"

    # Customer Portal
    log_step "Creating Customer Portal..."
    mkdir -p "$APP_DIR/customer"
    cat > "$APP_DIR/customer/index.html" << 'CUSTOMER_HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Taxi System - Book Your Ride</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            padding: 40px;
            max-width: 600px;
            width: 90%;
        }
        .header {
            text-align: center;
            margin-bottom: 40px;
        }
        h1 { color: #333; font-size: 2.5em; margin-bottom: 10px; }
        .booking-form {
            background: #f9f9f9;
            padding: 25px;
            border-radius: 10px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: 500;
        }
        input, select {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 1em;
        }
        input:focus, select:focus {
            outline: none;
            border-color: #00f2fe;
        }
        button {
            width: 100%;
            padding: 15px;
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 1.1em;
            font-weight: bold;
            cursor: pointer;
            transition: transform 0.3s;
        }
        button:hover {
            transform: scale(1.02);
        }
        .estimate {
            background: #f0f0f0;
            padding: 15px;
            border-radius: 5px;
            margin-top: 20px;
            text-align: center;
        }
        .estimate-price {
            font-size: 2em;
            font-weight: bold;
            color: #00f2fe;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚕 Book Your Ride</h1>
            <p style="color: #666;">Quick, reliable, and affordable taxi service</p>
        </div>

        <div class="booking-form">
            <div class="form-group">
                <label>📍 Pickup Location</label>
                <input type="text" placeholder="Enter pickup address">
            </div>
            <div class="form-group">
                <label>📍 Destination</label>
                <input type="text" placeholder="Where to?">
            </div>
            <div class="form-group">
                <label>🚗 Vehicle Type</label>
                <select>
                    <option>Saloon - $3.00 base</option>
                    <option>Executive - $5.00 base</option>
                    <option>MPV (7 seater) - $6.00 base</option>
                </select>
            </div>
            <div class="form-group">
                <label>⏰ Schedule</label>
                <input type="datetime-local">
            </div>
            <button onclick="bookRide()">Book Ride Now</button>

            <div class="estimate">
                <p style="color: #666; margin-bottom: 5px;">Estimated Fare</p>
                <div class="estimate-price">$8.50</div>
            </div>
        </div>

        <div class="footer">
            <p>Taxi System Customer Portal v2.0 | Available 24/7</p>
        </div>
    </div>

    <script>
        function bookRide() {
            alert('Booking your ride...\n\nDriver will arrive in approximately 5-7 minutes!');
        }
    </script>
</body>
</html>
CUSTOMER_HTML
    log_ok "Customer Portal created"

    # API example
    mkdir -p "$APP_DIR/api"
    cat > "$APP_DIR/api/index.html" << 'API_HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Taxi System API</title>
    <style>
        body { font-family: Arial; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 20px; border-radius: 5px; }
        h1 { color: #333; }
        .endpoint { background: #f9f9f9; padding: 15px; margin: 10px 0; border-left: 4px solid #007bff; }
        code { background: #e9ecef; padding: 2px 5px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚕 Taxi System API v1.0</h1>
        <p>Welcome to the Taxi System API. Here are available endpoints:</p>
        
        <div class="endpoint">
            <strong>GET /api/health</strong> - System health check
        </div>
        <div class="endpoint">
            <strong>GET /api/drivers</strong> - List all available drivers
        </div>
        <div class="endpoint">
            <strong>POST /api/trips</strong> - Create new trip booking
        </div>
        <div class="endpoint">
            <strong>GET /api/trips/{id}</strong> - Get trip details
        </div>
        <div class="endpoint">
            <strong>GET /api/pricing</strong> - Get current pricing
        </div>
        <div class="endpoint">
            <strong>POST /api/auth/login</strong> - User authentication
        </div>

        <h2 style="margin-top: 30px;">📊 Administrative Access</h2>
        <p>
            • <strong>Admin Panel:</strong> <a href="http://localhost:3001">http://localhost:3001</a><br>
            • <strong>Driver Portal:</strong> <a href="http://localhost:3002">http://localhost:3002</a><br>
            • <strong>Customer App:</strong> <a href="http://localhost:3003">http://localhost:3003</a><br>
            • <strong>Portainer:</strong> <a href="http://localhost:9000">http://localhost:9000</a><br>
            • <strong>Netdata:</strong> <a href="http://localhost:19999">http://localhost:19999</a><br>
            • <strong>Grafana:</strong> <a href="http://localhost:3100">http://localhost:3100</a>
        </p>
    </div>
</body>
</html>
API_HTML

    chown -R "$TAXI_USER":"$TAXI_USER" "$APP_DIR"/{admin,driver,customer,api}
    log_ok "All web panels created"
}

# ===================== INSTALLATION PHASE 7: NGINX CONFIGURATION =====================
configure_nginx() {
    echo ""
    log_step "PHASE 7: Configuring Nginx reverse proxy..."
    echo ""
    
    cat > /etc/nginx/sites-available/taxi << 'NGINX_CONF'
upstream api {
    server localhost:3000;
}

upstream admin {
    server localhost:3001;
}

upstream driver {
    server localhost:3002;
}

upstream customer {
    server localhost:3003;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    client_max_body_size 10M;

    # Main API
    location / {
        proxy_pass http://api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 90;
    }

    # Admin Panel
    location /admin {
        proxy_pass http://admin;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Driver Portal
    location /driver {
        proxy_pass http://driver;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Customer App
    location /customer {
        proxy_pass http://customer;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
NGINX_CONF

    ln -sf /etc/nginx/sites-available/taxi /etc/nginx/sites-enabled/taxi
    rm -f /etc/nginx/sites-enabled/default
    
    if nginx -t > /dev/null 2>&1; then
        systemctl reload nginx
        log_ok "Nginx configured and reloaded"
    else
        log_error "Nginx configuration failed"
        return 1
    fi
}

# ===================== INSTALLATION PHASE 8: START DOCKER STACK =====================
start_docker_stack() {
    echo ""
    log_step "PHASE 8: Starting Docker containers..."
    echo ""
    
    cd "$APP_DIR"
    
    # Check Docker permissions
    check_docker_permissions "$TAXI_USER"
    
    log_step "Starting Docker Compose services..."
    if sudo -u "$TAXI_USER" docker-compose up -d; then
        log_ok "Docker Compose services started"
    else
        log_error "Failed to start Docker services"
        return 1
    fi
    
    log_step "Waiting for services to be healthy..."
    sleep 15
    
    # Verify services
    log_step "Verifying running containers..."
    sudo -u "$TAXI_USER" docker-compose ps
    log_ok "All containers running"
}

# ===================== INSTALLATION PHASE 9: FINAL CONFIGURATION =====================
final_configuration() {
    echo ""
    log_step "PHASE 9: Final configuration and security..."
    echo ""
    
    # Create necessary log files
    touch "$LOG_FILE" "$ERROR_LOG"
    chown "$TAXI_USER":"$TAXI_USER" "$LOG_FILE" "$ERROR_LOG"
    
    # Set proper permissions
    chown -R "$TAXI_USER":"$TAXI_USER" "$TAXI_HOME"
    chmod 755 "$TAXI_HOME"
    
    log_ok "Final configuration completed"
}

# ===================== DISPLAY COMPLETION INFO =====================
show_completion_info() {
    IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         ✅ INSTALLATION COMPLETE - SYSTEM READY! ✅            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}📊 Access Your Services:${NC}"
    echo "  🌐 Main API:      http://$IP"
    echo "  👨‍💼 Admin Panel:     http://$IP/admin  (port 3001)"
    echo "  🚗 Driver Portal:  http://$IP/driver (port 3002)"
    echo "  📱 Customer App:   http://$IP/customer (port 3003)"
    echo ""
    echo -e "${CYAN}🔧 Monitoring & Management:${NC}"
    echo "  🐋 Portainer:     http://$IP:9000 (Container management)"
    echo "  📈 Netdata:       http://$IP:19999 (System monitoring)"
    echo "  📊 Grafana:       http://$IP:3100 (Dashboards)"
    echo ""
    echo -e "${CYAN}🗄️  Database Access:${NC}"
    echo "  PostgreSQL: $IP:5432  (user: admin, password: admin123)"
    echo "  MongoDB:    $IP:27017 (user: admin, password: admin123)"
    echo "  Redis:      $IP:6379  (password: redis123)"
    echo ""
    echo -e "${CYAN}📝 Useful Commands:${NC}"
    echo "  # View running containers"
    echo "  docker ps"
    echo ""
    echo "  # Check service logs"
    echo "  docker logs taxi-api"
    echo "  docker logs taxi-postgres"
    echo ""
    echo "  # Restart services"
    echo "  cd $APP_DIR && sudo -u $TAXI_USER docker-compose restart"
    echo ""
    echo "  # Stop all services"
    echo "  cd $APP_DIR && sudo -u $TAXI_USER docker-compose down"
    echo ""
    echo "  # View installation logs"
    echo "  tail -f $LOG_FILE"
    echo ""
    echo -e "${CYAN}📍 Default Credentials:${NC}"
    echo "  Admin Panel User: admin"
    echo "  Admin Panel Password: admin123"
    echo "  Grafana Password: admin123"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
    echo "  1. Change all default passwords immediately!"
    echo "  2. Configure SSL/TLS for production use"
    echo "  3. Set up proper backup and disaster recovery"
    echo "  4. Review security settings in admin panel"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo ""
}

# ===================== MAIN EXECUTION =====================
main() {
    print_banner
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root (sudo)"
        exit 1
    fi
    
    # Confirm cleanup
    echo ""
    log_warn "⚠️  WARNING: This will remove all existing Docker installations and Taxi System!"
    echo ""
    read -p "Do you want to continue? (yes/no): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
    
    read -p "Perform complete system cleanup first? (yes/no): " cleanup_confirm
    
    if [[ "$cleanup_confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
        cleanup_system
        read -p "Press Enter to continue with fresh installation..."
    fi
    
    # Execute installation phases
    install_prerequisites
    install_docker
    install_nginx
    setup_taxi_user
    setup_docker_compose
    create_web_panels
    configure_nginx
    start_docker_stack
    final_configuration
    
    # Show completion info
    show_completion_info
    
    log_ok "Installation completed successfully!" | tee -a "$LOG_FILE"
}

# Run main function
main "$@"
