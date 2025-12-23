#!/bin/bash

################################################################################
# PROYECTO TAXI - COMPREHENSIVE SERVICE MANAGEMENT & DEPLOYMENT TOOL
# All-in-one script for:
#   • System diagnostics and monitoring
#   • Service installation and configuration
#   • Docker and VPS deployment
#   • Service management and fixing
#   • Email and API setup
#   • Dashboard management
#
# Usage:
#   bash main.sh                          # Interactive menu
#   bash main.sh diagnose                 # Run diagnostics
#   bash main.sh fix-all                  # Fix all services
#   bash main.sh fix-status               # Fix status dashboard only
#   bash main.sh deploy-vps               # Deploy to VPS
#   bash main.sh install                  # Full installation
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
MAGENTA='\033[0;35m'
NC='\033[0m'

# ============================================================================
# DIAGNOSTIC FUNCTION
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

    for port in 3030 3001 3002 3000 3040 3333; do
        echo -n "Port $port: "
        RESULT=$(timeout 3 curl -s -w "%{http_code}" -o /dev/null http://127.0.0.1:$port/ 2>&1)
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

    ps aux | grep -E "node|npm" | grep -v grep | awk '{print $2, $11, $12, $13}' | head -20 || echo "No Node.js processes"
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

    echo "--- taxi-postgres ---"
    docker logs taxi-postgres 2>&1 | tail -10 || echo "❌ Container taxi-postgres does not exist"
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
        ls -la "$PROJECT_ROOT"/ | grep -E "web|config|scripts|logs" | awk '{print "  " $9, "(" $5 " bytes)"}'
    else
        echo "❌ Project does NOT exist at $PROJECT_ROOT"
    fi
    echo ""

    # 7. Summary
    echo "═══════════════════════════════════════════════════════════════"
    echo "7. SUMMARY"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    echo "For more information:"
    echo "  docker ps -a              # View all containers"
    echo "  docker logs taxi-status   # View status dashboard logs"
    echo "  netstat -tuln             # View listening ports"
    echo "  ps aux | grep node        # View Node.js processes"
    echo ""
}

# ============================================================================
# FIX STATUS DASHBOARD (PORT 3030)
# ============================================================================
fix_status_dashboard() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              PORT 3030 - STATUS DASHBOARD FIX                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    echo -e "${BLUE}[1]${NC} Checking Docker..."
    docker --version > /dev/null 2>&1 || {
        echo "❌ Docker is not installed"
        exit 1
    }
    echo "✓ Docker is available"
    echo ""

    echo -e "${BLUE}[2]${NC} Looking for taxi-status container..."
    CONTAINER=$(docker ps -a --format '{{.Names}}' | grep taxi-status)

    if [ -z "$CONTAINER" ]; then
        echo "❌ Container 'taxi-status' not found"
        echo ""
        echo "Available containers:"
        docker ps -a --format '{{.Names}}'
        echo ""
        echo "Creating container..."
        cd "$PROJECT_ROOT/config"
        docker-compose -f docker-compose.yml up -d taxi-status
        sleep 10
    else
        echo "✓ Container 'taxi-status' found"
        
        RUNNING=$(docker ps --format '{{.Names}}' | grep taxi-status)
        if [ -z "$RUNNING" ]; then
            echo "⚠️  Container is not running"
            echo "Starting container..."
            docker start taxi-status
            sleep 5
        else
            echo "✓ Container is running"
        fi
    fi
    echo ""

    echo -e "${BLUE}[3]${NC} Checking Docker logs..."
    echo ""
    docker logs taxi-status 2>&1 | tail -20
    echo ""

    echo -e "${BLUE}[4]${NC} Checking port 3030..."
    if netstat -tuln 2>/dev/null | grep -q ":3030"; then
        echo "✓ Port 3030 is listening"
    else
        echo "❌ Port 3030 is NOT listening"
        echo "Restarting container..."
        docker restart taxi-status
        sleep 5
    fi
    echo ""

    echo -e "${BLUE}[5]${NC} Testing HTTP response..."
    RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null http://127.0.0.1:3030/ 2>&1)

    if [ "$RESPONSE" = "200" ]; then
        echo "✓ Port 3030 responding (HTTP $RESPONSE)"
    else
        echo "❌ Port 3030 not responding (HTTP $RESPONSE)"
        echo ""
        echo "Attempting force restart..."
        docker kill taxi-status 2>/dev/null || true
        docker rm taxi-status 2>/dev/null || true
        sleep 2
        
        cd "$PROJECT_ROOT/config"
        docker-compose -f docker-compose.yml up -d taxi-status
        sleep 10
        
        RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null http://127.0.0.1:3030/ 2>&1)
        if [ "$RESPONSE" = "200" ]; then
            echo "✓ Port 3030 now responding"
        fi
    fi
    echo ""

    echo -e "${BLUE}[6]${NC} Verifying ALL services..."
    echo ""

    declare -a PORTS=(3030 3001 3002 3040 3333)
    declare -a NAMES=("Status Dashboard" "Admin Dashboard" "Driver Portal" "Main API" "Magic Links API")

    for i in "${!PORTS[@]}"; do
        PORT=${PORTS[$i]}
        NAME=${NAMES[$i]}
        RESP=$(curl -s -w "%{http_code}" -o /dev/null http://127.0.0.1:$PORT/ 2>&1)
        
        if [ "$RESP" = "200" ]; then
            echo "✓ Port $PORT ($NAME) - WORKING"
        else
            echo "✗ Port $PORT ($NAME) - NOT RESPONDING (HTTP $RESP)"
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
    echo "  - Status Dashboard: http://5.249.164.40:3030"
    echo "  - Admin Dashboard:  http://5.249.164.40:3001"
    echo "  - Driver Portal:    http://5.249.164.40:3002"
    echo "  - Main API:         http://5.249.164.40:3040"
    echo "  - Magic Links API:  http://5.249.164.40:3333"
    echo ""
}

