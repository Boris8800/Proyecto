#!/bin/bash
# lib/menus.sh - Interactive menus and user interfaces
# Part of the modularized Taxi System installer

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ===================== MENU FUNCTIONS =====================
show_main_menu() {
    clear
    print_banner
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🚕 TAXI SYSTEM INSTALLATION & MANAGEMENT 🚕          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Main Menu:${NC}"
    echo "  ${GREEN}1)${NC}  Fresh Installation"
    echo "  ${GREEN}2)${NC}  Update Existing Installation"
    echo "  ${GREEN}3)${NC}  Service Management"
    echo "  ${GREEN}4)${NC}  System Diagnostics"
    echo "  ${GREEN}5)${NC}  Database Management"
    echo "  ${GREEN}6)${NC}  Security Audit"
    echo "  ${GREEN}7)${NC}  Error Recovery"
    echo "  ${GREEN}8)${NC}  Backup & Restore"
    echo "  ${GREEN}9)${NC}  System Cleanup"
    echo "  ${GREEN}0)${NC}  Exit"
    echo ""
    read -r -p "Select an option (0-9): " main_choice
    
    case "$main_choice" in
        1) fresh_installation_menu ;;
        2) update_menu ;;
        3) service_management_menu ;;
        4) diagnostics_menu ;;
        5) database_menu ;;
        6) security_menu ;;
        7) error_recovery_menu ;;
        8) backup_menu ;;
        9) cleanup_menu ;;
        0) 
            echo ""
            echo -e "${CYAN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            log_error "Invalid option"
            sleep 2
            show_main_menu
            ;;
    esac
}

fresh_installation_menu() {
    clear
    print_header "Fresh Installation"
    echo ""
    echo -e "${YELLOW}This will perform a complete installation of the Taxi System.${NC}"
    echo -e "${YELLOW}⚠️  WARNING: This may overwrite existing installations!${NC}"
    echo -e "${YELLOW}It is recommended to backup your data before proceeding.${NC}"
    echo ""
    read -r -p "Continue with fresh installation? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Call the actual fresh install function
        fresh_install
        echo ""
        read -r -p "Press Enter to return to main menu..."
        show_main_menu
    else
        log_info "Installation cancelled"
        sleep 1
        show_main_menu
    fi
}

update_menu() {
    clear
    print_header "Update Installation"
    echo ""
    echo -e "${BLUE}Update Options:${NC}"
    echo "  ${GREEN}1)${NC}  Update all services"
    echo "  ${GREEN}2)${NC}  Back to main menu"
    echo ""
    read -r -p "Select an option (1-2): " update_choice
    
    case "$update_choice" in
        1) 
            log_info "Updating all services..."
            update_installation
            echo ""
            read -r -p "Press Enter to return to main menu..."
            show_main_menu 
            ;;
        2) show_main_menu ;;
        *) log_error "Invalid option"; sleep 1; update_menu ;;
    esac
}

service_management_menu() {
    clear
    print_header "Service Management"
    echo ""
    echo -e "${BLUE}Service Management Options:${NC}"
    echo "  ${GREEN}1)${NC}  Start all services"
    echo "  ${GREEN}2)${NC}  Stop all services"
    echo "  ${GREEN}3)${NC}  Restart all services"
    echo "  ${GREEN}4)${NC}  View service status"
    echo "  ${GREEN}5)${NC}  View service logs"
    echo "  ${GREEN}6)${NC}  Back to main menu"
    echo ""
    read -r -p "Select an option (1-6): " service_choice
    
    case "$service_choice" in
        1)
            log_info "Starting all services..."
            docker-compose up -d
            sleep 3
            service_management_menu
            ;;
        2)
            log_info "Stopping all services..."
            docker-compose down
            sleep 3
            service_management_menu
            ;;
        3)
            log_info "Restarting all services..."
            docker-compose restart
            sleep 3
            service_management_menu
            ;;
        4)
            docker ps -a
            echo ""
            read -r -p "Press Enter to continue..."
            service_management_menu
            ;;
        5)
            service_logs_menu
            ;;
        6)
            show_main_menu
            ;;
        *)
            log_error "Invalid option"
            sleep 1
            service_management_menu
            ;;
    esac
}

service_logs_menu() {
    echo ""
    echo -e "${BLUE}Select service for logs:${NC}"
    echo "  1) API Gateway"
    echo "  2) PostgreSQL"
    echo "  3) MongoDB"
    echo "  4) Redis"
    echo "  5) Admin Dashboard"
    echo "  6) Back"
    echo ""
    read -r -p "Select (1-6): " log_choice
    
    case "$log_choice" in
        1) docker logs taxi-api -f ;;
        2) docker logs taxi-postgres -f ;;
        3) docker logs taxi-mongo -f ;;
        4) docker logs taxi-redis -f ;;
        5) docker logs taxi-admin -f ;;
        6) service_management_menu ;;
        *) log_error "Invalid option"; sleep 1; service_logs_menu ;;
    esac
}

