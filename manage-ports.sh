#!/bin/bash
# manage-ports.sh - Port management and conflict resolution
# Handles port conflicts and ensures required ports are available

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh" 2>/dev/null || {
    # Fallback if lib/common.sh not found
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
    
    log_step() { echo -e "${CYAN}[STEP]${NC} $*"; }
    log_ok() { echo -e "${GREEN}[OK]${NC} $*"; }
    log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
    log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
}

# Define required ports for Taxi System
REQUIRED_PORTS=(
    "80:nginx (HTTP)"
    "443:nginx (HTTPS)"
    "5432:PostgreSQL"
    "27017:MongoDB"
    "6379:Redis"
    "3000:API Gateway"
    "3001:Admin Dashboard"
    "3002:Driver Dashboard"
    "3003:Customer Dashboard"
)

# Function to check if port is in use
check_port() {
    local port=$1
    local timeout=1
    
    # Method 1: Using ss (most reliable and available on all modern systems)
    if command -v ss &> /dev/null; then
        if ss -tulpn 2>/dev/null | grep -q ":$port "; then
            return 0
        fi
    fi
    
    # Method 2: Using netstat if available
    if command -v netstat &> /dev/null; then
        if netstat -tln 2>/dev/null | grep -qE "[:.]$port\s"; then
            return 0
        fi
    fi
    
    # Method 3: Using lsof if available
    if command -v lsof &> /dev/null; then
        if lsof -Pi :$port -sTCP:LISTEN -t 2>/dev/null | grep -q .; then
            return 0
        fi
    fi
    
    # Method 4: Using /dev/tcp (bash builtin, checks connection)
    if timeout $timeout bash -c "</dev/tcp/127.0.0.1/$port" 2>/dev/null; then
        return 0
    fi
    
    # Method 5: Using nc if available
    if command -v nc &> /dev/null; then
        if nc -z -w $timeout 127.0.0.1 "$port" 2>/dev/null; then
            return 0
        fi
    fi
    
    # Port is not in use
    return 1
}

# Function to find process using port
find_process_using_port() {
    local port=$1
    
    if command -v lsof &> /dev/null; then
        lsof -i :"$port" 2>/dev/null | tail -1 | awk '{print $2}' || echo ""
    elif command -v ss &> /dev/null; then
        ss -tulpn 2>/dev/null | grep ":$port " | grep -oP 'pid=\K[^,]*' | head -1 || echo ""
    elif command -v netstat &> /dev/null; then
        netstat -tulpn 2>/dev/null | grep ":$port " | awk '{print $NF}' | cut -d'/' -f1 || echo ""
    else
        return 1
    fi
}

# Function to kill process using port
kill_port_process() {
    local port=$1
    local pid=$(find_process_using_port "$port")
    
    if [ -n "$pid" ] && [ "$pid" -gt 0 ] 2>/dev/null; then
        log_warn "Killing process $pid on port $port"
        if kill -9 "$pid" 2>/dev/null; then
            sleep 1
            return 0
        elif sudo kill -9 "$pid" 2>/dev/null; then
            sleep 1
            return 0
        fi
    fi
    
    # Alternative: Kill all processes matching common services
    case $port in
        80|443)
            sudo pkill -9 -f "nginx|apache|httpd|http-server" 2>/dev/null || true
            ;;
        5432)
            sudo pkill -9 -f "postgres|psql" 2>/dev/null || true
            ;;
        27017)
            sudo pkill -9 -f "mongod|mongodb" 2>/dev/null || true
            ;;
        6379)
            sudo pkill -9 -f "redis" 2>/dev/null || true
            ;;
    esac
    
    sleep 1
    return 0
}

# Function to stop Docker containers using specific ports
stop_docker_containers() {
    log_step "Stopping all Docker containers..."
    
    if command -v docker &> /dev/null; then
        docker-compose down -v 2>/dev/null || true
        docker stop $(docker ps -q) 2>/dev/null || true
        docker system prune -f 2>/dev/null || true
        sleep 2
        log_ok "Docker containers stopped"
    fi
}

# Main port management function
manage_ports() {
    log_step "Checking for port conflicts..."
    echo ""
    
    local conflicts=0
    local ports_in_use=()
    
    # Check all required ports
    for port_info in "${REQUIRED_PORTS[@]}"; do
        IFS=':' read -r port service <<< "$port_info"
        
        if check_port "$port"; then
            log_warn "Port $port ($service) is already in use"
            ports_in_use+=("$port")
            ((conflicts++))
        else
            log_ok "Port $port ($service) is available"
        fi
    done
    
    echo ""
    
    if [ $conflicts -eq 0 ]; then
        log_ok "All required ports are available!"
        return 0
    fi
    
    return 1
}

