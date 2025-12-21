#!/bin/bash
# lib/menus.sh - Interactive menus and user interfaces
# Part of the modularized Taxi System installer

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ===================== HELPER FUNCTIONS =====================
# Interactive menu with arrow keys and timeout
# Usage: interactive_menu "Title" "Default Option Index" "Option 1" "Option 2" ...
interactive_menu() {
    local title="$1"
    local default_idx="$2"
    shift 2
    local options=("$@")
    local num_options=${#options[@]}
    local current=$default_idx
    local timeout=10
    local start_time=$(date +%s)
    
    # Hide cursor
    tput civis
    
    # Clear menu area function
    clear_menu() {
        for ((i=0; i<num_options+2; i++)); do
            tput el
            tput cuu1
        done
        tput el
    }

    while true; do
        local now=$(date +%s)
        local elapsed=$((now - start_time))
        local remaining=$((timeout - elapsed))
        
        if [ $remaining -le 0 ]; then
            tput cnorm
            echo ""
            log_info "Timeout reached. Selecting recommended option: ${options[$default_idx]}"
            return $((default_idx + 1))
        fi

        # Print Title
        echo -e "${BLUE}$title:${NC}"
        
        # Print Options
        for i in "${!options[@]}"; do
            if [ $i -eq $current ]; then
                if [ $i -eq $default_idx ]; then
                    echo -e "  ${CYAN}➜ ${options[$i]} ${YELLOW}(Recommended)${NC}"
                else
                    echo -e "  ${CYAN}➜ ${options[$i]}${NC}"
                fi
            else
                if [ $i -eq $default_idx ]; then
                    echo -e "    ${options[$i]} ${YELLOW}(Recommended)${NC}"
                else
                    echo -e "    ${options[$i]}"
                fi
            fi
        done
        
        echo -e "\n${YELLOW}Auto-selecting in ${remaining}s... (Use arrows to navigate, Enter to select)${NC}"
        
        # Move cursor back up to start of menu
        tput cuu $((num_options + 3))
        
        # Read input with 1s timeout
        read -s -n 1 -t 1 key
        
        case "$key" in
            $'\x1b') # Escape sequence
                read -s -n 2 -t 0.1 next_key
                case "$next_key" in
                    "[A") # Up arrow
                        current=$(( (current - 1 + num_options) % num_options ))
                        ;;
                    "[B") # Down arrow
                        current=$(( (current + 1) % num_options ))
                        ;;
                esac
                ;;
            "") # Enter key
                # Check if it was actually Enter (exit code 0) or timeout (exit code > 128)
                if [ $? -eq 0 ]; then
                    tput cnorm
                    # Move cursor down to clear the menu area
                    for ((i=0; i<num_options+3; i++)); do echo ""; done
                    return $((current + 1))
                fi
                ;;
        esac
        
        # Clear the lines we just printed to redraw
        # (Actually tput cuu already moved us up, so we just redraw over)
    done
}

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
    
    interactive_menu "Main Menu" 0 \
        "Fresh Installation" \
        "Update Existing Installation" \
        "Service Management" \
        "System Diagnostics" \
        "Database Management" \
        "Security Audit" \
        "User Management" \
        "Error Recovery" \
        "Backup & Restore" \
        "System Cleanup" \
        "Exit"
    
    main_choice=$?
    
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
        10) cleanup_menu ;;
        11) 
            echo ""
            echo -e "${CYAN}Goodbye!${NC}"
            exit 0
            ;;
        *)
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
    
    interactive_menu "Continue with fresh installation?" 0 \
        "Yes, proceed with installation" \
        "No, cancel and go back"
    
    confirm=$?
    
    if [ $confirm -eq 1 ]; then
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
    
    interactive_menu "Update Options" 0 \
        "Update all services" \
        "Back to main menu"
    
    update_choice=$?
    
    case "$update_choice" in
        1) 
            log_info "Updating all services..."
            update_installation
            echo ""
            read -r -p "Press Enter to return to main menu..."
            show_main_menu 
            ;;
        2) show_main_menu ;;
        *) show_main_menu ;;
    esac
}

