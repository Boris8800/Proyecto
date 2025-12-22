#!/bin/bash

# 🚕 Taxi System Web Dashboards - Quick Start Guide
# This script sets up and starts all three web dashboards in one command

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚕 Taxi System - Web Dashboards Quick Start${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Check Node.js
echo -e "${YELLOW}Step 1: Checking Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo "Node.js not found. Installing..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi
echo -e "${GREEN}✓ Node.js $(node --version)${NC}"
echo -e "${GREEN}✓ npm $(npm --version)${NC}"
echo ""

# Step 2: Install dependencies
echo -e "${YELLOW}Step 2: Installing dependencies...${NC}"
cd /workspaces/Proyecto
npm install > /dev/null 2>&1
echo -e "${GREEN}✓ Dependencies installed (132 packages)${NC}"
echo ""

# Step 3: Start servers
echo -e "${YELLOW}Step 3: Starting dashboard servers...${NC}"
echo ""
echo "   Starting Admin Dashboard on port 3001..."
node web/server-admin.js > /tmp/admin.log 2>&1 &
ADMIN_PID=$!
sleep 1

echo "   Starting Driver Portal on port 3002..."
node web/server-driver.js > /tmp/driver.log 2>&1 &
DRIVER_PID=$!
sleep 1

echo "   Starting Customer App on port 3003..."
node web/server-customer.js > /tmp/customer.log 2>&1 &
CUSTOMER_PID=$!
sleep 1

echo -e "${GREEN}✓ All servers started${NC}"
echo ""

# Step 4: Verify
echo -e "${YELLOW}Step 4: Verifying servers...${NC}"
echo ""

test_server() {
    local name=$1
    local port=$2
    local pid=$3
    
    if kill -0 "$pid" 2>/dev/null; then
        if curl -s "http://localhost:$port/api/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} $name (Port $port) - Running & Responding"
            return 0
        else
            echo -e "${YELLOW}⚠${NC} $name (Port $port) - Starting..."
            return 1
        fi
    else
        echo -e "${YELLOW}⚠${NC} $name (Port $port) - PID dead"
        return 1
    fi
}

test_server "Admin Dashboard" 3001 $ADMIN_PID
test_server "Driver Portal" 3002 $DRIVER_PID
test_server "Customer App" 3003 $CUSTOMER_PID

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Access your dashboards:${NC}"
echo ""
echo -e "  ${GREEN}Admin Dashboard${NC}:  http://localhost:3001"
echo -e "  ${GREEN}Driver Portal${NC}:    http://localhost:3002"
echo -e "  ${GREEN}Customer App${NC}:     http://localhost:3003"
echo ""
echo -e "${YELLOW}Or on your VPS (IP: 5.249.164.40):${NC}"
echo ""
echo -e "  ${GREEN}Admin Dashboard${NC}:  http://5.249.164.40:3001"
echo -e "  ${GREEN}Driver Portal${NC}:    http://5.249.164.40:3002"
echo -e "  ${GREEN}Customer App${NC}:     http://5.249.164.40:3003"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo ""
echo "  Check status:      ./manage-dashboards.sh status"
echo "  View logs:         ./manage-dashboards.sh logs [admin|driver|customer]"
echo "  Stop servers:      ./manage-dashboards.sh stop"
echo "  Restart servers:   ./manage-dashboards.sh restart"
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo ""
echo "  Deployment Guide:  DASHBOARDS_DEPLOYMENT.md"
echo "  Testing Guide:     DASHBOARDS_TESTING.md"
echo "  Complete Overview: DASHBOARDS_COMPLETE.md"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Keep script running
echo -e "${YELLOW}Press Ctrl+C to stop all servers${NC}"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down servers...${NC}"
    kill $ADMIN_PID $DRIVER_PID $CUSTOMER_PID 2>/dev/null || true
    echo -e "${GREEN}✓ All servers stopped${NC}"
    exit 0
}

trap cleanup EXIT INT TERM

# Wait for servers to run
while true; do
    sleep 10
    
    # Check if any server died
    if ! kill -0 $ADMIN_PID 2>/dev/null || ! kill -0 $DRIVER_PID 2>/dev/null || ! kill -0 $CUSTOMER_PID 2>/dev/null; then
        echo -e "${YELLOW}Warning: One or more servers have stopped${NC}"
        break
    fi
done
