#!/bin/bash

# ════════════════════════════════════════════════════════════════════════════════
#                          TAXI SYSTEM - QUICK START GUIDE
#                         Complete Installation with Dashboard
# ════════════════════════════════════════════════════════════════════════════════

echo "🚕 TAXI SYSTEM - COMPLETE INSTALLATION"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
echo "This is the COMPLETE installer that includes:"
echo "✅ System cleanup (removes old installations)"
echo "✅ Fresh installation of all services"
echo "✅ Docker with auto permission handling"
echo "✅ Complete web dashboards (Admin, Driver, Customer)"
echo "✅ Database setup (PostgreSQL, MongoDB, Redis)"
echo "✅ Monitoring tools (Portainer, Netdata, Grafana)"
echo "✅ Nginx reverse proxy configuration"
echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# INSTALLATION OPTIONS
# ════════════════════════════════════════════════════════════════════════════════

echo "📋 INSTALLATION OPTIONS"
echo ""

echo "🚀 OPTION 1: One-liner (Recommended for fresh Ubuntu server)"
echo "───────────────────────────────────────────────────────────"
echo "bash <(curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh)"
echo ""

echo "🚀 OPTION 2: With logging to file"
echo "───────────────────────────────────"
echo "bash <(curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh) | tee /var/log/taxi-install.log"
echo ""

echo "🚀 OPTION 3: Persistent session (if SSH disconnects)"
echo "───────────────────────────────────"
echo "tmux new-session -d -s taxi-install 'bash <(curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh) | tee /var/log/taxi-install.log'"
echo ""
echo "# Monitor progress:"
echo "tmux attach-session -t taxi-install"
echo ""

echo "🚀 OPTION 4: Manual download and run"
echo "───────────────────────────────────"
echo "curl -L https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh -o taxi-complete-install.sh"
echo "chmod +x taxi-complete-install.sh"
echo "sudo bash taxi-complete-install.sh"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# INSTALLATION PROCESS
# ════════════════════════════════════════════════════════════════════════════════

echo "⏱️  INSTALLATION PROCESS"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

echo "The installation has 9 phases and will take 10-15 minutes:"
echo ""
echo "   Phase 1: System prerequisites (apt packages, tools)"
echo "   Phase 2: Docker CE & Docker Compose installation"
echo "   Phase 3: Nginx web server installation"
echo "   Phase 4: Taxi user creation and directories"
echo "   Phase 5: Docker Compose configuration"
echo "   Phase 6: Creating web dashboards (Admin, Driver, Customer)"
echo "   Phase 7: Nginx reverse proxy configuration"
echo "   Phase 8: Starting Docker containers"
echo "   Phase 9: Final configuration and security"
echo ""

echo "📌 During installation, you'll be asked:"
echo "   • Confirm system cleanup (removes old Docker installations)"
echo "   • If Docker permissions need fixing (choose option 1 for auto-fix)"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# AFTER INSTALLATION
# ════════════════════════════════════════════════════════════════════════════════

echo "✅ AFTER INSTALLATION COMPLETES"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

echo "📊 Access Your Services:"
echo "   🌐 Main API:         http://YOUR_IP/"
echo "   👨‍💼 Admin Panel:       http://YOUR_IP/admin  (port 3001)"
echo "   🚗 Driver Portal:    http://YOUR_IP/driver (port 3002)"
echo "   📱 Customer App:     http://YOUR_IP/customer (port 3003)"
echo ""

echo "🔧 Management & Monitoring:"
echo "   🐋 Portainer:        http://YOUR_IP:9000 (Docker management)"
echo "   📈 Netdata:          http://YOUR_IP:19999 (System monitoring)"
echo "   📊 Grafana:          http://YOUR_IP:3100 (Dashboards)"
echo ""

echo "🗄️  Databases:"
echo "   PostgreSQL: YOUR_IP:5432  (admin / admin123)"
echo "   MongoDB:    YOUR_IP:27017 (admin / admin123)"
echo "   Redis:      YOUR_IP:6379  (password: redis123)"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# USEFUL COMMANDS
# ════════════════════════════════════════════════════════════════════════════════

echo "📝 USEFUL COMMANDS"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

echo "🔍 Check status:"
echo "   docker ps                    # View all running containers"
echo "   docker ps -a                 # View all containers"
echo "   docker-compose ps            # Check Docker Compose services"
echo ""

echo "📋 View logs:"
echo "   docker logs taxi-api         # API service logs"
echo "   docker logs taxi-postgres    # PostgreSQL logs"
echo "   docker logs taxi-mongodb     # MongoDB logs"
echo "   docker logs taxi-redis       # Redis logs"
echo "   tail -f /var/log/taxi-install.log   # Installation log"
echo ""

echo "🔄 Manage services:"
echo "   cd /home/taxi/app"
echo "   sudo -u taxi docker-compose restart          # Restart all services"
echo "   sudo -u taxi docker-compose restart api      # Restart specific service"
echo "   sudo -u taxi docker-compose down             # Stop all services"
echo "   sudo -u taxi docker-compose up -d            # Start all services"
echo ""

echo "🔐 Access databases:"
echo "   # PostgreSQL"
echo "   psql -h localhost -U admin -d taxi"
echo ""
echo "   # MongoDB"
echo "   mongosh --username admin --password admin123 --authenticationDatabase admin"
echo ""

echo "🗄️  Backup:"
echo "   docker exec taxi-postgres pg_dump -U admin taxi > backup.sql"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# TROUBLESHOOTING
# ════════════════════════════════════════════════════════════════════════════════

echo "❌ TROUBLESHOOTING"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

echo "Problem: Docker socket permission denied"
echo "Solution: sudo usermod -aG docker taxi && newgrp docker"
echo ""

echo "Problem: Port 80/443 already in use"
echo "Solution: sudo fuser -k 80/tcp 443/tcp"
echo ""

echo "Problem: Docker service won't start"
echo "Solution: systemctl restart docker"
echo ""

echo "Problem: Containers not starting"
echo "Solution: docker-compose logs (check what's wrong)"
echo ""

echo "Problem: Out of disk space"
echo "Solution: docker system prune -a (removes unused images/containers)"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# NEXT STEPS
# ════════════════════════════════════════════════════════════════════════════════

echo "🎯 NEXT STEPS"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

echo "1. 🔐 Change default credentials (IMPORTANT!):"
echo "   • Admin panel password"
echo "   • Database passwords"
echo "   • Grafana password"
echo ""

echo "2. 🔒 Configure SSL/TLS:"
echo "   • Use Let's Encrypt or your own certificates"
echo "   • Update Nginx configuration"
echo ""

echo "3. 📊 Configure monitoring:"
echo "   • Set up Grafana dashboards"
echo "   • Configure alerts"
echo "   • Add data sources"
echo ""

echo "4. 💾 Set up backups:"
echo "   • Configure automated database backups"
echo "   • Set up disaster recovery"
echo ""

echo "5. 🚀 Deploy to production:"
echo "   • Configure domain name"
echo "   • Enable SSL"
echo "   • Set up firewall rules"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# SUPPORT
# ════════════════════════════════════════════════════════════════════════════════

echo "❓ SUPPORT & DOCUMENTATION"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

echo "GitHub Repository:"
echo "   https://github.com/Boris8800/Proyecto"
echo ""

echo "Documentation files:"
echo "   • DOCKER_PERMISSION_FIX.md - Docker permission issues"
echo "   • INSTALLATION_GUIDE.sh - Detailed installation guide"
echo "   • FIXES_APPLIED.md - All fixes and improvements"
echo ""

echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Ready to install? Copy and paste the command above! 🚀"
echo ""
