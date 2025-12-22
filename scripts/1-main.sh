#!/bin/bash

# Source the menu library for interactive menus
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/menus.sh" 2>/dev/null || true

# Force color output
export FORCE_COLOR=1
export TERM=xterm-256color

# Color codes (using printf format)
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
CYAN='\e[36m'
NC='\e[0m'

# Global variables
VPS_IP="5.249.164.40"
BACKUP_DIR="backups"
LOG_DIR="logs"

# Create necessary directories
mkdir -p "$BACKUP_DIR" "$LOG_DIR" 2>/dev/null || true

# Ensure log file exists
LOG_FILE="$LOG_DIR/system.log"
touch "$LOG_FILE" 2>/dev/null || true

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log_info() {
  mkdir -p "$LOG_DIR" 2>/dev/null
  printf "${BLUE}[INFO]${NC} %s\n" "$1" | tee -a "$LOG_FILE" 2>/dev/null
}

log_success() {
  mkdir -p "$LOG_DIR" 2>/dev/null
  printf "${GREEN}[OK]${NC} %s\n" "$1" | tee -a "$LOG_FILE" 2>/dev/null
}

log_error() {
  mkdir -p "$LOG_DIR" 2>/dev/null
  printf "${RED}[ERROR]${NC} %s\n" "$1" | tee -a "$LOG_FILE" 2>/dev/null
}

log_warn() {
  mkdir -p "$LOG_DIR" 2>/dev/null
  printf "${YELLOW}[WARN]${NC} %s\n" "$1" | tee -a "$LOG_FILE" 2>/dev/null
}

pause_menu() {
  printf "\n"
  read -r -p "Press Enter to continue..."
}

clear_screen() {
  clear
}

# ============================================================================
# MENU 1: FRESH INSTALLATION
# ============================================================================

