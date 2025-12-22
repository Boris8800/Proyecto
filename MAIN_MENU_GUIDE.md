# Main Menu System - Complete Operations Guide

All menu options in the main.sh script are now fully functional with proper responses and error handling.

## 🚕 Main Menu Options

### 1) Fresh Installation (Recommended)
**Purpose:** Complete clean setup of the taxi system

**What it does:**
- ✓ Validates Docker and npm dependencies
- ✓ Installs all npm packages
- ✓ Kills old processes on ports 3001-3003, 8080
- ✓ Stops all Docker containers
- ✓ Runs complete deployment script
- ✓ Starts all services fresh

**Use when:** Setting up the system for the first time or doing a complete reset

---

### 2) Update Existing Installation
**Purpose:** Update code and services without losing data

**What it does:**
- ✓ Pulls latest changes from GitHub
- ✓ Updates npm dependencies
- ✓ Restarts Docker services
- ✓ Restarts Node.js servers
- ✓ Verifies all services running

**Use when:** You want to get the latest updates from the repository

---

### 3) Service Management
**Purpose:** Control and monitor all services

**Sub-options:**
1. **Start All Services**
   - Starts Docker containers
   - Starts 3 Node servers (admin, driver, customer)
   - Runs in background with nohup

2. **Stop All Services**
   - Stops Docker containers
   - Kills Node servers gracefully
   - Frees all ports

3. **Restart All Services**
   - Stops and starts everything
   - Useful after configuration changes

4. **View Service Status**
   - Shows Docker container status
   - Shows Node server status on ports 3001-3003
   - Color-coded: Green ✓ Running, Red ✗ Stopped

5. **View Service Logs**
   - View logs for admin, driver, or customer servers
   - View Docker logs
   - Shows last 20 lines with timestamps

---

### 4) System Diagnostics
**Purpose:** Check health and status of entire system

**Checks performed:**
- 🐳 Docker container status and running services
- 🚀 Node server responses on ports 3001-3003
- 💾 Disk usage across all partitions
- 🧠 Memory usage and available RAM
- 🗄️ Database connectivity:
  - PostgreSQL connection test
  - MongoDB connection test
  - Redis connection test

**Output:** Color-coded results showing what's working and what needs attention

---

### 5) Database Management
**Purpose:** Manage all database operations

**Sub-options:**
1. **Backup Databases**
   - Creates PostgreSQL dump
   - Creates MongoDB backup
   - Saves with timestamp (YYYYMMDD_HHMMSS)
   - Location: `backups/` folder

2. **Restore from Backup**
   - Lists available backups
   - Restores selected backup
   - Confirms before restoring

3. **Reset PostgreSQL**
   - ⚠️ Warning confirmation required
   - Drops and recreates database
   - Clears all data

4. **Reset MongoDB**
   - ⚠️ Warning confirmation required
   - Drops all collections
   - Clears all data

5. **View Database Status**
   - Shows PostgreSQL databases
   - Shows MongoDB databases
   - Shows Redis key count

---

### 6) Security Audit
**Purpose:** Check system security posture

**Checks performed:**
- 📋 Configuration files present (.env file)
- 🔒 Port exposure analysis
- 🔐 File permissions validation
- 🛡️ npm dependency vulnerability scan

**Output:** Security recommendations and alerts

---

### 7) User Management
**Purpose:** Manage application users

**Sub-options:**
1. **List All Users**
   - Shows database users with email, role, creation date
   - Limited to 10 most recent users

2. **Create New User**
   - Prompts for email address
   - Prompts for role (admin/driver/customer)
   - Adds user to PostgreSQL database

3. **Reset User Password**
   - Prompts for user email
   - Sends password reset link

4. **Delete User**
   - Confirms before deletion
   - Removes from database

5. **View User Roles**
   - Shows count of users by role
   - Breakdown: admin, driver, customer

---

