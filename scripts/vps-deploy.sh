#!/bin/bash

###############################################
# VPS Service Fix & Deployment Script
# Deploys latest fixes from GitHub to VPS
# Fixes Port 8080 and starts all services
###############################################

set -e

PROJECT_ROOT="${PROJECT_ROOT:-/root/Proyecto}"
REMOTE_URL="https://github.com/Boris8800/Proyecto.git"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# ============================================
# Check if running on VPS
# ============================================
check_vps() {
    print_header "Checking VPS Environment"
    
    if [ ! -d "$PROJECT_ROOT" ]; then
        print_error "Project directory not found: $PROJECT_ROOT"
        exit 1
    fi
    
    if [ "$EUID" -ne 0 ]; then
        print_warning "Not running as root. Some operations may fail."
    fi
    
    print_success "Project directory found: $PROJECT_ROOT"
}

# ============================================
# Pull latest changes from GitHub
# ============================================
pull_latest() {
    print_header "Pulling Latest Changes from GitHub"
    
    cd "$PROJECT_ROOT"
    
    if [ ! -d ".git" ]; then
        print_error "Not a git repository. Initializing..."
        git init
        git remote add origin $REMOTE_URL
    fi
    
    git fetch origin main
    git reset --hard origin/main
    
    print_success "Latest changes pulled from GitHub"
}

# ============================================
# Install dependencies
# ============================================
install_deps() {
    print_header "Installing Dependencies"
    
    cd "$PROJECT_ROOT/web/api"
    
    if [ ! -d "node_modules" ]; then
        print_warning "Installing npm dependencies (this may take a minute)..."
        npm install --legacy-peer-deps >/dev/null 2>&1 || npm install --legacy-peer-deps
    else
        print_success "Dependencies already installed"
    fi
}

# ============================================
# Stop existing processes
# ============================================
stop_services() {
    print_header "Stopping Existing Services"
    
    # Kill Docker containers
    if command -v docker &> /dev/null; then
        docker-compose -f "$PROJECT_ROOT/config/docker-compose.yml" down 2>/dev/null || true
        print_success "Docker containers stopped"
    fi
    
    # Kill Node.js processes
    for port in 3000 3001 3002 3003 3333 3334 8080; do
        if lsof -i :$port >/dev/null 2>&1; then
            PID=$(lsof -i :$port -t 2>/dev/null | head -1)
            if [ ! -z "$PID" ]; then
                kill -9 $PID 2>/dev/null || true
                print_success "Killed process on port $port"
            fi
        fi
    done
    
    sleep 2
}

# ============================================
# Start services
# ============================================
start_services() {
    print_header "Starting Services"
    
    cd "$PROJECT_ROOT"
    
    # Make scripts executable
    chmod +x scripts/start-api-services.sh
    chmod +x scripts/services-monitor.sh
    
    # Start API services
    bash scripts/start-api-services.sh
    
    print_success "All services started"
}

# ============================================
# Verify services
# ============================================
verify_services() {
    print_header "Service Verification"
    
    FAILED=0
    
    for port in 3001 3002 3003 3333 3334 8080; do
        if lsof -i :$port >/dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} Port $port - LISTENING"
        else
            echo -e "${RED}❌${NC} Port $port - NOT LISTENING"
            FAILED=$((FAILED + 1))
        fi
    done
    
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        print_success "All services verified!"
        return 0
    else
        print_error "$FAILED service(s) not responding"
        return 1
    fi
}

# ============================================
# Create systemd service for auto-start
# ============================================
create_systemd_service() {
    print_header "Creating Systemd Service (Auto-Start)"
    
    cat > /etc/systemd/system/taxi-api-services.service << 'EOF'
[Unit]
Description=Taxi API Services (Magic Links, Job Magic Links, Status Dashboard)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/Proyecto
ExecStart=/bin/bash /root/Proyecto/scripts/start-api-services.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable taxi-api-services.service
    
    print_success "Systemd service created and enabled"
}

# ============================================
# Create monitor systemd service
# ============================================
create_monitor_service() {
    print_header "Creating Monitor Service (Auto-Restart on Crash)"
    
    cat > /etc/systemd/system/taxi-services-monitor.service << 'EOF'
[Unit]
Description=Taxi Services Monitor (Auto-Restart)
After=taxi-api-services.service

[Service]
Type=simple
User=root
WorkingDirectory=/root/Proyecto
ExecStart=/bin/bash /root/Proyecto/scripts/services-monitor.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable taxi-services-monitor.service
    
    print_success "Monitor service created and enabled"
}

# ============================================
# Main execution
# ============================================
main() {
    print_header "VPS DEPLOYMENT & FIX SCRIPT"
    
    check_vps
    pull_latest
    install_deps
    stop_services
    start_services
    
    if verify_services; then
        echo ""
        echo -e "${BLUE}Creating systemd services for auto-start...${NC}"
        create_systemd_service
        create_monitor_service
        
        echo ""
        print_success "Deployment Complete!"
        echo ""
        echo -e "${BLUE}Your services are now:${NC}"
        echo "  ✅ Running on all ports"
        echo "  ✅ Auto-starting on reboot"
        echo "  ✅ Auto-restarting on crash"
        echo ""
        echo -e "${BLUE}Access your VPS:${NC}"
        echo "  Admin Dashboard:     http://5.249.164.40:3001"
        echo "  Driver Portal:       http://5.249.164.40:3002"
        echo "  Customer App:        http://5.249.164.40:3003"
        echo "  Magic Links API:     http://5.249.164.40:3333"
        echo "  Job Magic Links API: http://5.249.164.40:3334"
        echo "  Status Dashboard:    http://5.249.164.40:8080"
        echo ""
        echo -e "${BLUE}Useful Commands:${NC}"
        echo "  View service status:    systemctl status taxi-api-services.service"
        echo "  View monitor status:    systemctl status taxi-services-monitor.service"
        echo "  View logs:              journalctl -u taxi-api-services.service -f"
        echo "  Restart services:       systemctl restart taxi-api-services.service"
        echo "  Stop services:          systemctl stop taxi-api-services.service"
        echo ""
    else
        print_error "Deployment failed. Check logs above."
        exit 1
    fi
}

main "$@"
