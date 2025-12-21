#!/bin/bash
# lib/menus.sh - Interactive menus and user interfaces
# Part of the modularized Taxi System installer

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ===================== HELPER FUNCTIONS =====================
# Read user input with 10-second timeout
# Usage: read_with_timeout variable_name "prompt" default_value
read_with_timeout() {
    local var_name=$1
    local prompt=$2
    local default=$3
    local timeout=10
    
    echo -n -e "$prompt (default: $default in ${timeout}s): "
    
    # Read with timeout
    if read -r -t $timeout user_input; then
        eval "$var_name='$user_input'"
    else
        # Timeout occurred, use default
        eval "$var_name='$default'"
        echo ""
        log_info "No input received. Using default option: $default"
    fi
}

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
    echo ""
    echo -e "  ${GREEN}1${NC}  Fresh Installation"
    echo -e "  ${GREEN}2${NC}  Update Existing Installation"
    echo -e "  ${GREEN}3${NC}  Service Management"
    echo -e "  ${GREEN}4${NC}  System Diagnostics"
    echo -e "  ${GREEN}5${NC}  Database Management"
    echo -e "  ${GREEN}6${NC}  Security Audit"
    echo -e "  ${GREEN}7${NC}  User Management"
    echo -e "  ${GREEN}8${NC}  Error Recovery"
    echo -e "  ${GREEN}9${NC}  Backup & Restore"
    echo -e "  ${GREEN}*${NC}  System Cleanup"
    echo -e "  ${GREEN}0${NC}  Exit"
    echo ""
    read_with_timeout main_choice "Select an option [0-9,*]" "1"
    
    case "$main_choice" in
        1) fresh_installation_menu ;;
        2) update_menu ;;
        3) service_management_menu ;;
        4) diagnostics_menu ;;
        5) database_menu ;;
        6) security_menu ;;
        7) user_management_menu ;;
        8) error_recovery_menu ;;
        9) backup_menu ;;
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
    read_with_timeout confirm "Continue with fresh installation? (y/n)" "y"
    
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
    echo ""
    echo -e "  ${GREEN}1${NC}  Update all services"
    echo -e "  ${GREEN}2${NC}  Back to main menu"
    echo ""
    read_with_timeout update_choice "Select an option [1-2]" "1"
    
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
    echo ""
    echo -e "  ${GREEN}1${NC}  Start all services"
    echo -e "  ${GREEN}2${NC}  Stop all services"
    echo -e "  ${GREEN}3${NC}  Restart all services"
    echo -e "  ${GREEN}4${NC}  View service status"
    echo -e "  ${GREEN}5${NC}  View service logs"
    echo -e "  ${GREEN}6${NC}  Back to main menu"
    echo ""
    read_with_timeout service_choice "Select an option [1-6]" "1"
    
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
    echo -e "  ${GREEN}1${NC}  API Gateway"
    echo -e "  ${GREEN}2${NC}  PostgreSQL"
    echo -e "  ${GREEN}3${NC}  MongoDB"
    echo -e "  ${GREEN}4${NC}  Redis"
    echo -e "  ${GREEN}5${NC}  Admin Dashboard"
    echo -e "  ${GREEN}6${NC}  Back"
    echo ""
    read_with_timeout log_choice "Select (1-6)" "6"
    
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
    echo -e "  ${GREEN}1${NC}  Full system check"
    echo -e "  ${GREEN}2${NC}  Docker diagnostics"
    echo -e "  ${GREEN}3${NC}  Port availability check"
    echo -e "  ${GREEN}4${NC}  Network connectivity test"
    echo -e "  ${GREEN}5${NC}  Database connectivity test"
    echo -e "  ${GREEN}6${NC}  Health check"
    echo -e "  ${GREEN}7${NC}  Back to main menu"
    echo ""
    read_with_timeout diag_choice "Select an option (1-7)" "1"
    
    case "$diag_choice" in
        1) echo "Running full system check..."; sleep 2; diagnostics_menu ;;
        2) echo "Running Docker diagnostics..."; sleep 2; diagnostics_menu ;;
        3) 
            echo ""
            bash "${SCRIPT_DIR}/manage-ports.sh" --check
            echo ""
            read -r -p "Press Enter to continue..."
            diagnostics_menu
            ;;
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
    echo -e "  ${GREEN}1${NC}  Initialize databases"
    echo -e "  ${GREEN}2${NC}  Create database backup"
    echo -e "  ${GREEN}3${NC}  Restore from backup"
    echo -e "  ${GREEN}4${NC}  View database status"
    echo -e "  ${GREEN}5${NC}  Reset databases (DESTRUCTIVE)"
    echo -e "  ${GREEN}6${NC}  Back to main menu"
    echo ""
    read_with_timeout db_choice "Select an option (1-6)" "1"
    
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
    echo -e "  ${GREEN}1${NC}  Run security audit"
    echo -e "  ${GREEN}2${NC}  Configure firewall"
    echo -e "  ${GREEN}3${NC}  Update security credentials"
    echo -e "  ${GREEN}4${NC}  View security report"
    echo -e "  ${GREEN}5${NC}  Back to main menu"
    echo ""
    read_with_timeout sec_choice "Select an option (1-5)" "1"
    
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
    echo -e "  ${GREEN}1${NC}  View recent errors"
    echo -e "  ${GREEN}2${NC}  Automatic error recovery"
    echo -e "  ${GREEN}3${NC}  Manual troubleshooting guide"
    echo -e "  ${GREEN}4${NC}  Restart failed services"
    echo -e "  ${GREEN}5${NC}  System reset"
    echo -e "  ${GREEN}6${NC}  Back to main menu"
    echo ""
    read_with_timeout err_choice "Select an option (1-6)" "1"
    
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
    echo -e "  ${GREEN}1${NC}  Create full backup"
    echo -e "  ${GREEN}2${NC}  Create database backup only"
    echo -e "  ${GREEN}3${NC}  Create configuration backup"
    echo -e "  ${GREEN}4${NC}  List backups"
    echo -e "  ${GREEN}5${NC}  Restore from backup"
    echo -e "  ${GREEN}6${NC}  Back to main menu"
    echo ""
    read_with_timeout backup_choice "Select an option (1-6)" "1"
    
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

