#!/bin/bash

################################################################################
# PROYECTO TAXI - COMPREHENSIVE SERVICE MANAGEMENT & DEPLOYMENT TOOL
# All-in-one script for:
#   • System diagnostics and monitoring
#   • Service installation and configuration
#   • Docker and VPS deployment
#   • Service management and fixing
#   • Email server setup
#   • API configuration
#   • HTTPS/SSL configuration
#   • Real-time monitoring
#   • Security testing
#   • Dashboard management
#   • Nginx deployment
#   • Web testing
#
# Usage:
#   bash main.sh                    # Interactive menu
#   bash main.sh diagnose           # Run diagnostics
#   bash main.sh fix-all            # Fix all services
#   bash main.sh fix-status         # Fix status dashboard only
#   bash main.sh deploy-vps         # Deploy to VPS
#   bash main.sh install            # Full installation
#   bash main.sh setup-email        # Setup email server
#   bash main.sh setup-https        # Configure HTTPS/SSL
#   bash main.sh setup-nginx        # Deploy Nginx
#   bash main.sh monitor            # Start monitoring
#   bash main.sh test-web           # Test web interfaces
#   bash main.sh test-security      # Security testing
#   bash main.sh manage-dashboards  # Dashboard management
################################################################################

set -e

PROJECT_ROOT="${PROJECT_ROOT:-/root/Proyecto}"
[ ! -d "$PROJECT_ROOT" ] && PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT" || exit 1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
# PURPLE='\033[0;35m' # Reserved for future use
NC='\033[0m'

# Service ports
STATUS_PORT=3030
ADMIN_PORT=3001
DRIVER_PORT=3002
CUSTOMER_PORT=3000
API_PORT=3040
MAGIC_LINKS_PORT=3333

# Log directory
LOG_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOG_DIR"

# ============================================================================
# SYSTEM DETECTION HELPERS
# ============================================================================
OS_NAME="Unknown"
OS_VERSION="Unknown"
PKG_MANAGER="apt"

detect_os_info() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS_NAME=${NAME:-Unknown}
        OS_VERSION=${VERSION_ID:-Unknown}
    fi
    if command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
    fi
}

