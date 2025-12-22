# VPS Deployment Guide for Swift Cab

## 🚀 Quick Start

Your Swift Cab taxi booking system is now configured for VPS deployment on **5.249.164.40**.

### Prerequisites
- Ubuntu 20.04+ or similar Linux distribution
- Docker and Docker Compose installed
- At least 4GB RAM and 20GB disk space
- Root or sudo access

---

## 📋 Deployment Steps

### Step 1: Initial Setup

```bash
cd /workspaces/Proyecto/scripts
chmod +x *.sh

# Configure VPS IP (use your actual IP)
./vps-setup.sh 5.249.164.40
```

This will:
- ✓ Validate your VPS IP address
- ✓ Create `.env` configuration file
- ✓ Set up environment variables
- ✓ Check firewall rules

### Step 2: Deploy Services

```bash
./vps-deploy.sh
```

This will:
- ✓ Pull latest Docker images
- ✓ Start all containers (API, web interfaces, databases)
- ✓ Configure services for your VPS IP
- ✓ Wait for services to stabilize
- ✓ Display access information

### Step 3: Verify Deployment

```bash
./vps-manage.sh status
```

This shows:
- ✓ Running containers
- ✓ Service URLs
- ✓ Database connections
- ✓ System uptime

---

## 🌐 Access Your Services

Once deployed, access your system at:

### Web Interfaces
| Service | URL | Port |
|---------|-----|------|
| **Admin Dashboard** | http://5.249.164.40:3001 | 3001 |
| **Driver Portal** | http://5.249.164.40:3002 | 3002 |
| **Customer App** | http://5.249.164.40:3003 | 3003 |
| **Status Dashboard** | http://5.249.164.40:8080 | 8080 |

### API Server
- **Base URL**: http://5.249.164.40:3000
- **Health Check**: http://5.249.164.40:3000/health

### Database Connections
| Database | Host | Port | User | Password |
|----------|------|------|------|----------|
| **PostgreSQL** | 5.249.164.40 | 5432 | taxi_admin | (see .env) |
| **MongoDB** | 5.249.164.40 | 27017 | admin | (see .env) |
| **Redis** | 5.249.164.40 | 6379 | - | (see .env) |

---

## 🛠️ Management Commands

### View System Status
```bash
./vps-manage.sh status
```

### Restart Services
```bash
./vps-manage.sh restart
```

### Stop Services
```bash
./vps-manage.sh stop
```

### Start Services
```bash
./vps-manage.sh start
```

### View Container Logs
```bash
./vps-manage.sh logs
```

### Health Check
```bash
./vps-manage.sh health
```

### Backup Databases
```bash
./vps-manage.sh backup
```

### View Service URLs
```bash
./vps-manage.sh urls
```

### Interactive Management Menu
```bash
./vps-manage.sh
```

---

## 🔐 Security Configuration

### Firewall Setup (UFW)

```bash
# Enable UFW (if not already enabled)
sudo ufw enable

# Allow required ports
sudo ufw allow 3000/tcp    # API
sudo ufw allow 3001/tcp    # Admin
sudo ufw allow 3002/tcp    # Driver
sudo ufw allow 3003/tcp    # Customer
sudo ufw allow 8080/tcp    # Status Dashboard
sudo ufw allow 5432/tcp    # PostgreSQL
sudo ufw allow 27017/tcp   # MongoDB
sudo ufw allow 6379/tcp    # Redis
sudo ufw allow 22/tcp      # SSH
```

### SSL/TLS Setup (Recommended)

For HTTPS support, use nginx as reverse proxy:

```bash
# Install nginx
sudo apt update && sudo apt install nginx certbot python3-certbot-nginx

# Configure reverse proxy
sudo nano /etc/nginx/sites-available/default
```

Example nginx configuration:
```nginx
upstream api {
    server 5.249.164.40:3000;
}

server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://api;
    }
}
```

Obtain SSL certificate:
```bash
sudo certbot certonly --standalone -d your-domain.com
```

---

## 📊 Status Monitoring Dashboard

Access the real-time status dashboard:

**URL**: http://5.249.164.40:8080

