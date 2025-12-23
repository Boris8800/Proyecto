#!/bin/bash

###############################################
# Services Monitor - Keep Services Alive
# Monitors and restarts services if they crash
###############################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOGFILE="/tmp/services-monitor.log"
CHECK_INTERVAL=30

print_log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a $LOGFILE
}

check_service() {
    local port=$1
    local name=$2
    local script=$3
    
    if ! lsof -i :$port >/dev/null 2>&1; then
        print_log "${RED}❌ $name (port $port) DOWN - Restarting...${NC}"
        
        # Kill any lingering process
        pkill -f "node $script" 2>/dev/null || true
        sleep 1
        
        # Start service
        case $script in
            "magic-links-server.js")
                cd "$PROJECT_ROOT/web/api"
                node magic-links-server.js > /tmp/magic-links.log 2>&1 &
                ;;
            "job-magic-links.js")
                cd "$PROJECT_ROOT/web/api"
                node job-magic-links.js > /tmp/job-magic-links.log 2>&1 &
                ;;
            "server.js")
                cd "$PROJECT_ROOT/web/status"
                node server.js > /tmp/status-dashboard.log 2>&1 &
                ;;
        esac
        
        sleep 2
        
        if lsof -i :$port >/dev/null 2>&1; then
            print_log "${GREEN}✅ $name (port $port) Restarted${NC}"
        else
            print_log "${RED}❌ Failed to restart $name${NC}"
        fi
    else
        print_log "${GREEN}✓${NC} $name (port $port) OK"
    fi
}

main() {
    print_log "${BLUE}Services Monitor Started${NC}"
    print_log "Checking every $CHECK_INTERVAL seconds..."
    
    while true; do
        check_service 3333 "Magic Links API" "magic-links-server.js"
        check_service 3334 "Job Magic Links API" "job-magic-links.js"
        check_service 8080 "Status Dashboard" "server.js"
        
        sleep $CHECK_INTERVAL
    done
}

main "$@"
