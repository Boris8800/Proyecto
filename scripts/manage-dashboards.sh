#!/bin/bash

# Taxi System Web Dashboard Manager
# Manages the three Express.js servers for Admin, Driver, and Customer interfaces

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Configuration
ADMIN_PORT=3001
DRIVER_PORT=3002
CUSTOMER_PORT=3003
ADMIN_PID_FILE="/tmp/taxi-admin-server.pid"
DRIVER_PID_FILE="/tmp/taxi-driver-server.pid"
CUSTOMER_PID_FILE="/tmp/taxi-customer-server.pid"
BASE_DIR="/home/taxi"
WEB_DIR="$BASE_DIR/web"
LOG_DIR="/var/log/taxi-dashboards"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to check if port is available
check_port() {
    local port=$1
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        return 1
    fi
    return 0
}

# Function to start a server
start_server() {
    local name=$1
    local port=$2
    local script=$3
    local pid_file=$4

    log_info "Starting $name server on port $port..."

    if ! check_port "$port"; then
        log_error "Port $port is already in use"
        return 1
    fi

    if [ ! -f "$script" ]; then
        log_error "Script not found: $script"
        return 1
    fi

    # Start server in background
    nohup node "$script" > "$LOG_DIR/${name}.log" 2>&1 &
    local pid=$!
    echo "$pid" > "$pid_file"

    # Wait a moment and check if process is still running
    sleep 2
    if kill -0 "$pid" 2>/dev/null; then
        log_success "$name server started with PID $pid"
        return 0
    else
        log_error "$name server failed to start"
        return 1
    fi
}

# Function to stop a server
stop_server() {
    local name=$1
    local pid_file=$2

    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_success "Stopped $name server (PID: $pid)"
            rm -f "$pid_file"
            return 0
        else
            log_warning "$name server not running (stale PID file removed)"
            rm -f "$pid_file"
            return 1
        fi
    else
        log_warning "$name server is not running"
        return 1
    fi
}

# Function to check server status
check_status() {
    local name=$1
    local port=$2
    local pid_file=$3

    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}●${NC} $name (Port $port) - Running (PID: $pid)"
            
            # Check if port is responding
            if timeout 2 bash -c "echo >/dev/tcp/localhost/$port" 2>/dev/null; then
                echo "  Status: ${GREEN}Responding${NC}"
            else
                echo "  Status: ${YELLOW}Running but not responding${NC}"
            fi
            return 0
        else
            echo -e "${RED}●${NC} $name (Port $port) - Stopped (PID: $pid - invalid)"
            rm -f "$pid_file"
            return 1
        fi
    else
        echo -e "${RED}●${NC} $name (Port $port) - Not running"
        return 1
    fi
}

# Function to install dependencies
install_dependencies() {
    log_info "Installing Node.js dependencies..."
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        return 1
    fi

    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        return 1
    fi

    cd "$BASE_DIR"
    npm install
    log_success "Dependencies installed"
}

# Main command handler
case "${1:-status}" in
    start)
        log_info "Starting all taxi dashboard servers..."
        
        if ! check_port "$ADMIN_PORT" || ! check_port "$DRIVER_PORT" || ! check_port "$CUSTOMER_PORT"; then
            log_error "One or more required ports are already in use"
            log_info "Admin: $ADMIN_PORT, Driver: $DRIVER_PORT, Customer: $CUSTOMER_PORT"
            exit 1
        fi

        start_server "Admin" "$ADMIN_PORT" "$WEB_DIR/server-admin.js" "$ADMIN_PID_FILE"
        start_server "Driver" "$DRIVER_PORT" "$WEB_DIR/server-driver.js" "$DRIVER_PID_FILE"
        start_server "Customer" "$CUSTOMER_PORT" "$WEB_DIR/server-customer.js" "$CUSTOMER_PID_FILE"

        log_success "All servers started!"
        echo ""
        echo "Access the dashboards at:"
        echo "  Admin:    http://localhost:$ADMIN_PORT"
        echo "  Driver:   http://localhost:$DRIVER_PORT"
        echo "  Customer: http://localhost:$CUSTOMER_PORT"
        ;;

    stop)
        log_info "Stopping all taxi dashboard servers..."
        stop_server "Admin" "$ADMIN_PID_FILE"
        stop_server "Driver" "$DRIVER_PID_FILE"
        stop_server "Customer" "$CUSTOMER_PID_FILE"
        log_success "All servers stopped"
        ;;

    restart)
        log_info "Restarting all taxi dashboard servers..."
        "$0" stop
        sleep 1
        "$0" start
        ;;

    status)
        log_info "Checking taxi dashboard server status..."
        echo ""
        check_status "Admin" "$ADMIN_PORT" "$ADMIN_PID_FILE"
        echo ""
        check_status "Driver" "$DRIVER_PORT" "$DRIVER_PID_FILE"
        echo ""
        check_status "Customer" "$CUSTOMER_PORT" "$CUSTOMER_PID_FILE"
        echo ""
        ;;

    logs)
        local service="${2:-admin}"
        case "$service" in
            admin)
                tail -f "$LOG_DIR/Admin.log"
                ;;
            driver)
                tail -f "$LOG_DIR/Driver.log"
                ;;
            customer)
                tail -f "$LOG_DIR/Customer.log"
                ;;
            all)
                log_info "Tailing all logs (use Ctrl+C to exit)"
                tail -f "$LOG_DIR"/*.log
                ;;
            *)
                log_error "Unknown service: $service"
                echo "Usage: $0 logs [admin|driver|customer|all]"
                exit 1
                ;;
        esac
        ;;

    install)
        install_dependencies
        ;;

    *)
        echo "Taxi System Web Dashboard Manager"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  start              Start all dashboard servers"
        echo "  stop               Stop all dashboard servers"
        echo "  restart            Restart all dashboard servers"
        echo "  status             Check status of all servers"
        echo "  logs [service]     View logs (admin|driver|customer|all)"
        echo "  install            Install Node.js dependencies"
        echo ""
        echo "Example:"
        echo "  $0 start"
        echo "  $0 status"
        echo "  $0 logs admin"
        echo ""
        exit 1
        ;;
esac

exit 0
