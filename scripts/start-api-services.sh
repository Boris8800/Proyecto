#!/bin/bash

###############################################
# Services Startup Script - All Services
# Starts Magic Links, Job Magic Links, and Status Dashboard
###############################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# ============================================
# Kill existing processes
# ============================================
kill_existing_services() {
    print_header "Stopping Existing Services"
    
    for port in 3333 3334 8080; do
        if lsof -i :$port >/dev/null 2>&1; then
            PID=$(lsof -i :$port -t)
            kill -9 $PID 2>/dev/null || true
            print_success "Killed process on port $port"
        fi
    done
}

# ============================================
# Start Magic Links API (port 3333)
# ============================================
start_magic_links() {
    print_header "Starting Magic Links API (Port 3333)"
    
    cd "$PROJECT_ROOT/web/api"
    
    if [ ! -f "magic-links-server.js" ]; then
        print_error "magic-links-server.js not found!"
        return 1
    fi
    
    node magic-links-server.js > /tmp/magic-links.log 2>&1 &
    MAGIC_PID=$!
    
    sleep 2
    
    if lsof -i :3333 >/dev/null 2>&1; then
        print_success "Magic Links API running on port 3333 (PID: $MAGIC_PID)"
    else
        print_error "Magic Links API failed to start"
        cat /tmp/magic-links.log
        return 1
    fi
}

# ============================================
# Start Job Magic Links API (port 3334)
# ============================================
start_job_magic_links() {
    print_header "Starting Job Magic Links API (Port 3334)"
    
    cd "$PROJECT_ROOT/web/api"
    
    if [ ! -f "job-magic-links.js" ]; then
        print_error "job-magic-links.js not found!"
        return 1
    fi
    
    node job-magic-links.js > /tmp/job-magic-links.log 2>&1 &
    JOB_PID=$!
    
    sleep 2
    
    if lsof -i :3334 >/dev/null 2>&1; then
        print_success "Job Magic Links API running on port 3334 (PID: $JOB_PID)"
    else
        print_error "Job Magic Links API failed to start"
        cat /tmp/job-magic-links.log
        return 1
    fi
}

# ============================================
# Start Status Dashboard (port 8080)
# ============================================
start_status_dashboard() {
    print_header "Starting Status Dashboard (Port 8080)"
    
    cd "$PROJECT_ROOT/web/status"
    
    if [ ! -f "server.js" ]; then
        print_error "server.js not found!"
        return 1
    fi
    
    node server.js > /tmp/status-dashboard.log 2>&1 &
    STATUS_PID=$!
    
    sleep 2
    
    if lsof -i :8080 >/dev/null 2>&1; then
        print_success "Status Dashboard running on port 8080 (PID: $STATUS_PID)"
    else
        print_error "Status Dashboard failed to start"
        cat /tmp/status-dashboard.log
        return 1
    fi
}

# ============================================
# Verify all services
# ============================================
verify_services() {
    print_header "Service Verification"
    
    FAILED=0
    
    for port in 3333 3334 8080; do
        if lsof -i :$port >/dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} Port $port - LISTENING"
        else
            echo -e "${RED}❌${NC} Port $port - NOT LISTENING"
            FAILED=$((FAILED + 1))
        fi
    done
    
    if [ $FAILED -eq 0 ]; then
        print_success "All services running!"
        return 0
    else
        print_error "$FAILED service(s) failed to start"
        return 1
    fi
}

# ============================================
# Main execution
# ============================================
main() {
    print_header "API SERVICES STARTUP"
    
    cd "$PROJECT_ROOT"
    
    # Kill existing
    kill_existing_services
    
    # Start services
    if ! start_magic_links; then
        print_warning "Magic Links API start had issues - continuing"
    fi
    
    if ! start_job_magic_links; then
        print_warning "Job Magic Links API start had issues - continuing"
    fi
    
    if ! start_status_dashboard; then
        print_warning "Status Dashboard start had issues - continuing"
    fi
    
    # Verify
    echo ""
    if verify_services; then
        echo ""
        print_success "Services started successfully!"
        echo ""
        echo -e "${BLUE}Access your services:${NC}"
        echo "  Magic Links API:     http://localhost:3333"
        echo "  Job Magic Links API: http://localhost:3334"
        echo "  Status Dashboard:    http://localhost:8080"
        echo ""
        echo -e "${BLUE}View logs:${NC}"
        echo "  tail -f /tmp/magic-links.log"
        echo "  tail -f /tmp/job-magic-links.log"
        echo "  tail -f /tmp/status-dashboard.log"
        echo ""
    else
        print_error "Some services failed to start. Check logs above."
        exit 1
    fi
}

main "$@"