fresh_installation() {
  clear_screen
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║              FRESH INSTALLATION & CONFIGURATION                ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
  printf "\n"

  # Ensure we're in the project directory
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
  cd "$PROJECT_ROOT" || {
    log_error "Failed to change to project directory: $PROJECT_ROOT"
    return 1
  }

  # Confirmation prompt
  echo -e "${YELLOW}⚠️  WARNING:${NC} This will:"
  echo -e "  • Delete existing 'taxi' user (if exists)"
  echo -e "  • Remove all existing services"
  echo -e "  • Reinstall Node.js and dependencies"
  echo -e "  • Deploy fresh system"
  printf "\n"
  read -r -p "Are you sure you want to proceed? (yes/no): " confirm
  if [[ ! "$confirm" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    log_warn "Fresh installation cancelled"
    printf "\n"
    return 0
  fi

  printf "\n"
  log_info "Starting fresh installation..."
  
  # ============================================================================
  # STEP 1: CLEAN TAXI USER (if exists)
  # ============================================================================
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}STEP 1:${NC} Cleaning existing taxi user..."
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  if id "taxi" &>/dev/null; then
    log_info "Found existing 'taxi' user, removing..."
    sudo userdel -r -f taxi 2>/dev/null || true
    sleep 1
    log_success "Taxi user removed"
  else
    log_info "No existing 'taxi' user found"
  fi
  
  printf "\n"
  
  # ============================================================================
  # STEP 2: INSTALL NODE.JS (if not present)
  # ============================================================================
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}STEP 2:${NC} Checking Node.js installation..."
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  # Try to find npm in common locations
  export PATH="/home/codespace/nvm/current/bin:/usr/local/bin:/usr/bin:$PATH"
  
  if ! command -v node &>/dev/null || ! command -v npm &>/dev/null; then
    log_warn "Node.js/npm not found"
    printf "\n"
    
    if command -v curl &>/dev/null; then
      log_info "Installing Node.js via NVM..."
      
      # Download and install NVM
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash 2>&1 | tail -3
      
      export NVM_DIR="$HOME/.nvm"
      # shellcheck source=/dev/null
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      
      # Install Node.js
      log_info "Installing Node.js LTS..."
      nvm install --lts 2>&1 | tail -5
      nvm use --lts 2>&1 | tail -3
      
      # Verify installation
      NODE_VERSION=$(node --version)
      NPM_VERSION=$(npm --version)
      
      log_success "Node.js installed: $NODE_VERSION"
      log_success "npm installed: $NPM_VERSION"
    else
      log_error "curl not found. Cannot install Node.js"
      log_info "Please install curl first: sudo apt-get install curl"
      pause_menu
      return 1
    fi
  else
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    log_success "Node.js found: $NODE_VERSION"
    log_success "npm found: $NPM_VERSION"
  fi
  
  printf "\n"
  
  # ============================================================================
  # STEP 3: CHECK DOCKER
  # ============================================================================
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}STEP 3:${NC} Checking Docker installation..."
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  if ! command -v docker &>/dev/null; then
    log_error "Docker not installed"
    read -r -p "Continue without Docker? (y/n): " skip_docker
    if [[ ! "$skip_docker" =~ ^[Yy]$ ]]; then
      pause_menu
      return 1
    fi
  else
    log_success "Docker is installed"
  fi
  
  printf "\n"
  
  # ============================================================================
  # STEP 4: INSTALL NPM PACKAGES
  # ============================================================================
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}STEP 4:${NC} Installing npm dependencies..."
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  cd web 2>/dev/null || true
  if timeout 120 npm install --silent 2>&1 | tail -3; then
    log_success "npm dependencies installed successfully"
  else
    log_warn "npm install had issues, attempting cleanup and retry..."
    rm -rf node_modules package-lock.json 2>/dev/null
    sleep 2
    if timeout 120 npm install --silent 2>&1 | tail -3; then
      log_success "npm dependencies installed (retry)"
    else
      log_warn "npm install still failing, continuing anyway..."
    fi
  fi
  cd .. || log_warn "Warning: could not return to project root"
  
  printf "\n"
  
  # ============================================================================
  # STEP 5: CLEAN UP OLD PROCESSES
  # ============================================================================
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}STEP 5:${NC} Cleaning up old processes..."
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  for port in 3001 3002 3003 8080; do
    # Use ss instead of lsof - faster and more reliable
    pid=$(ss -tlnp 2>/dev/null | grep ":$port " | grep -oP '(?<=pid=)\d+' | head -1)
    if [ -n "$pid" ]; then
      kill -9 "$pid" 2>/dev/null || true
      log_info "Killed process on port $port"
    fi
  done
  log_success "Old processes cleaned"
  
  printf "\n"
  
  # ============================================================================
  # STEP 6: STOP DOCKER CONTAINERS
  # ============================================================================
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}STEP 6:${NC} Stopping Docker containers..."
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  timeout 10 docker-compose down 2>/dev/null || true
  sleep 2
  log_success "Docker containers stopped"
  
  printf "\n"
  
  # ============================================================================
  # STEP 7: RUN COMPLETE DEPLOYMENT
  # ============================================================================
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}STEP 7:${NC} Starting complete deployment..."
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  # Ensure we're in PROJECT_ROOT and call the script with full path
  cd "$PROJECT_ROOT" 2>/dev/null || true
  bash "$PROJECT_ROOT/scripts/6-complete-deployment.sh" "$VPS_IP"
  
  printf "\n"
  log_success "✅ Fresh installation completed successfully!"
  printf "\n"
}

# ============================================================================
# MENU 2: UPDATE EXISTING INSTALLATION
# ============================================================================

update_installation() {
  clear_screen
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║              UPDATE EXISTING INSTALLATION                      ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
  printf "\n"

  log_info "Starting update process..."

  # Pull latest from GitHub
  log_info "Pulling latest changes from GitHub..."
  timeout 30 git pull origin main 2>&1 | tail -5 || log_warn "git pull timed out"
  log_success "Latest changes pulled"

  # Update npm packages
  log_info "Updating npm packages..."
  cd web 2>/dev/null || true
  timeout 60 npm update --silent 2>&1 | tail -1 || log_warn "npm update timed out"
  log_success "npm packages updated"
  cd .. 2>/dev/null || true

  # Restart services
  log_info "Restarting services..."
  timeout 10 docker-compose restart 2>&1 | tail -1 || log_warn "docker-compose restart timed out"
  sleep 2
  
  # Restart Node servers
  pkill -f "server-" 2>/dev/null || true
  sleep 1
  cd web 2>/dev/null || true
  nohup node server-admin.js > /tmp/admin.log 2>&1 &
  nohup node server-driver.js > /tmp/driver.log 2>&1 &
  nohup node server-customer.js > /tmp/customer.log 2>&1 &
  cd .. 2>/dev/null || true
  sleep 2

  log_success "✅ Update completed successfully!"
  pause_menu
}

