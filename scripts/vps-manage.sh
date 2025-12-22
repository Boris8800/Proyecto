#!/bin/bash
# VPS Management Utilities
# Usage: ./vps-manage.sh [command]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info() { echo -e "${CYAN}ℹ${NC} $1"; }

# Load environment
load_env() {
    if [ ! -f "$CONFIG_DIR/.env" ]; then
        print_error "No .env file found. Run vps-setup.sh first"
        exit 1
    fi
    set -a
    # shellcheck source=/dev/null
    source "$CONFIG_DIR/.env"
    set +a
}

# Show menu
show_menu() {
    clear
    echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC} Swift Cab VPS Management Dashboard     ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}1.${NC}  View System Status"
    echo -e "${CYAN}2.${NC}  View Container Logs"
    echo -e "${CYAN}3.${NC}  Restart Services"
    echo -e "${CYAN}4.${NC}  Stop All Services"
    echo -e "${CYAN}5.${NC}  Start All Services"
    echo -e "${CYAN}6.${NC}  View Docker Status"
    echo -e "${CYAN}7.${NC}  Monitor System Resources"
    echo -e "${CYAN}8.${NC}  Backup Databases"
    echo -e "${CYAN}9.${NC}  Health Check"
    echo -e "${CYAN}10.${NC} Security Audit"
    echo -e "${CYAN}11.${NC} Update Environment"
    echo -e "${CYAN}12.${NC} View Service URLs"
    echo -e "${CYAN}13.${NC} Clean Up Disk Space"
    echo -e "${CYAN}14.${NC} Exit"
    echo ""
    read -r -p "Select option: " choice
    
    case $choice in
        1) view_status ;;
        2) view_logs ;;
        3) restart_services ;;
        4) stop_services ;;
        5) start_services ;;
        6) view_docker_status ;;
        7) monitor_resources ;;
        8) backup_databases ;;
        9) health_check ;;
        10) security_audit ;;
        11) update_environment ;;
        12) view_service_urls ;;
        13) cleanup_disk ;;
        14) exit 0 ;;
        *) print_error "Invalid option"; show_menu ;;
    esac
}

# View system status
view_status() {
    clear
    print_status "System Status Report"
    echo ""
    
    load_env
    
    echo -e "${CYAN}=== Server Information ===${NC}"
    echo "Hostname: $(hostname)"
    echo "OS: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo ""
    
    echo -e "${CYAN}=== Docker Containers ===${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || print_error "Docker not running"
    echo ""
    
    echo -e "${CYAN}=== Network Interfaces ===${NC}"
    ip addr show | grep "inet " | awk '{print $7 ": " $2}'
    echo ""
    
    echo -e "${CYAN}=== VPS Configuration ===${NC}"
    echo "VPS IP: $VPS_IP"
    echo "API URL: http://$VPS_IP:3000"
    echo "Admin URL: http://$VPS_IP:3001"
    echo "Driver URL: http://$VPS_IP:3002"
    echo "Customer URL: http://$VPS_IP:3003"
    echo "Status Dashboard: http://$VPS_IP:8080"
    echo ""
    
    read -r -p "Press Enter to continue..."
    show_menu
}

# View container logs
view_logs() {
    clear
    print_status "Select Container for Logs"
    echo ""
    
    docker ps --format "{{.Names}}" | nl
    echo ""
    read -r -p "Enter container number: " container_num
    
    container=$(docker ps --format "{{.Names}}" | sed -n "${container_num}p")
    if [ -z "$container" ]; then
        print_error "Invalid selection"
    else
        print_status "Logs for $container (last 100 lines):"
        docker logs --tail 100 -f "$container"
    fi
    
    show_menu
}

# Restart services
restart_services() {
    if [ ! -f "$CONFIG_DIR/docker-compose.yml" ]; then
        print_error "docker-compose.yml not found"
        show_menu
        return
    fi
    
    print_status "Restarting all services..."
    cd "$CONFIG_DIR"
    
    load_env
    docker-compose restart
    
    print_success "Services restarted"
    sleep 5
    show_menu
}

# Stop all services
stop_services() {
    print_warning "This will stop all services. Continue? (y/N)"
    read -r -p "" confirm
    
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        print_status "Stopping services..."
        cd "$CONFIG_DIR"
        docker-compose down
        print_success "Services stopped"
    else
        print_info "Cancelled"
    fi
    
    sleep 2
    show_menu
}

# Start all services
start_services() {
    if [ ! -f "$CONFIG_DIR/docker-compose.yml" ]; then
        print_error "docker-compose.yml not found"
        show_menu
        return
    fi
    
    print_status "Starting services..."
    cd "$CONFIG_DIR"
    
    load_env
    docker-compose up -d
    
    sleep 10
    print_success "Services started"
    show_menu
}

# View Docker status
view_docker_status() {
    clear
    print_status "Docker Status"
    echo ""
    
    echo -e "${CYAN}=== Docker Version ===${NC}"
    docker --version
    docker-compose --version
    echo ""
    
    echo -e "${CYAN}=== Running Containers ===${NC}"
    docker ps
    echo ""
    
    echo -e "${CYAN}=== Stopped Containers ===${NC}"
    docker ps -a --filter "status=exited"
    echo ""
    
    echo -e "${CYAN}=== Docker Images ===${NC}"
    docker images
    echo ""
    
    echo -e "${CYAN}=== Docker Networks ===${NC}"
    docker network ls
    echo ""
    
    echo -e "${CYAN}=== Docker Volumes ===${NC}"
    docker volume ls
    echo ""
    
    read -r -p "Press Enter to continue..."
    show_menu
}

