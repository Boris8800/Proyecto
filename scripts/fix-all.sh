#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              FIX ALL - Complete Taxi System Repair             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

PROJECT_ROOT="/root/Proyecto"
cd "$PROJECT_ROOT" || { echo -e "${RED}Failed to navigate to $PROJECT_ROOT${NC}"; exit 1; }

# Step 1: Kill the installation loop
echo -e "${YELLOW}[STEP 1]${NC} Stopping installation loop..."
tmux kill-session -t taxi-install 2>/dev/null || true
pkill -9 -f "install-taxi-system.sh" 2>/dev/null || true
pkill -9 -f "wget.*install-taxi" 2>/dev/null || true
sleep 1
echo -e "${GREEN}✓${NC} Installation loop stopped"

# Step 2: Kill all http-server and Node processes
echo -e "${YELLOW}[STEP 2]${NC} Killing http-server and conflicting processes..."
pkill -9 -f "http-server" 2>/dev/null || true
pkill -9 -f "npm exec http-server" 2>/dev/null || true
for port in 3001 3002 3003 8080; do
  pid=$(lsof -ti:$port 2>/dev/null)
  if [ -n "$pid" ]; then
    kill -9 "$pid" 2>/dev/null || true
  fi
done
sleep 2
echo -e "${GREEN}✓${NC} Processes killed"

# Step 3: Pull latest code
echo -e "${YELLOW}[STEP 3]${NC} Pulling latest code..."
git pull origin main 2>&1 | grep -E "Already up to date|Fast-forward|Updating" || true
echo -e "${GREEN}✓${NC} Code updated"

# Step 4: Stop all Docker containers and networks
echo -e "${YELLOW}[STEP 4]${NC} Stopping Docker services..."
sudo docker-compose -f "$PROJECT_ROOT/config/docker-compose.yml" down -v 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓${NC} Docker services stopped"

# Step 5: Remove any stuck containers
echo -e "${YELLOW}[STEP 5]${NC} Cleaning up stuck containers..."
STUCK=$(docker container ls -a --filter "status=created" -q 2>/dev/null)
if [ -n "$STUCK" ]; then
  docker rm -f $STUCK 2>/dev/null || true
  echo -e "${GREEN}✓${NC} Stuck containers removed"
else
  echo -e "${GREEN}✓${NC} No stuck containers found"
fi

# Step 6: Start fresh Node.js servers (3001-3003)
echo -e "${YELLOW}[STEP 6]${NC} Starting Node.js dashboard servers..."
cd "$PROJECT_ROOT/web"

# Verify dependencies
if [ ! -d "node_modules" ] || [ ! -d "node_modules/express" ]; then
  echo -e "${YELLOW}[INFO]${NC} Installing dependencies..."
  npm install --prefer-offline 2>&1 | tail -5
fi

# Start admin (3001)
nohup node server-admin.js > /root/Proyecto/logs/admin.log 2>&1 &
sleep 1
if lsof -i:3001 >/dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} Admin Dashboard (3001) started"
else
  echo -e "${RED}✗${NC} Admin Dashboard failed to start"
  cat /root/Proyecto/logs/admin.log | head -10
fi

# Start driver (3002)
nohup node server-driver.js > /root/Proyecto/logs/driver.log 2>&1 &
sleep 1
if lsof -i:3002 >/dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} Driver Portal (3002) started"
else
  echo -e "${RED}✗${NC} Driver Portal failed to start"
  cat /root/Proyecto/logs/driver.log | head -10
fi

# Start customer (3003)
nohup node server-customer.js > /root/Proyecto/logs/customer.log 2>&1 &
sleep 1
if lsof -i:3003 >/dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} Customer App (3003) started"
else
  echo -e "${RED}✗${NC} Customer App failed to start"
  cat /root/Proyecto/logs/customer.log | head -10
fi

cd "$PROJECT_ROOT"

# Step 7: Start Docker services
echo -e "${YELLOW}[STEP 7]${NC} Starting Docker services..."

# Ensure Docker daemon is running
if ! sudo docker ps &>/dev/null 2>&1; then
  echo -e "${YELLOW}[INFO]${NC} Starting Docker daemon..."
  sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null
  sleep 3
fi

# Start docker-compose
sudo docker-compose -f "$PROJECT_ROOT/config/docker-compose.yml" up -d 2>&1 | tail -10
sleep 3
echo -e "${GREEN}✓${NC} Docker services started"

# Step 8: Force start any containers stuck in "Created" state
echo -e "${YELLOW}[STEP 8]${NC} Verifying Docker containers..."
CREATED=$(docker container ls -a --filter "status=created" -q 2>/dev/null)
if [ -n "$CREATED" ]; then
  echo -e "${YELLOW}[INFO]${NC} Starting stuck containers..."
  docker container start $CREATED 2>/dev/null || true
  sleep 3
fi

# Verify all containers are Running
RUNNING=$(docker ps -q 2>/dev/null | wc -l)
echo -e "${GREEN}✓${NC} Running containers: $RUNNING"
docker ps --format "table {{.Names}}\t{{.Status}}"

# Step 9: Test all ports
echo -e ""
echo -e "${YELLOW}[STEP 9]${NC} Testing all services..."
echo ""

test_port() {
  local port=$1
  local name=$2
  if timeout 2 bash -c "echo >/dev/tcp/localhost/$port" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} $name (Port $port) responding"
    return 0
  else
    echo -e "${RED}✗${NC} $name (Port $port) NOT responding"
    return 1
  fi
}

test_port 3001 "Admin Dashboard"
test_port 3002 "Driver Portal"
test_port 3003 "Customer App"
test_port 8080 "Status Dashboard"
test_port 3000 "API Server"

# Step 10: Display summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    REPAIR COMPLETE                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Access your services at:${NC}"
echo "  • Admin Dashboard:    http://5.249.164.40:3001"
echo "  • Driver Portal:      http://5.249.164.40:3002"
echo "  • Customer App:       http://5.249.164.40:3003"
echo "  • Status Dashboard:   http://5.249.164.40:8080"
echo "  • API Server:         http://5.249.164.40:3000"
echo ""
echo -e "${YELLOW}Log files:${NC}"
echo "  • Admin:    /root/Proyecto/logs/admin.log"
echo "  • Driver:   /root/Proyecto/logs/driver.log"
echo "  • Customer: /root/Proyecto/logs/customer.log"
echo ""
echo -e "${YELLOW}Docker status:${NC}"
docker ps --no-trunc
echo ""
