#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           SWIFTCAB SERVER STATUS                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker daemon is NOT running!${NC}"
    echo -e "${YELLOW}Start Docker with:${NC} sudo docker daemon &"
    echo ""
fi

# Docker Containers Status
echo -e "${YELLOW}📦 DOCKER CONTAINERS:${NC}"
docker-compose ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo -e "  ${RED}(Docker not available)${NC}"
echo ""

# Services and URLs
echo -e "${YELLOW}🚀 SERVICES & URLS:${NC}"
echo -e "  ${GREEN}✓${NC} Admin Dashboard     → ${BLUE}http://localhost:3001${NC}"
echo -e "  ${GREEN}✓${NC} Driver App         → ${BLUE}http://localhost:3002${NC}"
echo -e "  ${GREEN}✓${NC} Customer Dashboard → ${BLUE}http://localhost:3003${NC}"
echo -e "  ${GREEN}✓${NC} Customer Booking   → ${BLUE}http://localhost:3003/booking.html${NC}"
echo -e "  ${GREEN}✓${NC} Authentication     → ${BLUE}http://localhost:3003/auth/index.html${NC}"
echo ""

# Port Status
echo -e "${YELLOW}🔌 PORT STATUS:${NC}"
for port in 3001 3002 3003 5432 6379 27017; do
    if lsof -i :$port &> /dev/null; then
        echo -e "  Port $port → ${GREEN}✓ OPEN${NC}"
    else
        echo -e "  Port $port → ${RED}✗ CLOSED${NC}"
    fi
done
echo ""

# Network Status
echo -e "${YELLOW}🌐 NETWORK CONNECTIVITY:${NC}"
echo -n "  Testing admin (3001)... "
curl -s -o /dev/null -w "%{http_code}" http://localhost:3001 > /dev/null && echo -e "${GREEN}✓ OK${NC}" || echo -e "${RED}✗ FAIL${NC}"

echo -n "  Testing driver (3002)... "
curl -s -o /dev/null -w "%{http_code}" http://localhost:3002 > /dev/null && echo -e "${GREEN}✓ OK${NC}" || echo -e "${RED}✗ FAIL${NC}"

echo -n "  Testing customer (3003)... "
curl -s -o /dev/null -w "%{http_code}" http://localhost:3003 > /dev/null && echo -e "${GREEN}✓ OK${NC}" || echo -e "${RED}✗ FAIL${NC}"

echo -n "  Testing booking.html... "
curl -s -o /dev/null -w "%{http_code}" http://localhost:3003/booking.html > /dev/null && echo -e "${GREEN}✓ OK${NC}" || echo -e "${RED}✗ FAIL${NC}"
echo ""

# Database Status
echo -e "${YELLOW}🗄️  DATABASE STATUS:${NC}"
echo "  PostgreSQL (5432)"
echo "  Redis (6379)"
echo "  MongoDB (27017)"
echo ""

# Storage Usage
echo -e "${YELLOW}💾 STORAGE USAGE:${NC}"
du -sh /workspaces/Proyecto 2>/dev/null | awk '{print "  Project size: " $1}'
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