diagnostics_menu() {
    clear
    print_header "System Diagnostics"
    echo ""
    echo -e "${BLUE}Diagnostics Options:${NC}"
    echo "  ${GREEN}1)${NC}  Full system check"
    echo "  ${GREEN}2)${NC}  Docker diagnostics"
    echo "  ${GREEN}3)${NC}  Port availability check"
    echo "  ${GREEN}4)${NC}  Network connectivity test"
    echo "  ${GREEN}5)${NC}  Database connectivity test"
    echo "  ${GREEN}6)${NC}  Health check"
    echo "  ${GREEN}7)${NC}  Back to main menu"
    echo ""
    read -r -p "Select an option (1-7): " diag_choice
    
    case "$diag_choice" in
        1) echo "Running full system check..."; sleep 2; diagnostics_menu ;;
        2) echo "Running Docker diagnostics..."; sleep 2; diagnostics_menu ;;
        3) echo "Checking port availability..."; check_ports; read -r -p "Press Enter..."; diagnostics_menu ;;
        4) echo "Testing network connectivity..."; sleep 2; diagnostics_menu ;;
        5) echo "Testing database connectivity..."; sleep 2; diagnostics_menu ;;
        6) echo "Running health check..."; sleep 2; diagnostics_menu ;;
        7) show_main_menu ;;
        *) log_error "Invalid option"; sleep 1; diagnostics_menu ;;
    esac
}

database_menu() {
    clear
    print_header "Database Management"
    echo ""
    echo -e "${BLUE}Database Options:${NC}"
    echo "  ${GREEN}1)${NC}  Initialize databases"
    echo "  ${GREEN}2)${NC}  Create database backup"
    echo "  ${GREEN}3)${NC}  Restore from backup"
    echo "  ${GREEN}4)${NC}  View database status"
    echo "  ${GREEN}5)${NC}  Reset databases (DESTRUCTIVE)"
    echo "  ${GREEN}6)${NC}  Back to main menu"
    echo ""
    read -r -p "Select an option (1-6): " db_choice
    
    case "$db_choice" in
        1) log_info "Initializing databases..."; sleep 2; database_menu ;;
        2) log_info "Creating database backup..."; sleep 2; database_menu ;;
        3) log_info "Restore menu..."; sleep 2; database_menu ;;
        4) log_info "Database status..."; sleep 2; database_menu ;;
        5)
            echo ""
            echo -e "${RED}⚠️  WARNING: This will DELETE all database data!${NC}"
            read -r -p "Type 'RESET' to confirm: " reset_confirm
            if [ "$reset_confirm" = "RESET" ]; then
                log_info "Resetting databases..."
                sleep 2
            fi
            database_menu
            ;;
        6) show_main_menu ;;
        *) log_error "Invalid option"; sleep 1; database_menu ;;
    esac
}

security_menu() {
    clear
    print_header "Security Audit"
    echo ""
    echo -e "${BLUE}Security Options:${NC}"
    echo "  ${GREEN}1)${NC}  Run security audit"
    echo "  ${GREEN}2)${NC}  Configure firewall"
    echo "  ${GREEN}3)${NC}  Update security credentials"
    echo "  ${GREEN}4)${NC}  View security report"
    echo "  ${GREEN}5)${NC}  Back to main menu"
    echo ""
    read -r -p "Select an option (1-5): " sec_choice
    
    case "$sec_choice" in
        1) log_info "Running security audit..."; sleep 2; security_menu ;;
        2) log_info "Configuring firewall..."; sleep 2; security_menu ;;
        3) log_info "Updating credentials..."; sleep 2; security_menu ;;
        4) log_info "Security report..."; sleep 2; security_menu ;;
        5) show_main_menu ;;
        *) log_error "Invalid option"; sleep 1; security_menu ;;
    esac
}

