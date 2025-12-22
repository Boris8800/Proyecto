#!/bin/bash
# lib/database.sh - Database initialization and setup
# Part of the modularized Taxi System installer

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/validation.sh"

# ===================== DATABASE INITIALIZATION FUNCTIONS =====================
initialize_postgresql() {
    log_step "Initializing PostgreSQL database..."
    
    local db_container="${1:-taxi-postgres}"
    local postgres_password="${POSTGRES_PASSWORD:-postgres_secure_password_123}"
    
    # Wait for PostgreSQL to be ready
    log_info "Waiting for PostgreSQL to be ready..."
    local attempts=0
    while [ $attempts -lt 30 ]; do
        if docker exec "$db_container" pg_isready -U taxi_admin >/dev/null 2>&1; then
            log_ok "PostgreSQL is ready"
            break
        fi
        attempts=$((attempts + 1))
        sleep 2
    done
    
    if [ $attempts -eq 30 ]; then
        log_error "PostgreSQL failed to start within timeout"
        return 1
    fi
    
    # Create database and user (if they don't already exist)
    log_info "Ensuring database and user are configured..."
    
    # Try with taxi_admin first (since it's the superuser defined in docker-compose)
    docker exec -e PGPASSWORD="$postgres_password" "$db_container" \
        psql -U taxi_admin -d postgres -c "CREATE DATABASE taxi_db;" 2>/dev/null || true
    
    docker exec -e PGPASSWORD="$postgres_password" "$db_container" \
        psql -U taxi_admin -d postgres -c "ALTER USER taxi_admin WITH PASSWORD '$postgres_password';" 2>/dev/null || true
    
    log_ok "PostgreSQL database initialized"
}

initialize_mongodb() {
    log_step "Initializing MongoDB..."
    
    local db_container="${1:-taxi-mongo}"
    local mongo_password="${MONGO_PASSWORD:-mongo_secure_password_456}"
    
    # Wait for MongoDB to be ready
    log_info "Waiting for MongoDB to be ready..."
    local attempts=0
    while [ $attempts -lt 30 ]; do
        if docker exec "$db_container" mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
            log_ok "MongoDB is ready"
            break
        fi
        attempts=$((attempts + 1))
        sleep 2
    done
    
    if [ $attempts -eq 30 ]; then
        log_error "MongoDB failed to start within timeout"
        return 1
    fi
    
    # Initialize admin user and database
    log_info "Creating MongoDB admin user and databases..."
    
    # Try to connect with password first, then without
    local mongo_auth=""
    if ! docker exec "$db_container" mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
        mongo_auth="-u admin -p $mongo_password --authenticationDatabase admin"
    fi

    docker exec "$db_container" mongosh $mongo_auth << MONGO_SCRIPT 2>/dev/null
        use admin
        // Only create admin if it doesn't exist (though INITDB usually handles this)
        if (!db.getUser('admin')) {
            db.createUser({
                user: 'admin',
                pwd: '$mongo_password',
                roles: [{ role: 'root', db: 'admin' }]
            })
        }
        
        use taxi_locations
        if (!db.getUser('taxi_user')) {
            db.createUser({
                user: 'taxi_user',
                pwd: '$mongo_password',
                roles: [{ role: 'readWrite', db: 'taxi_locations' }]
            })
        }
        
        // Create initial collections
        db.drivers.createIndex({ location: "2dsphere" })
        db.rides.createIndex({ createdAt: 1 })
        db.createCollection("logs")
MONGO_SCRIPT
    
    log_ok "MongoDB initialized"
}

