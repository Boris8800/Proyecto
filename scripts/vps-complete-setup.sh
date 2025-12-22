#!/bin/bash
# Swift Cab VPS Complete Setup
# All-in-one installation and configuration for VPS deployment

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
print_error() { echo -e "${RED}✗${NC} $1"; exit 1; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root. Use: sudo ./vps-complete-setup.sh"
    fi
}

# Get VPS IP
get_vps_ip() {
    local ip="${1:-}"
    
    if [ -z "$ip" ]; then
        # Try to detect IP
        ip=$(hostname -I | awk '{print $1}')
        if [ -z "$ip" ] || [ "$ip" = "127.0.0.1" ]; then
            read -r -p "Enter your VPS IP address: " ip
        fi
    fi
    
    # Validate
    if ! [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        print_error "Invalid IP address: $ip"
    fi
    
    echo "$ip"
}

# Check Docker installation
check_docker() {
    print_status "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not found. Installing..."
        apt update
        apt install -y docker.io docker-compose git curl
        systemctl start docker
        systemctl enable docker
        print_success "Docker installed"
    else
        print_success "Docker is installed"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        apt install -y docker-compose
    fi
}

# Setup environment
setup_environment() {
    local vps_ip=$1
    
    print_header "Setting up environment for IP: $vps_ip"
    
    # Create .env if it doesn't exist
    if [ ! -f "$PROJECT_ROOT/config/.env" ]; then
        cp "$PROJECT_ROOT/config/.env.example" "$PROJECT_ROOT/config/.env"
        print_success "Created .env file"
    fi
    
    # Update VPS_IP
    sed -i "s/^VPS_IP=.*/VPS_IP=$vps_ip/" "$PROJECT_ROOT/config/.env"
    sed -i "s|^API_BASE_URL=.*|API_BASE_URL=http://$vps_ip:3000|" "$PROJECT_ROOT/config/.env"
    
    print_success "Configuration updated for IP: $vps_ip"
}

# Deploy services
deploy_services() {
    print_header "Deploying services..."
    
    cd "$PROJECT_ROOT/config"
    
    print_status "Loading environment..."
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
    
    print_status "Pulling Docker images..."
    docker-compose pull
    
    print_status "Starting services..."
    docker-compose up -d
    
    print_success "Services started"
}

# Wait for services to be ready
wait_for_services() {
    print_header "Waiting for services to stabilize..."
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local running
        running=$(docker ps --format '{{.Names}}' | wc -l)
        
        if [ "$running" -ge 7 ]; then
            print_success "All services are running"
            return 0
        fi
        
        echo -ne "\rWaiting... ($((attempt+1))/$max_attempts) Running: $running/7"
        sleep 2
        ((attempt++))
    done
    
    print_warning "Some services may still be starting"
}

# Check health
check_health() {
    print_header "Checking service health..."
    
    local services=("taxi-api" "taxi-admin" "taxi-driver" "taxi-customer" "taxi-postgres" "taxi-mongo" "taxi-redis")
    local healthy=0
    
    for service in "${services[@]}"; do
        if docker ps --filter "name=$service" --format '{{.Names}}' | grep -q "$service"; then
            print_success "$service is running"
            ((healthy++))
        else
            print_warning "$service is starting..."
        fi
    done
    
    echo ""
    echo -e "Status: ${GREEN}$healthy/7${NC} services running"
}

# Display access information
show_access_info() {
    local vps_ip
    vps_ip=$(grep "^VPS_IP=" "$PROJECT_ROOT/config/.env" | cut -d= -f2)
    
    print_header "Access Information"
    
    echo -e "${CYAN}Web Interfaces:${NC}"
    echo "  • Admin Dashboard:   ${BLUE}http://$vps_ip:3001${NC}"
    echo "  • Driver Portal:     ${BLUE}http://$vps_ip:3002${NC}"
    echo "  • Customer App:      ${BLUE}http://$vps_ip:3003${NC}"
    echo ""
    
    echo -e "${CYAN}API & Monitoring:${NC}"
    echo "  • API Server:        ${BLUE}http://$vps_ip:3000${NC}"
    echo "  • Status Dashboard:  ${BLUE}http://$vps_ip:8080${NC}"
    echo ""
    
    echo -e "${CYAN}Database Connections:${NC}"
    echo "  • PostgreSQL:        ${BLUE}$vps_ip:5432${NC}"
    echo "  • MongoDB:           ${BLUE}$vps_ip:27017${NC}"
    echo "  • Redis:             ${BLUE}$vps_ip:6379${NC}"
    echo ""
}

# Setup firewall
setup_firewall() {
    if command -v ufw &> /dev/null; then
        print_header "Setting up firewall rules..."
        
        local ports=(22 3000 3001 3002 3003 8080 5432 27017 6379)
        
        for port in "${ports[@]}"; do
            ufw allow "$port/tcp" 2>/dev/null || true
        done
        
        print_success "Firewall rules configured"
    fi
}

# Setup backup schedule
setup_backups() {
    print_header "Setting up automatic backups..."
    
    # Check if cron job exists
    if ! crontab -l 2>/dev/null | grep -q "vps-manage.sh backup"; then
        (crontab -l 2>/dev/null || true; echo "0 2 * * * cd $SCRIPT_DIR && ./vps-manage.sh backup >> /var/log/swift-cab-backup.log 2>&1") | crontab -
        print_success "Daily backups scheduled at 2 AM"
    else
        print_success "Backups already scheduled"
    fi
}

# Create systemd service (optional)
setup_systemd_service() {
    print_header "Creating systemd service..."
    
    cat > /etc/systemd/system/swift-cab.service << 'EOF'
[Unit]
Description=Swift Cab Taxi Booking System
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/workspaces/Proyecto/config
ExecStart=/usr/bin/docker-compose up
ExecStop=/usr/bin/docker-compose down
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    print_success "Systemd service created"
}

# Summary and next steps
show_summary() {
    local vps_ip
    vps_ip=$(grep "^VPS_IP=" "$PROJECT_ROOT/config/.env" | cut -d= -f2)
    
    print_header "Setup Complete!"
    
    echo -e "${GREEN}Your Swift Cab system is now deployed!${NC}"
    echo ""
    
    echo -e "${CYAN}Quick Links:${NC}"
    echo "  • Open in browser: ${BLUE}http://$vps_ip:3001${NC}"
    echo "  • Monitor status:  ${BLUE}http://$vps_ip:8080${NC}"
    echo ""
    
    echo -e "${CYAN}Management Commands:${NC}"
    echo "  • Check status:    ${YELLOW}./vps-manage.sh status${NC}"
    echo "  • View logs:       ${YELLOW}./vps-manage.sh logs${NC}"
    echo "  • Backup data:     ${YELLOW}./vps-manage.sh backup${NC}"
    echo "  • Health check:    ${YELLOW}./vps-manage.sh health${NC}"
    echo "  • Full menu:       ${YELLOW}./vps-manage.sh${NC}"
    echo ""
    
    echo -e "${CYAN}Documentation:${NC}"
    echo "  • Full Guide:      ${YELLOW}docs/VPS_DEPLOYMENT_GUIDE.md${NC}"
    echo "  • Quick Reference: ${YELLOW}docs/VPS_QUICK_REFERENCE.md${NC}"
    echo ""
    
    echo -e "${YELLOW}⚠ Important:${NC}"
    echo "  1. Change default passwords in config/.env"
    echo "  2. Configure firewall rules if needed"
    echo "  3. Set up SSL/TLS with your domain"
    echo "  4. Test all services before going live"
    echo ""
}

# Main flow
main() {
    clear
    print_header "Swift Cab VPS Complete Setup"
    
    check_root
    
    # Get VPS IP
    local vps_ip
    vps_ip=$(get_vps_ip "$@")
    
    # Setup steps
    check_docker
    setup_environment "$vps_ip"
    deploy_services
    wait_for_services
    check_health
    setup_firewall
    setup_backups
    setup_systemd_service
    show_access_info
    show_summary
}

main "$@"
