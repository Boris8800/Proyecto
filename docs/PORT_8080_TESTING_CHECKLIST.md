# Port 8080 Status Dashboard - Testing Checklist

## Pre-Deployment Verification

- [ ] SSH into your VPS: `ssh root@5.249.164.40`
- [ ] Navigate to project: `cd /root/Proyecto`
- [ ] Verify scripts are in place: `ls -la scripts/1-main.sh scripts/6-complete-deployment.sh`
- [ ] Check Docker is installed: `which docker`
- [ ] Check git is current: `git status`

## Running Fresh Installation (Updated)

```bash
# Navigate to project directory
cd /root/Proyecto

# Run fresh installation with Option 1
bash scripts/1-main.sh
# Select: 1 (Fresh Installation)

# Or run directly
bash scripts/1-main.sh < <(echo "1")
```

## Monitoring Installation Progress

The installation will now show:

```
STEP 1: ✓ Delete existing taxi user
STEP 2: ✓ Create taxi user & set permissions  
STEP 3: ✓ Install Node.js via nvm
STEP 4: ✓ Check Docker & START daemon ⭐ NEW
STEP 5: ✓ Install npm dependencies
STEP 6: ✓ Clean up old processes
STEP 7: ✓ Stop Docker containers ⭐ NEW
STEP 8: ✓ Run deployment
```

## Post-Installation Testing

### Test 1: Check All Dashboard Servers

```bash
# Admin Dashboard (Port 3001)
curl -I http://localhost:3001/
# Expected: HTTP/1.1 200 OK

# Driver Portal (Port 3002)
curl -I http://localhost:3002/
# Expected: HTTP/1.1 200 OK

# Customer App (Port 3003)
curl -I http://localhost:3003/
# Expected: HTTP/1.1 200 OK
```

### Test 2: Check Status Dashboard (Port 8080) ⭐ CRITICAL

```bash
# Test from VPS
curl -I http://localhost:8080/
# Expected: HTTP/1.1 200 OK

# Test from your local machine
curl -I http://5.249.164.40:8080/
# Expected: HTTP/1.1 200 OK (or HTTP response, not connection refused)
```

### Test 3: Verify Docker Containers

```bash
# List running Docker containers
docker ps

# Expected output should include:
# - taxi-status (Port 8080)
# - taxi-api (Port 3000)
# - Any other configured services

# View docker-compose status
docker-compose -f /root/Proyecto/config/docker-compose.yml ps
```

### Test 4: Check Process Status

```bash
# List Node.js processes
ps aux | grep "node\|server" | grep -v grep

# Expected: Should show server-admin.js, server-driver.js, server-customer.js

# Check if ports are listening
lsof -i -P -n | grep -E ":(3001|3002|3003|8080|3000)"
```

### Test 5: Review Logs

```bash
# Check taxi user deployment log
tail -20 /root/Proyecto/logs/admin.log
tail -20 /root/Proyecto/logs/driver.log
tail -20 /root/Proyecto/logs/customer.log

# Check Docker logs for Status Dashboard
docker logs taxi-status | tail -20

# Check Docker logs for API Server
docker logs taxi-api | tail -20
```

## Expected Results

✅ **All tests passing:**
- Curl returns HTTP 200 or connection success for all ports
- Docker containers running (output from `docker ps`)
- Node.js processes running (output from `ps aux`)
- All ports 3001, 3002, 3003, 8080 listening
- Log files showing normal operation

## If Port 8080 Still Not Working

1. **Check Docker daemon is running:**
   ```bash
   systemctl status docker
   # or
   service docker status
   ```

2. **Check taxi-status container logs:**
   ```bash
   docker logs taxi-status -f
   # Look for errors in http-server initialization
   ```

3. **Check if docker-compose config is valid:**
   ```bash
   docker-compose -f /root/Proyecto/config/docker-compose.yml config
   ```

4. **Verify status files exist:**
   ```bash
   ls -la /root/Proyecto/web/status/
   cat /root/Proyecto/web/status/index.html | wc -l
   ```

5. **Manually start status container:**
   ```bash
   docker-compose -f /root/Proyecto/config/docker-compose.yml up taxi-status
   ```

## Browser Testing

### Option 1: Direct Browser Access (Recommended)

1. Open your browser
2. Visit: `http://5.249.164.40:3001/` (Admin Dashboard)
3. Visit: `http://5.249.164.40:3002/` (Driver Portal)
4. Visit: `http://5.249.164.40:3003/` (Customer App)
5. Visit: `http://5.249.164.40:8080/` (Status Dashboard) ⭐

### Option 2: Using SSH Tunnel

If direct access is blocked by firewall:

```bash
# From your local machine
ssh -L 3001:localhost:3001 -L 3002:localhost:3002 -L 3003:localhost:3003 -L 8080:localhost:8080 root@5.249.164.40

# Then visit in browser:
# http://localhost:3001/
# http://localhost:8080/
```

## Troubleshooting Commands

```bash
# Full system check
echo "=== Docker Status ===" && systemctl status docker && \
echo "" && echo "=== Docker Containers ===" && docker ps && \
echo "" && echo "=== Node Processes ===" && ps aux | grep -E "node|server" | grep -v grep && \
echo "" && echo "=== Listening Ports ===" && lsof -i -P -n | grep -E ":(3001|3002|3003|8080|3000)" && \
echo "" && echo "=== Logs ===" && tail -5 /root/Proyecto/logs/*.log

# Or just run the complete deployment script again
cd /root/Proyecto && bash scripts/6-complete-deployment.sh
```

## Success Criteria

| Port | Service | Expected Response |
|------|---------|-------------------|
| 3001 | Admin | HTTP 200 with HTML |
| 3002 | Driver | HTTP 200 with HTML |
| 3003 | Customer | HTTP 200 with HTML |
| 8080 | Status | HTTP 200 with HTML ⭐ |
| 3000 | API | HTTP (via Docker) |

All ports should respond with either HTTP 200 or connection success (not "Connection refused").

---

**After this test**, you should have a fully functional Taxi System with all dashboards accessible on the specified ports, including the Status Dashboard on port 8080. 🎉
