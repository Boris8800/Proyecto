#!/bin/bash
# VPS Fresh Deployment - Complete setup from scratch
# Usage: sudo ./vps-deploy-fresh.sh [VPS_IP]
# Or: sudo bash -c "cd /tmp && git clone https://github.com/Boris8800/Proyecto.git && bash Proyecto/scripts/vps-deploy-fresh.sh [IP]"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} $1"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

print_status() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Validate root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root. Use: sudo ./vps-deploy-fresh.sh"
    exit 1
fi

print_header "SWIFT CAB - VPS FRESH DEPLOYMENT"

# Get VPS IP
VPS_IP="${1:-}"
if [ -z "$VPS_IP" ]; then
    VPS_IP=$(hostname -I | awk '{print $1}')
    if [ -z "$VPS_IP" ] || [ "$VPS_IP" = "127.0.0.1" ]; then
        read -rp "Enter VPS IP address: " VPS_IP
    fi
fi

# Validate IP
if ! [[ $VPS_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    print_error "Invalid IP format: $VPS_IP"
    exit 1
fi

print_status "VPS IP: $VPS_IP"
print_status "Project Root: $PROJECT_ROOT"

# Step 1: Update system
print_header "Step 1: Updating system packages"
apt-get update -qq
apt-get upgrade -y -qq
print_success "System updated"

# Step 2: Install dependencies
print_header "Step 2: Installing dependencies"
print_status "Installing Docker, Git, curl..."

if ! command -v docker &>/dev/null; then
    apt-get install -y -qq docker.io docker-compose git curl wget
    systemctl start docker || true
    systemctl enable docker || true
    print_success "Docker installed and started"
else
    print_success "Docker already installed"
fi

# Step 3: Configure environment
print_header "Step 3: Configuring environment"

if [ ! -d "$PROJECT_ROOT/config" ]; then
    mkdir -p "$PROJECT_ROOT/config"
    print_status "Created config directory"
fi

if [ ! -f "$PROJECT_ROOT/config/.env" ]; then
    if [ -f "$PROJECT_ROOT/config/.env.example" ]; then
        cp "$PROJECT_ROOT/config/.env.example" "$PROJECT_ROOT/config/.env"
        print_success "Created .env from template"
    else
        print_warning ".env.example not found, skipping .env creation"
    fi
fi

# Update VPS_IP in .env
if [ -f "$PROJECT_ROOT/config/.env" ]; then
    sed -i "s/^VPS_IP=.*/VPS_IP=$VPS_IP/" "$PROJECT_ROOT/config/.env" || true
    sed -i "s|^API_BASE_URL=.*|API_BASE_URL=http://$VPS_IP:3000|" "$PROJECT_ROOT/config/.env" || true
    print_success "Updated .env configuration"
fi

# Step 4: Create logs directory
print_header "Step 4: Setting up log directory"
if [ ! -d "$PROJECT_ROOT/logs" ]; then
    mkdir -p "$PROJECT_ROOT/logs"
    chmod 755 "$PROJECT_ROOT/logs"
    print_success "Log directory created"
else
    chmod 755 "$PROJECT_ROOT/logs"
    print_success "Log directory verified"
fi

# Step 5: Check Node.js and npm
print_header "Step 5: Checking Node.js installation"

if ! command -v node &>/dev/null; then
    print_warning "Node.js not found, installing via NVM..."
    
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash || true
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    nvm install --latest-npm 18 || node_version="$(command -v node)"
    
    if ! command -v node &>/dev/null; then
        print_error "Failed to install Node.js"
        exit 1
    fi
    print_success "Node.js installed"
else
    print_success "Node.js found: $(node --version)"
fi

if ! command -v npm &>/dev/null; then
    print_error "npm not found after Node.js installation"
    exit 1
fi

print_success "npm found: $(npm --version)"

# Step 6: Display deployment info
print_header "DEPLOYMENT COMPLETE"
echo ""
echo -e "${GREEN}=== Access Points ===${NC}"
echo -e "  Admin Dashboard:   ${BLUE}http://$VPS_IP:3001${NC}"
echo -e "  Driver Dashboard:  ${BLUE}http://$VPS_IP:3002${NC}"
echo -e "  Customer Portal:   ${BLUE}http://$VPS_IP:3003${NC}"
echo -e "  API Server:        ${BLUE}http://$VPS_IP:3000${NC}"
echo ""
echo -e "${GREEN}=== Database Info ===${NC}"
echo -e "  PostgreSQL:  ${BLUE}$VPS_IP:5432${NC}"
echo -e "  MongoDB:     ${BLUE}$VPS_IP:27017${NC}"
echo -e "  Redis:       ${BLUE}$VPS_IP:6379${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Start services: ${BLUE}bash $SCRIPT_DIR/main.sh${NC}"
echo "  2. Select 'Fresh Installation' from menu"
echo "  3. Wait for deployment to complete"
echo ""