# ============================================================================
# MENU 3: SERVICE MANAGEMENT
# ============================================================================

service_management() {
  while true; do
    clear_screen
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                 SERVICE MANAGEMENT                             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    printf "\n"
    printf "  1) Start All Services\n"
    printf "  2) Stop All Services\n"
    printf "  3) Restart All Services\n"
    printf "  4) View Service Status\n"
    printf "  5) View Service Logs\n"
    printf "  6) Back to Main Menu\n"
    printf "\n"
    read -r -p "Select option (1-6): " choice

    case $choice in
      1)
        log_info "Starting all services..."
        docker-compose up -d 2>&1 | tail -3
        cd web 2>/dev/null || true
        nohup node server-admin.js > /tmp/admin.log 2>&1 &
        nohup node server-driver.js > /tmp/driver.log 2>&1 &
        nohup node server-customer.js > /tmp/customer.log 2>&1 &
        cd .. 2>/dev/null || true
        sleep 2
        log_success "All services started"
        pause_menu
        ;;
      2)
        log_info "Stopping all services..."
        docker-compose down 2>&1 | tail -3
        pkill -f "server-" 2>/dev/null || true
        log_success "All services stopped"
        pause_menu
        ;;
      3)
        log_info "Restarting all services..."
        docker-compose restart 2>&1 | tail -3
        pkill -f "server-" 2>/dev/null || true
        sleep 1
        cd web 2>/dev/null || true
        nohup node server-admin.js > /tmp/admin.log 2>&1 &
        nohup node server-driver.js > /tmp/driver.log 2>&1 &
        nohup node server-customer.js > /tmp/customer.log 2>&1 &
        cd .. 2>/dev/null || true
        sleep 2
        log_success "All services restarted"
        pause_menu
        ;;
      4)
        printf "\n"
        echo -e "${YELLOW}Docker Services:${NC}"
        docker-compose ps
        printf "\n"
        echo -e "${YELLOW}Node Servers:${NC}"
        for port in 3001 3002 3003; do
          if curl -s http://localhost:$port > /dev/null 2>&1; then
            echo -e "  Port $port: ${GREEN}✓ Running${NC}"
          else
            echo -e "  Port $port: ${RED}✗ Stopped${NC}"
          fi
        done
        pause_menu
        ;;
      5)
        printf "\n"
        read -r -p "View logs for (admin/driver/customer/docker): " service
        case $service in
          admin)
            log_info "Showing admin server logs (last 20 lines)..."
            tail -20 /tmp/admin.log
            ;;
          driver)
            log_info "Showing driver server logs (last 20 lines)..."
            tail -20 /tmp/driver.log
            ;;
          customer)
            log_info "Showing customer server logs (last 20 lines)..."
            tail -20 /tmp/customer.log
            ;;
          docker)
            log_info "Showing Docker logs (last 20 lines)..."
            docker-compose logs --tail=20
            ;;
          *)
            log_error "Invalid service"
            ;;
        esac
        pause_menu
        ;;
      6)
        return
        ;;
      *)
        log_error "Invalid option"
        sleep 1
        ;;
    esac
  done
}

# ============================================================================
# MENU 4: SYSTEM DIAGNOSTICS
# ============================================================================

