#!/bin/bash

################################################################################
# COMPLETE DIAGNOSTIC - ALL SERVICES
# Comprehensive diagnostic for all ports and services
################################################################################

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        COMPREHENSIVE DIAGNOSTIC - ALL SERVICES                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# 1. Docker Status
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "1. DOCKER STATUS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "Docker Version:"
docker --version 2>/dev/null || echo "❌ Docker not available"
echo ""

echo "Running Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "All Containers (including stopped):"
docker ps -a --format "table {{.Names}}\t{{.Status}}"
echo ""

# ============================================================================
# 2. Port Status
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "2. LISTENING PORTS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

netstat -tuln 2>/dev/null | grep -E ":(3000|3001|3002|3003|3030|3040|3333)" || echo "No services listening"
echo ""

# ============================================================================
# 3. HTTP Response Tests
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "3. SERVICE RESPONSE TESTS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

for port in 3030 3001 3002 3040 3333; do
    echo -n "Port $port: "
    RESULT=$(timeout 3 curl -s -w "%{http_code}" -o /dev/null http://127.0.0.1:$port/ 2>&1)
    if [ -z "$RESULT" ]; then
        echo "❌ TIMEOUT or no response"
    elif [ "$RESULT" = "200" ]; then
        echo "✓ RESPONDING (HTTP 200)"
    else
        echo "⚠️  HTTP $RESULT"
    fi
done
echo ""

# ============================================================================
# 4. Node.js Processes
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "4. NODE.JS PROCESSES"
echo "═══════════════════════════════════════════════════════════════"
echo ""

ps aux | grep -E "node|npm" | grep -v grep | awk '{print $2, $11, $12, $13}' | head -20 || echo "No Node.js processes"
echo ""

# ============================================================================
# 5. Docker Logs
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "5. DOCKER LOGS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "--- taxi-status (last 10 lines) ---"
docker logs taxi-status 2>&1 | tail -10 || echo "❌ Container taxi-status does not exist"
echo ""

echo "--- taxi-api (last 10 lines) ---"
docker logs taxi-api 2>&1 | tail -10 || echo "❌ Container taxi-api does not exist"
echo ""

echo "--- taxi-postgres (last 10 lines) ---"
docker logs taxi-postgres 2>&1 | tail -10 || echo "❌ Container taxi-postgres does not exist"
echo ""

# ============================================================================
# 6. File System Check
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "6. PROJECT FILES"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -d "/root/Proyecto" ]; then
    echo "✓ Project exists at: /root/Proyecto"
    echo ""
    echo "Structure:"
    ls -la /root/Proyecto/ | grep -E "web|config|scripts|logs" | awk '{print "  " $9, "(" $5 " bytes)"}'
else
    echo "❌ Project does NOT exist at /root/Proyecto"
fi
echo ""

# ============================================================================
# 7. Summary
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "7. SUMMARY"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "For more information:"
echo "  docker ps -a              # View all containers"
echo "  docker logs taxi-status   # View status dashboard logs"
echo "  netstat -tuln             # View listening ports"
echo "  ps aux | grep node        # View Node.js processes"
echo ""

echo "To fix issues:"
echo "  bash /root/Proyecto/scripts/fix-status-dashboard.sh   # Fix port 3030"
echo "  bash /root/Proyecto/scripts/fix-all-services.sh       # Fix all services"
echo "  docker-compose restart                                # Restart containers"
echo ""
