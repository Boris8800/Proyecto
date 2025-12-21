#!/bin/bash
cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════════╗
║                   TAXI SYSTEM - PORT FIX QUICK REFERENCE                    ║
╚══════════════════════════════════════════════════════════════════════════════╝

ISSUE: Port 80 (nginx) is already in use
  [WARN] Port 80 (nginx (HTTP)) is already in use
  [ERROR] Port conflicts could not be resolved


SOLUTION OPTIONS (Choose One):
═══════════════════════════════════════════════════════════════════════════════

✅ OPTION 1: Automatic Installation (Recommended)
   Run the main installer - it will automatically resolve port conflicts:

   sudo bash /root/install-taxi-system.sh

   The installer will:
   • Pre-emptively kill blocking processes
   • Check all required ports
   • Auto-fix conflicts (up to 3 attempts)
   • Show helpful error messages if needed


✅ OPTION 2: Diagnose First, Then Fix
   Use the diagnostic tool to understand what's blocking ports:

   sudo bash /root/debug-ports.sh

   This will:
   • Show which ports are in use
   • Identify blocking processes
   • Offer interactive auto-fix
   • Provide manual commands if needed


✅ OPTION 3: Manual Cleanup
   Run these commands in order:

   # 1. Kill web servers
   sudo pkill -9 nginx
   sudo pkill -9 apache2
   sudo pkill -9 httpd
   sudo pkill -9 haproxy

   # 2. Stop Docker
   sudo systemctl stop docker 2>/dev/null || true
   sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true

   # 3. Clean Docker
   sudo docker system prune -af

   # 4. Wait for ports to release
   sleep 3

   # 5. Verify ports are free
   sudo ss -tulpn | grep -E ':(80|443|3000|3001|3002|3003|5432|27017|6379)'

   # 6. Start installation
   sudo bash /root/install-taxi-system.sh


✅ OPTION 4: Check and Use Force Release (Advanced)
   For stubborn ports:

   # Release specific port
   sudo fuser -k 80/tcp 2>/dev/null || true
   sudo fuser -k 443/tcp 2>/dev/null || true

   # Or use iptables to reset connections
   sudo iptables -F
   sudo iptables -X

   # Then run installer
   sudo bash /root/install-taxi-system.sh


═══════════════════════════════════════════════════════════════════════════════
WHAT CHANGED & WHY IT NOW WORKS:
═══════════════════════════════════════════════════════════════════════════════

IMPROVED PORT DETECTION
  • Now uses 'ss' (most reliable method) first
  • Falls back to lsof, netstat, /dev/tcp if ss unavailable
  • Detects ports on first check correctly

AGGRESSIVE CLEANUP
  • Pre-kills nginx, apache, httpd
  • Stops all Docker containers
  • Uses fuser to force-release ports
  • Waits 4 seconds between retries

SMART RETRY LOGIC
  • Tries up to 3 times to resolve conflicts
  • Each attempt with increased aggressiveness
  • Logs what's being attempted
  • Clear error message with manual commands if all fail

NEW DIAGNOSTIC TOOL
  • debug-ports.sh shows real-time port status
  • Identifies blocking processes
  • Offers one-click automatic fix
  • Same detection methods as installer

COMPREHENSIVE DOCUMENTATION
  • PORT_TROUBLESHOOTING.md - full guide for any port issue
  • Specific solutions for each port
  • Prevention tips
  • Real-time monitoring commands


═══════════════════════════════════════════════════════════════════════════════
QUICK COMMANDS:
═══════════════════════════════════════════════════════════════════════════════

Check ports:             sudo bash /root/debug-ports.sh
Run installer:          sudo bash /root/install-taxi-system.sh
View troubleshooting:   cat /workspaces/Proyecto/PORT_TROUBLESHOOTING.md
Check specific port:    sudo ss -tulpn | grep ":80"
Find process on port:   sudo lsof -i :80
Kill port:              sudo fuser -k 80/tcp
Watch ports (live):     watch -n 1 'sudo ss -tulpn'


═══════════════════════════════════════════════════════════════════════════════
WHAT PORTS ARE USED:
═══════════════════════════════════════════════════════════════════════════════

Port  Service                    Default Process
────  ──────────────────────────  ────────────────
80    HTTP Web Server           nginx
443   HTTPS Web Server          nginx
5432  PostgreSQL Database       postgres
27017 MongoDB Database          mongod
6379  Redis Cache               redis-server
3000  API Gateway               node
3001  Admin Dashboard           node
3002  Driver Dashboard          node
3003  Customer Dashboard        node


═══════════════════════════════════════════════════════════════════════════════
WHICH SOLUTION TO CHOOSE:
═══════════════════════════════════════════════════════════════════════════════

IF YOU...                           THEN USE...
─────────────────────────────────  ──────────────────────────────────────
Want quick installation            Option 1: sudo bash install-taxi-system.sh
Want to understand the problem     Option 2: sudo bash debug-ports.sh
Want complete control              Option 3: Manual cleanup commands
Have recurring issues              Option 4: Force release + install
Just want one command              Option 1 (automatic, usually works)


═══════════════════════════════════════════════════════════════════════════════
EXAMPLE: Complete Automated Fix
═══════════════════════════════════════════════════════════════════════════════

# Copy this entire block and paste in terminal:

sudo bash /root/install-taxi-system.sh

# That's it! The installer now:
# ✓ Pre-kills blocking processes
# ✓ Checks all 9 ports
# ✓ Auto-fixes conflicts
# ✓ Retries if needed
# ✓ Shows helpful errors if manual fix needed


═══════════════════════════════════════════════════════════════════════════════
HELPFUL INFORMATION:
═══════════════════════════════════════════════════════════════════════════════

When port conflicts were reported in past attempts, the system now:

  1. DIAGNOSES: Checks which ports are in use
  2. CLEANS: Kills blocking processes
  3. WAITS: Gives system time to release
  4. VERIFIES: Confirms ports are free
  5. RETRIES: Up to 3 times if needed
  6. INFORMS: Shows manual fixes if auto-fix fails

All this happens automatically with the improved installer!


═══════════════════════════════════════════════════════════════════════════════

For detailed information, see:
  /workspaces/Proyecto/PORT_TROUBLESHOOTING.md
  /workspaces/Proyecto/PORT_FIX_SUMMARY.md

EOF
