#!/bin/bash
# main.sh - Taxi System Installation Main Entry Point
# Part of the modularized Taxi System installer

set -euo pipefail

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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
    
    # No arguments - show interactive menu
    if [ $# -eq 0 ]; then
        show_main_menu
    fi
}

fresh_install() {
    print_banner
    
    log_step "Starting Taxi System Fresh Installation..."
    
    # Configure Docker mirror first to avoid image pull issues
    log_step "Configuring Docker registry mirror..."
    configure_docker_mirror
    
    # Pre-installation checks
    log_step "Running pre-installation checks..."
    check_internet
    check_space
    check_system_requirements
    check_docker_permissions taxi
    
    # System initialization
    log_step "Initializing system..."
    initialize_system
    
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
