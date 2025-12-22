#!/bin/bash

#============================================================
# SWIFTCAB SERVER CONTROL SCRIPT
# Manage all SwiftCab services and infrastructure
#============================================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/swiftcab.log"
SERVICES=("taxi-postgres" "taxi-redis" "taxi-mongo" "taxi-api" "taxi-admin" "taxi-driver" "taxi-customer")
PORTS=(5432 6379 27017 3000 3001 3002 3003)

#============================================================
# UTILITY FUNCTIONS
#============================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
}

print_section() {
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

check_docker() {
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker daemon is NOT running!${NC}"
        echo -e "${YELLOW}Attempting to start Docker...${NC}"
        log "Docker not running, attempting to start"
        return 1
    fi
    return 0
}

check_port() {
    if lsof -i :$1 &> /dev/null; then
        return 0
    fi
    return 1
}

#============================================================
# MAIN COMMANDS
#============================================================

cmd_status() {
    print_header "SWIFTCAB SERVER STATUS"
    
    if ! check_docker; then
        echo -e "${RED}⚠️  Docker is not available - Status may be incomplete${NC}\n"
    fi
    
    print_section "📦 DOCKER CONTAINERS"
    docker-compose ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || {
        echo -e "${RED}Unable to retrieve container status${NC}"
    }
    
    print_section "🚀 SERVICES & ACCESS POINTS"
    echo -e "  ${GREEN}✓${NC} Admin Dashboard      → ${CYAN}http://localhost:3001${NC}"
    echo -e "  ${GREEN}✓${NC} Driver App           → ${CYAN}http://localhost:3002${NC}"
    echo -e "  ${GREEN}✓${NC} Customer Dashboard   → ${CYAN}http://localhost:3003${NC}"
    echo -e "  ${GREEN}✓${NC} SwiftCab Booking     → ${CYAN}http://localhost:3003/booking.html${NC}"
    echo -e "  ${GREEN}✓${NC} Authentication       → ${CYAN}http://localhost:3003/auth${NC}"
    echo -e "  ${GREEN}✓${NC} API Server           → ${CYAN}http://localhost:3000${NC}"
    
    print_section "🔌 PORT STATUS"
    for i in "${!SERVICES[@]}"; do
        port=${PORTS[$i]}
        if check_port $port; then
            echo -e "  ${GREEN}✓${NC} ${SERVICES[$i]:5} (Port $port) → ${GREEN}OPEN${NC}"
        else
            echo -e "  ${RED}✗${NC} ${SERVICES[$i]:5} (Port $port) → ${RED}CLOSED${NC}"
        fi
    done
    
    print_section "🌐 CONNECTIVITY CHECKS"
    declare -A endpoints=(
        ["Admin"]="http://localhost:3001"
        ["Driver"]="http://localhost:3002"
        ["Customer"]="http://localhost:3003"
        ["Booking"]="http://localhost:3003/booking.html"
    )
    
    for name in "${!endpoints[@]}"; do
        url=${endpoints[$name]}
        status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
        if [ "$status" = "200" ]; then
            echo -e "  ${GREEN}✓${NC} $name → ${GREEN}OK${NC} (HTTP $status)"
        else
            echo -e "  ${RED}✗${NC} $name → ${RED}FAIL${NC} (HTTP $status)"
        fi
    done
    
    print_section "🗄️  DATABASE STATUS"
    echo -e "  PostgreSQL (5432)"
    echo -e "  Redis (6379)"
    echo -e "  MongoDB (27017)"
    
    print_section "💾 STORAGE"
    du -sh "$SCRIPT_DIR" 2>/dev/null | awk '{print "  Project size: " $1}'
    
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}\n"
}

cmd_start() {
    print_header "STARTING SWIFTCAB SERVICES"
    
    if ! check_docker; then
        echo -e "${RED}❌ Cannot start services - Docker daemon not running${NC}\n"
        log "Failed to start - Docker not available"
        return 1
    fi
    
    echo -e "${YELLOW}Starting all Docker containers...${NC}\n"
    cd "$SCRIPT_DIR"
    docker-compose up -d
    
    echo -e "\n${YELLOW}Waiting for services to initialize...${NC}"
    sleep 3
    
    echo -e "${GREEN}✓ Services started!${NC}\n"
    log "Started all services"
    
    cmd_status
}

cmd_stop() {
    print_header "STOPPING SWIFTCAB SERVICES"
    
    if ! check_docker; then
        echo -e "${RED}❌ Docker daemon not running${NC}\n"
        return 1
    fi
    
    echo -e "${YELLOW}Stopping all Docker containers...${NC}\n"
    cd "$SCRIPT_DIR"
    docker-compose down
    
    echo -e "\n${GREEN}✓ Services stopped!${NC}\n"
    log "Stopped all services"
}

cmd_restart() {
    print_header "RESTARTING SWIFTCAB SERVICES"
    cmd_stop
    sleep 2
    cmd_start
}

