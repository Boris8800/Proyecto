#!/bin/bash
# lib/setup.sh - Initial setup and configuration
# Part of the modularized Taxi System installer

# Source dependencies
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/validation.sh"
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/docker.sh"
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/database.sh"
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/dashboard.sh"

# ===================== SETUP FUNCTIONS =====================
create_taxi_user() {
    log_step "Creating taxi system user..."
    
    local username="${1:-taxi}"
    local home_dir="/home/$username"
    
    # Check if user already exists
    if id "$username" &>/dev/null; then
        log_ok "User '$username' already exists"
        return 0
    fi
    
    # Create user
    useradd -m -s /bin/bash -G docker,sudo "$username" >/dev/null 2>&1
    
    # Set password (if provided)
    if [ -n "${2:-}" ]; then
        echo "$username:${2:-}" | chpasswd
        log_ok "User created with password"
    else
        log_ok "User created (password required on first login)"
    fi
    
    # Create directory structure
    mkdir -p "$home_dir"/{app,data,logs,backups,config,scripts} 2>/dev/null
    chown -R "$username:$username" "$home_dir"
    chmod 755 "$home_dir"
    
    log_ok "Taxi user created: $username"
}

setup_directory_structure() {
    log_step "Setting up directory structure..."
    
    local root_dir="${1:-/home/taxi}"
    
    mkdir -p "$root_dir"/{app,data,logs,backups,config,scripts,dashboards}
    mkdir -p "$root_dir"/data/{postgresql,mongodb,redis}
    mkdir -p "$root_dir"/logs/{api,docker,nginx,system}
    mkdir -p "$root_dir"/config/{nginx,docker,database}
    
    # Set permissions
    chown -R taxi:taxi "$root_dir" 2>/dev/null || true
    chmod -R 755 "$root_dir" 2>/dev/null || true
    chmod -R 700 "$root_dir"/config 2>/dev/null || true
    
    log_ok "Directory structure created"
    log_info "Root directory: $root_dir"
}

