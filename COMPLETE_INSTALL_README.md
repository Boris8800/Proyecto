# 🚕 Taxi System - Complete Installation Script

## Overview

The **`taxi-complete-install.sh`** is a comprehensive, production-ready installation script that sets up a complete Taxi System from scratch on a clean Ubuntu server. It includes system cleanup, all dependencies, Docker containers, and complete web dashboards.

## What's Included

### ✅ System Components

- **Operating System:** Ubuntu 20.04+ LTS
- **Container Runtime:** Docker CE + Docker Compose
- **Web Server:** Nginx with reverse proxy
- **Databases:** PostgreSQL 15, MongoDB 6, Redis 7
- **API:** Node.js 18
- **Monitoring:** Portainer, Netdata, Grafana

### ✅ Web Dashboards

1. **Admin Panel** (port 3001)
   - Driver management
   - Trip oversight
   - Customer management
   - Payment tracking
   - Analytics & reports
   - System settings

2. **Driver Portal** (port 3002)
   - Accept trips
   - Real-time tracking
   - Earnings tracking
   - Rating management
   - Trip history

3. **Customer App** (port 3003)
   - Book rides
   - Select vehicle type
   - Schedule rides
   - View pricing
   - Track trips

4. **API Gateway** (port 3000)
   - RESTful API endpoints
   - Real-time WebSocket support
   - Rate limiting & security
   - Authentication & authorization

### ✅ Monitoring Tools

- **Portainer** (port 9000) - Docker container management
- **Netdata** (port 19999) - Real-time system monitoring
- **Grafana** (port 3100) - Custom dashboards and alerts

## Installation

### Prerequisites

- Ubuntu 20.04+ LTS server
- Root or sudo access
- Minimum 2GB RAM
- 10GB free disk space
- Internet connection

### Quick Start

**Option 1: One-liner (Recommended)**
```bash
bash <(curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh)
```

**Option 2: With logging**
```bash
bash <(curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh) | tee /var/log/taxi-install.log
```

**Option 3: Persistent session (for SSH disconnects)**
```bash
tmux new-session -d -s taxi-install 'bash <(curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh) | tee /var/log/taxi-install.log'
tmux attach-session -t taxi-install
```

**Option 4: Manual download**
```bash
curl -L https://raw.githubusercontent.com/Boris8800/Proyecto/main/taxi-complete-install.sh -o taxi-complete-install.sh
chmod +x taxi-complete-install.sh
sudo bash taxi-complete-install.sh
```

## Installation Phases (10-15 minutes)

1. **Phase 1:** System prerequisites (apt packages, security tools)
2. **Phase 2:** Docker CE & Docker Compose installation
3. **Phase 3:** Nginx web server installation
4. **Phase 4:** Taxi user and directory setup
5. **Phase 5:** Docker Compose configuration
6. **Phase 6:** Web dashboards creation (Admin, Driver, Customer, API)
7. **Phase 7:** Nginx reverse proxy configuration
8. **Phase 8:** Starting Docker containers
9. **Phase 9:** Final configuration and security

## Features

### 🔐 Security

- Docker permission auto-detection and fixing
- Non-root user execution (taxi user)
- UFW firewall integration
- fail2ban protection
- SSH hardening
- Automatic security updates

### 🛠️ Auto-Configuration

- **Docker Permissions:** Interactive menu to add user to docker group
- **Nginx Setup:** Automatic reverse proxy configuration
- **Database Setup:** Pre-configured connections
- **Environment Files:** .env with sensible defaults

### 📊 Monitoring

- Real-time system metrics (Netdata)
- Docker container monitoring (Portainer)
- Custom dashboards (Grafana)
- Automatic service health checks

### 💾 Data Persistence

- PostgreSQL volumes mounted
- MongoDB persistent storage
- Redis data persistence
- Application logs in `/home/taxi/logs`

## After Installation

### Access Points

```
Admin Panel:     http://YOUR_IP/admin (port 3001)
Driver Portal:   http://YOUR_IP/driver (port 3002)
Customer App:    http://YOUR_IP/customer (port 3003)
API Gateway:     http://YOUR_IP/ (port 3000)

Portainer:       http://YOUR_IP:9000
Netdata:         http://YOUR_IP:19999
Grafana:         http://YOUR_IP:3100
```

### Database Connections

```
PostgreSQL: YOUR_IP:5432 (user: admin, password: admin123)
MongoDB:    YOUR_IP:27017 (user: admin, password: admin123)
Redis:      YOUR_IP:6379 (password: redis123)
```

### Useful Commands

```bash
# View running containers
docker ps

# Check service logs
docker logs taxi-api
docker logs taxi-postgres

# Restart services
cd /home/taxi/app && sudo -u taxi docker-compose restart

# Stop services
cd /home/taxi/app && sudo -u taxi docker-compose down

# Start services
cd /home/taxi/app && sudo -u taxi docker-compose up -d

# View installation log
tail -f /var/log/taxi-install.log

# Check system status
docker stats
```

## Troubleshooting

### Docker Permission Issues

```bash
sudo usermod -aG docker taxi
sudo -u taxi docker ps
```

### Port Conflicts

```bash
sudo fuser -k 80/tcp 443/tcp
systemctl restart nginx
```

### Service Won't Start

```bash
# Check logs
docker logs <container_name>

# Restart service
docker restart <container_name>

# View docker-compose status
cd /home/taxi/app && docker-compose ps
```

### Out of Disk Space

```bash
docker system prune -a  # Remove unused images/containers
docker volume prune     # Remove unused volumes
```

## Production Checklist

- [ ] Change all default passwords
- [ ] Configure SSL/TLS certificates
- [ ] Set up domain name
- [ ] Configure firewall rules
- [ ] Enable automatic backups
- [ ] Set up monitoring alerts
- [ ] Configure email service
- [ ] Enable payment gateway
- [ ] Set up SMS notifications
- [ ] Review security settings

## System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 2GB | 4GB+ |
| Storage | 10GB | 50GB+ |
| Network | 1 Mbps | 10+ Mbps |

## Default Credentials (⚠️ Change Immediately!)

```
Admin Panel:  admin123
Database:     admin / admin123
Grafana:      admin / admin123
```

## Support & Documentation

- **GitHub:** https://github.com/Boris8800/Proyecto
- **Docker Guide:** DOCKER_PERMISSION_FIX.md
- **Installation Guide:** COMPLETE_INSTALL_GUIDE.sh
- **Fixes Applied:** FIXES_APPLIED.md

## File Locations

```
/home/taxi/               - Taxi user home directory
/home/taxi/app/          - Application directory
/home/taxi/app/docker-compose.yml - Docker configuration
/home/taxi/app/.env      - Environment variables
/home/taxi/app/admin/    - Admin panel files
/home/taxi/app/driver/   - Driver portal files
/home/taxi/app/customer/ - Customer app files
/home/taxi/app/api/      - API files
/home/taxi/logs/         - Application logs
/var/log/taxi-install.log - Installation log
```

## Development

To modify the installation script:

1. Edit `taxi-complete-install.sh`
2. Test syntax: `bash -n taxi-complete-install.sh`
3. Commit changes: `git commit -m "Your message"`
4. Push to GitHub: `git push origin main`

## Version

- **Version:** 2.0
- **Last Updated:** December 20, 2025
- **Status:** Production Ready ✅

---

**Ready to deploy the Taxi System? Run the installation command above!** 🚀
