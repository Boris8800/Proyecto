#!/bin/bash
# debug-ports.sh - Diagnostic tool for port issues
# Use this script to diagnose and manually resolve port conflicts

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Taxi System - Port Diagnostic Tool${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Function to check a port with detailed info
check_port_detailed() {
    local port=$1
    local service=$2
    
    echo -e "${CYAN}Checking port $port ($service)...${NC}"
    
    # Try ss first (most reliable)
    if command -v ss &> /dev/null; then
        echo "  Using: ss (socket statistics)"
        if ss -tulpn 2>/dev/null | grep -E ":$port\s" | while read line; do
            echo "    $line"
        done; then
            echo -e "    ${RED}⚠️  Port IN USE${NC}"
            return 0
        fi
    fi
    
    # Try lsof
    if command -v lsof &> /dev/null; then
        echo "  Using: lsof (open file descriptor)"
        if lsof -i :"$port" 2>/dev/null | tail -n +2 | while read line; do
            echo "    $line"
        done; then
            echo -e "    ${RED}⚠️  Port IN USE${NC}"
            return 0
        fi
    fi
    
    # Try netstat
    if command -v netstat &> /dev/null; then
        echo "  Using: netstat (network statistics)"
        if netstat -tulpn 2>/dev/null | grep -E ":$port\s" | while read line; do
            echo "    $line"
        done; then
            echo -e "    ${RED}⚠️  Port IN USE${NC}"
            return 0
        fi
    fi
    
    echo -e "    ${GREEN}✓ Port is AVAILABLE${NC}"
    return 1
}

# Check all critical ports
echo -e "${YELLOW}Required Ports:${NC}"
echo ""

PORTS=(
    "80:nginx (HTTP)"
    "443:nginx (HTTPS)"
    "5432:PostgreSQL"
    "27017:MongoDB"
    "6379:Redis"
    "3000:API Gateway"
    "3001:Admin Dashboard"
    "3002:Driver Dashboard"
    "3003:Customer Dashboard"
)

for port_info in "${PORTS[@]}"; do
    IFS=':' read -r port service <<< "$port_info"
    check_port_detailed "$port" "$service"
    echo ""
done

# Docker status
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Docker Status:${NC}"
echo ""

if command -v docker &> /dev/null; then
    echo -e "  ${GREEN}✓ Docker is installed${NC}"
    
    # Running containers
    echo ""
    echo "  Running containers:"
    if docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -v "NAMES" | grep -q .; then
        docker ps --format "table {{.Names}}\t{{.Ports}}"
    else
        echo "    (none)"
    fi
    
    # All containers
    echo ""
    echo "  All containers:"
    if docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -v "NAMES" | grep -q .; then
        docker ps -a --format "table {{.Names}}\t{{.Status}}" | head -10
    else
        echo "    (none)"
    fi
else
    echo -e "  ${RED}✗ Docker is NOT installed${NC}"
fi

echo ""

# Process status
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Relevant Processes:${NC}"
echo ""

for process in nginx apache httpd postgres mongod redis; do
    if pgrep -x "$process" > /dev/null 2>&1; then
        echo -e "  ${YELLOW}$process:${NC} Running"
        pgrep -a "$process" | head -3
    fi
done

echo ""

# Manual resolution commands
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Manual Resolution Commands:${NC}"
echo ""
echo "If ports are in use, try these commands:"
echo ""
echo -e "  ${CYAN}Kill web servers:${NC}"
echo "    sudo pkill -9 nginx"
echo "    sudo pkill -9 apache2"
echo "    sudo pkill -9 httpd"
echo ""
echo -e "  ${CYAN}Stop Docker:${NC}"
echo "    sudo systemctl stop docker"
echo "    sudo docker stop \$(sudo docker ps -aq)"
echo "    sudo docker system prune -af"
echo ""
echo -e "  ${CYAN}Kill specific port:${NC}"
echo "    sudo fuser -k PORT/tcp    # e.g., sudo fuser -k 80/tcp"
echo ""
echo -e "  ${CYAN}Show all listening ports:${NC}"
echo "    sudo ss -tulpn"
echo "    sudo netstat -tulpn"
echo ""

# Automatic fix option
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
read -r -p "Automatically fix port conflicts? (y/n) [n]: " auto_fix
if [ "${auto_fix:-n}" = "y" ] || [ "${auto_fix:-n}" = "Y" ]; then
    echo ""
    echo -e "${YELLOW}Attempting automatic fix...${NC}"
    echo ""
    
    # Kill web servers
    echo "  Killing web servers..."
    sudo systemctl stop haproxy 2>/dev/null || true
    sudo pkill -9 -f "nginx|apache|httpd|haproxy" 2>/dev/null || true
    
    # Stop docker
    echo "  Stopping Docker..."
    sudo systemctl stop docker 2>/dev/null || true
    sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true
    docker stop $(docker ps -aq) 2>/dev/null || true
    
    # Clean docker
    echo "  Cleaning Docker..."
    sudo docker system prune -af 2>/dev/null || true
    
    # Wait
    echo "  Waiting for ports to release..."
    sleep 3
    
    # Re-check
    echo ""
    echo "  Re-checking ports..."
    echo ""
    
    has_conflicts=0
    for port_info in "${PORTS[@]}"; do
        IFS=':' read -r port service <<< "$port_info"
        if ! check_port_detailed "$port" "$service" > /dev/null 2>&1; then
            has_conflicts=1
        fi
    done
    
    if [ $has_conflicts -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ All ports are now available!${NC}"
    else
        echo ""
        echo -e "${RED}⚠️  Some ports are still in use. Manual intervention may be needed.${NC}"
    fi
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
