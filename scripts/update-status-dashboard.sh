#!/bin/bash
# Update status dashboard on VPS with latest code

set -euo pipefail

COLORS=true
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; exit 1; }

# Change to project directory
cd /root/Proyecto || print_error "Project directory not found"

print_status "Pulling latest changes from Git..."
git pull origin main || print_error "Failed to pull from Git"
print_success "Latest code pulled"

print_status "Stopping old Docker container (taxi-status)..."
if docker ps --filter "name=taxi-status" --format '{{.Names}}' | grep -q "taxi-status"; then
    docker stop taxi-status || print_error "Failed to stop container"
    print_success "Container stopped"
else
    print_status "Container not running, skipping stop"
fi

print_status "Pulling Docker image..."
docker pull node:18-alpine || print_error "Failed to pull Node image"

print_status "Starting new status dashboard container..."
cd /root/Proyecto/config
docker-compose up -d taxi-status || print_error "Failed to start container"
print_success "Container started"

# Wait for server to be ready
print_status "Waiting for server to be ready..."
sleep 3

# Test the endpoint
print_status "Testing login endpoint..."
if timeout 5 curl -s http://localhost:8080/api/auth/csrf > /dev/null 2>&1; then
    print_success "Login endpoint is working!"
    echo ""
    echo -e "${GREEN}✓ Status dashboard updated successfully!${NC}"
    echo -e "  • Access: http://YOUR_VPS_IP:8080"
    echo -e "  • Default login: admin / admin123"
else
    print_error "Endpoint test failed - container may not be ready yet"
fi
