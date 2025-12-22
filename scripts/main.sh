#!/bin/bash
# main.sh - Taxi System Installation Main Entry Point
# Part of the modularized Taxi System installer

set -euo pipefail

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"  # main.sh is in the project root

# Find the web directory (could be in multiple locations)
if [ -d "$PROJECT_ROOT/web" ]; then
    WEB_DIR="$PROJECT_ROOT/web"
elif [ -d "$SCRIPT_DIR/web" ]; then
    WEB_DIR="$SCRIPT_DIR/web"
elif [ -d "/workspaces/Proyecto/web" ]; then
    WEB_DIR="/workspaces/Proyecto/web"
else
    WEB_DIR=""
fi
export WEB_DIR

# Source all library modules
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/validation.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/security.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/docker.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/database.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/cleanup.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/dashboard.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/setup.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/menus.sh"

# ===================== MAIN FUNCTIONS =====================
main() {
    # Check if running as root
    check_root
    
    # Check Ubuntu version
    check_ubuntu
    
    # Parse command-line arguments
    parse_arguments "$@"
}

parse_arguments() {
    # If no arguments provided, show interactive menu
    if [[ $# -eq 0 ]]; then
        show_main_menu
        exit 0
    fi
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fresh)
                fresh_install
                exit 0
                ;;
            --update)
                update_installation
                exit 0
                ;;
            --interactive)
                show_main_menu
                exit 0
                ;;
            --health-check)
                health_check
                exit 0
                ;;
            --security-audit)
                security_audit
                exit 0
                ;;
            --docker-status)
                docker_status
                exit 0
                ;;
            --database-status)
                database_status
                exit 0
                ;;
            --cleanup)
                cleanup_system
                exit 0
                ;;
            --full-cleanup)
                full_cleanup
                exit 0
                ;;
            --monitor)
                monitor_system
                exit 0
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

fresh_install() {
    print_banner
    
    log_step "Starting Taxi System Fresh Installation..."
    
    # Clean the server first
    log_step "Cleaning Ubuntu Server..."
    log_info "Removing old installations, users, and temporary files..."
    
    # Stop and remove existing services
    if command -v systemctl &> /dev/null; then
        systemctl stop docker 2>/dev/null || true
        systemctl stop nginx 2>/dev/null || true
        systemctl stop apache2 2>/dev/null || true
        systemctl stop haproxy 2>/dev/null || true
        systemctl stop taxi-system 2>/dev/null || true
    fi
    pkill -u taxi 2>/dev/null || true
    
    # AGGRESSIVE PRE-CLEANUP: Kill ALL potential port blockers
    log_info "Performing aggressive port cleanup..."
    
    # Stop Docker service first
    if command -v systemctl &> /dev/null; then
        systemctl stop docker 2>/dev/null || true
    fi
    pkill -9 -f "dockerd|docker" 2>/dev/null || true
    
    # Kill all web servers
    if command -v systemctl &> /dev/null; then
        systemctl stop nginx 2>/dev/null || true
        systemctl stop apache2 2>/dev/null || true
        systemctl stop haproxy 2>/dev/null || true
    fi
    pkill -9 -f "nginx|apache2|apache|httpd|http-server|haproxy" 2>/dev/null || true
    
    # Kill all database services
    pkill -9 postgres 2>/dev/null || true
    pkill -9 mongod 2>/dev/null || true
    pkill -9 redis-server 2>/dev/null || true
    pkill -9 node 2>/dev/null || true
    
    # Force release all critical ports
    for port in 80 443 5432 27017 6379 3000 3001 3002 3003; do
        fuser -k "$port/tcp" 2>/dev/null || true
    done
    
    # Remove taxi user and data
    userdel -f taxi 2>/dev/null || true
    groupdel taxi 2>/dev/null || true
    rm -rf /home/taxi 2>/dev/null || true
    rm -rf /var/log/taxi 2>/dev/null || true
    rm -rf /var/lib/taxi 2>/dev/null || true
    
    # Clean Docker
    docker system prune -f 2>/dev/null || true
    docker volume prune -f 2>/dev/null || true
    docker system prune -f --all --volumes 2>/dev/null || true
    
    # LONGER WAIT for system to fully release ports
    log_info "Waiting for system to fully release ports... (5 seconds)"
    sleep 5
    
    # Clean temporary files
    rm -rf /tmp/taxi* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    # Clean cache
    apt-get clean 2>/dev/null || true
    apt-get autoclean 2>/dev/null || true
    
    log_ok "Server cleaned"
    
    # System initialization (create user FIRST before any permission checks)
    log_step "Initializing system..."
    initialize_system
        # Configure Docker mirror first to avoid image pull issues
    log_step "Configuring Docker registry mirror..."
    configure_docker_mirror
    
    # Pre-installation checks
    log_step "Running pre-installation checks..."
    check_internet
    check_space
    check_system_requirements
    check_docker_permissions taxi
    
    # Check and manage ports
    log_step "Checking for port conflicts..."
    if ! bash "${SCRIPT_DIR}/manage-ports.sh" --fix; then
        log_error "Port conflicts could not be resolved"
        echo ""
        echo "Please manually resolve conflicts:"
        echo "  • Stop conflicting services: sudo pkill -9 nginx"
        echo "  • Stop Docker: sudo docker stop \$(sudo docker ps -aq)"
        echo "  • Clean Docker: sudo docker system prune -af"
        echo "  • Check ports: sudo ss -tulpn | grep -E ':(80|443|3000|3001|3002|3003|5432|27017|6379)'"
        echo ""
        return 1
    fi
    
    # Install Docker
    log_step "Installing Docker..."
    install_docker
    install_docker_compose
    setup_docker_permissions taxi
    verify_docker_installation
    
    # Setup security
    log_step "Configuring security..."
    configure_firewall
    save_credentials
        # Start services
    log_step "Starting services..."
    cd "$PROJECT_ROOT" || exit 1
    docker-compose up -d
    
    # Initialize databases
    log_step "Initializing databases..."
    sleep 5  # Wait for containers to start
    initialize_postgresql taxi-postgres
    initialize_mongodb taxi-mongo
    setup_redis taxi-redis
    create_database_schema taxi-postgres
    seed_initial_data taxi-postgres
    
    # Deploy dashboards
    log_step "Deploying dashboards..."
    create_all_dashboards
    deploy_dashboards
    create_nginx_dashboard_config
    
    # Final checks
    log_step "Running final checks..."
    health_check
    system_status
    
    # Cleanup
    log_step "Cleaning up temporary files..."
    cleanup_temp_files
    
    print_success_banner
    
    log_ok "Installation completed successfully!"
    log_info "Next steps:"
    log_info "  • Admin Dashboard: http://localhost:3001"
    log_info "  • Driver Dashboard: http://localhost:3002"
    log_info "  • Customer Dashboard: http://localhost:3003"
    log_info "  • API Gateway: http://localhost:3000"
    log_info ""
    log_info "Run 'sudo bash main.sh --help' for more options"
}