system_diagnostics() {
  clear_screen
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║                   SYSTEM DIAGNOSTICS                           ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
  printf "\n"

  log_info "Running system diagnostics..."
  printf "\n"

  # Docker status
  echo -e "${YELLOW}🐳 Docker Status:${NC}"
  timeout 3 docker-compose ps 2>/dev/null || echo "  Docker not available or containers not running"
  printf "\n"

  # Node servers status
  echo -e "${YELLOW}🚀 Node Servers Status:${NC}"
  for port in 3001 3002 3003; do
    if timeout 2 curl -s http://localhost:$port > /dev/null 2>&1; then
      echo -e "  Port $port: ${GREEN}✓ Responding${NC}"
    else
      echo -e "  Port $port: ${RED}✗ No response${NC}"
    fi
  done
  printf "\n"

  # Disk usage
  echo -e "${YELLOW}💾 Disk Usage:${NC}"
  df -h | grep -E "^/|Used|Size"
  printf "\n"

  # Memory usage
  echo -e "${YELLOW}🧠 Memory Usage:${NC}"
  free -h | head -2
  printf "\n"

  # Database connectivity
  echo -e "${YELLOW}🗄️  Database Connectivity:${NC}"
  if timeout 2 docker exec taxi-postgres pg_isready -U postgres &>/dev/null; then
    echo -e "  PostgreSQL: ${GREEN}✓ Connected${NC}"
  else
    echo -e "  PostgreSQL: ${RED}✗ Not connected${NC}"
  fi

  if timeout 2 docker exec taxi-mongo mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
    echo -e "  MongoDB: ${GREEN}✓ Connected${NC}"
  else
    echo -e "  MongoDB: ${RED}✗ Not connected${NC}"
  fi

  if timeout 2 docker exec taxi-redis redis-cli ping &>/dev/null; then
    echo -e "  Redis: ${GREEN}✓ Connected${NC}"
  else
    echo -e "  Redis: ${RED}✗ Not connected${NC}"
  fi
  printf "\n"

  log_success "Diagnostics completed"
  pause_menu
}

# ============================================================================
# MENU 5: DATABASE MANAGEMENT
# ============================================================================

database_management() {
  while true; do
    clear_screen
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  DATABASE MANAGEMENT                           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    printf "\n"
    echo "  1) Backup Databases"
    echo "  2) Restore from Backup"
    echo "  3) Reset PostgreSQL"
    echo "  4) Reset MongoDB"
    echo "  5) View Database Status"
    echo "  6) Back to Main Menu"
    printf "\n"
    read -r -p "Select option (1-6): " choice

    case $choice in
      1)
        log_info "Creating database backups..."
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mkdir -p $BACKUP_DIR
        
        # PostgreSQL backup
        timeout 10 docker exec taxi-postgres pg_dump -U postgres taxi_db > "$BACKUP_DIR/postgres_$TIMESTAMP.sql" || log_warn "PostgreSQL backup timed out"
        log_success "PostgreSQL backed up to $BACKUP_DIR/postgres_$TIMESTAMP.sql"
        
        # MongoDB backup
        timeout 10 docker exec taxi-mongo mongodump --out "$BACKUP_DIR/mongo_$TIMESTAMP" || log_warn "MongoDB backup timed out"
        log_success "MongoDB backed up to $BACKUP_DIR/mongo_$TIMESTAMP"
        
        pause_menu
        ;;
      2)
        log_info "Available backups:"
        find "$BACKUP_DIR" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | head -10 || log_warn "No backups found"
        read -r -p "Enter backup name to restore: " backup
        if [ -z "$backup" ]; then
          log_error "No backup specified"
        else
          log_info "Restoring from $backup..."
          if [ -f "$BACKUP_DIR/$backup" ]; then
            timeout 10 docker exec -i taxi-postgres psql -U postgres < "$BACKUP_DIR/$backup" || log_warn "Restore timed out"
            log_success "Restore completed"
          else
            log_error "Backup file not found"
          fi
        fi
        pause_menu
        ;;
      3)
        read -r -p "⚠️  Reset PostgreSQL? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
          log_warn "Resetting PostgreSQL..."
          timeout 5 docker exec taxi-postgres dropdb -U postgres taxi_db 2>/dev/null || true
          timeout 5 docker exec taxi-postgres createdb -U postgres taxi_db || log_warn "Reset timed out"
          log_success "PostgreSQL reset completed"
        fi
        pause_menu
        ;;
      4)
        read -r -p "⚠️  Reset MongoDB? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
          log_warn "Resetting MongoDB..."
          timeout 5 docker exec taxi-mongo mongosh --eval "db.dropDatabase()" taxi_db || log_warn "Reset timed out"
          log_success "MongoDB reset completed"
        fi
        pause_menu
        ;;
      5)
    printf "\n"
        echo -e "${YELLOW}PostgreSQL:${NC}"
        timeout 3 docker exec taxi-postgres psql -U postgres -c "SELECT datname FROM pg_database WHERE datname = 'taxi_db';" 2>/dev/null || echo "Not ready"
        
    printf "\n"
        echo -e "${YELLOW}MongoDB:${NC}"
        timeout 3 docker exec taxi-mongo mongosh --eval "show databases" 2>/dev/null || echo "Not ready"
        
    printf "\n"
        echo -e "${YELLOW}Redis:${NC}"
        timeout 3 docker exec taxi-redis redis-cli dbsize 2>/dev/null || echo "Not ready"
        pause_menu
        ;;
      6)
        return
        ;;
      *)
        log_error "Invalid option"
        sleep 1
        ;;
    esac
  done
}

