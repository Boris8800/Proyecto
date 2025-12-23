#!/bin/bash

################################################################################
# STATUS DASHBOARD FIX (PORT 3030)
# Quick fix for port 3030 not responding
################################################################################

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              PORT 3030 - STATUS DASHBOARD FIX                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

PROJECT_ROOT="/root/Proyecto"
cd "$PROJECT_ROOT" || exit 1

# ============================================================================
# STEP 1: Check Docker Status
# ============================================================================
echo "[1] Checking Docker..."
docker --version > /dev/null 2>&1 || {
    echo "❌ Docker is not installed"
    exit 1
}

echo "✓ Docker is available"
echo ""

# ============================================================================
# STEP 2: Check if taxi-status container exists
# ============================================================================
echo "[2] Looking for taxi-status container..."
CONTAINER=$(docker ps -a --format '{{.Names}}' | grep taxi-status)

if [ -z "$CONTAINER" ]; then
    echo "❌ Container 'taxi-status' not found"
    echo ""
    echo "Available containers:"
    docker ps -a --format '{{.Names}}'
    echo ""
    echo "Creating container..."
    cd "$PROJECT_ROOT/config"
    docker-compose -f docker-compose.yml up -d taxi-status
    sleep 10
else
    echo "✓ Container 'taxi-status' found"
    
    # Check if running
    RUNNING=$(docker ps --format '{{.Names}}' | grep taxi-status)
    if [ -z "$RUNNING" ]; then
        echo "⚠️  Container is not running"
        echo "Starting container..."
        docker start taxi-status
        sleep 5
    else
        echo "✓ Container is running"
    fi
fi

echo ""

# ============================================================================
# STEP 3: Check Docker logs
# ============================================================================
echo "[3] Checking Docker logs..."
echo ""
docker logs taxi-status 2>&1 | tail -20
echo ""

# ============================================================================
# STEP 4: Check if port 3030 is listening
# ============================================================================
echo "[4] Checking port 3030..."
if netstat -tuln 2>/dev/null | grep -q ":3030"; then
    echo "✓ Port 3030 is listening"
else
    echo "❌ Port 3030 is NOT listening"
    echo "Restarting container..."
    docker restart taxi-status
    sleep 5
fi

echo ""

# ============================================================================
# STEP 5: Test Response
# ============================================================================
echo "[5] Testing HTTP response..."
RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null http://127.0.0.1:3030/ 2>&1)

if [ "$RESPONSE" = "200" ]; then
    echo "✓ Port 3030 responding (HTTP $RESPONSE)"
else
    echo "❌ Port 3030 not responding (HTTP $RESPONSE)"
    echo ""
    echo "Attempting force restart..."
    docker kill taxi-status 2>/dev/null || true
    docker rm taxi-status 2>/dev/null || true
    sleep 2
    
    cd "$PROJECT_ROOT/config"
    docker-compose -f docker-compose.yml up -d taxi-status
    sleep 10
    
    RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null http://127.0.0.1:3030/ 2>&1)
    if [ "$RESPONSE" = "200" ]; then
        echo "✓ Port 3030 now responding"
    fi
fi

echo ""

# ============================================================================
# STEP 6: Verify ALL Services
# ============================================================================
echo "[6] Verifying ALL services..."
echo ""

declare -a PORTS=(3030 3001 3002 3040 3333)
declare -a NAMES=("Status Dashboard" "Admin Dashboard" "Driver Portal" "Main API" "Magic Links API")

for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    NAME=${NAMES[$i]}
    RESP=$(curl -s -w "%{http_code}" -o /dev/null http://127.0.0.1:$PORT/ 2>&1)
    
    if [ "$RESP" = "200" ]; then
        echo "✓ Port $PORT ($NAME) - WORKING"
    else
        echo "✗ Port $PORT ($NAME) - NOT RESPONDING (HTTP $RESP)"
    fi
done

echo ""

# ============================================================================
# STEP 7: Final Status
# ============================================================================
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    FINAL STATUS                               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "Docker Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep taxi

echo ""
echo "Access to services:"
echo "  - Status Dashboard: http://5.249.164.40:3030"
echo "  - Admin Dashboard:  http://5.249.164.40:3001"
echo "  - Driver Portal:    http://5.249.164.40:3002"
echo "  - Main API:         http://5.249.164.40:3040"
echo "  - Magic Links API:  http://5.249.164.40:3333"
echo ""

echo "If problems persist, check:"
echo "  docker logs taxi-status"
echo "  docker logs taxi-api"
echo "  docker logs taxi-postgres"
echo ""