update_installation() {
    print_banner
    
    log_step "Starting Taxi System Update..."
    
    log_info "Pulling latest images..."
    docker-compose pull
    
    log_info "Restarting services..."
    docker-compose up -d
    
    log_ok "Update completed"
}

show_help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║           🚕 TAXI SYSTEM INSTALLATION SCRIPT - HELP 🚕          ║
╚════════════════════════════════════════════════════════════════╝

USAGE:
  sudo bash main.sh [OPTION]

OPTIONS:
  --fresh              Perform fresh installation
  --update             Update existing installation
  --interactive        Start interactive menu (default)
  --health-check       Run system health check
  --security-audit     Run security audit report
  --docker-status      Show Docker status and info
  --database-status    Show database status
  --cleanup            Clean temporary files and Docker resources
  --full-cleanup       Full system cleanup and reset (DESTRUCTIVE)
  --monitor            Start real-time system monitoring
  --help               Show this help message

EXAMPLES:
  # Fresh installation
  sudo bash main.sh --fresh

  # Interactive menu (default)
  sudo bash main.sh

  # Check system health
  sudo bash main.sh --health-check

  # Run security audit
  sudo bash main.sh --security-audit

FEATURES:
  ✓ Complete installation automation
  ✓ Docker containerization
  ✓ PostgreSQL, MongoDB, Redis databases
  ✓ Admin, Driver, Customer dashboards
  ✓ Security hardening and auditing
  ✓ System monitoring and diagnostics
  ✓ Backup and restore capabilities
  ✓ Error recovery tools

REQUIREMENTS:
  • Ubuntu 20.04 or later
  • 8GB+ RAM
  • 50GB+ disk space
  • Root or sudo access
  • Internet connection

DOCUMENTATION:
  For detailed documentation, see:
  • README.md
  • MODULARIZATION_COMPLETE.md
  • WEB_DIRECTORY_FIX.md

EOF
}

print_success_banner() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║         🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉             ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║              Your Taxi System is ready to use!                 ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ===================== EXECUTION =====================
# Set up logging
export LOG_FILE="/var/log/taxi-system-install.log"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Run main function with all arguments
main "$@"