# ============================================================================
# FIX ALL SERVICES
# ============================================================================
fix_all_services() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║        COMPREHENSIVE SERVICE FIX - ALL SERVICES               ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    echo -e "${YELLOW}[STEP 1]${NC} Checking current service status..."
    echo ""

    echo "Docker Containers:"
    docker ps -a | grep taxi || echo "No taxi containers found"
    echo ""

    echo "Listening Ports:"
    netstat -tuln 2>/dev/null | grep -E "(3001|3002|3030|3040|3333)" || echo "No services listening"
    echo ""

    echo -e "${YELLOW}[STEP 2]${NC} Stopping all services..."

    pkill -f "node server-admin.js" || true
    pkill -f "node server-driver.js" || true
    pkill -f "node server-customer.js" || true
    pkill -f "node status/server.js" || true
    pkill -f "node magic-links-server.js" || true
    pkill -f "node job-magic-links.js" || true

    sleep 2
    echo -e "${GREEN}✓${NC} Node processes stopped"
    echo ""

    echo -e "${YELLOW}[STEP 3]${NC} Stopping Docker containers..."

    cd "$PROJECT_ROOT/config" || exit 1
    docker-compose -f docker-compose.yml down 2>/dev/null || true
    sleep 3

    echo -e "${GREEN}✓${NC} Docker containers stopped"
    echo ""

    echo -e "${YELLOW}[STEP 4]${NC} Installing dependencies..."

    cd "$PROJECT_ROOT/web" || exit 1
    rm -rf node_modules package-lock.json 2>/dev/null || true
    npm install --prefer-offline 2>&1 | tail -5

    echo -e "${GREEN}✓${NC} Dependencies installed"
    echo ""

    echo -e "${YELLOW}[STEP 5]${NC} Starting Docker containers..."

    cd "$PROJECT_ROOT/config" || exit 1
    docker-compose -f docker-compose.yml up -d 2>&1 | tail -10

    echo "Waiting for containers to start (15 seconds)..."
    sleep 15

    echo -e "${GREEN}✓${NC} Docker containers started"
    echo ""

    echo -e "${YELLOW}[STEP 6]${NC} Checking container health..."
    echo ""

    docker ps -a | grep taxi

    echo ""

    echo -e "${YELLOW}[STEP 7]${NC} Starting Node.js web services..."

    cd "$PROJECT_ROOT" || exit 1

    echo "Starting Status Dashboard (port 3030)..."
    nohup node web/status/server.js > "$PROJECT_ROOT/logs/status.log" 2>&1 &
    STATUS_PID=$!
    sleep 2
    echo -e "${GREEN}✓${NC} Status Dashboard started (PID: $STATUS_PID)"

    echo "Starting Admin Dashboard (port 3001)..."
    nohup npm run server-admin > "$PROJECT_ROOT/logs/admin.log" 2>&1 &
    sleep 2
    echo -e "${GREEN}✓${NC} Admin Dashboard started"

    echo "Starting Driver Portal (port 3002)..."
    nohup npm run server-driver > "$PROJECT_ROOT/logs/driver.log" 2>&1 &
    sleep 2
    echo -e "${GREEN}✓${NC} Driver Portal started"

    echo "Starting Customer App (port 3000)..."
    nohup npm run server-customer > "$PROJECT_ROOT/logs/customer.log" 2>&1 &
    sleep 2
    echo -e "${GREEN}✓${NC} Customer App started"

    echo ""

    echo -e "${YELLOW}[STEP 8]${NC} Waiting for services to become ready (10 seconds)..."
    sleep 10
    echo ""

    echo -e "${YELLOW}[STEP 9]${NC} Verifying all services..."
    echo ""

    declare -a PORTS=(3030 3001 3002 3000 3040 3333)
    declare -a SERVICES=("Status Dashboard" "Admin Dashboard" "Driver Portal" "Customer App" "Main API" "Magic Links API")
    FAILED=0

    for i in "${!PORTS[@]}"; do
        PORT=${PORTS[$i]}
        SERVICE=${SERVICES[$i]}
        
        if timeout 2 curl -s -w "%{http_code}" -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null | grep -q "200"; then
            echo -e "${GREEN}✓${NC} Port $PORT ($SERVICE) - RESPONDING"
        else
            echo -e "${RED}✗${NC} Port $PORT ($SERVICE) - NOT RESPONDING"
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
    netstat -tuln 2>/dev/null | grep -E "(3001|3002|3030|3040|3333)" | awk '{print $4}' | sort -u | while read port; do
        echo "  ✓ $port"
    done

    echo ""
    echo "Node.js Processes:"
    ps aux | grep -E "node.*server|status" | grep -v grep | wc -l | xargs echo "  Running processes:"

    echo ""

    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✓ ALL SERVICES ARE OPERATIONAL${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "Access your services:"
        echo "  Status Dashboard: http://5.249.164.40:3030"
        echo "  Admin Dashboard:  http://5.249.164.40:3001"
        echo "  Driver Portal:    http://5.249.164.40:3002"
        echo "  Customer App:     http://5.249.164.40:3000"
        echo "  Main API:         http://5.249.164.40:3040"
        echo "  Magic Links API:  http://5.249.164.40:3333"
    else
        echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}⚠ $FAILED service(s) failed to start${NC}"
        echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "Check logs:"
        echo "  tail -f $PROJECT_ROOT/logs/status.log"
        echo "  tail -f $PROJECT_ROOT/logs/admin.log"
        echo "  tail -f $PROJECT_ROOT/logs/driver.log"
        echo "  tail -f $PROJECT_ROOT/logs/customer.log"
        echo "  docker logs taxi-status"
    fi

    echo ""
}