### 8) Error Recovery
**Purpose:** Automatically fix common issues

**Recovery steps:**
1. Checks Docker container status
2. Clears port conflicts (kills stuck processes)
3. Restarts all services
4. Waits for services to stabilize
5. Verifies all ports responding

**Use when:** Services aren't responding or ports show conflicts

---

### 9) Backup & Restore
**Purpose:** Create and restore system backups

**Sub-options:**
1. **Full System Backup**
   - Backs up web/, config/, scripts/
   - Backs up PostgreSQL database
   - Backs up MongoDB database
   - Creates compressed archive (.tar.gz)

2. **Database Only Backup**
   - Backs up PostgreSQL and MongoDB only
   - Faster than full backup
   - Smaller file size

3. **Code Only Backup**
   - Backs up application code
   - Excludes databases
   - Excludes node_modules

4. **List Backups**
   - Shows all available backups with sizes
   - Latest backups listed first

5. **Restore from Backup**
   - Lists available backups
   - Confirms before restoring
   - Restores code and configuration

---

### 10) System Cleanup
**Purpose:** Remove temporary files and unused resources

**Cleanup actions (requires confirmation):**
1. Remove unused Docker images (older than 24 hours)
2. Remove stopped containers
3. Delete old log files (older than 30 days)
4. Clear Node module cache
5. Remove temporary files (/tmp/*.log)
6. Remove unused Docker volumes

**Use when:** Freeing up disk space or doing maintenance

---

### 11) Exit
**Purpose:** Close the menu system

**Action:** Gracefully exits the program

---

## 📊 Feature Matrix

| Feature | Menu | Status |
|---------|------|--------|
| Docker management | 1,2,3,5,8 | ✓ Full |
| Node server management | 1,2,3,8 | ✓ Full |
| Service monitoring | 3,4 | ✓ Full |
| Database operations | 5,7 | ✓ Full |
| Backups | 9 | ✓ Full |
| Security checks | 6 | ✓ Full |
| Error recovery | 8 | ✓ Full |
| System cleanup | 10 | ✓ Full |
| Logging | All | ✓ Full |
| Color output | All | ✓ Full |

---

## 🎯 Quick Start Examples

### First Time Setup:
```bash
cd /workspaces/Proyecto
bash scripts/main.sh
# Select: 1) Fresh Installation
```

### Check System Health:
```bash
bash scripts/main.sh
# Select: 4) System Diagnostics
```

### Backup Before Major Changes:
```bash
bash scripts/main.sh
# Select: 9) Backup & Restore → 1) Full System Backup
```

### Fix Service Issues:
```bash
bash scripts/main.sh
# Select: 8) Error Recovery
```

### Update to Latest:
```bash
bash scripts/main.sh
# Select: 2) Update Existing Installation
```

---

## 📁 Output Locations

- **Logs:** `logs/system.log`
- **Backups:** `backups/` directory
- **Service logs:** `/tmp/{admin,driver,customer}.log`

---

## ✅ All Menus Functional

Every menu option now:
- ✓ Has proper input validation
- ✓ Provides color-coded feedback
- ✓ Logs all operations
- ✓ Handles errors gracefully
- ✓ Returns to menu after completion
- ✓ Shows appropriate responses and confirmations

---

## 🔧 Configuration

Current settings in main.sh:
- VPS_IP: 5.249.164.40
- Ports monitored: 3001, 3002, 3003, 8080
- Backup directory: backups/
- Log directory: logs/

---

## 💡 Tips

1. **Always backup before making changes** (Menu 9)
2. **Check diagnostics if unsure** (Menu 4)
3. **Use error recovery for quick fixes** (Menu 8)
4. **Monitor logs for troubleshooting** (Menu 3 → View Logs)
5. **Keep system clean** (Menu 10 → System Cleanup)

---

**Last Updated:** 2025-12-22  
**Script Version:** 2.0 (Fully Functional)
