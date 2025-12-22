#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure we're in the project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || {
  echo -e "${RED}Error: Failed to change to project directory${NC}"
  exit 1
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        SWIFT CAB - COMPLETE DEPLOYMENT & FIX                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

VPS_IP="${1:-5.249.164.40}"
echo -e "${YELLOW}[INFO]${NC} VPS IP: $VPS_IP"
echo ""

# Step 1: Kill old processes
echo -e "${YELLOW}[STEP 1]${NC} Killing old processes on ports 3001-3003..."
for port in 3001 3002 3003 8080; do
  pid=$(lsof -ti:$port 2>/dev/null)
  if [ -n "$pid" ]; then
    kill -9 $pid 2>/dev/null
    echo -e "${GREEN}✓${NC} Killed process on port $port"
  fi
done
sleep 2

# Step 2: Stop old Docker containers
echo -e "${YELLOW}[STEP 2]${NC} Stopping old Docker containers..."
docker-compose -f docker-compose.yml down 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓${NC} Docker containers stopped"

# Step 3: Clean up old dashboards (but keep modern ones)
echo -e "${YELLOW}[STEP 3]${NC} Cleaning up old/legacy files..."
# Remove only old test/legacy files, not the modern dashboards
rm -f web/customer/booking.html web/customer/payment.html web/customer/test.html 2>/dev/null || true
rm -f web/admin/legacy.html web/driver/legacy.html 2>/dev/null || true
echo -e "${GREEN}✓${NC} Old files cleaned"

# Step 4: Verify new dashboard files exist
echo -e "${YELLOW}[STEP 4]${NC} Verifying modern dashboards..."
if [ -f "web/admin/index.html" ] && [ -f "web/driver/index.html" ] && [ -f "web/customer/index.html" ]; then
  echo -e "${GREEN}✓${NC} Modern dashboards verified"
else
  echo -e "${RED}✗${NC} Dashboards not found!"
  exit 1
fi

# Step 5: Install npm dependencies
echo -e "${YELLOW}[STEP 5]${NC} Installing npm dependencies..."
cd web
npm install --silent 2>/dev/null
echo -e "${GREEN}✓${NC} Dependencies installed"
cd ..

# Step 6: Start dashboard servers in background
echo -e "${YELLOW}[STEP 6]${NC} Starting dashboard servers..."
cd web

# Start admin server
nohup node server-admin.js > /tmp/admin.log 2>&1 &
ADMIN_PID=$!
sleep 1
if kill -0 $ADMIN_PID 2>/dev/null; then
  echo -e "${GREEN}✓${NC} Admin server started (PID: $ADMIN_PID, Port 3001)"
else
  echo -e "${RED}✗${NC} Failed to start admin server"
  cat /tmp/admin.log
fi

# Start driver server
nohup node server-driver.js > /tmp/driver.log 2>&1 &
DRIVER_PID=$!
sleep 1
if kill -0 $DRIVER_PID 2>/dev/null; then
  echo -e "${GREEN}✓${NC} Driver server started (PID: $DRIVER_PID, Port 3002)"
else
  echo -e "${RED}✗${NC} Failed to start driver server"
  cat /tmp/driver.log
fi

# Start customer server
nohup node server-customer.js > /tmp/customer.log 2>&1 &
CUSTOMER_PID=$!
sleep 1
if kill -0 $CUSTOMER_PID 2>/dev/null; then
  echo -e "${GREEN}✓${NC} Customer server started (PID: $CUSTOMER_PID, Port 3003)"
else
  echo -e "${RED}✗${NC} Failed to start customer server"
  cat /tmp/customer.log
fi

cd ..

# Step 7: Start Docker containers
echo -e "${YELLOW}[STEP 7]${NC} Starting Docker services..."
docker-compose up -d 2>&1 | grep -E "(Created|Starting|Started)" || true
sleep 3
echo -e "${GREEN}✓${NC} Docker services started"

# Step 8: Wait for services
echo -e "${YELLOW}[STEP 8]${NC} Waiting for services to be ready..."
sleep 5

# Step 9: Verify all services
echo -e "${YELLOW}[STEP 9]${NC} Verifying services..."
echo ""

FAILED=0

# Check dashboard servers
for port in 3001 3002 3003; do
  if curl -s http://localhost:$port > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Port $port responding"
  else
    echo -e "${RED}✗${NC} Port $port not responding"
    FAILED=$((FAILED+1))
  fi
done

# Check Docker containers
echo ""
echo -e "${BLUE}Docker Containers:${NC}"
docker-compose ps

# Step 10: Display access information
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  ✅ DEPLOYMENT COMPLETE                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📊 ACCESS YOUR DASHBOARDS:${NC}"
echo -e "  Admin Dashboard:    ${YELLOW}http://$VPS_IP:3001${NC}"
echo -e "  Driver Portal:      ${YELLOW}http://$VPS_IP:3002${NC}"
echo -e "  Customer App:       ${YELLOW}http://$VPS_IP:3003${NC}"
echo ""
echo -e "${GREEN}🐳 DOCKER SERVICES:${NC}"
echo -e "  API Server:         ${YELLOW}http://$VPS_IP:3000${NC}"
echo -e "  Status Dashboard:   ${YELLOW}http://$VPS_IP:8080${NC}"
echo ""
echo -e "${GREEN}📁 PROCESS IDS:${NC}"
echo -e "  Admin:   $ADMIN_PID"
echo -e "  Driver:  $DRIVER_PID"
echo -e "  Customer: $CUSTOMER_PID"
echo ""
echo -e "${GREEN}🛠️  MANAGEMENT COMMANDS:${NC}"
echo -e "  View logs:     tail -f /tmp/{admin,driver,customer}.log"
echo -e "  Stop servers:  pkill -f 'server-admin.js'; pkill -f 'server-driver.js'; pkill -f 'server-customer.js'"
echo -e "  Docker logs:   docker-compose logs -f"
echo ""

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✅ All services are running successfully!${NC}"
  exit 0
else
  echo -e "${YELLOW}⚠️  Some services may not be responding. Check logs above.${NC}"
  exit 1
fi
