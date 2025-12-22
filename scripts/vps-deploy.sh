#!/bin/bash
# VPS Deployment Script - Build and start all services
# Usage: ./vps-deploy.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Check if running with proper permissions
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    local missing=0
    
    for cmd in docker docker-compose; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "$cmd is not installed"
            missing=1
        fi
    done
    
    if [ $missing -eq 1 ]; then
        exit 1
    fi
    
    print_success "All dependencies installed"
}

# Deploy services
deploy() {
    print_status "Starting VPS Deployment..."
    
    cd "$CONFIG_DIR"
    
    print_status "Loading environment variables..."
    export $(grep -v '^#' .env | xargs)
    
    print_status "Pulling latest images..."
    docker-compose pull || true
    
    print_status "Building and starting containers..."
    docker-compose up -d
    
    print_status "Waiting for services to stabilize..."
    sleep 10
    
    # Check container health
    print_status "Checking container health..."
    check_container_health
    
    print_success "Deployment complete!"
}

# Check container health
check_container_health() {
    local containers=("taxi-api" "taxi-admin" "taxi-driver" "taxi-customer" "taxi-postgres" "taxi-mongo" "taxi-redis")
    
    for container in "${containers[@]}"; do
        if docker ps --filter "name=$container" --format '{{.Names}}' | grep -q "$container"; then
            print_success "Container $container is running"
        else
            print_error "Container $container failed to start"
        fi
    done
}

# Show deployment info
show_info() {
    local vps_ip=$(grep "^VPS_IP=" "$PROJECT_ROOT/config/.env" | cut -d= -f2)
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} VPS Deployment Information             ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "VPS IP Address: ${GREEN}$vps_ip${NC}"
    echo ""
    echo -e "${YELLOW}Web Interfaces:${NC}"
    echo "  • Admin:    http://$vps_ip:3001"
    echo "  • Driver:   http://$vps_ip:3002"
    echo "  • Customer: http://$vps_ip:3003"
    echo "  • Status:   http://$vps_ip:8080"
    echo ""
    echo -e "${YELLOW}API Server:${NC}"
    echo "  • Base URL: http://$vps_ip:3000"
    echo ""
    echo -e "${YELLOW}Databases:${NC}"
    echo "  • PostgreSQL: $vps_ip:5432"
    echo "  • MongoDB:    $vps_ip:27017"
    echo "  • Redis:      $vps_ip:6379"
    echo ""
}

main() {
    check_permissions
    check_dependencies
    deploy
    show_info
    
    echo -e "${GREEN}Deployment successful!${NC}"
}

main "$@"
