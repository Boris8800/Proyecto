# 🚕 Web Dashboards - Testing & Verification Guide

## Quick Start (5 minutes)

### 1. Local Testing (Development)

```bash
# Navigate to project directory
cd /workspaces/Proyecto

# Install dependencies
npm install

# Start all three servers
node web/server-admin.js &     # Admin (Port 3001)
node web/server-driver.js &    # Driver (Port 3002)
node web/server-customer.js &  # Customer (Port 3003)

# Verify servers are running
sleep 2
ps aux | grep "node web/server"

# Test endpoints
curl -I http://localhost:3001
curl -I http://localhost:3002
curl -I http://localhost:3003

# Kill servers
pkill -f "node web/server"
```

## Detailed Testing Checklist

### Phase 1: Environment Verification ✓

- [ ] Node.js installed: `node --version`
- [ ] npm installed: `npm --version`
- [ ] Package.json exists: `test -f package.json`
- [ ] Server files exist: `test -f web/server-*.js`
- [ ] Dashboard directories exist: `test -d web/admin web/driver web/customer`
- [ ] Port 3001 available: `! netstat -tlnp 2>/dev/null | grep :3001`
- [ ] Port 3002 available: `! netstat -tlnp 2>/dev/null | grep :3002`
- [ ] Port 3003 available: `! netstat -tlnp 2>/dev/null | grep :3003`

### Phase 2: Dependency Installation ✓

```bash
# Install dependencies
npm install

# Verify key packages
npm list express
npm list cors

# Check installation
ls -la node_modules/ | head -20
```

**Expected Packages:**
- express (^4.18.2)
- cors (^2.8.5)
- path (^0.12.7)

### Phase 3: Server Startup Tests ✓

#### Test 1: Admin Server
```bash
cd /workspaces/Proyecto
timeout 3 node web/server-admin.js &
sleep 1

# Check port
lsof -i :3001 || echo "Port 3001 available"

# Test endpoint
curl -s http://localhost:3001/api/health | jq .

# Expected: {"status":"ok","service":"admin-dashboard",...}
```

#### Test 2: Driver Server
```bash
timeout 3 node web/server-driver.js &
sleep 1

# Check port
lsof -i :3002 || echo "Port 3002 available"

# Test endpoint
curl -s http://localhost:3002/api/health | jq .

# Expected: {"status":"ok","service":"driver-portal",...}
```

#### Test 3: Customer Server
```bash
timeout 3 node web/server-customer.js &
sleep 1

# Check port
lsof -i :3003 || echo "Port 3003 available"

# Test endpoint
curl -s http://localhost:3003/api/health | jq .

# Expected: {"status":"ok","service":"customer-app",...}
```

### Phase 4: HTTP Response Tests ✓

```bash
# Test Admin Dashboard
curl -I http://localhost:3001
# Expected: HTTP/1.1 200 OK

# Test Driver Portal
curl -I http://localhost:3002
# Expected: HTTP/1.1 200 OK

# Test Customer App
curl -I http://localhost:3003
# Expected: HTTP/1.1 200 OK

# Test HTML content
curl -s http://localhost:3001 | head -5
# Expected: <!DOCTYPE html>

# Test API health endpoints
curl http://localhost:3001/api/health
curl http://localhost:3002/api/health
curl http://localhost:3003/api/health
```

### Phase 5: Load Testing

```bash
# Install Apache Bench (if not available)
sudo apt-get install -y apache2-utils

# Test Admin Dashboard (100 requests, 10 concurrent)
ab -n 100 -c 10 http://localhost:3001/

# Test Driver Portal
ab -n 100 -c 10 http://localhost:3002/

# Test Customer App
ab -n 100 -c 10 http://localhost:3003/

# Expected: Response time < 50ms, Success rate 100%
```

### Phase 6: Browser Verification (If GUI Available)