cmd_logs() {
    if [ -z "$1" ]; then
        print_header "SWIFTCAB LOGS (last 100 lines, all services)"
        docker-compose logs --tail=100 2>/dev/null
    else
        print_header "SWIFTCAB LOGS - $1"
        docker-compose logs --tail=100 "$1" 2>/dev/null
    fi
}

cmd_clean() {
    print_header "CLEANING SWIFTCAB SYSTEM"
    
    read -p "This will remove all containers and volumes. Continue? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$SCRIPT_DIR"
        echo -e "${YELLOW}Removing containers and volumes...${NC}"
        docker-compose down -v
        echo -e "${GREEN}✓ Clean complete!${NC}\n"
        log "System cleaned"
    else
        echo -e "${YELLOW}Cancelled.${NC}\n"
    fi
}

cmd_health() {
    print_header "HEALTH CHECK"
    
    echo -e "${YELLOW}Checking system health...${NC}\n"
    
    local all_ok=true
    
    # Check Docker
    if check_docker; then
        echo -e "${GREEN}✓${NC} Docker daemon"
    else
        echo -e "${RED}✗${NC} Docker daemon"
        all_ok=false
    fi
    
    # Check containers
    for service in "${SERVICES[@]}"; do
        if docker-compose ps -q "$service" 2>/dev/null | grep -q .; then
            echo -e "${GREEN}✓${NC} $service"
        else
            echo -e "${RED}✗${NC} $service"
            all_ok=false
        fi
    done
    
    echo ""
    if [ "$all_ok" = true ]; then
        echo -e "${GREEN}✓ All systems healthy!${NC}\n"
        log "Health check passed"
        return 0
    else
        echo -e "${RED}✗ Some systems are down${NC}\n"
        log "Health check failed"
        return 1
    fi
}

cmd_open() {
    print_header "OPENING SWIFTCAB SERVICES"
    
    echo -e "${YELLOW}Opening in default browser...${NC}\n"
    
    if command -v "$BROWSER" &> /dev/null; then
        "$BROWSER" "http://localhost:3003/booking.html" &
    elif command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:3003/booking.html" &
    elif command -v open &> /dev/null; then
        open "http://localhost:3003/booking.html" &
    else
        echo -e "${CYAN}Open manually: http://localhost:3003/booking.html${NC}\n"
    fi
}

cmd_backup() {
    print_header "CREATING BACKUP"
    
    local backup_dir="$SCRIPT_DIR/backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/swiftcab_backup_$timestamp.tar.gz"
    
    mkdir -p "$backup_dir"
    
    echo -e "${YELLOW}Creating backup...${NC}"
    tar -czf "$backup_file" \
        --exclude=node_modules \
        --exclude=.git \
        --exclude=.docker \
        -C "$(dirname "$SCRIPT_DIR")" "$(basename "$SCRIPT_DIR")" 2>/dev/null
    
    echo -e "${GREEN}✓ Backup created: $backup_file${NC}\n"
    log "Backup created: $backup_file"
}

cmd_help() {
    print_header "SWIFTCAB CONTROL - HELP"
    
    cat << 'EOF'
Usage: ./swiftcab-control.sh [COMMAND] [OPTIONS]

COMMANDS:

  status              Show status of all services
  start               Start all services
  stop                Stop all services
  restart             Restart all services
  logs [SERVICE]      View logs (optionally for specific service)
  health              Perform system health check
  clean               Remove all containers and volumes (DESTRUCTIVE)
  backup              Create backup of project
  open                Open booking page in browser
  help                Show this help message

EXAMPLES:

  # Check if everything is running
  ./swiftcab-control.sh status

  # Start all services and check status
  ./swiftcab-control.sh start

  # View logs from API
  ./swiftcab-control.sh logs taxi-api

  # Perform health check
  ./swiftcab-control.sh health

  # Restart everything
  ./swiftcab-control.sh restart

SERVICES:
  - PostgreSQL (Port 5432)
  - Redis (Port 6379)
  - MongoDB (Port 27017)
  - API Server (Port 3000)
  - Admin Dashboard (Port 3001)
  - Driver App (Port 3002)
  - Customer Dashboard (Port 3003)

ACCESS POINTS:
  Admin Dashboard    → http://localhost:3001
  Driver App         → http://localhost:3002
  Customer Dashboard → http://localhost:3003
  SwiftCab Booking   → http://localhost:3003/booking.html

LOGS:
  View all logs     → swiftcab-control.sh logs
  View API logs     → swiftcab-control.sh logs taxi-api
  View in real-time → docker-compose logs -f

EOF
}

#============================================================
# MAIN EXECUTION
#============================================================

main() {
    local command="${1:-help}"
    
    case "$command" in
        status)
            cmd_status
            ;;
        start)
            cmd_start
            ;;
        stop)
            cmd_stop
            ;;
        restart)
            cmd_restart
            ;;
        logs)
            cmd_logs "$2"
            ;;
        health)
            cmd_health
            ;;
        clean)
            cmd_clean
            ;;
        backup)
            cmd_backup
            ;;
        open)
            cmd_open
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            echo "Run './swiftcab-control.sh help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