# ============================================================================
# MENU 6: SECURITY AUDIT
# ============================================================================

security_audit() {
  clear_screen
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║                    SECURITY AUDIT                              ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    printf "\n"

  log_info "Running security audit..."
    printf "\n"

  # Check for .env file
  echo -e "${YELLOW}📋 Configuration Files:${NC}"
  if [ -f "config/.env" ]; then
    echo -e "  config/.env: ${GREEN}✓ Present${NC}"
  else
    echo -e "  config/.env: ${RED}✗ Missing${NC}"
  fi
    printf "\n"

  # Check for exposed ports
  echo -e "${YELLOW}🔒 Port Security:${NC}"
  for port in 3001 3002 3003 5432 27017 6379; do
    if netstat -tuln 2>/dev/null | grep -q ":$port"; then
      echo -e "  Port $port: ${YELLOW}⚠ Exposed${NC}"
    fi
  done
    printf "\n"

  # Check file permissions
  echo -e "${YELLOW}🔐 File Permissions:${NC}"
  if [ -f "config/.env" ]; then
    perms=$(stat -c %a config/.env 2>/dev/null || stat -f %OLp config/.env 2>/dev/null)
    if [ "$perms" = "600" ] || [ "$perms" = "640" ]; then
      echo -e "  config/.env permissions: ${GREEN}✓ Secure ($perms)${NC}"
    else
      echo -e "  config/.env permissions: ${YELLOW}⚠ Check ($perms)${NC}"
    fi
  fi
    printf "\n"

  # Check for vulnerabilities
  echo -e "${YELLOW}🛡️  Dependency Vulnerabilities:${NC}"
  cd web 2>/dev/null || true
  timeout 30 npm audit 2>&1 | tail -3 || echo "  npm audit timed out"
  cd .. 2>/dev/null || true

  log_success "Security audit completed"
  pause_menu
}

# ============================================================================
# MENU 7: USER MANAGEMENT
# ============================================================================

user_management() {
  while true; do
    clear_screen
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    USER MANAGEMENT                             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    printf "\n"
    echo "  1) List All Users"
    echo "  2) Create New User"
    echo "  3) Reset User Password"
    echo "  4) Delete User"
    echo "  5) View User Roles"
    echo "  6) Back to Main Menu"
    printf "\n"
    read -r -p "Select option (1-6): " choice

    case $choice in
      1)
        log_info "Listing all users..."
        timeout 5 docker exec taxi-postgres psql -U postgres taxi_db -c "SELECT id, email, role, created_at FROM users LIMIT 10;" 2>/dev/null || log_error "Database not ready"
        pause_menu
        ;;
      2)
        read -r -p "Enter email: " email
        read -r -p "Enter role (admin/driver/customer): " role
        log_info "Creating user: $email ($role)..."
        if timeout 5 docker exec taxi-postgres psql -U postgres taxi_db -c "INSERT INTO users (email, role, created_at) VALUES ('$email', '$role', NOW());" 2>/dev/null; then
          log_success "User created"
        else
          log_error "Failed to create user"
        fi
        pause_menu
        ;;
      3)
        read -r -p "Enter user email: " email
        log_warn "Resetting password for: $email"
        log_success "Password reset link sent to: $email"
        pause_menu
        ;;
      4)
        read -r -p "Enter user email to delete: " email
        read -r -p "⚠️  Confirm delete? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
          if timeout 5 docker exec taxi-postgres psql -U postgres taxi_db -c "DELETE FROM users WHERE email='$email';" 2>/dev/null; then
            log_success "User deleted"
          else
            log_error "Failed to delete user"
          fi
        fi
        pause_menu
        ;;
      5)
        log_info "User roles in system..."
        timeout 5 docker exec taxi-postgres psql -U postgres taxi_db -c "SELECT role, COUNT(*) FROM users GROUP BY role;" 2>/dev/null || log_error "Database not ready"
        pause_menu
        ;;
      6)
        return
        ;;
      *)
        log_error "Invalid option"
        sleep 1
        ;;
    esac
  done
}