**Admin Dashboard:**
```
URL: http://localhost:3001
Expected Elements:
- Modern gradient background (purple)
- "🚕 Admin Dashboard" title
- 6 metric cards (Active Drivers, Active Rides, Revenue, Rating, Service Areas, Total Users)
- System Status section
- Management buttons
```

**Driver Portal:**
```
URL: http://localhost:3002
Expected Elements:
- Modern gradient background (pink/red)
- "🚗 Driver Portal" title
- 6 performance cards
- Performance Metrics section
- Action buttons (Start New Ride, Ride History, View Earnings)
```

**Customer App:**
```
URL: http://localhost:3003
Expected Elements:
- Modern gradient background (blue)
- "🚕 Taxi Booking App" title
- Hero section with "Request a Ride Now"
- 6 feature cards
- "Why Choose Us?" feature list
- Action buttons
```

## VPS Deployment Testing

### Step 1: Upload Files to VPS

```bash
# From local machine
scp -r /workspaces/Proyecto/web/* root@5.249.164.40:/home/taxi/web/
scp /workspaces/Proyecto/package.json root@5.249.164.40:/home/taxi/
scp /workspaces/Proyecto/manage-dashboards.sh root@5.249.164.40:/home/taxi/
scp /workspaces/Proyecto/DASHBOARDS_DEPLOYMENT.md root@5.249.164.40:/home/taxi/

# Or using rsync for faster transfer
rsync -avz /workspaces/Proyecto/web/ root@5.249.164.40:/home/taxi/web/
rsync -avz /workspaces/Proyecto/package.json root@5.249.164.40:/home/taxi/
```

### Step 2: SSH to VPS and Install

```bash
ssh root@5.249.164.40

# Navigate to taxi directory
cd /home/taxi

# Install Node.js if needed
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install dependencies
npm install

# Make management script executable
chmod +x manage-dashboards.sh
```

### Step 3: Start Servers on VPS

```bash
# Start all servers
./manage-dashboards.sh start

# Check status
./manage-dashboards.sh status

# Verify ports are listening
netstat -tlnp | grep -E ':(3001|3002|3003)'
```

### Step 4: Test from Remote

```bash
# From your local machine
curl -I http://5.249.164.40:3001
curl -I http://5.249.164.40:3002
curl -I http://5.249.164.40:3003

# Test health endpoints
curl http://5.249.164.40:3001/api/health
curl http://5.249.164.40:3002/api/health
curl http://5.249.164.40:3003/api/health

# Expected: HTTP 200 with JSON response
```

### Step 5: Browser Test (From Your Machine)

Open these URLs in your browser:
- **Admin**: http://5.249.164.40:3001
- **Driver**: http://5.249.164.40:3002
- **Customer**: http://5.249.164.40:3003

All should display modern, responsive dashboards!

## Automated Test Script

Create `test-dashboards.sh`:

```bash
#!/bin/bash

echo "🚕 Taxi Dashboards Testing Suite"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

passed=0
failed=0

test_endpoint() {
    local name=$1
    local port=$2
    local url="http://localhost:$port"

    echo -n "Testing $name... "

    if curl -s "$url/api/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((passed++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((failed++))
    fi
}

test_port() {
    local name=$1
    local port=$2

    echo -n "Port $port ($name)... "

    if timeout 2 bash -c "echo >/dev/tcp/localhost/$port" 2>/dev/null; then
        echo -e "${GREEN}✓ OPEN${NC}"
        ((passed++))
    else
        echo -e "${RED}✗ CLOSED${NC}"
        ((failed++))
    fi
}

test_html() {
    local name=$1
    local port=$2

    echo -n "HTML Content ($name)... "

    if curl -s "http://localhost:$port" | grep -q "<!DOCTYPE html>"; then
        echo -e "${GREEN}✓ VALID${NC}"
        ((passed++))
    else
        echo -e "${RED}✗ INVALID${NC}"
        ((failed++))
    fi
}

# Run tests
echo "Testing Port Availability:"
test_port "Admin" 3001
test_port "Driver" 3002
test_port "Customer" 3003
echo ""

echo "Testing API Health Endpoints:"
test_endpoint "Admin" 3001
test_endpoint "Driver" 3002
test_endpoint "Customer" 3003
echo ""

echo "Testing HTML Content:"
test_html "Admin" 3001
test_html "Driver" 3002
test_html "Customer" 3003
echo ""

# Summary
total=$((passed + failed))
echo "=================================="
echo "Test Results: $passed/$total passed"

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}$failed test(s) failed${NC}"
    exit 1
fi
```