# ============================================================================
# VPS DEPLOYMENT
# ============================================================================
deploy_vps() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              VPS DEPLOYMENT - COMPLETE SETUP                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    echo -e "${YELLOW}[STEP 1]${NC} Pre-deployment checks..."
    
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose not installed. Please install Docker Compose first."
        exit 1
    fi
    
    echo "✓ Docker and Docker Compose are installed"
    echo ""

    echo -e "${YELLOW}[STEP 2]${NC} Pulling latest code from GitHub..."
    cd "$PROJECT_ROOT"
    git pull origin main || true
    echo "✓ Code updated"
    echo ""

    echo -e "${YELLOW}[STEP 3]${NC} Running fix-all services..."
    fix_all_services
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              VPS DEPLOYMENT COMPLETE                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
}

# ============================================================================
# FULL INSTALLATION
# ============================================================================
install_system() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              FULL SYSTEM INSTALLATION                         ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    echo -e "${YELLOW}[STEP 1]${NC} Installing system dependencies..."
    apt-get update -qq
    apt-get install -y -qq curl wget git nodejs npm docker.io docker-compose jq > /dev/null 2>&1
    echo "✓ System dependencies installed"
    echo ""

    echo -e "${YELLOW}[STEP 2]${NC} Installing project dependencies..."
    cd "$PROJECT_ROOT/web"
    npm install --prefer-offline > /dev/null 2>&1
    echo "✓ npm dependencies installed"
    echo ""

    echo -e "${YELLOW}[STEP 3]${NC} Starting services..."
    fix_all_services
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              INSTALLATION COMPLETE                            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
}

# ============================================================================
# SHOW MENU
# ============================================================================
show_menu() {
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║     PROYECTO TAXI - COMPREHENSIVE SERVICE MANAGEMENT TOOL     ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Select an option:"
    echo ""
    echo -e "${CYAN}DIAGNOSTICS:${NC}"
    echo -e "${CYAN}1)${NC}  Run Full Diagnostics"
    echo ""
    echo -e "${CYAN}SERVICE MANAGEMENT:${NC}"
    echo -e "${CYAN}2)${NC}  Fix Status Dashboard (Port 3030)"
    echo -e "${CYAN}3)${NC}  Fix All Services"
    echo ""
    echo -e "${CYAN}DEPLOYMENT:${NC}"
    echo -e "${CYAN}4)${NC}  Deploy to VPS"
    echo -e "${CYAN}5)${NC}  Full System Installation"
    echo ""
    echo -e "${CYAN}6)${NC}  Exit"
    echo ""
    echo -n "Enter option (1-6): "
}

# ============================================================================
# MAIN LOGIC
# ============================================================================
if [ "$1" = "diagnose" ]; then
    run_diagnostics
elif [ "$1" = "fix-status" ]; then
    fix_status_dashboard
elif [ "$1" = "fix-all" ]; then
    fix_all_services
elif [ "$1" = "deploy-vps" ]; then
    deploy_vps
elif [ "$1" = "install" ]; then
    install_system
else
    # Interactive menu
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                run_diagnostics
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                fix_status_dashboard
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                fix_all_services
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                deploy_vps
                echo ""
                read -p "Press Enter to continue..."
                ;;
            5)
                install_system
                echo ""
                read -p "Press Enter to continue..."
                ;;
            6)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                sleep 1
                ;;
        esac
    done
fi