setup_redis() {
    log_step "Setting up Redis..."
    
    local redis_container="${1:-taxi-redis}"
    local redis_password="${REDIS_PASSWORD:-redis_secure_password_789}"
    
    # Wait for Redis to be ready
    log_info "Waiting for Redis to be ready..."
    local attempts=0
    while [ $attempts -lt 30 ]; do
        # Try pinging with password if provided, otherwise without
        if [ -n "$redis_password" ]; then
            if docker exec "$redis_container" redis-cli -a "$redis_password" ping 2>/dev/null | grep -q "PONG"; then
                log_ok "Redis is ready (authenticated)"
                break
            fi
        fi
        
        if docker exec "$redis_container" redis-cli ping 2>/dev/null | grep -q "PONG"; then
            log_ok "Redis is ready"
            break
        fi
        attempts=$((attempts + 1))
        sleep 2
    done
    
    if [ $attempts -eq 30 ]; then
        log_error "Redis failed to start within timeout"
        return 1
    fi
    
    # Configure Redis password (only if not already set via command line)
    log_info "Ensuring Redis authentication is configured..."
    if ! docker exec "$redis_container" redis-cli ping 2>/dev/null | grep -q "PONG"; then
        # If ping fails without password, it's likely already protected
        if docker exec "$redis_container" redis-cli -a "$redis_password" ping 2>/dev/null | grep -q "PONG"; then
            log_ok "Redis authentication already active"
        else
            # Try to set it if it's not set and we can't ping
            docker exec "$redis_container" redis-cli CONFIG SET requirepass "$redis_password" >/dev/null 2>&1 || true
        fi
    else
        # If ping succeeds without password, set the password now
        docker exec "$redis_container" redis-cli CONFIG SET requirepass "$redis_password" >/dev/null 2>&1
    fi
    
    log_ok "Redis configured"
}

create_database_schema() {
    log_step "Creating database schema..."
    
    local postgres_container="${1:-taxi-postgres}"
    local postgres_password="${POSTGRES_PASSWORD:-postgres_secure_password_123}"
    
    log_info "Creating PostgreSQL tables..."
    docker exec -e PGPASSWORD="$postgres_password" "$postgres_container" \
        psql -U taxi_admin -d taxi_db << SQL_SCRIPT 2>/dev/null
        
-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    role VARCHAR(50) DEFAULT 'customer',
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    verified BOOLEAN DEFAULT FALSE
);

