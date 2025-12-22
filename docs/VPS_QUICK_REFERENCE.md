# VPS Quick Reference Guide

## 🚀 60-Second Deployment

```bash
cd scripts
sudo ./vps-setup.sh 5.249.164.40
sudo ./vps-deploy.sh
```

Then access at:
- http://5.249.164.40:3001 (Admin)
- http://5.249.164.40:3002 (Driver)
- http://5.249.164.40:3003 (Customer)
- http://5.249.164.40:8080 (Status)

---

## 📋 Key Commands

### Setup & Deployment
```bash
./vps-setup.sh <IP>              # Configure VPS
./vps-deploy.sh                  # Deploy services
./vps-manage.sh                  # Open management menu
```

### Service Management
```bash
./vps-manage.sh status           # Show status
./vps-manage.sh restart          # Restart all
./vps-manage.sh start            # Start all
./vps-manage.sh stop             # Stop all
./vps-manage.sh health           # Health check
```

### Monitoring & Backup
```bash
./vps-manage.sh logs             # View logs
./vps-manage.sh backup           # Backup databases
./vps-manage.sh urls             # List all URLs
```

---

## 🌐 Service URLs

| Service | URL | Port |
|---------|-----|------|
| Admin | http://5.249.164.40:3001 | 3001 |
| Driver | http://5.249.164.40:3002 | 3002 |
| Customer | http://5.249.164.40:3003 | 3003 |
| Status | http://5.249.164.40:8080 | 8080 |
| API | http://5.249.164.40:3000 | 3000 |

---

## 🔐 Firewall (UFW)

```bash
# Allow required ports
sudo ufw allow 3000:3003/tcp  # Web services
sudo ufw allow 8080/tcp       # Status dashboard
sudo ufw allow 5432/tcp       # PostgreSQL
sudo ufw allow 27017/tcp      # MongoDB
sudo ufw allow 6379/tcp       # Redis
sudo ufw allow 22/tcp         # SSH
```

---

## 📊 Database Credentials

Located in: `/workspaces/Proyecto/config/.env`

- **PostgreSQL**: User=`taxi_admin`, Port=5432
- **MongoDB**: User=`admin`, Port=27017
- **Redis**: Port=6379

---

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| Services won't start | Run `./vps-manage.sh health` |
| Port already in use | Kill process: `sudo lsof -i :PORT` |
| Database can't connect | Check `./vps-manage.sh logs` |
| Out of disk | Run `./vps-manage.sh cleanup` |
| Forgot IP | Check `.env`: `grep VPS_IP config/.env` |

---

## 📝 File Locations

- Config: `/workspaces/Proyecto/config/.env`
- Docker Compose: `/workspaces/Proyecto/config/docker-compose.yml`
- Scripts: `/workspaces/Proyecto/scripts/`
- Web Apps: `/workspaces/Proyecto/web/`
- Backups: `/workspaces/Proyecto/backups/`

---

## 🔄 Daily Operations

```bash
# Morning: Check status
./scripts/vps-manage.sh status

# Backup databases (daily)
./scripts/vps-manage.sh backup

# Monitor health
./scripts/vps-manage.sh health

# View real-time dashboard
# Open: http://5.249.164.40:8080
```

---

## 📚 Documentation

- **Full Guide**: `docs/VPS_DEPLOYMENT_GUIDE.md`
- **API Docs**: `docs/MAGIC_LINKS_SYSTEM.md`
- **Changes**: `docs/CHANGELOG.md`
- **Main README**: `README.md`

---

## 💡 Pro Tips

1. **Auto-refresh status** - Dashboard auto-updates every 30 seconds
2. **Backup before restart** - Always backup before major changes
3. **Check logs first** - Most issues are in service logs
4. **Monitor resources** - Use status dashboard to watch CPU/memory
5. **Schedule backups** - Add to crontab for automatic backups

---

## 🆘 Emergency Procedures

### Complete System Reset
```bash
cd config
docker-compose down -v      # Stop and remove volumes
docker-compose up -d        # Restart fresh
```

### Database Recovery
```bash
./scripts/vps-manage.sh backup
# Manual restore from backup file
```

### Port Conflicts
```bash
# Find what's using port 3000
sudo netstat -tulpn | grep 3000
# Kill process
sudo kill -9 <PID>
```

---

**Quick Ref** • VPS 5.249.164.40 • Swift Cab 2025