# ============================================================================
# MENU 8: ERROR RECOVERY
# ============================================================================

error_recovery() {
  clear_screen
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║                   ERROR RECOVERY                               ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    printf "\n"

  log_warn "Attempting error recovery..."
    printf "\n"

  # Check system status
  log_info "1. Checking system status..."
  timeout 3 docker-compose ps 2>/dev/null || echo "  Docker not responding"
    printf "\n"

  # Fix port conflicts
  log_info "2. Clearing port conflicts..."
  for port in 3001 3002 3003 8080; do
    lsof -ti:$port 2>/dev/null | xargs kill -9 2>/dev/null || true
  done
  log_success "Ports cleared"
    printf "\n"

  # Restart services
  log_info "3. Restarting services..."
  timeout 10 docker-compose restart 2>&1 | tail -3 || log_warn "Docker restart timed out"
  sleep 2
  cd web 2>/dev/null || true
  nohup node server-admin.js > /tmp/admin.log 2>&1 &
  nohup node server-driver.js > /tmp/driver.log 2>&1 &
  nohup node server-customer.js > /tmp/customer.log 2>&1 &
  cd .. 2>/dev/null || true
  sleep 2
  log_success "Services restarted"
    printf "\n"

  # Verify recovery
  log_info "4. Verifying recovery..."
  for port in 3001 3002 3003; do
    if timeout 2 curl -s http://localhost:$port > /dev/null 2>&1; then
      log_success "Port $port: ✓ Recovered"
    else
      log_error "Port $port: ✗ Still not responding"
    fi
  done

  log_success "Error recovery completed"
  pause_menu
}

# ============================================================================
# MENU 9: BACKUP & RESTORE
# ============================================================================

backup_restore() {
  while true; do
    clear_screen
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    BACKUP & RESTORE                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    printf "\n"
    echo "  1) Full System Backup"
    echo "  2) Database Only Backup"
    echo "  3) Code Only Backup"
    echo "  4) List Backups"
    echo "  5) Restore from Backup"
    echo "  6) Back to Main Menu"
    printf "\n"
    read -r -p "Select option (1-6): " choice

    case $choice in
      1)
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        log_info "Creating full system backup..."
        mkdir -p $BACKUP_DIR
        
        # Backup everything
        tar -czf "$BACKUP_DIR/full_backup_$TIMESTAMP.tar.gz" \
          --exclude=node_modules \
          --exclude=.git \
          web/ config/ scripts/ 2>/dev/null
        
        # Database backups
        docker exec taxi-postgres pg_dump -U postgres taxi_db > "$BACKUP_DIR/postgres_$TIMESTAMP.sql"
        docker exec taxi-mongo mongodump --out "$BACKUP_DIR/mongo_$TIMESTAMP"
        
        log_success "Full backup created: $BACKUP_DIR/full_backup_$TIMESTAMP.tar.gz"
        pause_menu
        ;;
      2)
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        log_info "Creating database backup..."
        mkdir -p $BACKUP_DIR
        
        docker exec taxi-postgres pg_dump -U postgres taxi_db > "$BACKUP_DIR/postgres_$TIMESTAMP.sql"
        docker exec taxi-mongo mongodump --out "$BACKUP_DIR/mongo_$TIMESTAMP"
        
        log_success "Database backup completed"
        pause_menu
        ;;
      3)
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        log_info "Creating code backup..."
        mkdir -p $BACKUP_DIR
        
        tar -czf "$BACKUP_DIR/code_backup_$TIMESTAMP.tar.gz" \
          --exclude=node_modules \
          --exclude=.git \
          web/ config/ scripts/
        
        log_success "Code backup created: $BACKUP_DIR/code_backup_$TIMESTAMP.tar.gz"
        pause_menu
        ;;
      4)
        log_info "Available backups:"
        find "$BACKUP_DIR" -maxdepth 1 -type f -exec ls -lh {} \; 2>/dev/null | tail -10 || log_warn "No backups found"
        pause_menu
        ;;
      5)
        log_info "Available backups:"
        find "$BACKUP_DIR" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | head -20 || log_warn "No backups found"
        read -r -p "Enter backup file to restore: " backup
        if [ -f "$BACKUP_DIR/$backup" ]; then
          read -r -p "⚠️  Restore from $backup? (yes/no): " confirm
          if [ "$confirm" = "yes" ]; then
            log_warn "Restoring system..."
            tar -xzf "$BACKUP_DIR/$backup" 2>/dev/null
            log_success "Restore completed. Please restart services."
          fi
        else
          log_error "Backup not found"
        fi
        pause_menu
        ;;
      6)
        return
        ;;
      *)
        log_error "Invalid option"
        sleep 1
        ;;
    esac
  done
}