setup_logging() {
    log_step "Setting up logging..."
    
    local log_dir="${1:-/home/taxi/logs}"
    
    # Create log files
    touch "$log_dir"/{install.log,error.log,docker.log,nginx.log}
    
    # Initialize the main LOG_FILE variable
    export LOG_FILE="$log_dir/install.log"
    
    # Set permissions
    chmod 644 "$log_dir"/*.log
    chown -R taxi:taxi "$log_dir"
    
    log_ok "Logging configured"
    log_info "Log file: $LOG_FILE"
}

generate_environment_file() {
    log_step "Generating environment configuration..."
    
    local config_file="${1:-/home/taxi/config/.env}"
    local config_dir
    config_dir=$(dirname "$config_file")
    
    mkdir -p "$config_dir"
    
    # Generate random passwords
    local postgres_pass
    postgres_pass=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    local mongo_pass
    mongo_pass=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    local redis_pass
    redis_pass=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    local jwt_secret
    jwt_secret=$(openssl rand -base64 64 | tr -d "=+/")
    
    # Create .env file
    cat > "$config_file" << EOF
# Taxi System Environment Configuration
# Generated: $(date)

# Application Settings
NODE_ENV=production
APP_NAME=Taxi System
APP_VERSION=1.0.0
LOG_LEVEL=info

# Server Configuration
SERVER_HOST=0.0.0.0
SERVER_PORT=3000
ENABLE_HTTPS=false
API_GATEWAY_URL=http://localhost:3000

# PostgreSQL Database
POSTGRES_HOST=taxi-postgres
POSTGRES_PORT=5432
POSTGRES_DB=taxi_db
POSTGRES_USER=taxi_admin
POSTGRES_PASSWORD=$postgres_pass

# MongoDB
MONGO_HOST=taxi-mongo
MONGO_PORT=27017
MONGO_DB=taxi_locations
MONGO_USER=admin
MONGO_PASSWORD=$mongo_pass

# Redis Cache
REDIS_HOST=taxi-redis
REDIS_PORT=6379
REDIS_PASSWORD=$redis_pass

# JWT Configuration
JWT_SECRET=$jwt_secret
JWT_EXPIRATION=24h

# Email Configuration (optional)
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USER=
MAIL_PASSWORD=
MAIL_FROM=noreply@taxi.system

# Storage Configuration
STORAGE_TYPE=local
STORAGE_PATH=/home/taxi/data

# Dashboard URLs
ADMIN_DASHBOARD_URL=http://localhost:3001
DRIVER_DASHBOARD_URL=http://localhost:3002
CUSTOMER_DASHBOARD_URL=http://localhost:3003

# Security
BCRYPT_ROUNDS=10
MAX_LOGIN_ATTEMPTS=5
LOCK_TIME=15m

# Timezone
TZ=UTC

# Debug Mode (set to true only in development)
DEBUG=false
EOF
    
    chmod 600 "$config_file"
    chown taxi:taxi "$config_file"
    
    log_ok "Environment file created: $config_file"
    
    # Export variables for use in script
    export POSTGRES_PASSWORD="$postgres_pass"
    export MONGO_PASSWORD="$mongo_pass"
    export REDIS_PASSWORD="$redis_pass"
    export JWT_SECRET="$jwt_secret"
}

setup_nginx() {
    log_step "Configuring Nginx..."
    log_info "Docker networking enabled - Nginx not required"
    log_ok "Configuration skipped"
}

setup_docker_compose() {
    log_step "Creating Docker Compose configuration..."
    
    local compose_file="${1:-docker-compose.yml}"
    
    cat > "$compose_file" << 'EOF'
services:
  taxi-postgres:
    image: postgres:15-alpine
    container_name: taxi-postgres
    environment:
      POSTGRES_USER: taxi_admin
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: taxi_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - taxi_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U taxi_admin"]
      interval: 10s
      timeout: 5s
      retries: 5

  taxi-mongo:
    image: mongo:6
    container_name: taxi-mongo
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db
    networks:
      - taxi_network
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5

  taxi-redis:
    image: redis:7-alpine
    container_name: taxi-redis
    command: redis-server --requirepass ${REDIS_PASSWORD}
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - taxi_network
    healthcheck:
      test: ["CMD-SHELL", "redis-cli -a ${REDIS_PASSWORD} ping | grep PONG"]
      interval: 10s
      timeout: 5s
      retries: 5

  taxi-nginx:
    image: nginx:alpine
    container_name: taxi-nginx
    ports:
      - "80:80"
      - "3001:3001"
      - "3002:3002"
      - "3003:3003"
    volumes:
      - /etc/nginx/sites-available/taxi-system:/etc/nginx/conf.d/default.conf:ro
      - /var/www/taxi-dashboards:/var/www/taxi-dashboards:ro
    depends_on:
      - taxi-postgres
      - taxi-mongo
      - taxi-redis
    networks:
      - taxi_network

networks:
  taxi_network:
    driver: bridge

volumes:
  postgres_data:
  mongo_data:
  redis_data:
EOF
    
    log_ok "Docker Compose configuration created"
    
    # Start the Docker containers
    log_info "Starting Docker containers..."
    if docker compose -f "$compose_file" up -d 2>&1; then
        log_ok "Docker containers started successfully"
        sleep 5  # Give containers time to start
    else
        log_error "Failed to start Docker containers"
        return 1
    fi
}

initialize_system() {
    log_step "Initializing system..."
    
    # Create taxi user
    create_taxi_user taxi
    
    # Setup directories
    setup_directory_structure
    
    # Setup logging
    setup_logging
    
    # Generate environment
    generate_environment_file
    
    # Setup Nginx
    setup_nginx
    
    # Setup Docker Compose
    setup_docker_compose
    
    log_ok "System initialization completed"
}

# Fresh installation orchestrator
fresh_install() {
    log_step "Starting fresh Taxi System installation..."
    
    # Validate system requirements
    log_info "Step 1/6: Validating system requirements..."
    check_system_requirements
    check_ports
    
    # Install and configure Docker
    log_info "Step 2/6: Installing Docker..."
    install_docker
    install_docker_compose
    setup_docker_permissions
    verify_docker_installation
    
    # Initialize system
    log_info "Step 3/6: Initializing system..."
    initialize_system
    
    # Initialize databases
    log_info "Step 4/6: Initializing databases..."
    initialize_postgresql
    initialize_mongodb
    setup_redis
    
    # Create database schema
    log_info "Step 5/6: Creating database schema..."
    create_database_schema
    seed_initial_data
    
    # Deploy dashboards
    log_info "Step 6/6: Deploying dashboards..."
    create_all_dashboards
    
    log_ok "✅ Fresh installation completed successfully!"
}
