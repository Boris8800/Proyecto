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

# Create logs directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/logs" 2>/dev/null
LOG_DIR="$PROJECT_ROOT/logs"

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

# Step 1B: Fix web directory permissions
echo -e "${YELLOW}[STEP 1B]${NC} Setting web directory permissions..."
if [ -d "$PROJECT_ROOT/web" ]; then
  chmod -R 755 "$PROJECT_ROOT/web" 2>/dev/null || true
  echo -e "${GREEN}✓${NC} Web directory permissions set"
else
  echo -e "${RED}✗${NC} Web directory not found"
fi

# Step 2: Stop old Docker containers
echo -e "${YELLOW}[STEP 2]${NC} Stopping old Docker containers..."
sudo docker-compose -f "$PROJECT_ROOT/config/docker-compose.yml" down 2>/dev/null || true
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
cd "$PROJECT_ROOT/web"

# Check if Node.js is available
if ! command -v node &>/dev/null; then
  echo -e "${RED}✗${NC} Node.js not found!"
  exit 1
fi

echo "  node version: $(node --version)"
echo "  npm version: $(npm --version)"

# Remove old node_modules if corrupted
if [ -d "node_modules" ] && [ ! -f "package-lock.json" ]; then
  echo -e "${YELLOW}[WARN]${NC} Removing potentially corrupted node_modules..."
  rm -rf node_modules
fi

# Install dependencies with better error handling
if npm install 2>&1 | tee /tmp/npm_install.log; then
  echo -e "${GREEN}✓${NC} Dependencies installed successfully"
  # Verify express was installed
  if [ -d "node_modules/express" ]; then
    echo -e "${GREEN}✓${NC} Express verified"
  else
    echo -e "${RED}✗${NC} Express not installed!"
    cat /tmp/npm_install.log
    exit 1
  fi
else
  echo -e "${RED}✗${NC} npm install failed!"
  cat /tmp/npm_install.log
  exit 1
fi

cd "$PROJECT_ROOT"

# Step 6: Start dashboard servers in background
echo -e "${YELLOW}[STEP 6]${NC} Starting dashboard servers..."
cd "$PROJECT_ROOT/web"

# Verify we're in the right directory
if [ ! -f "server-admin.js" ]; then
  echo -e "${RED}✗${NC} Cannot find server scripts in $PWD"
  ls -la
  exit 1
fi

# Verify node_modules exists
if [ ! -d "node_modules" ] || [ ! -d "node_modules/express" ]; then
  echo -e "${RED}✗${NC} node_modules/express not found! npm install may have failed"
  exit 1
fi

# Start admin server
nohup node server-admin.js > "$LOG_DIR/admin.log" 2>&1 &
ADMIN_PID=$!
sleep 2
if kill -0 $ADMIN_PID 2>/dev/null; then
  echo -e "${GREEN}✓${NC} Admin server started (PID: $ADMIN_PID, Port 3001)"
else
  echo -e "${RED}✗${NC} Failed to start admin server"
  echo -e "${RED}Error output:${NC}"
  cat "$LOG_DIR/admin.log" | head -20
  exit 1
fi

# Start driver server
nohup node server-driver.js > "$LOG_DIR/driver.log" 2>&1 &
DRIVER_PID=$!
sleep 2
if kill -0 $DRIVER_PID 2>/dev/null; then
  echo -e "${GREEN}✓${NC} Driver server started (PID: $DRIVER_PID, Port 3002)"
else
  echo -e "${RED}✗${NC} Failed to start driver server"
  echo -e "${RED}Error output:${NC}"
  cat "$LOG_DIR/driver.log" | head -20
  exit 1
fi

# Start customer server
nohup node server-customer.js > "$LOG_DIR/customer.log" 2>&1 &
CUSTOMER_PID=$!
sleep 2
if kill -0 $CUSTOMER_PID 2>/dev/null; then
  echo -e "${GREEN}✓${NC} Customer server started (PID: $CUSTOMER_PID, Port 3003)"
else
  echo -e "${RED}✗${NC} Failed to start customer server"
  echo -e "${RED}Error output:${NC}"
  cat "$LOG_DIR/customer.log" | head -20
  exit 1
fi

cd "$PROJECT_ROOT"

# Step 7: Ensure Docker is running
echo -e "${YELLOW}[STEP 7]${NC} Ensuring Docker daemon is running..."
if ! sudo docker ps &>/dev/null 2>&1; then
  echo -e "${YELLOW}[INFO]${NC} Starting Docker daemon..."
  if sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null; then
    sleep 3
    echo -e "${GREEN}✓${NC} Docker daemon started"
  else
    echo -e "${YELLOW}[WARN]${NC} Could not start Docker - continuing anyway"
  fi
  
  # Wait for Docker to be fully ready
  for i in {1..30}; do
    if sudo docker ps &>/dev/null 2>&1; then
      echo -e "${GREEN}✓${NC} Docker is ready"
      break
    fi
    sleep 1
  done
else
  echo -e "${GREEN}✓${NC} Docker daemon is running"
fi

# Step 8: Start Docker containers
echo -e "${YELLOW}[STEP 8]${NC} Starting Docker services..."
if sudo docker-compose -f "$PROJECT_ROOT/config/docker-compose.yml" up -d 2>&1 | grep -E "(Created|Starting|Started|WARNING)" | head -10; then
  echo -e "${GREEN}✓${NC} Docker services started"
else
  echo -e "${YELLOW}[INFO]${NC} Docker services being initialized..."
fi
sleep 3

# Step 9: Wait for services
echo -e "${YELLOW}[STEP 9]${NC} Waiting for services to be ready..."
sleep 5

# Step 10: Verify all services
echo -e "${YELLOW}[STEP 10]${NC} Verifying services..."
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

# Check Status Dashboard
echo -n "  Status Dashboard (port 8080)... "
if curl -s http://localhost:8080 > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${YELLOW}⚠${NC} (may start in a moment)"
fi

# Check Docker containers
echo ""
echo -e "${BLUE}Docker Containers:${NC}"
sudo docker-compose -f "$PROJECT_ROOT/config/docker-compose.yml" ps

# Step 11: Display access information
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
echo -e "  View logs:     tail -f $LOG_DIR/{admin,driver,customer}.log"
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
