# Fix for Web Directories Showing "Index of /" 

## Problem
After fresh installation, accessing the dashboards showed "Index of /" (directory listing) instead of the actual web pages.

## Root Causes
1. **Missing package.json** - Express dependencies weren't installed
2. **Missing permissions** - Web directories weren't readable by taxi user
3. **Working directory issues** - Servers might not have been in correct directory

## What Was Fixed

### 1. Created package.json
```json
{
  "name": "swift-cab-dashboards",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "body-parser": "^1.20.2",
    "dotenv": "^16.0.3"
  }
}
```

### 2. Added Permission Fixes

**In Fresh Installation (STEP 4B):**
```bash
sudo chmod -R 755 "$PROJECT_ROOT/web"
sudo chown -R taxi:taxi "$PROJECT_ROOT/web"
```

**In Deployment (STEP 1B):**
```bash
chmod -R 755 "$PROJECT_ROOT/web"
```

### 3. Updated Deployment Script
- Absolute path: `cd "$PROJECT_ROOT/web"` (instead of relative `cd web`)
- Added verification: Checks server scripts exist before starting
- Added cd back: `cd "$PROJECT_ROOT"` after starting servers

## Steps to Fix on Your VPS

1. **Pull latest changes:**
```bash
cd /root/Proyecto
git pull origin main
```

2. **Run fresh installation:**
```bash
bash scripts/1-main.sh
# Select: 1 (Fresh Installation)
```

3. **Wait for all 9 steps to complete**

4. **Test the dashboards:**
```bash
# Should show HTML, not "Index of /"
curl http://localhost:3001/ | head -20
curl http://localhost:3002/ | head -20
curl http://localhost:3003/ | head -20
```

5. **Open in browser:**
- http://5.249.164.40:3001/ (Admin)
- http://5.249.164.40:3002/ (Driver)
- http://5.249.164.40:3003/ (Customer)

## What Happens During Installation

1. ✅ npm install runs successfully (now has package.json)
2. ✅ Web directory permissions set for taxi user (STEP 4B & 1B)
3. ✅ Servers start from correct working directory
4. ✅ Express serves admin/driver/customer directories
5. ✅ index.html files are served (not directory listing)

## Expected Output

```
[STEP 1B] Setting web directory permissions...
  ✓ Web directory permissions set

[STEP 5] Installing npm dependencies...
  ✓ Dependencies installed successfully
  
[STEP 6] Starting dashboard servers...
  ✓ Admin server started (Port 3001)
  ✓ Driver server started (Port 3002)
  ✓ Customer server started (Port 3003)
```

## If Still Seeing "Index of /"

Check:
1. **Server logs:**
```bash
tail -20 /root/Proyecto/logs/admin.log
tail -20 /root/Proyecto/logs/driver.log
tail -20 /root/Proyecto/logs/customer.log
```

2. **Check permissions:**
```bash
ls -la /root/Proyecto/web/admin/index.html
ls -la /root/Proyecto/web/driver/index.html
ls -la /root/Proyecto/web/customer/index.html
```

3. **Check server is using correct directory:**
```bash
ps aux | grep "node server"
```

4. **Test locally:**
```bash
curl -v http://localhost:3001/
# Should return HTML, not 301/302 redirect
```

## Files Changed

| File | Change |
|------|--------|
| `web/package.json` | **Created** - Added express dependencies |
| `scripts/1-main.sh` | Added STEP 4B for web permissions |
| `scripts/6-complete-deployment.sh` | Added STEP 1B for web permissions + absolute path |

---

**After these fixes, the dashboards will display correctly instead of showing directory listings!** ✅