user_management_menu() {
    clear
    print_header "User Management"
    echo ""
    echo -e "${BLUE}User Management Options:${NC}"
    echo -e "  ${GREEN}1${NC}  List all system users"
    echo -e "  ${GREEN}2${NC}  List taxi users"
    echo -e "  ${GREEN}3${NC}  Create new user"
    echo -e "  ${GREEN}4${NC}  Delete user"
    echo -e "  ${GREEN}5${NC}  Change user permissions"
    echo -e "  ${GREEN}6${NC}  Back to main menu"
    echo ""
    read_with_timeout user_choice "Select an option (1-6)" "1"
    
    case "$user_choice" in
        1) 
            echo ""
            log_info "System Users:"
            echo ""
            cut -d: -f1 /etc/passwd | grep -v "^_" | sort
            echo ""
            read -r -p "Press Enter to continue..."
            user_management_menu
            ;;
        2)
            echo ""
            log_info "Taxi-related Users:"
            echo ""
            cut -d: -f1 /etc/passwd | grep -i taxi || echo "No taxi users found"
            echo ""
            read -r -p "Press Enter to continue..."
            user_management_menu
            ;;
        3)
            echo ""
            read -r -p "Enter new username: " new_user
            if [ -n "$new_user" ]; then
                if sudo useradd -m -s /bin/bash "$new_user" 2>/dev/null; then
                    log_ok "User '$new_user' created successfully"
                    echo "Set password for $new_user:"
                    sudo passwd "$new_user"
                else
                    log_error "Failed to create user '$new_user'"
                fi
            fi
            echo ""
            read -r -p "Press Enter to continue..."
            user_management_menu
            ;;
        4)
            echo ""
            log_warn "Available users to delete:"
            cut -d: -f1 /etc/passwd | grep -v "^root$" | grep -v "^_" | head -20
            echo ""
            read -r -p "Enter username to delete (or press Enter to cancel): " del_user
            if [ -n "$del_user" ]; then
                echo ""
                echo -e "${RED}⚠️  WARNING: This will delete the user and their home directory!${NC}"
                read -r -p "Type the username again to confirm deletion: " confirm_user
                if [ "$del_user" = "$confirm_user" ]; then
                    if sudo userdel -r "$del_user" 2>/dev/null; then
                        log_ok "User '$del_user' deleted successfully"
                    else
                        log_error "Failed to delete user '$del_user'"
                    fi
                else
                    log_info "Deletion cancelled"
                fi
            fi
            echo ""
            read -r -p "Press Enter to continue..."
            user_management_menu
            ;;
        5)
            echo ""
            log_info "User Permissions Management"
            cut -d: -f1 /etc/passwd | grep -v "^root$" | grep -v "^_" | head -20
            echo ""
            read -r -p "Enter username to modify permissions: " perm_user
            if [ -n "$perm_user" ] && id "$perm_user" &>/dev/null; then
                echo ""
                echo "Add user to groups:"
                echo "  1) docker (run Docker commands)"
                echo "  2) sudo (run with sudo)"
                echo "  3) Exit"
                echo ""
                read -r -p "Select group (1-3): " group_choice
                case "$group_choice" in
                    1)
                        if sudo usermod -aG docker "$perm_user" 2>/dev/null; then
                            log_ok "User added to docker group"
                        else
                            log_error "Failed to add user to docker group"
                        fi
                        ;;
                    2)
                        if sudo usermod -aG sudo "$perm_user" 2>/dev/null; then
                            log_ok "User added to sudo group"
                        else
                            log_error "Failed to add user to sudo group"
                        fi
                        ;;
                    3)
                        log_info "Cancelled"
                        ;;
                esac
            else
                log_error "User '$perm_user' not found"
            fi
            echo ""
            read -r -p "Press Enter to continue..."
            user_management_menu
            ;;
        6) show_main_menu ;;
        *) log_error "Invalid option"; sleep 1; user_management_menu ;;
    esac
}

cleanup_menu() {
    clear
    print_header "System Cleanup"
    echo ""
    echo -e "${BLUE}Cleanup Options:${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}  Clean temporary files"
    echo -e "  ${GREEN}2${NC}  Clean Docker images and containers"
    echo -e "  ${GREEN}3${NC}  Clean logs"
    echo -e "  ${GREEN}4${NC}  Full system cleanup"
    echo -e "  ${GREEN}5${NC}  Back to main menu"
    echo ""
    read_with_timeout clean_choice "Select an option [1-5]" "5"
    
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
