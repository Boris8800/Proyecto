#!/bin/bash

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Docker Cleanup and Restart ===${NC}"

# Navigate to project directory
cd /root/Proyecto || { echo -e "${RED}Failed to navigate to /root/Proyecto${NC}"; exit 1; }
echo -e "${GREEN}✓ In /root/Proyecto${NC}"

# Pull latest changes
echo -e "\n${YELLOW}Pulling latest changes from GitHub...${NC}"
git pull origin main || { echo -e "${RED}Git pull failed${NC}"; exit 1; }
echo -e "${GREEN}✓ Git pull complete${NC}"

# Kill http-server (blocking port 8080)
echo -e "\n${YELLOW}Killing http-server processes...${NC}"
pkill -9 http-server 2>/dev/null || true
echo -e "${GREEN}✓ http-server killed${NC}"

# Remove old containers
echo -e "\n${YELLOW}Removing old containers...${NC}"
docker container prune -f || true
echo -e "${GREEN}✓ Old containers pruned${NC}"

# Manually remove the stuck ones
echo -e "\n${YELLOW}Removing specific stuck containers...${NC}"
docker rm 27b3dcffc1e9 461713b30e54 38784ea6603b a67205a34401 fbf6e0c56dc9 3e8af03ec0db 266c8e39d8ba 69e8900f5b7e 2>/dev/null || true
echo -e "${GREEN}✓ Stuck containers removed${NC}"

# Stop and remove running docker-compose services
echo -e "\n${YELLOW}Stopping Docker Compose services...${NC}"
docker-compose -f config/docker-compose.yml down || { echo -e "${RED}docker-compose down failed${NC}"; exit 1; }
echo -e "${GREEN}✓ Docker Compose stopped${NC}"

# Start fresh
echo -e "\n${YELLOW}Starting Docker Compose services...${NC}"
docker-compose -f config/docker-compose.yml up -d || { echo -e "${RED}docker-compose up failed${NC}"; exit 1; }
echo -e "${GREEN}✓ Docker Compose started${NC}"

# Wait for containers to start
echo -e "\n${YELLOW}Waiting for containers to start...${NC}"
sleep 5

# Verify containers are running
echo -e "\n${YELLOW}Verifying containers...${NC}"
docker ps
echo -e "${GREEN}✓ Container status displayed${NC}"

# Test port 8080
echo -e "\n${YELLOW}Testing port 8080...${NC}"
curl -s http://localhost:8080/ | head -20
echo -e "\n${GREEN}✓ Port 8080 test complete${NC}"

echo -e "\n${GREEN}=== Cleanup and Restart Complete ===${NC}"
