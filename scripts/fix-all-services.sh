#!/bin/bash

################################################################################
# COMPREHENSIVE FIX - ALL SERVICES
# Complete service restart and configuration with new port mappings
################################################################################

set -e

PROJECT_ROOT="/root/Proyecto"
cd "$PROJECT_ROOT" || exit 1

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        COMPREHENSIVE SERVICE FIX - ALL SERVICES               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# STEP 1: Check Current Status
# ============================================================================
echo -e "${BLUE}[STEP 1]${NC} Checking current service status..."
echo ""

echo "Docker Containers:"
docker ps -a | grep taxi || echo "No taxi containers found"
echo ""

echo "Listening Ports:"
netstat -tuln 2>/dev/null | grep -E "(3001|3002|3030|3040|3333)" || echo "No services listening"
echo ""

# ============================================================================
# STEP 2: Stop all Services
# ============================================================================
echo -e "${YELLOW}[STEP 2]${NC} Stopping all services..."

# Kill Node processes
pkill -f "node server-admin.js" || true
pkill -f "node server-driver.js" || true
pkill -f "node server-customer.js" || true
pkill -f "node status/server.js" || true
pkill -f "node magic-links-server.js" || true
pkill -f "node job-magic-links.js" || true

sleep 2
echo -e "${GREEN}✓${NC} Node processes stopped"
echo ""

# ============================================================================
# STEP 3: Stop Docker Containers
# ============================================================================
echo -e "${YELLOW}[STEP 3]${NC} Stopping Docker containers..."

cd "$PROJECT_ROOT/config" || exit 1
docker-compose -f docker-compose.yml down 2>/dev/null || true
sleep 3

echo -e "${GREEN}✓${NC} Docker containers stopped"
echo ""

# ============================================================================
# STEP 4: Clean up and reinstall dependencies
# ============================================================================
echo -e "${YELLOW}[STEP 4]${NC} Installing dependencies..."

cd "$PROJECT_ROOT/web" || exit 1
rm -rf node_modules package-lock.json 2>/dev/null || true
npm install --prefer-offline 2>&1 | tail -5

echo -e "${GREEN}✓${NC} Dependencies installed"
echo ""

# ============================================================================
# STEP 5: Start Docker Containers
# ============================================================================
echo -e "${YELLOW}[STEP 5]${NC} Starting Docker containers..."

cd "$PROJECT_ROOT/config" || exit 1
docker-compose -f docker-compose.yml up -d 2>&1 | tail -10

# Wait for containers to start
echo "Waiting for containers to start (15 seconds)..."
sleep 15

echo -e "${GREEN}✓${NC} Docker containers started"
echo ""

# ============================================================================
# STEP 6: Check Container Health
# ============================================================================
echo -e "${BLUE}[STEP 6]${NC} Checking container health..."
echo ""

docker ps -a | grep taxi

echo ""

# ============================================================================
# STEP 7: Start Node.js Services
# ============================================================================
echo -e "${YELLOW}[STEP 7]${NC} Starting Node.js web services..."

cd "$PROJECT_ROOT" || exit 1

# Start Status Dashboard
echo "Starting Status Dashboard (port 3030)..."
nohup node web/status/server.js > /root/Proyecto/logs/status.log 2>&1 &
STATUS_PID=$!
sleep 2
echo -e "${GREEN}✓${NC} Status Dashboard started (PID: $STATUS_PID)"

# Start Admin Server
echo "Starting Admin Dashboard (port 3001)..."
nohup npm run server-admin > /root/Proyecto/logs/admin.log 2>&1 &
sleep 2
echo -e "${GREEN}✓${NC} Admin Dashboard started"

# Start Driver Server
echo "Starting Driver Portal (port 3002)..."
nohup npm run server-driver > /root/Proyecto/logs/driver.log 2>&1 &
sleep 2
echo -e "${GREEN}✓${NC} Driver Portal started"

# Start Customer Server
echo "Starting Customer App (port 3000)..."
nohup npm run server-customer > /root/Proyecto/logs/customer.log 2>&1 &
sleep 2
echo -e "${GREEN}✓${NC} Customer App started"

echo ""

# ============================================================================
# STEP 8: Wait for Services to Be Ready
# ============================================================================
echo -e "${YELLOW}[STEP 8]${NC} Waiting for services to become ready (10 seconds)..."
sleep 10
echo ""

# ============================================================================
# STEP 9: Verify All Services
# ============================================================================
echo -e "${BLUE}[STEP 9]${NC} Verifying all services..."
echo ""

declare -a PORTS=(3030 3001 3002 3000 3040 3333)
declare -a SERVICES=("Status Dashboard" "Admin Dashboard" "Driver Portal" "Customer App" "Main API" "Magic Links API")
FAILED=0

for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    SERVICE=${SERVICES[$i]}
    
    if timeout 2 curl -s -w "%{http_code}" -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null | grep -q "200"; then
        echo -e "${GREEN}✓${NC} Port $PORT ($SERVICE) - RESPONDING"
    else
        echo -e "${RED}✗${NC} Port $PORT ($SERVICE) - NOT RESPONDING"
        FAILED=$((FAILED+1))
    fi
done

echo ""

# ============================================================================
# STEP 10: Final Status Report
# ============================================================================
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    FINAL STATUS REPORT                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "Docker Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep taxi

echo ""
echo "Listening Ports:"
netstat -tuln 2>/dev/null | grep -E "(3001|3002|3030|3040|3333)" | awk '{print $4}' | sort -u | while read port; do
    echo "  ✓ $port"
done

echo ""
echo "Node.js Processes:"
ps aux | grep -E "node.*server|status" | grep -v grep | wc -l | xargs echo "  Running processes:"

echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ ALL SERVICES ARE OPERATIONAL${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Access your services:"
    echo "  Status Dashboard: http://5.249.164.40:3030"
    echo "  Admin Dashboard:  http://5.249.164.40:3001"
    echo "  Driver Portal:    http://5.249.164.40:3002"
    echo "  Customer App:     http://5.249.164.40:3000"
    echo "  Main API:         http://5.249.164.40:3040"
    echo "  Magic Links API:  http://5.249.164.40:3333"
else
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}⚠ $FAILED service(s) failed to start${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Check logs:"
    echo "  tail -f /root/Proyecto/logs/status.log"
    echo "  tail -f /root/Proyecto/logs/admin.log"
    echo "  tail -f /root/Proyecto/logs/driver.log"
    echo "  tail -f /root/Proyecto/logs/customer.log"
    echo "  docker logs taxi-status"
fi

echo ""
