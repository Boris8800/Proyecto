# 🔧 VPS FIX ALL SERVICES - Quick Start Guide

## **One-Command Fix**

Run this on your VPS server (5.249.164.40) to fix **all** services:

```bash
bash /root/Proyecto/scripts/fix-all-vps.sh
```

---

## **What This Script Does:**

✅ Checks current service status  
✅ Stops all running Node.js processes  
✅ Stops all Docker containers  
✅ Reinstalls npm dependencies  
✅ Starts Docker containers (postgres, mongo, redis, api)  
✅ Starts Status Dashboard (port 8080)  
✅ Starts Admin Dashboard (port 3001)  
✅ Starts Driver Portal (port 3002)  
✅ Starts Customer App (port 3003)  
✅ Verifies all services are responding  

---

## **Expected Output:**

```
✓ Port 8080 (Status Dashboard) - RESPONDING
✓ Port 3001 (Admin Dashboard) - RESPONDING
✓ Port 3002 (Driver Portal) - RESPONDING
✓ Port 3003 (Customer App) - RESPONDING

✓ ALL SERVICES ARE OPERATIONAL (5/5)
```

---

## **If Issues Persist:**

### Check Logs
```bash
# Status Dashboard
tail -f /root/Proyecto/logs/status.log

# Docker Containers
docker logs taxi-postgres
docker logs taxi-mongo
docker logs taxi-redis
docker logs taxi-api

# Web Services
tail -f /root/Proyecto/logs/admin.log
tail -f /root/Proyecto/logs/driver.log
tail -f /root/Proyecto/logs/customer.log
```

### Manual Fixes
```bash
# Restart only port 8080
cd /root/Proyecto/web
node status/server.js

# Restart Docker
cd /root/Proyecto/config
docker-compose down
docker-compose up -d

# Kill all and start fresh
pkill -9 node
docker-compose down
bash /root/Proyecto/scripts/fix-all-vps.sh
```

---

## **Access Your Services:**

| Service | URL |
|---------|-----|
| Status Dashboard | http://5.249.164.40:8080 |
| Admin Dashboard | http://5.249.164.40:3001 |
| Driver Portal | http://5.249.164.40:3002 |
| Customer App | http://5.249.164.40:3003 |
| API Server | http://5.249.164.40:3000 |

---

## **Need Help?**

```bash
# Run diagnostics
bash /root/Proyecto/scripts/diagnose-8080.sh

# View all processes
ps aux | grep node

# Check port usage
netstat -tuln | grep -E "(3000|3001|3002|3003|8080)"

# Full deployment
bash /root/Proyecto/scripts/6-complete-deployment.sh
```