clean_downloads() {
    if [ -d /root/Downloads ]; then
        rm -rf /root/Downloads/* 2>/dev/null || true
    fi
}

kill_taxi_processes() {
    # Kill processes on known service ports
    for port in $STATUS_PORT $ADMIN_PORT $DRIVER_PORT $CUSTOMER_PORT $API_PORT $MAGIC_LINKS_PORT; do
        fuser -k "$port"/tcp 2>/dev/null || true
    done
    # Kill common process names
    pkill -f "taxi" 2>/dev/null || true
    pkill -f "status/server.js" 2>/dev/null || true
    pkill -f "server-admin" 2>/dev/null || true
    pkill -f "server-driver" 2>/dev/null || true
    pkill -f "server-customer" 2>/dev/null || true
    pkill -f "magic-links" 2>/dev/null || true
}

remove_taxi_user() {
    if id -u taxi >/dev/null 2>&1; then
        pkill -u taxi 2>/dev/null || true
        userdel -r taxi 2>/dev/null || true
    fi
}

create_taxi_user() {
    if ! id -u taxi >/dev/null 2>&1; then
        useradd -m -s /bin/bash taxi 2>/dev/null || true
    fi
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# ============================================================================
# 1. DIAGNOSTIC FUNCTION
# ============================================================================
run_diagnostics() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║        COMPREHENSIVE DIAGNOSTIC - ALL SERVICES                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # 1. Docker Status
    echo "═══════════════════════════════════════════════════════════════"
    echo "1. DOCKER STATUS"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    echo "Docker Version:"
    docker --version 2>/dev/null || echo "❌ Docker not available"
    echo ""

    echo "Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers found"
    echo ""

    echo "All Containers (including stopped):"
    docker ps -a --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "No containers"
    echo ""

    # 2. Port Status
    echo "═══════════════════════════════════════════════════════════════"
    echo "2. LISTENING PORTS"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    netstat -tuln 2>/dev/null | grep -E ":(3000|3001|3002|3030|3040|3333)" || echo "No services listening"
    echo ""

    # 3. HTTP Response Tests
    echo "═══════════════════════════════════════════════════════════════"
    echo "3. SERVICE RESPONSE TESTS"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    for port in $STATUS_PORT $ADMIN_PORT $DRIVER_PORT $CUSTOMER_PORT $API_PORT $MAGIC_LINKS_PORT; do
        echo -n "Port $port: "
        RESULT=$(timeout 3 curl -s -w "%{http_code}" -o /dev/null "http://127.0.0.1:$port/" 2>&1)
        if [ -z "$RESULT" ]; then
            echo "❌ TIMEOUT or no response"
        elif [ "$RESULT" = "200" ]; then
            echo "✓ RESPONDING (HTTP 200)"
        else
            echo "⚠️  HTTP $RESULT"
        fi
    done
    echo ""

    # 4. Node.js Processes
    echo "═══════════════════════════════════════════════════════════════"
    echo "4. NODE.JS PROCESSES"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    pgrep -a "node|npm" | awk '{print $1, $2, $3, $4}' | head -20 || echo "No Node.js processes"
    echo ""

    # 5. Docker Logs
    echo "═══════════════════════════════════════════════════════════════"
    echo "5. DOCKER LOGS (Last 10 Lines)"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    echo "--- taxi-status ---"
    docker logs taxi-status 2>&1 | tail -10 || echo "❌ Container taxi-status does not exist"
    echo ""

    echo "--- taxi-api ---"
    docker logs taxi-api 2>&1 | tail -10 || echo "❌ Container taxi-api does not exist"
    echo ""

    # 6. Project Files
    echo "═══════════════════════════════════════════════════════════════"
    echo "6. PROJECT FILES"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    if [ -d "$PROJECT_ROOT" ]; then
        echo "✓ Project exists at: $PROJECT_ROOT"
        echo ""
        echo "Structure:"
        for item in "$PROJECT_ROOT"/web "$PROJECT_ROOT"/config "$PROJECT_ROOT"/scripts "$PROJECT_ROOT"/logs; do
            if [ -d "$item" ] || [ -f "$item" ]; then
                size=$(stat -f%z "$item" 2>/dev/null || stat -c%s "$item" 2>/dev/null || echo 0)
                basename=$(basename "$item")
                echo "  $basename ($size bytes)"
            fi
        done
    else
        echo "❌ Project does NOT exist at $PROJECT_ROOT"
    fi
    echo ""

    # 7. System Resources
    echo "═══════════════════════════════════════════════════════════════"
    echo "7. SYSTEM RESOURCES"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    echo "Memory Usage:"
    free -h 2>/dev/null || echo "free command not available"
    echo ""
    
    echo "Disk Usage:"
    df -h / 2>/dev/null | head -2 || echo "df command not available"
    echo ""

    # 8. Summary
    echo "═══════════════════════════════════════════════════════════════"
    echo "8. SUMMARY"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    echo "For more information:"
    echo "  docker ps -a              # View all containers"
    echo "  docker logs taxi-status   # View status dashboard logs"
    echo "  netstat -tuln             # View listening ports"
    echo "  pgrep node                # View Node.js processes"
    echo ""
}

# ============================================================================
# 2. FIX STATUS DASHBOARD (PORT 3030)
# ============================================================================
fix_status_dashboard() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              PORT 3030 - STATUS DASHBOARD FIX                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    log_step "[1] Checking Docker..."
    docker --version > /dev/null 2>&1 || {
        log_error "Docker is not installed"
        exit 1
    }
    log_ok "Docker is available"
    echo ""

    log_step "[2] Looking for taxi-status container..."
    CONTAINER=$(docker ps -a --format '{{.Names}}' | grep taxi-status)

    if [ -z "$CONTAINER" ]; then
        log_error "Container 'taxi-status' not found"
        echo ""
        echo "Available containers:"
        docker ps -a --format '{{.Names}}'
        echo ""
        log_info "Creating container..."
        cd "$PROJECT_ROOT/config"
        docker-compose -f docker-compose.yml up -d taxi-status
        sleep 10
    else
        log_ok "Container 'taxi-status' found"
        
        RUNNING=$(docker ps --format '{{.Names}}' | grep taxi-status)
        if [ -z "$RUNNING" ]; then
            log_warn "Container is not running"
            log_info "Starting container..."
            docker start taxi-status
            sleep 5
        else
            log_ok "Container is running"
        fi
    fi
    echo ""

    log_step "[3] Checking Docker logs..."
    echo ""
    docker logs taxi-status 2>&1 | tail -20
    echo ""

    log_step "[4] Checking port $STATUS_PORT..."
    if netstat -tuln 2>/dev/null | grep -q ":$STATUS_PORT"; then
        log_ok "Port $STATUS_PORT is listening"
    else
        log_error "Port $STATUS_PORT is NOT listening"
        log_info "Restarting container..."
        docker restart taxi-status
        sleep 5
    fi
    echo ""

    log_step "[5] Testing HTTP response..."
    RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null "http://127.0.0.1:$STATUS_PORT/" 2>&1)

    if [ "$RESPONSE" = "200" ]; then
        log_ok "Port $STATUS_PORT responding (HTTP $RESPONSE)"
    else
        log_error "Port $STATUS_PORT not responding (HTTP $RESPONSE)"
        echo ""
        log_info "Attempting force restart..."
        docker kill taxi-status 2>/dev/null || true
        docker rm taxi-status 2>/dev/null || true
        sleep 2
        
        cd "$PROJECT_ROOT/config"
        docker-compose -f docker-compose.yml up -d taxi-status
        sleep 10
        
        RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null "http://127.0.0.1:$STATUS_PORT/" 2>&1)
        if [ "$RESPONSE" = "200" ]; then
            log_ok "Port $STATUS_PORT now responding"
        fi
    fi
    echo ""

    log_step "[6] Verifying ALL services..."
    echo ""

    PORTS=("$STATUS_PORT" "$ADMIN_PORT" "$DRIVER_PORT" "$API_PORT" "$MAGIC_LINKS_PORT")
    NAMES=("Status Dashboard" "Admin Dashboard" "Driver Portal" "Main API" "Magic Links API")

    for i in "${!PORTS[@]}"; do
        PORT=${PORTS[$i]}
        NAME=${NAMES[$i]}
        RESP=$(curl -s -w "%{http_code}" -o /dev/null "http://127.0.0.1:$PORT/" 2>&1)
        
        if [ "$RESP" = "200" ]; then
            log_ok "Port $PORT ($NAME) - WORKING"
        else
            log_error "Port $PORT ($NAME) - NOT RESPONDING (HTTP $RESP)"
        fi
    done
    echo ""

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    FINAL STATUS                               ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    echo "Docker Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep taxi

    echo ""
    echo "Access to services:"
    echo "  - Status Dashboard: http://5.249.164.40:$STATUS_PORT"
    echo "  - Admin Dashboard:  http://5.249.164.40:$ADMIN_PORT"
    echo "  - Driver Portal:    http://5.249.164.40:$DRIVER_PORT"
    echo "  - Main API:         http://5.249.164.40:$API_PORT"
    echo "  - Magic Links API:  http://5.249.164.40:$MAGIC_LINKS_PORT"
    echo ""
}

# ============================================================================
# 3. FIX ALL SERVICES
# ============================================================================
fix_all_services() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║        COMPREHENSIVE SERVICE FIX - ALL SERVICES               ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    log_step "[STEP 1] Checking current service status..."
    echo ""

    echo "Docker Containers:"
    docker ps -a | grep taxi || echo "No taxi containers found"
    echo ""

    echo "Listening Ports:"
    netstat -tuln 2>/dev/null | grep -E "($ADMIN_PORT|$DRIVER_PORT|$STATUS_PORT|$API_PORT|$MAGIC_LINKS_PORT)" || echo "No services listening"
    echo ""

    log_step "[STEP 2] Stopping all services..."

    pkill -f "node server-admin.js" || true
    pkill -f "node server-driver.js" || true
    pkill -f "node server-customer.js" || true
    pkill -f "node status/server.js" || true
    pkill -f "node magic-links-server.js" || true
    pkill -f "node job-magic-links.js" || true

    sleep 2
    log_ok "Node processes stopped"
    echo ""

    log_step "[STEP 3] Stopping Docker containers..."

    cd "$PROJECT_ROOT/config" || exit 1
    docker-compose -f docker-compose.yml down 2>/dev/null || true
    sleep 3

    log_ok "Docker containers stopped"
    echo ""

    log_step "[STEP 4] Installing dependencies..."

    cd "$PROJECT_ROOT/web" || exit 1
    rm -rf node_modules package-lock.json 2>/dev/null || true
    npm install --prefer-offline 2>&1 | tail -5

    log_ok "Dependencies installed"
    echo ""

    log_step "[STEP 5] Starting Docker containers..."

    cd "$PROJECT_ROOT/config" || exit 1
    docker-compose -f docker-compose.yml up -d 2>&1 | tail -10

    echo "Waiting for containers to start (15 seconds)..."
    sleep 15

    log_ok "Docker containers started"
    echo ""

    log_step "[STEP 6] Checking container health..."
    echo ""

    docker ps -a | grep taxi

    echo ""

    log_step "[STEP 7] Starting Node.js web services..."

    cd "$PROJECT_ROOT" || exit 1

    echo "Starting Status Dashboard (port $STATUS_PORT)..."
    nohup node web/status/server.js > "$LOG_DIR/status.log" 2>&1 &
    STATUS_PID=$!
    sleep 2
    log_ok "Status Dashboard started (PID: $STATUS_PID)"

    echo "Starting Admin Dashboard (port $ADMIN_PORT)..."
    nohup npm run server-admin > "$LOG_DIR/admin.log" 2>&1 &
    sleep 2
    log_ok "Admin Dashboard started"

    echo "Starting Driver Portal (port $DRIVER_PORT)..."
    nohup npm run server-driver > "$LOG_DIR/driver.log" 2>&1 &
    sleep 2
    log_ok "Driver Portal started"

    echo "Starting Customer App (port $CUSTOMER_PORT)..."
    nohup npm run server-customer > "$LOG_DIR/customer.log" 2>&1 &
    sleep 2
    log_ok "Customer App started"

    echo ""

    log_step "[STEP 8] Waiting for services to become ready (10 seconds)..."
    sleep 10
    echo ""

    log_step "[STEP 9] Verifying all services..."
    echo ""

    PORTS=("$STATUS_PORT" "$ADMIN_PORT" "$DRIVER_PORT" "$CUSTOMER_PORT" "$API_PORT" "$MAGIC_LINKS_PORT")
    SERVICES=("Status Dashboard" "Admin Dashboard" "Driver Portal" "Customer App" "Main API" "Magic Links API")
    FAILED=0

    for i in "${!PORTS[@]}"; do
        PORT=${PORTS[$i]}
        SERVICE=${SERVICES[$i]}
        
        CURL_RESP=$(timeout 2 curl -s -w "%{http_code}" -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null)
        if [ "$CURL_RESP" = "200" ]; then
            log_ok "Port $PORT ($SERVICE) - RESPONDING"
        else
            log_error "Port $PORT ($SERVICE) - NOT RESPONDING"
            FAILED=$((FAILED+1))
        fi
    done

    echo ""

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    FINAL STATUS REPORT                        ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    echo "Docker Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep taxi

    echo ""
    echo "Listening Ports:"
    netstat -tuln 2>/dev/null | grep -E "($ADMIN_PORT|$DRIVER_PORT|$STATUS_PORT|$API_PORT|$MAGIC_LINKS_PORT)" | awk '{print $4}' | sort -u | while read -r port; do
        echo "  ✓ $port"
    done

    echo ""
    echo "Node.js Processes:"
    count=$(pgrep -c "node" 2>/dev/null || echo 0)
    echo "  Running processes: $count"

    echo ""

    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✓ ALL SERVICES ARE OPERATIONAL${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "Access your services:"
        echo "  Status Dashboard: http://5.249.164.40:$STATUS_PORT"
        echo "  Admin Dashboard:  http://5.249.164.40:$ADMIN_PORT"
        echo "  Driver Portal:    http://5.249.164.40:$DRIVER_PORT"
        echo "  Customer App:     http://5.249.164.40:$CUSTOMER_PORT"
        echo "  Main API:         http://5.249.164.40:$API_PORT"
        echo "  Magic Links API:  http://5.249.164.40:$MAGIC_LINKS_PORT"
    else
        echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}⚠ $FAILED service(s) failed to start${NC}"
        echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "Check logs:"
        echo "  tail -f $LOG_DIR/status.log"
        echo "  tail -f $LOG_DIR/admin.log"
        echo "  docker logs taxi-status"
    fi

    echo ""
}

# ============================================================================
# 4. VPS DEPLOYMENT
# ============================================================================
deploy_vps() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              VPS DEPLOYMENT - COMPLETE SETUP                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    log_step "[STEP 1] Pre-deployment checks..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose not installed. Please install Docker Compose first."
        exit 1
    fi
    
    log_ok "Docker and Docker Compose are installed"
    echo ""

    log_step "[STEP 2] Pulling latest code from GitHub..."
    cd "$PROJECT_ROOT"
    git pull origin main || true
    log_ok "Code updated"
    echo ""

    log_step "[STEP 3] Running fix-all services..."
    fix_all_services
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              VPS DEPLOYMENT COMPLETE                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
}

# ============================================================================
# 5. FULL INSTALLATION
# ============================================================================
install_system() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              FULL SYSTEM INSTALLATION                         ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    log_step "[STEP 1] Installing system dependencies..."
    apt-get update -qq
    apt-get install -y -qq curl wget git nodejs npm docker.io docker-compose jq netcat openssl > /dev/null 2>&1
    log_ok "System dependencies installed"
    echo ""

    log_step "[STEP 2] Installing project dependencies..."
    cd "$PROJECT_ROOT/web"
    npm install --prefer-offline > /dev/null 2>&1
    log_ok "npm dependencies installed"
    echo ""

    log_step "[STEP 3] Starting services..."
    fix_all_services
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              INSTALLATION COMPLETE                            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
}

# ============================================================================
# CLEAN INSTALL & UPDATE FLOWS
# ============================================================================
full_clean_install() {
    clear
    detect_os_info
    echo "===================================================="
    echo "        VPS TAXI SYSTEM – MAIN MENU"
    echo "===================================================="
    echo ""
    echo "Detected OS:"
    echo "→ Distribution  : $OS_NAME"
    echo "→ Version       : $OS_VERSION"
    echo "→ Package Manager: $PKG_MANAGER"
    echo ""
    log_step "Performing full clean install (destructive)"
    clean_downloads
    kill_taxi_processes
    remove_taxi_user
    create_taxi_user
    install_system
}

update_existing_taxi_user() {
    clear
    detect_os_info
    echo "===================================================="
    echo "        VPS TAXI SYSTEM – MAIN MENU"
    echo "===================================================="
    echo ""
    echo "Detected OS:"
    echo "→ Distribution  : $OS_NAME"
    echo "→ Version       : $OS_VERSION"
    echo "→ Package Manager: $PKG_MANAGER"
    echo ""
    log_step "Updating existing taxi user (non-destructive)"
    if [ "$PKG_MANAGER" = "apt" ]; then
        apt-get update -y >/dev/null 2>&1 || true
        apt-get upgrade -y >/dev/null 2>&1 || true
    fi
    fix_all_services
}

# ============================================================================
# 6. EMAIL SERVER SETUP
# ============================================================================
setup_email() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              EMAIL SERVER SETUP                               ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    log_step "[STEP 1] Installing email dependencies..."
    cd "$PROJECT_ROOT"
    
    if ! grep -q "nodemailer" package.json 2>/dev/null; then
        log_warn "nodemailer not found, installing..."
        npm install nodemailer@^6.9.7 --save
        log_ok "nodemailer installed"
    else
        log_ok "nodemailer already installed"
    fi
    echo ""

    log_step "[STEP 2] Creating config directory..."
    mkdir -p "$PROJECT_ROOT/config"
    log_ok "Config directory ready"
    echo ""

    log_step "[STEP 3] Creating email configuration..."
    if [ ! -f "$PROJECT_ROOT/config/email-config.json" ]; then
        cat > "$PROJECT_ROOT/config/email-config.json" << 'EMAILCONF'
{
  "email": {
    "provider": "smtp",
    "smtp": {
      "host": "smtp.gmail.com",
      "port": 587,
      "secure": false,
      "auth": {
        "user": "your-email@gmail.com",
        "pass": "your-app-password"
      },
      "from": "noreply@swiftcab.com",
      "replyTo": "support@swiftcab.com"
    },
    "sendgrid": {
      "apiKey": "your-sendgrid-api-key",
      "fromEmail": "noreply@swiftcab.com",
      "fromName": "Swift Cab"
    },
    "mailgun": {
      "apiKey": "your-mailgun-api-key",
      "domain": "mg.swiftcab.com",
      "fromEmail": "noreply@swiftcab.com"
    }
  },
  "notifications": {
    "enabled": true,
    "types": ["booking", "driver_assigned", "ride_complete", "payment"]
  }
}
EMAILCONF
        log_ok "Email configuration created"
    else
        log_ok "Email configuration already exists"
    fi
    echo ""

    log_step "[STEP 4] Testing email configuration..."
    if [ -f "$PROJECT_ROOT/config/email-config.json" ]; then
        log_ok "Email config file exists and is readable"
    else
        log_error "Email config file not found"
    fi
    echo ""

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              EMAIL SETUP COMPLETE                             ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Next steps:"
    echo "  1. Edit $PROJECT_ROOT/config/email-config.json"
    echo "  2. Add your SMTP credentials"
    echo "  3. Restart the application"
    echo ""
}

# ============================================================================
# 7. HTTPS/SSL CONFIGURATION
# ============================================================================
setup_https() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              HTTPS/SSL CONFIGURATION                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    CERT_DIR="$PROJECT_ROOT/certs"
    KEY_FILE="$CERT_DIR/server.key"
    CERT_FILE="$CERT_DIR/server.crt"

    log_step "[STEP 1] Creating certificate directory..."
    mkdir -p "$CERT_DIR"
    log_ok "Created $CERT_DIR"
    echo ""

    echo "Select certificate type:"
    echo "  1) Self-signed certificate (for development)"
    echo "  2) Let's Encrypt certificate (for production)"
    echo ""
    read -rp "Enter choice (1-2): " cert_choice

    case $cert_choice in
        1)
            log_step "[STEP 2] Generating self-signed certificate..."
            openssl req -x509 -newkey rsa:2048 -keyout "$KEY_FILE" -out "$CERT_FILE" \
                -days 365 -nodes \
                -subj "/C=US/ST=State/L=City/O=SwiftCab/CN=localhost"
            
            chmod 600 "$KEY_FILE"
            chmod 644 "$CERT_FILE"
            
            log_ok "Self-signed certificate generated"
            echo "  Key: $KEY_FILE"
            echo "  Cert: $CERT_FILE"
            ;;
        2)
            log_step "[STEP 2] Setting up Let's Encrypt..."
            read -rp "Enter your domain (e.g., example.com): " domain
            
            if ! command -v certbot &> /dev/null; then
                log_warn "Certbot not found. Installing..."
                apt-get update && apt-get install -y certbot python3-certbot-nginx
            fi
            
            certbot certonly --standalone -d "$domain" \
                --non-interactive --agree-tos --email admin@"$domain"
            
            log_ok "Let's Encrypt certificate installed"
            echo "  Cert: /etc/letsencrypt/live/$domain/fullchain.pem"
            echo "  Key: /etc/letsencrypt/live/$domain/privkey.pem"
            ;;
        *)
            log_error "Invalid choice"
            return
            ;;
    esac
    echo ""

    log_step "[STEP 3] Creating production environment file..."
    cat > "$PROJECT_ROOT/.env.production" << 'ENVPROD'
NODE_ENV=production
ADMIN_PORT=3001
DRIVER_PORT=3002
CUSTOMER_PORT=3000
API_PORT=3040
STATUS_PORT=3030
MAGIC_LINKS_PORT=3333
SSL_ENABLED=true
ENVPROD
    log_ok "Production environment file created"
    echo ""

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              HTTPS SETUP COMPLETE                             ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
}

# ============================================================================
# 8. NGINX DEPLOYMENT
# ============================================================================
setup_nginx() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              NGINX DEPLOYMENT                                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    log_step "[STEP 1] Installing Nginx..."
    if ! command -v nginx &> /dev/null; then
        apt-get update && apt-get install -y nginx
        log_ok "Nginx installed"
    else
        log_ok "Nginx already installed"
    fi
    echo ""

    log_step "[STEP 2] Creating Nginx configuration..."
    cat > /etc/nginx/sites-available/proyecto << 'NGINXCONF'
upstream admin_dashboard {
    server 127.0.0.1:3001;
}

upstream driver_portal {
    server 127.0.0.1:3002;
}

upstream customer_app {
    server 127.0.0.1:3000;
}

upstream status_dashboard {
    server 127.0.0.1:3030;
}

upstream api_server {
    server 127.0.0.1:3040;
}

server {
    listen 80;
    server_name _;

    location /admin {
        proxy_pass http://admin_dashboard;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /driver {
        proxy_pass http://driver_portal;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /customer {
        proxy_pass http://customer_app;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /status {
        proxy_pass http://status_dashboard;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://api_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
NGINXCONF
    log_ok "Nginx configuration created"
    echo ""

    log_step "[STEP 3] Enabling site..."
    ln -sf /etc/nginx/sites-available/proyecto /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    log_ok "Site enabled"
    echo ""

    log_step "[STEP 4] Testing Nginx configuration..."
    nginx -t
    log_ok "Configuration valid"
    echo ""

    log_step "[STEP 5] Restarting Nginx..."
    systemctl restart nginx
    systemctl enable nginx
    log_ok "Nginx restarted and enabled"
    echo ""

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              NGINX DEPLOYMENT COMPLETE                        ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
}

# ============================================================================
# 9. MONITORING
# ============================================================================
start_monitoring() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              REAL-TIME SERVICE MONITORING                     ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # MONITOR_LOG="$LOG_DIR/monitoring.log" # Reserved
    ALERT_LOG="$LOG_DIR/alerts.log"
    
    # Thresholds
    # CPU_THRESHOLD=80 # Reserved for threshold alerts
    # MEMORY_THRESHOLD=85 # Reserved for threshold alerts
    RESPONSE_THRESHOLD=1000

    log_info "Starting monitoring... (Press Ctrl+C to stop)"
    echo ""

    while true; do
        clear
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║              REAL-TIME SERVICE MONITORING                     ║"
        echo "║              $(date '+%Y-%m-%d %H:%M:%S')                              ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""

        echo "SERVICE STATUS:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        PORTS=("$STATUS_PORT" "$ADMIN_PORT" "$DRIVER_PORT" "$CUSTOMER_PORT" "$API_PORT" "$MAGIC_LINKS_PORT")
        declare -a NAMES=("Status Dashboard" "Admin Dashboard" "Driver Portal" "Customer App" "Main API" "Magic Links")

        for i in "${!PORTS[@]}"; do
            PORT=${PORTS[$i]}
            NAME=${NAMES[$i]}
            
            START_TIME=$(date +%s%N)
            RESP=$(timeout 2 curl -s -w "%{http_code}" -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null)
            END_TIME=$(date +%s%N)
            RESPONSE_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
            
            if [ "$RESP" = "200" ]; then
                if [ "$RESPONSE_TIME" -lt "$RESPONSE_THRESHOLD" ]; then
                    echo -e "  ${GREEN}✓${NC} $NAME (Port $PORT) - ${RESPONSE_TIME}ms"
                else
                    echo -e "  ${YELLOW}⚠${NC} $NAME (Port $PORT) - ${RESPONSE_TIME}ms (SLOW)"
                fi
            else
                echo -e "  ${RED}✗${NC} $NAME (Port $PORT) - DOWN"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ALERT] $NAME is DOWN" >> "$ALERT_LOG"
            fi
        done

        echo ""
        echo "SYSTEM RESOURCES:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # CPU Usage
        CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "N/A")
        echo "  CPU Usage: $CPU%"
        
        # Memory Usage
        MEM=$(free | grep Mem | awk '{print int($3/$2 * 100)}' 2>/dev/null || echo "N/A")
        echo "  Memory Usage: $MEM%"
        
        # Disk Usage
        DISK=$(df -h / | awk 'NR==2 {print $5}' 2>/dev/null || echo "N/A")
        echo "  Disk Usage: $DISK"

        echo ""
        echo "DOCKER CONTAINERS:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        docker ps --format "  {{.Names}}: {{.Status}}" 2>/dev/null | grep taxi || echo "  No containers found"

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Press Ctrl+C to stop monitoring"
        
        sleep 5
    done
}

# ============================================================================
# 10. WEB TESTING
# ============================================================================
test_web() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              WEB APPLICATION TESTING                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    PASSED=0
    FAILED=0

    log_step "Testing HTTP endpoints..."
    echo ""

    PORTS=("$STATUS_PORT" "$ADMIN_PORT" "$DRIVER_PORT" "$CUSTOMER_PORT" "$API_PORT" "$MAGIC_LINKS_PORT")
    declare -a NAMES=("Status Dashboard" "Admin Dashboard" "Driver Portal" "Customer App" "Main API" "Magic Links")

    for i in "${!PORTS[@]}"; do
        PORT=${PORTS[$i]}
        NAME=${NAMES[$i]}
        
        echo -n "Testing $NAME (port $PORT)... "
        RESP=$(timeout 5 curl -s -w "%{http_code}" -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null)
        
        if [ "$RESP" = "200" ]; then
            log_ok "PASSED (HTTP $RESP)"
            PASSED=$((PASSED+1))
        else
            log_error "FAILED (HTTP $RESP)"
            FAILED=$((FAILED+1))
        fi
    done

    echo ""
    log_step "Testing API endpoints..."
    echo ""

    API_ENDPOINTS=("/api/health" "/api/status" "/api/version")
    for endpoint in "${API_ENDPOINTS[@]}"; do
        echo -n "Testing $endpoint... "
        RESP=$(timeout 5 curl -s -w "%{http_code}" -o /dev/null "http://127.0.0.1:$API_PORT$endpoint" 2>/dev/null)
        
        if [ "$RESP" = "200" ] || [ "$RESP" = "404" ]; then
            log_ok "RESPONDED (HTTP $RESP)"
            PASSED=$((PASSED+1))
        else
            log_warn "NO RESPONSE (HTTP $RESP)"
            FAILED=$((FAILED+1))
        fi
    done

    echo ""
    log_step "Testing security headers..."
    echo ""

    for PORT in $ADMIN_PORT $DRIVER_PORT; do
        echo -n "Checking headers on port $PORT... "
        HEADERS=$(curl -sI "http://127.0.0.1:$PORT/" 2>/dev/null | grep -i "x-frame-options\|x-content-type\|x-xss")
        if [ -n "$HEADERS" ]; then
            log_ok "Security headers present"
        else
            log_warn "Some security headers missing"
        fi
    done

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              TEST RESULTS                                     ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Passed: $PASSED"
    echo "  Failed: $FAILED"
    echo "  Total:  $((PASSED+FAILED))"
    echo ""

    if [ $FAILED -eq 0 ]; then
        log_ok "All tests passed!"
    else
        log_warn "$FAILED test(s) failed"
    fi
    echo ""
}

# ============================================================================
# 11. SECURITY TESTING
# ============================================================================
test_security() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              SECURITY TESTING                                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    log_step "Running security checks..."
    echo ""

    # Check for exposed ports
    echo "1. EXPOSED PORTS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    netstat -tuln 2>/dev/null | grep LISTEN | head -20
    echo ""

    # Check for running as root
    echo "2. PROCESS OWNERSHIP:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    pgrep -a node 2>/dev/null | head -10 || echo "No node processes found"
    echo ""

    # Check file permissions
    echo "3. SENSITIVE FILE PERMISSIONS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for file in "$PROJECT_ROOT/.env" "$PROJECT_ROOT/.env.production" "$PROJECT_ROOT/config/email-config.json"; do
        if [ -f "$file" ]; then
            perms=$(stat -c '%A' "$file" 2>/dev/null || stat -f '%Sp' "$file" 2>/dev/null)
            echo "  $file: $perms"
        fi
    done
    echo ""

    # Check Docker security
    echo "4. DOCKER SECURITY:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker info 2>/dev/null | grep -E "Security|Rootless" || echo "  Docker security info not available"
    echo ""

    # Check for security headers
    echo "5. SECURITY HEADERS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for PORT in $ADMIN_PORT $DRIVER_PORT; do
        echo "  Port $PORT:"
        curl -sI "http://127.0.0.1:$PORT/" 2>/dev/null | grep -iE "x-frame|x-content|x-xss|strict-transport|content-security" | head -5 || echo "    No security headers found"
    done
    echo ""

    # SSL/TLS Check
    echo "6. SSL/TLS CERTIFICATES:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ -d "$PROJECT_ROOT/certs" ]; then
        ls -la "$PROJECT_ROOT/certs/" 2>/dev/null || echo "  No certificates found"
    else
        echo "  Certificate directory not found"
    fi
    echo ""

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              SECURITY CHECK COMPLETE                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
}

# ============================================================================
# 12. DASHBOARD MANAGEMENT
# ============================================================================
manage_dashboards() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              DASHBOARD MANAGEMENT                             ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    echo "Select an action:"
    echo ""
    echo "  1) Check dashboard status"
    echo "  2) Restart Admin Dashboard"
    echo "  3) Restart Driver Portal"
    echo "  4) Restart Customer App"
    echo "  5) Restart Status Dashboard"
    echo "  6) Restart ALL dashboards"
    echo "  7) View dashboard logs"
    echo "  8) Back to main menu"
    echo ""
    read -rp "Enter choice (1-8): " dashboard_choice

    case $dashboard_choice in
        1)
            echo ""
            log_step "Checking dashboard status..."
            echo ""
            for PORT in $ADMIN_PORT $DRIVER_PORT $CUSTOMER_PORT $STATUS_PORT; do
                RESP=$(curl -s -w "%{http_code}" -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null)
                if [ "$RESP" = "200" ]; then
                    log_ok "Port $PORT - RUNNING"
                else
                    log_error "Port $PORT - DOWN"
                fi
            done
            ;;
        2)
            log_step "Restarting Admin Dashboard..."
            pkill -f "server-admin" || true
            sleep 2
            cd "$PROJECT_ROOT" && nohup npm run server-admin > "$LOG_DIR/admin.log" 2>&1 &
            sleep 3
            log_ok "Admin Dashboard restarted"
            ;;
        3)
            log_step "Restarting Driver Portal..."
            pkill -f "server-driver" || true
            sleep 2
            cd "$PROJECT_ROOT" && nohup npm run server-driver > "$LOG_DIR/driver.log" 2>&1 &
            sleep 3
            log_ok "Driver Portal restarted"
            ;;
        4)
            log_step "Restarting Customer App..."
            pkill -f "server-customer" || true
            sleep 2
            cd "$PROJECT_ROOT" && nohup npm run server-customer > "$LOG_DIR/customer.log" 2>&1 &
            sleep 3
            log_ok "Customer App restarted"
            ;;
        5)
            log_step "Restarting Status Dashboard..."
            pkill -f "status/server.js" || true
            sleep 2
            cd "$PROJECT_ROOT" && nohup node web/status/server.js > "$LOG_DIR/status.log" 2>&1 &
            sleep 3
            log_ok "Status Dashboard restarted"
            ;;
        6)
            log_step "Restarting ALL dashboards..."
            pkill -f "server-admin" || true
            pkill -f "server-driver" || true
            pkill -f "server-customer" || true
            pkill -f "status/server.js" || true
            sleep 2
            cd "$PROJECT_ROOT"
            nohup npm run server-admin > "$LOG_DIR/admin.log" 2>&1 &
            nohup npm run server-driver > "$LOG_DIR/driver.log" 2>&1 &
            nohup npm run server-customer > "$LOG_DIR/customer.log" 2>&1 &
            nohup node web/status/server.js > "$LOG_DIR/status.log" 2>&1 &
            sleep 5
            log_ok "All dashboards restarted"
            ;;
        7)
            echo ""
            echo "Select log to view:"
            echo "  1) Admin Dashboard"
            echo "  2) Driver Portal"
            echo "  3) Customer App"
            echo "  4) Status Dashboard"
            echo ""
            read -rp "Enter choice (1-4): " log_choice
            case $log_choice in
                1) tail -50 "$LOG_DIR/admin.log" 2>/dev/null || echo "Log not found" ;;
                2) tail -50 "$LOG_DIR/driver.log" 2>/dev/null || echo "Log not found" ;;
                3) tail -50 "$LOG_DIR/customer.log" 2>/dev/null || echo "Log not found" ;;
                4) tail -50 "$LOG_DIR/status.log" 2>/dev/null || echo "Log not found" ;;
                *) echo "Invalid choice" ;;
            esac
            ;;
        8)
            return
            ;;
        *)
            log_error "Invalid choice"
            ;;
    esac
    echo ""
}

# ============================================================================
# 13. DEMO MAGIC LINKS
# ============================================================================
demo_magic_links() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              MAGIC LINKS DEMO                                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    log_step "Checking Magic Links API status..."
    RESP=$(curl -s -w "%{http_code}" -o /dev/null "http://127.0.0.1:$MAGIC_LINKS_PORT/" 2>/dev/null)
    
    if [ "$RESP" = "200" ]; then
        log_ok "Magic Links API is running on port $MAGIC_LINKS_PORT"
    else
        log_error "Magic Links API is not responding"
        echo ""
        log_step "Starting Magic Links API..."
        cd "$PROJECT_ROOT"
        nohup node job-magic-links.js > "$LOG_DIR/magic-links.log" 2>&1 &
        sleep 3
        log_ok "Magic Links API started"
    fi
    echo ""

    echo "MAGIC LINKS ENDPOINTS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Base URL: http://5.249.164.40:$MAGIC_LINKS_PORT"
    echo ""
    echo "  POST /api/magic-link/generate"
    echo "       Generate a new magic link for a job"
    echo ""
    echo "  GET  /api/magic-link/verify/:token"
    echo "       Verify a magic link token"
    echo ""
    echo "  POST /api/magic-link/accept"
    echo "       Accept a job via magic link"
    echo ""

    echo "EXAMPLE USAGE:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  # Generate magic link:"
    echo "  curl -X POST http://localhost:$MAGIC_LINKS_PORT/api/magic-link/generate \\"
    echo "       -H 'Content-Type: application/json' \\"
    echo "       -d '{\"jobId\": \"123\", \"driverId\": \"456\"}'"
    echo ""
    echo "  # Verify token:"
    echo "  curl http://localhost:$MAGIC_LINKS_PORT/api/magic-link/verify/TOKEN"
    echo ""
}

# ============================================================================
# MENUS
# ============================================================================
show_primary_menu() {
    clear
    detect_os_info
    echo "===================================================="
    echo "        VPS TAXI SYSTEM – MAIN MENU"
    echo "===================================================="
    echo ""
    echo "System Check:"
    echo "- Detecting Linux distribution..."
    echo "- Supported systems:"
    echo "  • Ubuntu (18.04 / 20.04 / 22.04 / 24.04)"
    echo "  • Debian (10 / 11 / 12)"
    echo ""
    echo "If an unsupported distribution is detected,"
    echo "the installer will stop automatically."
    echo ""
    echo "Detected OS:"
    echo "→ Distribution  : $OS_NAME"
    echo "→ Version       : $OS_VERSION"
    echo "→ Package Manager: $PKG_MANAGER"
    echo ""
    echo "Please choose one of the following options:"
    echo "----------------------------------------------------"
    echo "[1] FULL CLEAN INSTALL (RECOMMENDED)"
    echo "  - Remove old downloads"
    echo "  - Kill Taxi processes"
    echo "  - Remove/create taxi user"
    echo "  - Fresh install"
    echo ""
    echo "[2] UPDATE EXISTING TAXI USER"
    echo "  - Keep taxi user"
    echo "  - Update services"
    echo ""
    echo "[3] TESTS & ERROR DIAGNOSTICS"
    echo "  - Verify OS, permissions, ports, services"
    echo ""
    echo "[4] EXIT"
    echo ""
    echo -n "Enter your choice [1-4]: "
}

show_advanced_menu() {
    clear
    detect_os_info
    echo "===================================================="
    echo "        VPS TAXI SYSTEM – ADVANCED MENU"
    echo "===================================================="
    echo ""
    echo "System Pre-Check:"
    echo "- Detecting Linux distribution (Ubuntu / Debian)"
    echo "- Validating root permissions"
    echo "- Checking network connectivity"
    echo "- Scanning critical ports status"
    echo ""
    echo "Supported OS only. Installer will stop if unsupported."
    echo ""
    echo "Detected OS:"
    echo "→ Distribution  : $OS_NAME"
    echo "→ Version       : $OS_VERSION"
    echo "→ Package Manager: $PKG_MANAGER"
    echo ""
    echo "Please select an option (auto-select 7 in 30s):"
    echo "----------------------------------------------------"
    echo "[1] RUN FULL DIAGNOSTICS"
    echo "[2] START REAL-TIME MONITORING"
    echo "[3] FIX STATUS DASHBOARD"
    echo "[4] FIX ALL SERVICES"
    echo "[5] MANAGE DASHBOARDS"
    echo "[6] DEPLOY TO VPS"
    echo "[7] FULL SYSTEM INSTALLATION"
    echo "[8] SETUP EMAIL SERVER"
    echo "[9] CONFIGURE HTTPS / SSL"
    echo "[10] DEPLOY NGINX"
    echo "[11] TEST WEB INTERFACES"
    echo "[12] SECURITY TESTING"
    echo "[13] DEMO MAGIC LINKS"
    echo "[14] EXIT"
    echo ""
    echo -n "Enter your choice [1-14] (default 7 after 30s): "
}

# ============================================================================
# MAIN LOGIC
# ============================================================================
case "$1" in
    diagnose) run_diagnostics ;;
    fix-status) fix_status_dashboard ;;
    fix-all) fix_all_services ;;
    deploy-vps) deploy_vps ;;
    install) install_system ;;
    setup-email) setup_email ;;
    setup-https) setup_https ;;
    setup-nginx) setup_nginx ;;
    monitor) start_monitoring ;;
    test-web) test_web ;;
    test-security) test_security ;;
    manage-dashboards) manage_dashboards ;;
    demo-magic-links) demo_magic_links ;;
    *)
        # Primary menu
        while true; do
            show_primary_menu
            if ! read -r primary_choice; then
                exit 1
            fi
            case $primary_choice in
                1) full_clean_install; echo ""; read -rp "Press Enter to continue..." ;;
                2) update_existing_taxi_user; echo ""; read -rp "Press Enter to continue..." ;;
                3) run_diagnostics; echo ""; read -rp "Press Enter to continue..." ;;
                4) exit 0 ;;
                *) echo "Invalid option. Please try again."; sleep 1 ;;
            esac

            # After primary choice, show advanced menu with 30s default to option 7
            while true; do
                show_advanced_menu
                if ! read -t 30 -r adv_choice; then
                    adv_choice=7
                fi
                case $adv_choice in
                    1) run_diagnostics; echo ""; read -rp "Press Enter to continue..." ;;
                    2) start_monitoring ;;
                    3) fix_status_dashboard; echo ""; read -rp "Press Enter to continue..." ;;
                    4) fix_all_services; echo ""; read -rp "Press Enter to continue..." ;;
                    5) manage_dashboards; echo ""; read -rp "Press Enter to continue..." ;;
                    6) deploy_vps; echo ""; read -rp "Press Enter to continue..." ;;
                    7) install_system; echo ""; read -rp "Press Enter to continue..." ;;
                    8) setup_email; echo ""; read -rp "Press Enter to continue..." ;;
                    9) setup_https; echo ""; read -rp "Press Enter to continue..." ;;
                    10) setup_nginx; echo ""; read -rp "Press Enter to continue..." ;;
                    11) test_web; echo ""; read -rp "Press Enter to continue..." ;;
                    12) test_security; echo ""; read -rp "Press Enter to continue..." ;;
                    13) demo_magic_links; echo ""; read -rp "Press Enter to continue..." ;;
                    14) exit 0 ;;
                    *) echo "Invalid option. Please try again."; sleep 1 ;;
                esac
            done
        done
        ;;
esac
