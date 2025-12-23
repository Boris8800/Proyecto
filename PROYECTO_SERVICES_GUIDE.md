# 🚀 Proyecto Services - All-in-One Management Tool

## Single Combined Script

All service management functionality is now in one file:

```bash
/root/Proyecto/scripts/proyecto-services.sh
```

---

## Usage

### Interactive Menu (Default)
```bash
bash /root/Proyecto/scripts/proyecto-services.sh
```

This opens an interactive menu with options:
1. Run Full Diagnostics
2. Fix Status Dashboard (Port 3030)
3. Fix All Services
4. Exit

### Command Line Options

#### Run Diagnostics
```bash
bash /root/Proyecto/scripts/proyecto-services.sh diagnose
```

Outputs:
- Docker status and containers
- Listening ports
- HTTP response tests
- Node.js processes
- Container logs
- Project file structure

#### Fix Status Dashboard Only
```bash
bash /root/Proyecto/scripts/proyecto-services.sh fix-status
```

Fixes port 3030 issues:
- Checks Docker availability
- Verifies container exists
- Restarts if needed
- Tests HTTP response
- Verifies all ports

#### Fix All Services
```bash
bash /root/Proyecto/scripts/proyecto-services.sh fix-all
```

Complete service restart:
- Stops all Node.js processes
- Stops Docker containers
- Reinstalls dependencies
- Starts Docker containers
- Starts all web services
- Verifies all services

---

## Features

✅ **All-in-One**: No need to run multiple scripts  
✅ **Interactive Menu**: Easy to use for beginners  
✅ **Command Line Options**: Scriptable for automation  
✅ **Color Output**: Easy to read results  
✅ **Comprehensive Diagnostics**: Full system visibility  
✅ **Detailed Logging**: Track what's happening  

---

## What It Manages

### Services (6 total)
- Status Dashboard (Port 3030)
- Admin Dashboard (Port 3001)
- Driver Portal (Port 3002)
- Customer App (Port 3000)
- Main API (Port 3040)
- Magic Links API (Port 3333)

### Docker Containers
- taxi-status
- taxi-api
- taxi-postgres
- taxi-mongo
- taxi-redis

### Node.js Processes
- web/status/server.js
- npm run server-admin
- npm run server-driver
- npm run server-customer

---

## Example Usage Scenarios

### Quick Status Check
```bash
bash /root/Proyecto/scripts/proyecto-services.sh diagnose
```

### Port 3030 Not Responding
```bash
bash /root/Proyecto/scripts/proyecto-services.sh fix-status
```

### Everything Down - Full Restart
```bash
bash /root/Proyecto/scripts/proyecto-services.sh fix-all
```

### Interactive Mode (Menu)
```bash
bash /root/Proyecto/scripts/proyecto-services.sh
# Then select option 1-3
```

---

## Output Examples

### Successful All Services Fix
```
[✓] Port 3030 (Status Dashboard) - RESPONDING
[✓] Port 3001 (Admin Dashboard) - RESPONDING
[✓] Port 3002 (Driver Portal) - RESPONDING
[✓] Port 3000 (Customer App) - RESPONDING
[✓] Port 3040 (Main API) - RESPONDING
[✓] Port 3333 (Magic Links API) - RESPONDING

✓ ALL SERVICES ARE OPERATIONAL
```

### Access Endpoints
```
Status Dashboard: http://5.249.164.40:3030
Admin Dashboard:  http://5.249.164.40:3001
Driver Portal:    http://5.249.164.40:3002
Customer App:     http://5.249.164.40:3000
Main API:         http://5.249.164.40:3040
Magic Links API:  http://5.249.164.40:3333
```

---

## Troubleshooting

### If services still fail
Check detailed logs:
```bash
docker logs taxi-status
docker logs taxi-api
tail -f /root/Proyecto/logs/status.log
```

### Full diagnostics
```bash
bash /root/Proyecto/scripts/proyecto-services.sh diagnose
```

### Manual Docker commands
```bash
# Check containers
docker ps -a

# View logs
docker logs container-name

# Restart specific container
docker restart taxi-status

# View listening ports
netstat -tuln | grep LISTEN
```

---

## Previous Scripts

These are now included in `proyecto-services.sh`:
- ❌ `fix-status-dashboard.sh` (deprecated)
- ❌ `fix-all-services.sh` (deprecated)
- ❌ `diagnose-all-services.sh` (deprecated)

Use `proyecto-services.sh` instead!

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `bash proyecto-services.sh` | Interactive menu |
| `bash proyecto-services.sh diagnose` | Run diagnostics |
| `bash proyecto-services.sh fix-status` | Fix port 3030 |
| `bash proyecto-services.sh fix-all` | Fix all services |

---

**All-in-one tool for complete Proyecto Taxi service management!** 🎉
