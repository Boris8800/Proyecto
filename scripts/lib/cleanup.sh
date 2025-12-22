#!/bin/bash
# lib/cleanup.sh - System cleanup and maintenance functions
# Part of the modularized Taxi System installer

# Source dependencies
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ===================== CLEANUP AND MAINTENANCE FUNCTIONS =====================

cleanup_temp_files() {
    log_step "Performing complete system cleanup..."
    
    # Limpiar archivos temporales
    log_info "Removing temporary files..."
    rm -rf /tmp/taxi-* 2>/dev/null || true
    rm -rf /tmp/*.tmp 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    # Limpiar cache de paquetes
    log_info "Clearing package manager cache..."
    apt-get clean >/dev/null 2>&1 || true
    apt-get autoclean >/dev/null 2>&1 || true
    apt-get autoremove -y >/dev/null 2>&1 || true
    
    # Limpiar logs antiguos
    log_info "Removing old log files..."
    find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null || true
    find /var/log -type f -name "*.gz" -mtime +30 -delete 2>/dev/null || true
    
    # Limpiar Docker
    log_info "Cleaning up Docker resources..."
    docker container prune -f >/dev/null 2>&1 || true
    docker image prune -f >/dev/null 2>&1 || true
    docker volume prune -f >/dev/null 2>&1 || true
    
    # Limpiar directorios de caché
    log_info "Clearing application caches..."
    rm -rf /root/.cache/* 2>/dev/null || true
    rm -rf /home/taxi/.cache/* 2>/dev/null || true
    
    log_ok "System cleanup completed"
}

cleanup_system() {
    log_step "Cleaning up system..."
    
    log_info "Removing temporary files..."
    rm -rf /tmp/taxi-* 2>/dev/null || true
    
    log_info "Clearing package manager cache..."
    apt-get clean >/dev/null 2>&1
    apt-get autoclean >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    
    log_info "Removing old log files..."
    find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null || true
    
    log_ok "System cleanup completed"
}

cleanup_docker() {
    log_step "Cleaning up Docker..."
    
    log_info "Removing stopped containers..."
    docker container prune -f >/dev/null 2>&1
    
    log_info "Removing unused images..."
    docker image prune -f --filter "dangling=true" >/dev/null 2>&1
    
    log_info "Removing unused volumes..."
    docker volume prune -f >/dev/null 2>&1
    
    log_info "Removing unused networks..."
    docker network prune -f >/dev/null 2>&1
    
    log_ok "Docker cleanup completed"
}

clear_ports() {
    log_step "Clearing ports..."
    
    local ports=(80 443 3000 3001 3002 3003 5432 27017 6379 9000 19999)
    
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            log_info "Port $port is in use. Attempting to clear..."
            kill_port "$port"
        fi
    done
    
    log_ok "Ports cleared"
}

kill_services() {
    log_step "Stopping taxi services..."
    
    log_info "Stopping Docker Compose services..."
    if [ -f "docker-compose.yml" ]; then
        docker-compose down >/dev/null 2>&1
        log_ok "Docker Compose services stopped"
    fi
    
    log_info "Stopping system services..."
    systemctl stop nginx >/dev/null 2>&1 || true
    systemctl stop apache2 >/dev/null 2>&1 || true
    systemctl stop haproxy >/dev/null 2>&1 || true
    systemctl stop docker >/dev/null 2>&1 || true
    
    sleep 2
    log_ok "Services stopped"
}

full_cleanup() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           🧹 FULL SYSTEM CLEANUP AND RESET${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: This will remove all Taxi System data and containers!${NC}"
    echo -e "${YELLOW}This action cannot be undone.${NC}"
    echo ""
    
    read -r -p "Type 'yes' to confirm cleanup and reset: " confirm
    
    if [ "$confirm" != "yes" ]; then
        log_info "Cleanup cancelled"
        return 0
    fi
    
    log_step "Starting full system cleanup..."
    
    # Stop all services
    log_info "Stopping all services..."
    kill_services
    
    # Remove containers and volumes
    log_info "Removing Docker containers and volumes..."
    docker-compose down -v 2>/dev/null || true
    docker container prune -fa 2>/dev/null || true
    docker volume prune -fa 2>/dev/null || true
    
    # Reset directories
    log_info "Resetting data directories..."
    rm -rf /home/taxi/data/* 2>/dev/null || true
    rm -rf /home/taxi/logs/* 2>/dev/null || true
    rm -rf /home/taxi/backups/* 2>/dev/null || true
    
    # Clear Nginx configuration
    log_info "Resetting Nginx configuration..."
    rm -rf /etc/nginx/sites-enabled/* 2>/dev/null || true
    rm -rf /etc/nginx/sites-available/* 2>/dev/null || true
    
    # System cleanup
    cleanup_system
    cleanup_docker
    
    echo ""
    echo -e "${GREEN}✅ Full system cleanup completed!${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

remove_installation() {
    log_step "Removing Taxi System installation..."
    
    log_info "Removing application directory..."
    rm -rf /home/taxi 2>/dev/null || true
    
    log_info "Removing system user..."
    userdel -r taxi 2>/dev/null || true
    
    log_info "Removing Docker images..."
    docker rmi taxi-app:latest 2>/dev/null || true
    docker rmi taxi-dashboard:latest 2>/dev/null || true
    
    log_ok "Installation removed"
}

health_check() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           ❤️  SYSTEM HEALTH CHECK${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local healthy=0
    local warnings=0
    local errors=0
    
    # Check disk space
    echo -n "Checking disk space... "
    local available_gb
    available_gb=$(df /home | awk 'NR==2 {print int($4/1024/1024)}')
    if [ "$available_gb" -gt 5 ]; then
        echo -e "${GREEN}✅ OK (${available_gb}GB available)${NC}"
        healthy=$((healthy + 1))
    elif [ "$available_gb" -gt 2 ]; then
        echo -e "${YELLOW}⚠️  WARNING (${available_gb}GB available)${NC}"
        warnings=$((warnings + 1))
    else
        echo -e "${RED}❌ ERROR (${available_gb}GB available)${NC}"
        errors=$((errors + 1))
    fi
    
    # Check memory
    echo -n "Checking memory... "
    local available_mem
    available_mem=$(free -m | awk 'NR==2 {print int($7)}')
    if [ "$available_mem" -gt 1000 ]; then
        echo -e "${GREEN}✅ OK (${available_mem}MB free)${NC}"
        healthy=$((healthy + 1))
    elif [ "$available_mem" -gt 500 ]; then
        echo -e "${YELLOW}⚠️  WARNING (${available_mem}MB free)${NC}"
        warnings=$((warnings + 1))
    else
        echo -e "${RED}❌ ERROR (${available_mem}MB free)${NC}"
        errors=$((errors + 1))
    fi
    
    # Check CPU load
    echo -n "Checking CPU load... "
    local cpu_load
    cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
    echo -e "${GREEN}✅ Load average: ${cpu_load}${NC}"
    healthy=$((healthy + 1))
    
    # Check Docker
    echo -n "Checking Docker... "
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}✅ Running${NC}"
        healthy=$((healthy + 1))
    else
        echo -e "${RED}❌ Not running${NC}"
        errors=$((errors + 1))
    fi
    
    # Check Nginx
    echo -n "Checking Nginx... "
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}✅ Running${NC}"
        healthy=$((healthy + 1))
    else
        echo -e "${YELLOW}⚠️  Not running${NC}"
        warnings=$((warnings + 1))
    fi
    
    # Check key services
    echo -n "Checking PostgreSQL... "
    if docker ps --filter name=taxi-postgres --filter status=running | grep -q taxi-postgres; then
        echo -e "${GREEN}✅ Running${NC}"
        healthy=$((healthy + 1))
    else
        echo -e "${YELLOW}⚠️  Not running${NC}"
        warnings=$((warnings + 1))
    fi
    
    echo ""
    echo -e "${CYAN}Summary: ${GREEN}${healthy} healthy${NC}, ${YELLOW}${warnings} warnings${NC}, ${RED}${errors} errors${NC}${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ $errors -gt 0 ]; then
        return 1
    fi
    return 0
}

log_rotation() {
    log_step "Setting up log rotation..."
    
    cat > /etc/logrotate.d/taxi-system << 'EOF'
/home/taxi/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 taxi taxi
    sharedscripts
    postrotate
        systemctl reload nginx > /dev/null 2>&1 || true
    endscript
}
EOF
    
    log_ok "Log rotation configured"
}

monitor_system() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           📊 REAL-TIME SYSTEM MONITORING${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    while true; do
        clear
        
        echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}           📊 TAXI SYSTEM MONITORING${NC}"
        echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        
        # System Resources
        echo -e "${BLUE}System Resources:${NC}"
        echo "  Memory: $(free -h | awk 'NR==2 {print $3 " / " $2}')"
        echo "  CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
        echo "  Disk: $(df -h /home | awk 'NR==2 {print $3 " / " $2 " (" $5 " used)"}')"
        echo ""
        
        # Container Status
        echo -e "${BLUE}Docker Containers:${NC}"
        docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | tail -n +2 | while read -r name status; do
            if [[ "$status" == *"Up"* ]]; then
                echo -e "  ${GREEN}✅${NC} $name ($status)"
            else
                echo -e "  ${RED}❌${NC} $name ($status)"
            fi
        done || echo "  No containers running"
        echo ""
        
        # Service Ports
        echo -e "${BLUE}Active Ports:${NC}"
        echo "  Dashboards:"
        lsof -i :3000 2>/dev/null && echo -e "    ${GREEN}✅${NC} 3000 (API Gateway)" || echo -e "    ${RED}❌${NC} 3000"
        lsof -i :3001 2>/dev/null && echo -e "    ${GREEN}✅${NC} 3001 (Admin)" || echo -e "    ${RED}❌${NC} 3001"
        lsof -i :3002 2>/dev/null && echo -e "    ${GREEN}✅${NC} 3002 (Driver)" || echo -e "    ${RED}❌${NC} 3002"
        lsof -i :3003 2>/dev/null && echo -e "    ${GREEN}✅${NC} 3003 (Customer)" || echo -e "    ${RED}❌${NC} 3003"
        echo "  Databases:"
        lsof -i :5432 2>/dev/null && echo -e "    ${GREEN}✅${NC} 5432 (PostgreSQL)" || echo -e "    ${RED}❌${NC} 5432"
        lsof -i :27017 2>/dev/null && echo -e "    ${GREEN}✅${NC} 27017 (MongoDB)" || echo -e "    ${RED}❌${NC} 27017"
        lsof -i :6379 2>/dev/null && echo -e "    ${GREEN}✅${NC} 6379 (Redis)" || echo -e "    ${RED}❌${NC} 6379"
        echo ""
        
        echo -e "${CYAN}Press Ctrl+C to exit | Press Enter to refresh${NC}"
        read -t 5 -r || true
    done
}
