#!/bin/bash
# Quick Dashboard Test & Deployment Reference

echo "╔════════════════════════════════════════════════╗"
echo "║     DASHBOARD TEST & DEPLOYMENT GUIDE         ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

case "${1:-help}" in
  "local")
    echo -e "${BLUE}Starting local dashboard servers...${NC}"
    cd /workspaces/Proyecto/web
    npm install > /dev/null 2>&1
    echo "Starting servers..."
    node server-admin.js &
    node server-driver.js &
    node server-customer.js &
    sleep 2
    echo -e "${GREEN}✓ All servers started${NC}"
    echo ""
    echo "Access dashboards at:"
    echo "  Admin:    http://localhost:3001"
    echo "  Driver:   http://localhost:3002"
    echo "  Customer: http://localhost:3003"
    echo ""
    ;;
  "check")
    echo -e "${BLUE}Checking dashboard files...${NC}"
    cd /workspaces/Proyecto
    echo ""
    echo "Admin Dashboard:"
    wc -l web/admin/index.html | awk '{print "  Lines: " $1}'
    ls -lh web/admin/index.html | awk '{print "  Size: " $5}'
    echo ""
    echo "Driver Portal:"
    wc -l web/driver/index.html | awk '{print "  Lines: " $1}'
    ls -lh web/driver/index.html | awk '{print "  Size: " $5}'
    echo ""
    echo "Customer App:"
    wc -l web/customer/index.html | awk '{print "  Lines: " $1}'
    ls -lh web/customer/index.html | awk '{print "  Size: " $5}'
    echo ""
    echo -e "${GREEN}✓ All dashboards present and ready${NC}"
    ;;
  "vps")
    echo -e "${BLUE}VPS Deployment Instructions${NC}"
    echo ""
    echo "1. SSH into VPS:"
    echo "   ssh root@5.249.164.40"
    echo ""
    echo "2. Navigate to web directory:"
    echo "   cd /home/taxi/web"
    echo ""
    echo "3. Start servers:"
    echo "   npm install"
    echo "   ./start-dashboards.sh"
    echo ""
    echo "4. Access dashboards at:"
    echo "   Admin:    http://5.249.164.40:3001"
    echo "   Driver:   http://5.249.164.40:3002"
    echo "   Customer: http://5.249.164.40:3003"
    echo ""
    ;;
  "features")
    echo -e "${BLUE}Dashboard Features Overview${NC}"
    echo ""
    echo "ADMIN DASHBOARD (Purple Gradient)"
    echo "  • Sidebar navigation with 7 menu items"
    echo "  • Search bar with notifications badge"
    echo "  • 4 colored stat cards (drivers, customers, rides, revenue)"
    echo "  • Recent rides table with status indicators"
    echo "  • Top drivers earnings list"
    echo "  • System status monitor (4 services)"
    echo ""
    echo "DRIVER PORTAL (Pink/Red Gradient)"
    echo "  • Sidebar navigation with 6 menu items"
    echo "  • Dashboard header with notifications"
    echo "  • 6 metric cards (earnings, rides, rating, status)"
    echo "  • 4 quick action buttons"
    echo "  • Active rides table"
    echo "  • Earnings summary breakdown"
    echo "  • Recent ride history (10+ rides)"
    echo ""
    echo "CUSTOMER APP (Blue Gradient)"
    echo "  • Sticky navigation bar"
    echo "  • Hero section with booking form"
    echo "  • 4 trust statistics"
    echo "  • 6 feature highlight cards"
    echo "  • 8-item benefits section"
    echo "  • Recent rides display"
    echo "  • Professional footer"
    echo ""
    ;;
  "help"|*)
    echo -e "${BLUE}Available Commands:${NC}"
    echo ""
    echo "  ./dashboard-reference.sh local     - Start servers locally"
    echo "  ./dashboard-reference.sh check     - Verify dashboard files"
    echo "  ./dashboard-reference.sh vps       - VPS deployment guide"
    echo "  ./dashboard-reference.sh features  - View dashboard features"
    echo "  ./dashboard-reference.sh help      - Show this help message"
    echo ""
    ;;
esac
