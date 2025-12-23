# 🚀 Updated Port Configuration - Reference Guide

## New Port Mappings

All scripts have been updated to use the new port configuration:

| Port | Service | Type | Access |
|------|---------|------|--------|
| **3000** | Customer App | Web Interface | http://5.249.164.40:3000 |
| **3001** | Admin Dashboard | Web Interface | http://5.249.164.40:3001 |
| **3002** | Driver Portal | Web Interface | http://5.249.164.40:3002 |
| **3030** | Status Dashboard | Web Interface | http://5.249.164.40:3030 |
| **3040** | Main API (Docker) | API Server | http://5.249.164.40:3040 |
| **3333** | Magic Links API | API Service | http://5.249.164.40:3333 |

---

## Changes Made

✅ **Port 8080 → 3030** (Status Dashboard)  
✅ **Port 3000 → 3040** (Main API - Docker)  
✅ **Port 3001** (Admin Dashboard) - Unchanged  
✅ **Port 3002** (Driver Portal) - Unchanged  
✅ **Port 3333** (Magic Links API) - Unchanged  
✅ **Port 3000** (Customer App) - New assignment  

---

## Files Updated

1. **docker-compose.yml**
   - taxi-status: 8080 → 3030
   - taxi-api: 3000 → 3040

2. **Scripts** (All now in English)
   - `scripts/fix-status-dashboard.sh` - Fix port 3030
   - `scripts/fix-all-services.sh` - Fix all services
   - `scripts/diagnose-all-services.sh` - Comprehensive diagnostics

---

## Quick Start

### Run All Fixes
```bash
bash /root/Proyecto/scripts/fix-all-services.sh
```

### Diagnose Issues
```bash
bash /root/Proyecto/scripts/diagnose-all-services.sh
```

### Fix Only Status Dashboard
```bash
bash /root/Proyecto/scripts/fix-status-dashboard.sh
```

---

## Expected Output

```
✓ Port 3030 (Status Dashboard) - WORKING
✓ Port 3001 (Admin Dashboard) - WORKING
✓ Port 3002 (Driver Portal) - WORKING
✓ Port 3000 (Customer App) - WORKING
✓ Port 3040 (Main API) - WORKING
✓ Port 3333 (Magic Links API) - WORKING

✓ ALL SERVICES ARE OPERATIONAL
```

---

## Docker Compose Configuration

The `docker-compose.yml` has been updated with:

```yaml
taxi-status:
  ports:
    - "0.0.0.0:3030:3030"  # Changed from 8080
  environment:
    STATUS_PORT: 3030

taxi-api:
  ports:
    - "0.0.0.0:3040:3040"  # Changed from 3000
  environment:
    PORT: 3040
```

---

## All Scripts Now in English

✅ `fix-status-dashboard.sh` - Clear English messages  
✅ `fix-all-services.sh` - Comprehensive English diagnostics  
✅ `diagnose-all-services.sh` - Complete English output  

All scripts updated and pushed to GitHub! 🎉