-- Drivers table
CREATE TABLE IF NOT EXISTS drivers (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    vehicle_plate VARCHAR(20) UNIQUE NOT NULL,
    vehicle_type VARCHAR(50),
    rating DECIMAL(3, 2) DEFAULT 5.00,
    total_rides INTEGER DEFAULT 0,
    status VARCHAR(50) DEFAULT 'offline',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Rides table
CREATE TABLE IF NOT EXISTS rides (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    customer_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    driver_id INTEGER REFERENCES drivers(id) ON DELETE SET NULL,
    pickup_location VARCHAR(255) NOT NULL,
    dropoff_location VARCHAR(255) NOT NULL,
    pickup_lat DECIMAL(10, 8),
    pickup_lng DECIMAL(11, 8),
    dropoff_lat DECIMAL(10, 8),
    dropoff_lng DECIMAL(11, 8),
    distance DECIMAL(10, 2),
    estimated_fare DECIMAL(10, 2),
    actual_fare DECIMAL(10, 2),
    status VARCHAR(50) DEFAULT 'pending',
    rating INTEGER,
    review TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payments table
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    ride_id INTEGER REFERENCES rides(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    method VARCHAR(50),
    status VARCHAR(50) DEFAULT 'pending',
    transaction_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit log table
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(255) NOT NULL,
    resource VARCHAR(100),
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_drivers_user_id ON drivers(user_id);
CREATE INDEX IF NOT EXISTS idx_drivers_status ON drivers(status);
CREATE INDEX IF NOT EXISTS idx_drivers_location ON drivers(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_rides_customer_id ON rides(customer_id);
CREATE INDEX IF NOT EXISTS idx_rides_driver_id ON rides(driver_id);
CREATE INDEX IF NOT EXISTS idx_rides_status ON rides(status);
CREATE INDEX IF NOT EXISTS idx_rides_created_at ON rides(created_at);
CREATE INDEX IF NOT EXISTS idx_payments_ride_id ON payments(ride_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE taxi_db TO taxi_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO taxi_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO taxi_admin;

SQL_SCRIPT
    
    log_ok "Database schema created successfully"
}

seed_initial_data() {
    log_step "Seeding initial data..."
    
    local postgres_container="${1:-taxi-postgres}"
    local postgres_password="${POSTGRES_PASSWORD:-postgres_secure_password_123}"
    
    log_info "Adding initial system users..."
    docker exec -e PGPASSWORD="$postgres_password" "$postgres_container" \
        psql -U taxi_admin -d taxi_db << SQL_SCRIPT 2>/dev/null
        
-- Insert system admin user
INSERT INTO users (email, phone, name, password_hash, role, verified)
VALUES ('admin@taxi.system', '+1234567890', 'System Admin', 
        crypt('admin123', gen_salt('bf')), 'admin', true)
ON CONFLICT DO NOTHING;

-- Insert test driver
INSERT INTO users (email, phone, name, password_hash, role, verified)
VALUES ('driver1@taxi.system', '+1234567891', 'Test Driver', 
        crypt('driver123', gen_salt('bf')), 'driver', true)
ON CONFLICT DO NOTHING;

-- Insert test customer
INSERT INTO users (email, phone, name, password_hash, role, verified)
VALUES ('customer1@taxi.system', '+1234567892', 'Test Customer', 
        crypt('customer123', gen_salt('bf')), 'customer', true)
ON CONFLICT DO NOTHING;

SQL_SCRIPT
    
    log_ok "Initial data seeded"
}

backup_database() {
    log_step "Creating database backup..."
    
    local postgres_container="${1:-taxi-postgres}"
    local postgres_password="${POSTGRES_PASSWORD:-postgres_secure_password_123}"
    local backup_dir="${2:-.}"
    local backup_timestamp
    backup_timestamp="$(date +%Y%m%d_%H%M%S)"
    local backup_file="${backup_dir}/taxi_db_backup_${backup_timestamp}.sql"
    
    docker exec -e PGPASSWORD="$postgres_password" "$postgres_container" \
        pg_dump -U taxi_admin taxi_db > "$backup_file" 2>/dev/null
    
    if [ -f "$backup_file" ] && [ -s "$backup_file" ]; then
        log_ok "Database backed up to: $backup_file"
        echo "$backup_file"
    else
        log_error "Failed to create database backup"
        return 1
    fi
}

database_status() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}            📊 DATABASE STATUS REPORT${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # PostgreSQL
    echo -e "${BLUE}PostgreSQL:${NC}"
    if docker ps --filter name=taxi-postgres --filter status=running | grep -q taxi-postgres; then
        echo -e "  ${GREEN}✅ Running${NC}"
        
        if docker exec taxi-postgres pg_isready -U postgres >/dev/null 2>&1; then
            echo -e "  ${GREEN}✅ Accessible${NC}"
            
            # Get database info
            local db_size
            db_size=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD:-postgres_secure_password_123}" \
                taxi-postgres psql -U taxi_admin -d taxi_db -t -c \
                "SELECT pg_size_pretty(pg_database_size('taxi_db'));" 2>/dev/null | tr -d ' ')
            echo "  📦 Database size: $db_size"
        else
            echo -e "  ${RED}❌ Not accessible${NC}"
        fi
    else
        echo -e "  ${RED}❌ Not running${NC}"
    fi
    
    # MongoDB
    echo ""
    echo -e "${BLUE}MongoDB:${NC}"
    if docker ps --filter name=taxi-mongo --filter status=running | grep -q taxi-mongo; then
        echo -e "  ${GREEN}✅ Running${NC}"
        
        local mongo_pass="${MONGO_PASSWORD:-}"
        local mongo_auth=""
        [ -n "$mongo_pass" ] && mongo_auth="-u admin -p $mongo_pass --authenticationDatabase admin"
        
        if docker exec taxi-mongo mongosh $mongo_auth --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✅ Accessible${NC}"
        else
            echo -e "  ${RED}❌ Not accessible${NC}"
        fi
    else
        echo -e "  ${RED}❌ Not running${NC}"
    fi
    
    # Redis
    echo ""
    echo -e "${BLUE}Redis:${NC}"
    if docker ps --filter name=taxi-redis --filter status=running | grep -q taxi-redis; then
        echo -e "  ${GREEN}✅ Running${NC}"
        
        local redis_pass="${REDIS_PASSWORD:-}"
        local redis_auth=""
        [ -n "$redis_pass" ] && redis_auth="-a $redis_pass"
        
        if docker exec taxi-redis redis-cli $redis_auth ping 2>/dev/null | grep -q "PONG"; then
            echo -e "  ${GREEN}✅ Accessible${NC}"
            
            local redis_mem
            redis_mem=$(docker exec taxi-redis redis-cli $redis_auth INFO memory 2>/dev/null | grep used_memory_human | cut -d: -f2 | tr -d '\r')
            echo "  💾 Memory: $redis_mem"
        else
            echo -e "  ${RED}❌ Not accessible${NC}"
        fi
    else
        echo -e "  ${RED}❌ Not running${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}
