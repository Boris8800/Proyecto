#!/bin/bash

# SWIFTCAB - Quick Server Status Script for Ubuntu
# Paste this entire script to check server status quickly

echo "╔══════════════════════════════════════════════════════════╗"
echo "║         SWIFTCAB SERVER STATUS - UBUNTU                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ============ DOCKER STATUS ============
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 DOCKER STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        echo "✓ Docker daemon: RUNNING"
        docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "taxi|postgres|redis|mongo" || echo "  (no containers found)"
    else
        echo "✗ Docker daemon: NOT RUNNING"
        echo "  Start with: sudo systemctl start docker"
    fi
else
    echo "✗ Docker: NOT INSTALLED"
fi
echo ""

# ============ PORTS STATUS ============
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔌 PORTS STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_port() {
    if ss -tlnp 2>/dev/null | grep -q ":$1 "; then
        local service=$(ss -tlnp 2>/dev/null | grep ":$1 " | awk '{print $NF}')
        echo "✓ Port $1 OPEN ($service)"
    else
        echo "✗ Port $1 CLOSED"
    fi
}

check_port 3000  # API
check_port 3001  # Admin
check_port 3002  # Driver
check_port 3003  # Customer
check_port 5432  # PostgreSQL
check_port 6379  # Redis
check_port 27017 # MongoDB
echo ""

# ============ NETWORK CONNECTIVITY ============
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 NETWORK CONNECTIVITY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

test_url() {
    local name=$1
    local url=$2
    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    if [ "$status" = "200" ]; then
        echo "✓ $name → OK (HTTP 200)"
    else
        echo "✗ $name → FAIL (HTTP $status)"
    fi
}

test_url "Admin" "http://localhost:3001"
test_url "Driver" "http://localhost:3002"
test_url "Customer" "http://localhost:3003"
test_url "Booking" "http://localhost:3003/booking.html"
test_url "Payment" "http://localhost:3003/payment.html"
echo ""

# ============ SYSTEM RESOURCES ============
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 SYSTEM RESOURCES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print "  " $2}'

echo "Memory Usage:"
free -h | grep Mem | awk '{print "  Total: " $2 " | Used: " $3 " | Free: " $4}'

echo "Disk Usage:"
df -h / | tail -1 | awk '{print "  / : " $5 " used of " $2}'

echo ""

# ============ QUICK COMMANDS ============
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ QUICK COMMANDS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "START SERVICES:"
echo "  docker-compose up -d"
echo ""
echo "STOP SERVICES:"
echo "  docker-compose down"
echo ""
echo "VIEW LOGS:"
echo "  docker-compose logs -f"
echo ""
echo "ACCESS SERVICES:"
echo "  Admin:    http://localhost:3001"
echo "  Driver:   http://localhost:3002"
echo "  Customer: http://localhost:3003"
echo "  Booking:  http://localhost:3003/booking.html"
echo "  Payment:  http://localhost:3003/payment.html"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════════════"