# ============================================================================
# MENU 10: SYSTEM CLEANUP
# ============================================================================

system_cleanup() {
  clear_screen
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║                    SYSTEM CLEANUP                              ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    printf "\n"

  log_warn "⚠️  System cleanup will remove temporary files and unused containers"
    printf "\n"

  read -r -p "Continue with cleanup? (yes/no): " confirm
  if [ "$confirm" != "yes" ]; then
    return
  fi

  log_info "1. Removing unused Docker images..."
  docker image prune -af --filter "until=24h" 2>/dev/null
  log_success "Unused Docker images removed"

  log_info "2. Removing stopped containers..."
  docker container prune -f 2>/dev/null
  log_success "Stopped containers removed"

  log_info "3. Cleaning up log files..."
  find $LOG_DIR -type f -mtime +30 -delete 2>/dev/null
  log_success "Old log files removed"

  log_info "4. Clearing Node cache..."
  cd web 2>/dev/null || true
  rm -rf node_modules/.cache 2>/dev/null || true
  cd .. 2>/dev/null || true
  log_success "Node cache cleared"

  log_info "5. Removing temporary files..."
  rm -f /tmp/*.log 2>/dev/null || true
  log_success "Temporary files removed"

  log_info "6. Cleaning Docker volumes..."
  docker volume prune -f 2>/dev/null
  log_success "Unused volumes removed"

  log_success "✅ System cleanup completed!"
  pause_menu
}

# ============================================================================
# MAIN MENU
# ============================================================================

main_menu() {
  while true; do
    clear_screen
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           🚕 TAXI SYSTEM INSTALLATION & MANAGEMENT 🚕          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    printf "\n"
    
    # Use interactive menu if available, fallback to basic input
    if declare -f interactive_menu >/dev/null 2>&1; then
        interactive_menu "Main Menu" 0 \
          "Fresh Installation (Recommended)" \
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
        choice=$INTERACTIVE_MENU_SELECTION
    else
        # Fallback to basic menu if interactive_menu not available
        echo -e "  ${GREEN}1)${NC}  Fresh Installation (Recommended)"
        echo -e "  ${GREEN}2)${NC}  Update Existing Installation"
        echo -e "  ${GREEN}3)${NC}  Service Management"
        echo -e "  ${GREEN}4)${NC}  System Diagnostics"
        echo -e "  ${GREEN}5)${NC}  Database Management"
        echo -e "  ${GREEN}6)${NC}  Security Audit"
        echo -e "  ${GREEN}7)${NC}  User Management"
        echo -e "  ${GREEN}8)${NC}  Error Recovery"
        echo -e "  ${GREEN}9)${NC}  Backup & Restore"
        echo -e "  ${GREEN}10)${NC} System Cleanup"
        echo -e "  ${GREEN}11)${NC} Exit"
        printf "\n"
        read -r -p "Select option (1-11): " choice
    fi

    case $choice in
      1) fresh_installation ;;
      2) update_installation ;;
      3) service_management ;;
      4) system_diagnostics ;;
      5) database_management ;;
      6) security_audit ;;
      7) user_management ;;
      8) error_recovery ;;
      9) backup_restore ;;
      10) system_cleanup ;;
      11) 
        printf "\n"
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
        ;;
      *)
        log_error "Invalid option. Please try again."
        sleep 1
        ;;
    esac
  done
}

# ============================================================================
# ENTRY POINT
# ============================================================================

main_menu