## Performance Benchmarks

### Expected Performance

```
Server          Startup Time    Memory Usage    Response Time    Concurrency
Admin           < 1s            ~30MB           < 50ms           100+
Driver          < 1s            ~30MB           < 50ms           100+
Customer        < 1s            ~30MB           < 50ms           100+
```

### Test Performance

```bash
# Measure startup time
time node web/server-admin.js &
# Expected: real 0m1.234s

# Check memory usage
ps aux | grep "node web/server" | grep -v grep
# Expected: ~30-50MB VSZ, ~20-30MB RSS

# Measure response time
time curl -s http://localhost:3001 > /dev/null
# Expected: real 0m0.050s

# Load test
ab -n 1000 -c 50 http://localhost:3001/
# Expected: Requests per second: 500+
# Expected: Failed requests: 0
```

## Troubleshooting Tests

### If servers won't start:

```bash
# Check for syntax errors
node -c web/server-admin.js

# Check dependencies
npm list

# Check Node.js version
node --version
# Expected: v14+ (v18+ recommended)

# Check file permissions
ls -la web/server-*.js
# Expected: -rwxr-xr-x (executable)
```

### If ports are in use:

```bash
# Find process using port
lsof -i :3001

# Kill process
kill -9 <PID>

# Clear all Node processes
pkill -9 node
```

### If Health Check Fails:

```bash
# Start server with output
node web/server-admin.js

# In another terminal, test
curl -v http://localhost:3001/api/health

# Check for errors in output
# Should see: Server running on port 3001
```

## Success Criteria ✓

The deployment is successful when:

1. ✅ All 3 servers start without errors
2. ✅ All 3 ports (3001, 3002, 3003) are listening
3. ✅ All API health endpoints respond with HTTP 200
4. ✅ All health endpoints return valid JSON
5. ✅ Dashboard HTML loads successfully
6. ✅ No JavaScript console errors
7. ✅ Pages render with modern styling
8. ✅ Responsive design works on mobile
9. ✅ All buttons and links are functional
10. ✅ Load testing shows >500 req/sec

## Quick Verification Commands

```bash
# Copy & paste this entire block to test everything:

cd /workspaces/Proyecto && \
echo "Installing dependencies..." && \
npm install > /dev/null 2>&1 && \
echo "✓ Dependencies installed" && \
echo "" && \
echo "Starting servers..." && \
node web/server-admin.js > /tmp/admin.log 2>&1 & \
node web/server-driver.js > /tmp/driver.log 2>&1 & \
node web/server-customer.js > /tmp/customer.log 2>&1 & \
sleep 2 && \
echo "Testing endpoints..." && \
echo "Admin: $(curl -s http://localhost:3001/api/health | jq '.service')" && \
echo "Driver: $(curl -s http://localhost:3002/api/health | jq '.service')" && \
echo "Customer: $(curl -s http://localhost:3003/api/health | jq '.service')" && \
echo "" && \
echo "Cleaning up..." && \
pkill -f "node web/server" && \
echo "✓ All tests completed!"
```

## Report Template

When reporting issues, include:

```
Server: [Admin|Driver|Customer]
Port: [3001|3002|3003]
Error: [error message]
Steps to reproduce: [steps]
Expected behavior: [what should happen]
Actual behavior: [what actually happened]
Environment: [OS, Node version, npm version]
Logs: [paste relevant logs]
```

---

**Last Updated**: January 2025
**Status**: Ready for Production Testing
