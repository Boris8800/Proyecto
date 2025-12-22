# Docker and Port 8080 Status Dashboard Fix

## Problem
The Status Dashboard on port 8080 was not accessible on the VPS after running fresh installation because:
1. Docker daemon was not being started as part of the installation process
2. Docker-compose commands were not using the correct file path and sudo privileges
3. The step to stop Docker containers before deployment was not explicit

## Root Cause Analysis
- **Missing Docker daemon startup**: The fresh installation script checked if Docker was installed but didn't ensure the Docker daemon was actually running
- **Incomplete docker-compose paths**: The deployment script used relative paths (`docker-compose.yml`) instead of absolute paths (`config/docker-compose.yml`)
- **Missing sudo for docker-compose**: Docker-compose commands weren't being run with sudo, causing permission issues

## Changes Made

### 1. **STEP 4: Enhanced Docker Check** (`scripts/1-main.sh`)

**Before:**
```bash
if ! command -v docker &>/dev/null; then
  log_error "Docker not installed"
  # ... error handling ...
else
  log_success "Docker is installed"
fi
```

**After:**
```bash
if ! command -v docker &>/dev/null; then
  log_error "Docker not installed"
  # ... error handling ...
else
  log_success "Docker is installed"
  
  # Start Docker daemon if it's not running
  log_info "Ensuring Docker daemon is running..."
  if sudo service docker start 2>/dev/null || sudo systemctl start docker 2>/dev/null; then
    sleep 2
    log_success "Docker daemon started"
  else
    log_warn "Could not start Docker daemon - it may already be running or require sudo"
  fi
  
  # Verify Docker is accessible
  if sudo docker ps &>/dev/null; then
    log_success "Docker is accessible and running"
  else
    log_warn "Docker exists but may not be fully operational"
  fi
fi
```

**Impact**: Ensures Docker daemon is running before any docker-compose operations

---

### 2. **Added STEP 7: Explicit Docker Container Shutdown** (`scripts/1-main.sh`)

**New Step Added:**
```bash
# ============================================================================
# STEP 7: STOP DOCKER CONTAINERS
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}STEP 7:${NC} Stopping Docker containers..."
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v docker-compose &>/dev/null; then
  sudo docker-compose -f "$PROJECT_ROOT/config/docker-compose.yml" down 2>/dev/null || true
  log_success "Docker containers stopped"
else
  log_info "Docker-compose not found, skipping container shutdown"
fi

printf "\n"

# ============================================================================
# STEP 8: RUN DEPLOYMENT AS TAXI USER
# ============================================================================
```

**Impact**: Makes the Docker shutdown explicit and uses proper file paths

---

### 3. **Fixed docker-compose Command Paths** (`scripts/6-complete-deployment.sh`)

**STEP 2 - Stop Containers:**
```bash
# Before
docker-compose -f docker-compose.yml down 2>/dev/null || true

# After
sudo docker-compose -f "$PROJECT_ROOT/config/docker-compose.yml" down 2>/dev/null || true
```

**STEP 7 - Start Containers:**
```bash
# Before
docker-compose up -d 2>&1 | grep -E "(Created|Starting|Started)" || true

# After
sudo docker-compose -f "$PROJECT_ROOT/config/docker-compose.yml" up -d 2>&1 | grep -E "(Created|Starting|Started)" || true
```

**STEP 9 - Verify Containers:**
```bash
# Before
docker-compose ps

# After
sudo docker-compose -f "$PROJECT_ROOT/config/docker-compose.yml" ps
```

**Impact**: Ensures docker-compose commands use absolute paths and proper sudo privileges

---

## Fresh Installation Flow (Updated)

The complete fresh installation now follows these 8 steps:

1. **STEP 1**: Delete existing taxi user and clean old files
2. **STEP 2**: Create taxi user and set permissions
3. **STEP 3**: Install Node.js via nvm for taxi user
4. **STEP 4**: Check Docker and start daemon ✅ **ENHANCED**
5. **STEP 5**: Install npm dependencies as taxi user
6. **STEP 6**: Clean up old processes on all ports
7. **STEP 7**: Stop Docker containers ✅ **NEW**
8. **STEP 8**: Run deployment script (which starts services)

---

## Services Started During Deployment

After fresh installation completes, the following services will be running:

### Node.js Dashboard Servers
- **Admin Dashboard** - Port 3001 (User: `taxi`, Log: `/root/Proyecto/logs/admin.log`)
- **Driver Portal** - Port 3002 (User: `taxi`, Log: `/root/Proyecto/logs/driver.log`)
- **Customer App** - Port 3003 (User: `taxi`, Log: `/root/Proyecto/logs/customer.log`)

### Docker Services
- **Status Dashboard** - Port 8080 (Docker http-server from `/web/status`)
- **API Server** - Port 3000 (Configured in docker-compose.yml)

---

## Verification

After running fresh installation, verify all services are running:

```bash
# Check Node.js servers
curl http://localhost:3001  # Admin
curl http://localhost:3002  # Driver
curl http://localhost:3003  # Customer

# Check Docker services
curl http://localhost:8080  # Status Dashboard
docker ps                    # View running containers

# Check logs
tail -f /root/Proyecto/logs/admin.log
tail -f /root/Proyecto/logs/driver.log
tail -f /root/Proyecto/logs/customer.log
docker-compose logs -f      # Docker service logs
```

---

## Troubleshooting Port 8080

If port 8080 still doesn't respond after fresh installation:

1. **Check Docker daemon:**
   ```bash
   sudo service docker status
   # or
   sudo systemctl status docker
   ```

2. **Check Docker containers:**
   ```bash
   sudo docker ps  # Should see taxi-status, taxi-api, etc.
   ```

3. **Check docker-compose logs:**
   ```bash
   sudo docker-compose -f /root/Proyecto/config/docker-compose.yml logs taxi-status
   ```

4. **Check if port is listening:**
   ```bash
   lsof -i :8080
   # or
   curl -v http://localhost:8080
   ```

5. **Verify Status Dashboard files:**
   ```bash
   ls -la /root/Proyecto/web/status/
   cat /root/Proyecto/web/status/index.html | head -20
   ```

---

## Summary of Changes

| Script | Change | Impact |
|--------|--------|--------|
| `scripts/1-main.sh` | STEP 4 now starts Docker daemon | Docker services can be deployed |
| `scripts/1-main.sh` | Added STEP 7 for explicit shutdown | Clear separation of concerns |
| `scripts/6-complete-deployment.sh` | All docker-compose use proper paths | Correct file resolution |
| `scripts/6-complete-deployment.sh` | All docker-compose use sudo | Proper permissions |

These changes ensure that **port 8080 Status Dashboard is accessible** after fresh installation on your VPS.
