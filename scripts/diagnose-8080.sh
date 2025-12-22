#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Port 8080 Diagnostic - Find & Fix Issue              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

PROJECT_ROOT="/root/Proyecto"
cd "$PROJECT_ROOT" || exit 1

# Check 1: Is anything listening on 8080?
echo -e "${YELLOW}[1]${NC} Checking what's listening on port 8080..."
LISTENING=$(lsof -i :8080 2>/dev/null)
if [ -n "$LISTENING" ]; then
  echo -e "${GREEN}✓${NC} Something is listening:"
  echo "$LISTENING"
else
  echo -e "${RED}✗${NC} Nothing listening on port 8080!"
fi
echo ""

# Check 2: Is Docker container running?
echo -e "${YELLOW}[2]${NC} Checking taxi-status container..."
CONTAINER_STATUS=$(docker ps --filter "name=taxi-status" --format "{{.Status}}" 2>/dev/null)
if [ -z "$CONTAINER_STATUS" ]; then
  echo -e "${RED}✗${NC} Container not found or not running"
  echo -e "${YELLOW}[INFO]${NC} Checking all containers..."
  docker ps -a | grep -E "taxi-status|CONTAINER"
else
  echo -e "${GREEN}✓${NC} Container status: $CONTAINER_STATUS"
fi
echo ""

# Check 3: Container logs
echo -e "${YELLOW}[3]${NC} Container logs..."
docker logs taxi-status 2>&1 | tail -15 || echo -e "${RED}✗${NC} Cannot read logs"
echo ""

# Check 4: status/server.js exists?
echo -e "${YELLOW}[4]${NC} Checking status/server.js..."
if [ -f "$PROJECT_ROOT/web/status/server.js" ]; then
  echo -e "${GREEN}✓${NC} File exists"
  echo "   First 10 lines:"
  head -10 "$PROJECT_ROOT/web/status/server.js" | sed 's/^/   /'
else
  echo -e "${RED}✗${NC} File missing!"
fi
echo ""

# Check 5: Docker compose config
echo -e "${YELLOW}[5]${NC} Docker-compose config for taxi-status..."
docker-compose -f "$PROJECT_ROOT/config/docker-compose.yml" config 2>/dev/null | grep -A 15 "taxi-status:" || echo -e "${RED}✗${NC} Cannot read config"
echo ""

# Check 6: Network connectivity
echo -e "${YELLOW}[6]${NC} Testing network connectivity..."
if timeout 2 bash -c "echo >/dev/tcp/127.0.0.1/8080" 2>/dev/null; then
  echo -e "${GREEN}✓${NC} Port 8080 is reachable"
  # Try to get response
  curl -s http://127.0.0.1:8080/ | head -20 || echo -e "${RED}✗${NC} No HTTP response"
else
  echo -e "${RED}✗${NC} Port 8080 is NOT reachable"
fi
echo ""

# Check 7: Process list
echo -e "${YELLOW}[7]${NC} All running containers..."
docker ps --no-trunc
echo ""

# Check 8: Try to manually start container
echo -e "${YELLOW}[8]${NC} Attempting to manually start taxi-status..."
docker-compose -f "$PROJECT_ROOT/config/docker-compose.yml" up -d taxi-status 2>&1 | tail -5
sleep 3

# Final test
echo ""
echo -e "${YELLOW}[FINAL TEST]${NC} Testing port 8080 again..."
if timeout 2 bash -c "echo >/dev/tcp/127.0.0.1/8080" 2>/dev/null; then
  echo -e "${GREEN}✓✓✓ PORT 8080 NOW WORKING! ✓✓✓${NC}"
  curl -s http://127.0.0.1:8080/ | head -1
else
  echo -e "${RED}✗✗✗ PORT 8080 STILL NOT WORKING ✗✗✗${NC}"
  echo ""
  echo -e "${YELLOW}Debug info collected. Check logs above.${NC}"
fi