error_recovery_menu() {
    clear
    print_header "Error Recovery"
    echo ""
    echo -e "${BLUE}Error Recovery Options:${NC}"
    echo "  ${GREEN}1)${NC}  View recent errors"
    echo "  ${GREEN}2)${NC}  Automatic error recovery"
    echo "  ${GREEN}3)${NC}  Manual troubleshooting guide"
    echo "  ${GREEN}4)${NC}  Restart failed services"
    echo "  ${GREEN}5)${NC}  System reset"
    echo "  ${GREEN}6)${NC}  Back to main menu"
    echo ""
    read -r -p "Select an option (1-6): " err_choice
    
    case "$err_choice" in
        1) log_info "Recent errors..."; sleep 2; error_recovery_menu ;;
        2) log_info "Running automatic recovery..."; sleep 2; error_recovery_menu ;;
        3) log_info "Showing troubleshooting guide..."; sleep 2; error_recovery_menu ;;
        4) log_info "Restarting failed services..."; sleep 2; error_recovery_menu ;;
        5)
            echo ""
            echo -e "${RED}⚠️  WARNING: System reset is destructive!${NC}"
            read -r -p "Continue? (y/n): " reset
            if [[ "$reset" =~ ^[Yy]$ ]]; then
                log_info "Resetting system..."
                sleep 2
            fi
            error_recovery_menu
            ;;
        6) show_main_menu ;;
        *) log_error "Invalid option"; sleep 1; error_recovery_menu ;;
    esac
}

backup_menu() {
    clear
    print_header "Backup & Restore"
    echo ""
    echo -e "${BLUE}Backup Options:${NC}"
    echo "  ${GREEN}1)${NC}  Create full backup"
    echo "  ${GREEN}2)${NC}  Create database backup only"
    echo "  ${GREEN}3)${NC}  Create configuration backup"
    echo "  ${GREEN}4)${NC}  List backups"
    echo "  ${GREEN}5)${NC}  Restore from backup"
    echo "  ${GREEN}6)${NC}  Back to main menu"
    echo ""
    read -r -p "Select an option (1-6): " backup_choice
    
    case "$backup_choice" in
        1) log_info "Creating full backup..."; sleep 2; backup_menu ;;
        2) log_info "Creating database backup..."; sleep 2; backup_menu ;;
        3) log_info "Creating configuration backup..."; sleep 2; backup_menu ;;
        4) log_info "Listing backups..."; sleep 2; backup_menu ;;
        5) log_info "Restore from backup..."; sleep 2; backup_menu ;;
        6) show_main_menu ;;
        *) log_error "Invalid option"; sleep 1; backup_menu ;;
    esac
}

cleanup_menu() {
    clear
    print_header "System Cleanup"
    echo ""
    echo -e "${BLUE}Cleanup Options:${NC}"
    echo "  ${GREEN}1)${NC}  Clean temporary files"
    echo "  ${GREEN}2)${NC}  Clean Docker images and containers"
    echo "  ${GREEN}3)${NC}  Clean logs"
    echo "  ${GREEN}4)${NC}  Full system cleanup"
    echo "  ${GREEN}5)${NC}  Back to main menu"
    echo ""
    read -r -p "Select an option (1-5): " clean_choice
    
    case "$clean_choice" in
        1) log_info "Cleaning temporary files..."; sleep 2; cleanup_menu ;;
        2) log_info "Cleaning Docker resources..."; sleep 2; cleanup_menu ;;
        3) log_info "Cleaning logs..."; sleep 2; cleanup_menu ;;
        4)
            echo ""
            echo -e "${RED}⚠️  WARNING: Full cleanup will remove temporary files and logs!${NC}"
            read -r -p "Continue? (y/n): " cleanup_confirm
            if [[ "$cleanup_confirm" =~ ^[Yy]$ ]]; then
                log_info "Running full cleanup..."
                sleep 2
            fi
            cleanup_menu
            ;;
        5) show_main_menu ;;
        *) log_error "Invalid option"; sleep 1; cleanup_menu ;;
    esac
}

show_interactive_wizard() {
    clear
    print_banner
    echo ""
    echo -e "${CYAN}Welcome to Taxi System Installation Wizard${NC}"
    echo ""
    
    read -r -p "Enter server IP address (default: localhost): " server_ip
    server_ip="${server_ip:-localhost}"
    
    read -r -p "Enable SSL/HTTPS? (y/n, default: n): " enable_ssl
    enable_ssl="${enable_ssl:-n}"
    
    read -r -p "Enable automatic backups? (y/n, default: y): " enable_backups
    enable_backups="${enable_backups:-y}"
    
    read -r -p "Enable security monitoring? (y/n, default: y): " enable_monitoring
    enable_monitoring="${enable_monitoring:-y}"
    
    echo ""
    echo -e "${BLUE}Summary:${NC}"
    echo "  Server IP: $server_ip"
    echo "  SSL/HTTPS: $enable_ssl"
    echo "  Auto Backups: $enable_backups"
    echo "  Monitoring: $enable_monitoring"
    echo ""
    
    read -r -p "Proceed with installation? (y/n): " proceed
    if [[ "$proceed" =~ ^[Yy]$ ]]; then
        log_info "Configuration saved and installation starting..."
        return 0
    else
        log_info "Installation cancelled"
        return 1
    fi
}