# Monitor system resources
monitor_resources() {
    clear
    print_status "System Resources (Press Ctrl+C to exit)"
    echo ""
    
    watch -n 1 'echo "=== CPU & Memory ===" && free -h && echo "" && echo "=== Disk Space ===" && df -h && echo "" && docker stats --no-stream'
}

# Backup databases
backup_databases() {
    clear
    print_status "Backing up databases..."
    
    BACKUP_DIR="$PROJECT_ROOT/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    load_env
    
    # PostgreSQL backup
    if docker ps --filter "name=taxi-postgres" --format '{{.Names}}' | grep -q "taxi-postgres"; then
        print_status "Backing up PostgreSQL..."
        docker exec taxi-postgres pg_dump -U taxi_admin taxi_db > "$BACKUP_DIR/postgres_backup.sql"
        print_success "PostgreSQL backup created"
    fi
    
    # MongoDB backup
    if docker ps --filter "name=taxi-mongo" --format '{{.Names}}' | grep -q "taxi-mongo"; then
        print_status "Backing up MongoDB..."
        docker exec taxi-mongo mongodump --archive > "$BACKUP_DIR/mongo_backup.archive"
        print_success "MongoDB backup created"
    fi
    
    print_success "All backups saved to: $BACKUP_DIR"
    read -r -p "Press Enter to continue..."
    show_menu
}

# Health check
health_check() {
    clear
    print_status "Running Health Check..."
    echo ""
    
    load_env
    
    local healthy=0
    local total=7
    
    # Check services
    services=("taxi-api" "taxi-admin" "taxi-driver" "taxi-customer" "taxi-postgres" "taxi-mongo" "taxi-redis")
    
    for service in "${services[@]}"; do
        if docker ps --filter "name=$service" --format '{{.Names}}' | grep -q "$service"; then
            print_success "$service is running"
            ((healthy++))
        else
            print_error "$service is NOT running"
        fi
    done
    
    echo ""
    echo -e "${CYAN}Health Status: ${GREEN}$healthy/$total${NC} services running"
    
    if [ $healthy -eq $total ]; then
        echo -e "${GREEN}✓ System is healthy${NC}"
    else
        echo -e "${YELLOW}⚠ System has issues${NC}"
    fi
    
    echo ""
    read -r -p "Press Enter to continue..."
    show_menu
}

# Security audit
security_audit() {
    clear
    print_status "Security Audit"
    echo ""
    
    echo -e "${CYAN}=== Open Ports ===${NC}"
    netstat -tuln | grep LISTEN || ss -tuln | grep LISTEN
    echo ""
    
    echo -e "${CYAN}=== Firewall Status ===${NC}"
    if command -v ufw &> /dev/null; then
        ufw status
    else
        print_info "UFW not available"
    fi
    echo ""
    
    echo -e "${CYAN}=== Running Processes ===${NC}"
    ps aux --sort=-%mem | head -10
    echo ""
    
    read -r -p "Press Enter to continue..."
    show_menu
}

# Update environment
update_environment() {
    clear
    print_status "Update Environment Configuration"
    echo ""
    
    load_env
    
    read -r -p "Enter new VPS IP (current: $VPS_IP): " new_ip
    if [ -n "$new_ip" ]; then
        sed -i "s/^VPS_IP=.*/VPS_IP=$new_ip/" "$CONFIG_DIR/.env"
        print_success "VPS IP updated"
    fi
    
    read -r -p "Enter new API Port (current: 3000): " new_port
    if [ -n "$new_port" ]; then
        sed -i "s/^API_PORT=.*/API_PORT=$new_port/" "$CONFIG_DIR/.env"
        print_success "API Port updated"
    fi
    
    print_info "Configuration updated. Restart services to apply changes."
    read -r -p "Press Enter to continue..."
    show_menu
}

# View service URLs
view_service_urls() {
    clear
    print_status "Service URLs"
    echo ""
    
    load_env
    
    echo -e "${GREEN}Web Interfaces:${NC}"
    echo "  • Admin Dashboard:   http://$VPS_IP:3001"
    echo "  • Driver Portal:     http://$VPS_IP:3002"
    echo "  • Customer App:      http://$VPS_IP:3003"
    echo ""
    
    echo -e "${GREEN}API Server:${NC}"
    echo "  • Base URL:          http://$VPS_IP:3000"
    echo ""
    
    echo -e "${GREEN}Monitoring:${NC}"
    echo "  • Status Dashboard:  http://$VPS_IP:8080"
    echo ""
    
    echo -e "${GREEN}Databases:${NC}"
    echo "  • PostgreSQL:        $VPS_IP:5432"
    echo "  • MongoDB:           $VPS_IP:27017"
    echo "  • Redis:             $VPS_IP:6379"
    echo ""
    
    read -r -p "Press Enter to continue..."
    show_menu
}

# Cleanup disk space
cleanup_disk() {
    clear
    print_status "Disk Cleanup"
    echo ""
    
    print_warning "This will remove dangling images and volumes. Continue? (y/N)"
    read -r -p "" confirm
    
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        print_status "Cleaning up Docker..."
        docker system prune -af
        print_success "Cleanup complete"
    else
        print_info "Cancelled"
    fi
    
    read -r -p "Press Enter to continue..."
    show_menu
}

# Main
main() {
    if [ $# -eq 0 ]; then
        show_menu
    else
        case "$1" in
            status) view_status ;;
            logs) view_logs ;;
            restart) restart_services ;;
            stop) stop_services ;;
            start) start_services ;;
            health) health_check ;;
            backup) backup_databases ;;
            urls) view_service_urls ;;
            *)
                print_error "Unknown command: $1"
                echo "Available commands: status, logs, restart, stop, start, health, backup, urls"
                exit 1
                ;;
        esac
    fi
}

main "$@"
