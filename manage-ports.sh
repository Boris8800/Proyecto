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
    if command -v nc &> /dev/null; then
        nc -z 127.0.0.1 "$port" 2>/dev/null && return 0 || return 1
    elif command -v curl &> /dev/null; then
        curl -s http://127.0.0.1:"$port" >/dev/null 2>&1 && return 0 || return 1
    else
        # Fallback: use /dev/tcp
        bash -c "</dev/tcp/127.0.0.1/$port" 2>/dev/null && return 0 || return 1
    fi
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
    
    # Handle conflicts
    log_error "$conflicts port(s) in use. Attempting to resolve..."
    echo ""
    echo "Options:"
    echo "  1) Stop all Docker containers and try again"
    echo "  2) Kill processes using conflicting ports"
    echo "  3) Exit (manual cleanup required)"
    echo ""
    
    read -r -p "Choose option (1-3): " choice
    
    case "$choice" in
        1)
            stop_docker_containers
            sleep 2
            # Retry check
            manage_ports
            ;;
        2)
            for port in "${ports_in_use[@]}"; do
                if kill_port_process "$port"; then
                    log_ok "Freed port $port"
                else
                    log_warn "Could not free port $port"
                fi
            done
            sleep 2
            # Retry check
            manage_ports
            ;;
        3)
            log_error "Port conflicts not resolved. Please manually cleanup:"
            for port in "${ports_in_use[@]}"; do
                echo "  Port $port: lsof -i :$port (to identify process)"
                echo "  Port $port: sudo kill -9 <pid> (to kill process)"
            done
            return 1
            ;;
        *)
            log_error "Invalid option"
            manage_ports
            ;;
    esac
}

# Show usage
show_usage() {
    cat << EOF
Usage: bash manage-ports.sh [OPTION]

Port Management and Conflict Resolution for Taxi System

Options:
  --check          Check for port conflicts (default)
  --fix            Attempt to automatically fix conflicts
  --list           List required ports
  --help           Show this help message

Examples:
  bash manage-ports.sh --check
  bash manage-ports.sh --fix
  bash manage-ports.sh --list

EOF
}

# Main execution
main() {
    local action="${1:-check}"
    
    case "$action" in
        --check)
            manage_ports
            ;;
        --fix)
            stop_docker_containers
            sleep 2
            manage_ports
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