# Automatic port conflict resolution
auto_fix_ports() {
    log_step "Checking for port conflicts..."
    
    # IMMEDIATE PRE-CLEANUP: Kill everything that might block ports
    log_info "Pre-cleanup: Stopping potential port blockers..."
    pkill -9 -f "nginx|apache2|apache|httpd|haproxy" 2>/dev/null || true
    pkill -9 postgres 2>/dev/null || true
    pkill -9 mongod 2>/dev/null || true
    pkill -9 redis-server 2>/dev/null || true
    pkill -9 node 2>/dev/null || true
    
    # Safely stop Docker containers if Docker is running
    if command -v docker &> /dev/null && docker ps &> /dev/null; then
        local containers=$(docker ps -aq)
        if [ -n "$containers" ]; then
            docker stop $containers 2>/dev/null || true
        fi
    fi
    
    if command -v systemctl &> /dev/null; then
        systemctl stop docker 2>/dev/null || true
    fi
    sleep 2
    
    local conflicts=0
    local ports_in_use=()
    local max_attempts=3
    local attempt=1
    
    # Retry loop
    while [ $attempt -le $max_attempts ]; do
        conflicts=0
        ports_in_use=()
        
        # Check all required ports
        for port_info in "${REQUIRED_PORTS[@]}"; do
            IFS=':' read -r port service <<< "$port_info"
            
            if check_port "$port"; then
                log_warn "Port $port ($service) is already in use"
                ports_in_use+=("$port")
                ((conflicts++))
            fi
        done
        
        if [ $conflicts -eq 0 ]; then
            log_ok "All required ports are available!"
            return 0
        fi
        
        # Attempt to resolve conflicts
        log_warn "Attempt $attempt/$max_attempts to resolve $conflicts port conflict(s)..."
        
        # Kill nginx and apache directly
        log_info "Stopping web servers (nginx, apache, haproxy)..."
        if command -v systemctl &> /dev/null; then
            systemctl stop nginx 2>/dev/null || true
            systemctl stop apache2 2>/dev/null || true
            systemctl stop httpd 2>/dev/null || true
            systemctl stop haproxy 2>/dev/null || true
        fi
        pkill -9 -f "nginx|apache|httpd|http-server|haproxy" 2>/dev/null || true
        pkill -9 postgres mongod redis-server node 2>/dev/null || true
        
        # Stop all Docker containers safely
        log_info "Stopping all Docker containers..."
        if command -v systemctl &> /dev/null; then
            systemctl stop docker 2>/dev/null || true
        fi
        
        if command -v docker &> /dev/null && docker ps &> /dev/null; then
            local containers=$(docker ps -aq)
            if [ -n "$containers" ]; then
                docker stop $containers 2>/dev/null || true
            fi
            docker system prune -f --all --volumes 2>/dev/null || true
        fi
        
        # Kill any remaining processes using the specific ports
        for port in "${ports_in_use[@]}"; do
            log_info "Releasing port $port..."
            kill_port_process "$port" || true
        done
        
        # Force release of ports using fuser if available
        if command -v fuser &> /dev/null; then
            for port in "${ports_in_use[@]}"; do
                fuser -k "$port/tcp" 2>/dev/null || true
                fuser -k "$port/udp" 2>/dev/null || true
            done
        fi
        
        # LONGER WAIT for system to truly release ports
        log_info "Waiting for system to release ports... (8 seconds)"
        sleep 8
        ((attempt++))
        
        if [ $attempt -le $max_attempts ]; then
            log_info "Retrying port check (attempt $attempt/$max_attempts)..."
            echo ""
        fi
    done
    
    # All attempts exhausted
    log_error "Could not resolve port conflicts after $max_attempts attempts"
    echo ""
    echo "Remaining conflicting ports:"
    for port_info in "${REQUIRED_PORTS[@]}"; do
        IFS=':' read -r port service <<< "$port_info"
        if check_port "$port"; then
            echo "  - Port $port ($service)"
        fi
    done
    echo ""
    echo "Manual resolution:"
    echo "  sudo pkill -9 nginx          # Kill Nginx"
    echo "  sudo docker system prune -a  # Clean Docker"
    echo "  sudo netstat -tulpn | grep -E ':(80|443|3000|3001|3002|3003|5432|27017|6379)' # Check ports"
    return 1
}

# Show usage
show_usage() {
    cat << EOF
Usage: bash manage-ports.sh [OPTION]

Port Management and Conflict Resolution for Taxi System

Options:
  --auto           Automatically fix conflicts (default, same as --fix)
  --fix            Automatically fix port conflicts (up to 3 attempts)
  --check          Check for port conflicts only (non-interactive)
  --list           List required ports
  --help           Show this help message

Examples:
  bash manage-ports.sh                    # Auto-fix (default)
  bash manage-ports.sh --auto             # Auto-fix with retries
  bash manage-ports.sh --check            # Check only
  bash manage-ports.sh --list             # List ports
  bash manage-ports.sh --help             # Show help

Auto-fix behavior:
  1. Checks all 9 required ports
  2. If conflicts found, stops Docker containers
  3. Kills processes using conflicting ports
  4. Retries up to 3 times
  5. Returns success if all ports are free

EOF
}

# Main execution
main() {
    local action="${1:---auto}"
    
    case "$action" in
        --check)
            manage_ports
            ;;
        --auto|--fix)
            auto_fix_ports
            ;;
        --list)
            echo -e "${CYAN}Required Ports for Taxi System:${NC}"
            echo ""
            for port_info in "${REQUIRED_PORTS[@]}"; do
                IFS=':' read -r port service <<< "$port_info"
                printf "  %-6s %s\n" "$port" "$service"
            done
            echo ""
            ;;
        --help)
            show_usage
            ;;
        *)
            log_error "Unknown option: $action"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