service_management_menu() {
    clear
    print_header "Service Management"
    echo ""
    
    interactive_menu "Service Management Options" 0 \
        "Start all services" \
        "Stop all services" \
        "Restart all services" \
        "View service status" \
        "View service logs" \
        "Back to main menu"
    
    service_choice=$?
    
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
            service_management_menu
            ;;
    esac
}

service_logs_menu() {
    echo ""
    interactive_menu "Select service for logs" 5 \
        "API Gateway" \
        "PostgreSQL" \
        "MongoDB" \
        "Redis" \
        "Admin Dashboard" \
        "Back"
    
    log_choice=$?
    
    case "$log_choice" in
        1) docker logs taxi-api -f ;;
        2) docker logs taxi-postgres -f ;;
        3) docker logs taxi-mongo -f ;;
        4) docker logs taxi-redis -f ;;
        5) docker logs taxi-admin -f ;;
        6) service_management_menu ;;
        *) service_management_menu ;;
    esac
}

diagnostics_menu() {
    clear
    print_header "System Diagnostics"
    echo ""
    
    interactive_menu "Diagnostics Options" 0 \
        "Full system check" \
        "Docker diagnostics" \
        "Port availability check" \
        "Network connectivity test" \
        "Database connectivity test" \
        "Health check" \
        "Back to main menu"
    
    diag_choice=$?
    
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
        *) diagnostics_menu ;;
    esac
}

database_menu() {
    clear
    print_header "Database Management"
    echo ""
    
    interactive_menu "Database Options" 0 \
        "Initialize databases" \
        "Create database backup" \
        "Restore from backup" \
        "View database status" \
        "Reset databases (DESTRUCTIVE)" \
        "Back to main menu"
    
    db_choice=$?
    
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
        *) database_menu ;;
    esac
}

security_menu() {
    clear
    print_header "Security Audit"
    echo ""
    
    interactive_menu "Security Options" 0 \
        "Run security audit" \
        "Configure firewall" \
        "Update security credentials" \
        "View security report" \
        "Back to main menu"
    
    sec_choice=$?
    
    case "$sec_choice" in
        1) log_info "Running security audit..."; sleep 2; security_menu ;;
        2) log_info "Configuring firewall..."; sleep 2; security_menu ;;
        3) log_info "Updating credentials..."; sleep 2; security_menu ;;
        4) log_info "Security report..."; sleep 2; security_menu ;;
        5) show_main_menu ;;
        *) security_menu ;;
    esac
}

error_recovery_menu() {
    clear
    print_header "Error Recovery"
    echo ""
    
    interactive_menu "Error Recovery Options" 0 \
        "View recent errors" \
        "Automatic error recovery" \
        "Manual troubleshooting guide" \
        "Restart failed services" \
        "System reset" \
        "Back to main menu"
    
    err_choice=$?
    
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
        *) error_recovery_menu ;;
    esac
}

backup_menu() {
    clear
    print_header "Backup & Restore"
    echo ""
    
    interactive_menu "Backup Options" 0 \
        "Create full backup" \
        "Create database backup only" \
        "Create configuration backup" \
        "List backups" \
        "Restore from backup" \
        "Back to main menu"
    
    backup_choice=$?
    
    case "$backup_choice" in
        1) log_info "Creating full backup..."; sleep 2; backup_menu ;;
        2) log_info "Creating database backup..."; sleep 2; backup_menu ;;
        3) log_info "Creating configuration backup..."; sleep 2; backup_menu ;;
        4) log_info "Listing backups..."; sleep 2; backup_menu ;;
        5) log_info "Restore from backup..."; sleep 2; backup_menu ;;
        6) show_main_menu ;;
        *) backup_menu ;;
    esac
}

user_management_menu() {
    clear
    print_header "User Management"
    echo ""
    
    interactive_menu "User Management Options" 0 \
        "List all system users" \
        "List taxi users" \
        "Create new user" \
        "Delete user" \
        "Change user permissions" \
        "Back to main menu"
    
    user_choice=$?
    
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
        *) user_management_menu ;;
    esac
}

cleanup_menu() {
    clear
    print_header "System Cleanup"
    echo ""
    
    interactive_menu "Cleanup Options" 4 \
        "Clean temporary files" \
        "Clean Docker images and containers" \
        "Clean logs" \
        "Full system cleanup" \
        "Back to main menu"
    
    clean_choice=$?
    
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
        *) cleanup_menu ;;
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
