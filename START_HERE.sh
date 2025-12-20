#!/bin/bash

# ════════════════════════════════════════════════════════════════════════════════
#                    🚕 TAXI SYSTEM - COMPLETE INSTALLATION SUMMARY
# ════════════════════════════════════════════════════════════════════════════════

cat << 'EOF'

╔════════════════════════════════════════════════════════════════════════════════╗
║                   ✅ COMPLETE TAXI SYSTEM INSTALLER READY ✅                   ║
║                                                                                ║
║                  Clean Install + Full Dashboard + All Services                 ║
╚════════════════════════════════════════════════════════════════════════════════╝

📦 WHAT'S INCLUDED IN taxi-complete-install.sh:

   ✅ Complete system cleanup (removes old Docker installations)
   ✅ Fresh Docker installation with auto-permission handling
   ✅ PostgreSQL 15 database (admin/admin123)
   ✅ MongoDB 6 for document storage (admin/admin123)
   ✅ Redis 7 for caching (password: redis123)
   ✅ Node.js 18 API Gateway
   ✅ Nginx reverse proxy
   
   🎨 WEB DASHBOARDS:
   ✅ Admin Panel (port 3001) - Complete management interface
   ✅ Driver Portal (port 3002) - Driver earnings & trip tracking
   ✅ Customer App (port 3003) - Ride booking interface
   ✅ API Docs (port 3000) - RESTful API documentation
   
   🔧 MONITORING & MANAGEMENT:
   ✅ Portainer (port 9000) - Docker container management
   ✅ Netdata (port 19999) - Real-time system monitoring
   ✅ Grafana (port 3100) - Custom dashboards
   
   🔐 SECURITY:
   ✅ Interactive Docker permission fixing
   ✅ Non-root user execution (taxi user)
   ✅ Firewall integration (UFW)
   ✅ fail2ban protection
   ✅ SSH hardening

════════════════════════════════════════════════════════════════════════════════

🚀 INSTALLATION - JUST ONE COMMAND:

   bash <(curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh)

   Or with persistent session (for SSH):
   tmux new-session -d -s taxi-install 'bash <(curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh) | tee /var/log/taxi-install.log'

════════════════════════════════════════════════════════════════════════════════

⏱️  INSTALLATION TIME: 10-15 minutes

   Phase 1: System prerequisites
   Phase 2: Docker CE & Docker Compose
   Phase 3: Nginx installation
   Phase 4: Taxi user setup
   Phase 5: Docker Compose configuration
   Phase 6: Web dashboards creation
   Phase 7: Nginx configuration
   Phase 8: Docker containers startup
   Phase 9: Final configuration

════════════════════════════════════════════════════════════════════════════════

📊 AFTER INSTALLATION - ACCESS YOUR SERVICES:

   🌐 Web Interface:
      Admin Panel:      http://YOUR_IP/admin (port 3001)
      Driver Portal:    http://YOUR_IP/driver (port 3002)
      Customer App:     http://YOUR_IP/customer (port 3003)
      API Gateway:      http://YOUR_IP/ (port 3000)

   🔧 Management:
      Portainer:        http://YOUR_IP:9000 (Docker management)
      Netdata:          http://YOUR_IP:19999 (System monitoring)
      Grafana:          http://YOUR_IP:3100 (Dashboards)

   🗄️  Database Access:
      PostgreSQL:       YOUR_IP:5432 (admin / admin123)
      MongoDB:          YOUR_IP:27017 (admin / admin123)
      Redis:            YOUR_IP:6379 (password: redis123)

════════════════════════════════════════════════════════════════════════════════

📝 USEFUL COMMANDS AFTER INSTALLATION:

   # Check running containers
   docker ps

   # View service logs
   docker logs taxi-api
   docker logs taxi-postgres

   # Restart services
   cd /home/taxi/app && sudo -u taxi docker-compose restart

   # Stop all services
   cd /home/taxi/app && sudo -u taxi docker-compose down

   # View installation log
   tail -f /var/log/taxi-install.log

════════════════════════════════════════════════════════════════════════════════

🔐 DEFAULT CREDENTIALS (CHANGE IMMEDIATELY!):

   Database Username: admin
   Database Password: admin123
   Admin Panel:       admin123
   Grafana Password:  admin123

════════════════════════════════════════════════════════════════════════════════

📋 INSTALLATION OPTIONS:

   Option 1: Simple one-liner (Recommended)
   bash <(curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh)

   Option 2: With output logging
   bash <(curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh) | tee /var/log/taxi-install.log

   Option 3: With tmux (handles SSH disconnects)
   tmux new-session -d -s taxi-install 'bash <(curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh) | tee /var/log/taxi-install.log'
   tmux attach-session -t taxi-install

   Option 4: Manual download
   curl -L https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh -o taxi-complete-install.sh
   chmod +x taxi-complete-install.sh
   sudo bash taxi-complete-install.sh

════════════════════════════════════════════════════════════════════════════════

❓ FREQUENTLY ASKED QUESTIONS:

   Q: What if Docker permissions fail?
   A: The script has interactive menu - choose option 1 to auto-fix

   Q: What if port 80 is already in use?
   A: The script will ask you to resolve. Run: sudo fuser -k 80/tcp

   Q: What if SSH disconnects during installation?
   A: Use Option 3 (tmux) to keep installation running

   Q: How do I restart services?
   A: cd /home/taxi/app && sudo -u taxi docker-compose restart

   Q: How do I backup the database?
   A: docker exec taxi-postgres pg_dump -U admin taxi > backup.sql

   Q: How do I change default passwords?
   A: Access admin panel and update settings

════════════════════════════════════════════════════════════════════════════════

📚 DOCUMENTATION:

   COMPLETE_INSTALL_README.md     - Detailed documentation
   COMPLETE_INSTALL_GUIDE.sh      - Installation guide with commands
   DOCKER_PERMISSION_FIX.md       - Docker permission issues
   FIXES_APPLIED.md               - All improvements made

════════════════════════════════════════════════════════════════════════════════

🎯 NEXT STEPS:

   1. Run the installation command
   2. Wait for completion (10-15 minutes)
   3. Access the admin panel
   4. Change default passwords
   5. Configure your services
   6. Deploy drivers and customers

════════════════════════════════════════════════════════════════════════════════

GitHub Repository: https://github.com/Boris8800/Proyecto
Status: ✅ Production Ready
Version: 2.0
Last Updated: December 20, 2025

════════════════════════════════════════════════════════════════════════════════

Ready to start? Copy the command below and paste it in your Ubuntu terminal:

bash <(curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh)

════════════════════════════════════════════════════════════════════════════════

EOF
