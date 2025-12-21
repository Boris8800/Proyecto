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
    
    # Try multiple methods to check if port is in use
    # Method 1: Using /dev/tcp (most reliable in bash)
    if bash -c "</dev/tcp/127.0.0.1/$port" 2>/dev/null; then
        return 0
    fi
    
    # Method 2: Using nc if available
    if command -v nc &> /dev/null; then
        if nc -z -w $timeout 127.0.0.1 "$port" 2>/dev/null; then
            return 0
        fi
    fi
    
    # Method 3: Using curl if available
    if command -v curl &> /dev/null; then
        if curl -s --max-time $timeout http://127.0.0.1:"$port" >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    # Method 4: Using netstat if available (most direct)
    if command -v netstat &> /dev/null; then
        if netstat -tln 2>/dev/null | grep -q "127.0.0.1:$port"; then
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
        lsof -i :"$port" 2>/dev/null | grep -v COMMAND | awk '{print $2}' || true
    elif command -v ss &> /dev/null; then
        ss -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 || true
    else
        return 1
    fi
}

# Function to kill process using port
kill_port_process() {
    local port=$1
    local pid=$(find_process_using_port "$port")
    
    if [ -n "$pid" ]; then
        log_warn "Killing process $pid using port $port"
        kill -9 "$pid" 2>/dev/null || sudo kill -9 "$pid" 2>/dev/null || true
        sleep 1
        return 0
    fi
    return 1
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
        
        # Kill any nginx processes (common port 80 user)
        log_info "Stopping Nginx (if running)..."
        sudo pkill -9 nginx 2>/dev/null || true
        
        # Stop Docker completely
        log_info "Stopping all Docker containers..."
        sudo docker stop $(sudo docker ps -q) 2>/dev/null || true
        sudo docker-compose down -v 2>/dev/null || true
        docker-compose down -v 2>/dev/null || true
        
        # Clean Docker
        log_info "Cleaning Docker resources..."
        sudo docker system prune -f -a 2>/dev/null || true
        docker system prune -f -a 2>/dev/null || true
        
        # Kill any remaining processes using the ports
        for port in "${ports_in_use[@]}"; do
            kill_port_process "$port"
        done
        
        # Wait and retry with fresh port check
        sleep 3
        ((attempt++))
        
        if [ $attempt -le $max_attempts ]; then
            log_info "Retrying port check (attempt $attempt)..."
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
