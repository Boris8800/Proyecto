#!/bin/bash
# force-port-cleanup.sh - Aggressively free up all required ports
# Run this BEFORE installation if ports are in use

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}AGGRESSIVE PORT CLEANUP${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

PORTS=(80 443 5432 27017 6379 3000 3001 3002 3003)

echo -e "${YELLOW}Step 1: Killing all web servers...${NC}"
sudo systemctl stop haproxy 2>/dev/null || true
sudo pkill -9 -f "nginx|apache2|apache|httpd|haproxy" 2>/dev/null || true
echo -e "${GREEN}✓ Web servers killed${NC}"
sleep 1

echo ""
echo -e "${YELLOW}Step 2: Stopping Docker completely...${NC}"
sudo systemctl stop docker 2>/dev/null || true
sudo pkill -9 -f "dockerd|docker" 2>/dev/null || true
echo -e "${GREEN}✓ Docker stopped${NC}"
sleep 2

echo ""
echo -e "${YELLOW}Step 3: Force-releasing all critical ports...${NC}"
for port in "${PORTS[@]}"; do
    echo -n "  Port $port: "
    if sudo fuser -k "$port/tcp" 2>/dev/null; then
        echo -e "${GREEN}Released${NC}"
    else
        echo -e "${YELLOW}Not in use or already free${NC}"
    fi
done
sleep 1

echo ""
echo -e "${YELLOW}Step 4: Killing any remaining service processes...${NC}"
sudo pkill -9 postgres 2>/dev/null || true
sudo pkill -9 mongod 2>/dev/null || true
sudo pkill -9 redis-server 2>/dev/null || true
sudo pkill -9 node 2>/dev/null || true
echo -e "${GREEN}✓ Service processes killed${NC}"
sleep 1

echo ""
echo -e "${YELLOW}Step 5: Waiting for system to stabilize...${NC}"
sleep 3

echo ""
echo -e "${YELLOW}Step 6: Verifying ports are free...${NC}"
ALL_FREE=1
for port in "${PORTS[@]}"; do
    if sudo ss -tulpn 2>/dev/null | grep -q ":$port "; then
        echo -e "  Port $port: ${RED}⚠️  STILL IN USE${NC}"
        ALL_FREE=0
    else
        echo -e "  Port $port: ${GREEN}✓ Free${NC}"
    fi
done

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

if [ $ALL_FREE -eq 1 ]; then
    echo -e "${GREEN}✅ SUCCESS - All ports are free!${NC}"
    echo ""
    echo "You can now run:"
    echo -e "  ${GREEN}sudo bash /root/install-taxi-system.sh${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}⚠️  Some ports are still in use${NC}"
    echo ""
    echo "Try one of these:"
    echo "  1. Reboot: sudo reboot"
    echo "  2. Check what's using the ports:"
    echo "     sudo ss -tulpn | grep -E ':(80|443|5432|27017|6379|3000|3001|3002|3003)'"
    echo "  3. Kill specific process:"
    echo "     sudo lsof -i :PORT_NUMBER"
    echo "     sudo kill -9 PID"
    echo ""
    exit 1
fi