Features:
- ✓ Real-time service status
- ✓ Container health monitoring
- ✓ System resource usage
- ✓ Service uptime tracking
- ✓ Quick access to all services
- ✓ System information display

---

## 💾 Backup & Recovery

### Automatic Backups

Schedule daily backups with cron:

```bash
# Edit crontab
sudo crontab -e

# Add this line for daily backups at 2 AM
0 2 * * * /workspaces/Proyecto/scripts/vps-manage.sh backup
```

### Manual Backup

```bash
./vps-manage.sh backup
```

Backups are saved to: `/workspaces/Proyecto/backups/`

### Restore from Backup

```bash
# PostgreSQL
docker exec taxi-postgres psql -U taxi_admin taxi_db < backup.sql

# MongoDB
docker exec taxi-mongo mongorestore --archive < backup.archive
```

---

## 📈 Scaling & Performance

### Increase Resources

Edit `docker-compose.yml`:
```yaml
services:
  taxi-api:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

Restart services:
```bash
./vps-manage.sh restart
```

### Load Balancing

Use multiple API instances:
```bash
# Scale API to 3 instances
docker-compose up -d --scale taxi-api=3
```

---

## 🐛 Troubleshooting

### Services not starting

```bash
# Check logs
./vps-manage.sh logs

# Restart
./vps-manage.sh restart

# Health check
./vps-manage.sh health
```

### Port already in use

```bash
# Find what's using port 3000
sudo lsof -i :3000

# Kill process
sudo kill -9 <PID>
```

### Database connection issues

```bash
# Check database health
docker exec taxi-postgres pg_isready -U taxi_admin
docker exec taxi-mongo mongosh --eval "db.adminCommand('ping')"
docker exec taxi-redis redis-cli ping
```

### Out of disk space

```bash
# Check disk usage
df -h

# Cleanup Docker
./vps-manage.sh cleanup
```

---

## 📝 Configuration Files

### Main Configuration: `.env`

Located at: `/workspaces/Proyecto/config/.env`

```env
VPS_IP=5.249.164.40
POSTGRES_PASSWORD=ChangeMe_SecurePassword123!
MONGO_PASSWORD=ChangeMe_SecurePassword123!
REDIS_PASSWORD=ChangeMe_SecurePassword123!
```

### Docker Compose: `docker-compose.yml`

Located at: `/workspaces/Proyecto/config/docker-compose.yml`

Contains all service definitions and configurations.

---

## 🔄 Updating Services

### Pull Latest Images

```bash
cd /workspaces/Proyecto/config
docker-compose pull
docker-compose up -d
```

### Update Configuration

Edit `.env` file:
```bash
nano /workspaces/Proyecto/config/.env
```

Restart services to apply changes:
```bash
./vps-manage.sh restart
```

---

## 📞 Support & Documentation

- **Status Dashboard**: http://5.249.164.40:8080
- **API Documentation**: Check `/workspaces/Proyecto/docs/`
- **Configuration Guide**: See `docs/MAGIC_LINKS_SYSTEM.md`
- **Changelog**: See `docs/CHANGELOG.md`

---

## ✅ Deployment Checklist

- [ ] VPS IP configured (5.249.164.40)
- [ ] Docker and Docker Compose installed
- [ ] `vps-setup.sh` executed successfully
- [ ] `vps-deploy.sh` completed without errors
- [ ] All services showing "Online" in status
- [ ] Firewall rules configured
- [ ] Backup strategy established
- [ ] SSL/TLS configured (recommended)
- [ ] Database backups tested
- [ ] Team access configured

---

## 🎯 Next Steps

1. ✓ Access admin dashboard: http://5.249.164.40:3001
2. ✓ Configure admin users
3. ✓ Set up drivers and vehicles
4. ✓ Test customer booking flow
5. ✓ Monitor status dashboard: http://5.249.164.40:8080
6. ✓ Set up automated backups
7. ✓ Configure domain with SSL
8. ✓ Setup monitoring alerts

---

**Created**: 2025-12-21  
**Project**: Swift Cab Taxi Booking System  
**VPS IP**: 5.249.164.40
