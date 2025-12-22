# Swift Cab - Taxi Booking System

A complete, production-ready taxi booking platform with driver and customer management, built with Docker and modern web technologies. Deploy to your VPS (like 5.249.164.40) with a single command!

## 🚀 Quick Start

### For VPS Deployment

```bash
cd scripts

# 1. Configure for your VPS IP (e.g., 5.249.164.40)
sudo ./vps-setup.sh 5.249.164.40

# 2. Deploy all services
sudo ./vps-deploy.sh

# 3. Access your system
# Admin:    http://5.249.164.40:3001
# Driver:   http://5.249.164.40:3002
# Customer: http://5.249.164.40:3003
# Status:   http://5.249.164.40:8080
```

### For Local Development

```bash
cd scripts
./main.sh
```

## 📁 Project Structure

```
├── scripts/               # Deployment and management scripts
│   ├── vps-setup.sh      # VPS configuration setup
│   ├── vps-deploy.sh     # Deploy to VPS
│   ├── vps-manage.sh     # Management dashboard
│   ├── lib/              # Shared bash libraries
│   └── main.sh           # Main control script
├── config/               # Configuration files
│   ├── docker-compose.yml # Complete service definitions
│   ├── .env.example       # Environment template
│   └── nginx-vps.conf     # Nginx reverse proxy config
├── web/                  # Web applications
│   ├── admin/            # Admin dashboard
│   ├── customer/         # Customer booking app
│   ├── driver/           # Driver dashboard
│   ├── api/              # REST API backend
│   └── status/           # System status monitoring
└── docs/                 # Documentation
```

## 🌐 Services & Ports

| Service | Port | URL |
|---------|------|-----|
| **API Server** | 3000 | http://VPS_IP:3000 |
| **Admin Dashboard** | 3001 | http://VPS_IP:3001 |
| **Driver Portal** | 3002 | http://VPS_IP:3002 |
| **Customer App** | 3003 | http://VPS_IP:3003 |
| **Status Dashboard** | 8080 | http://VPS_IP:8080 |
| **PostgreSQL** | 5432 | VPS_IP:5432 |
| **MongoDB** | 27017 | VPS_IP:27017 |
| **Redis** | 6379 | VPS_IP:6379 |

## 📊 Status Monitoring

Real-time monitoring dashboard showing:
- ✓ Service status (online/offline)
- ✓ Container health
- ✓ System resources
- ✓ Database connectivity
- ✓ Uptime statistics

**Access**: http://VPS_IP:8080

## 🛠️ Management Commands

```bash
cd scripts

# View status
./vps-manage.sh status

# Manage services
./vps-manage.sh restart
./vps-manage.sh stop
./vps-manage.sh start

# Database backup
./vps-manage.sh backup

# Health check
./vps-manage.sh health

# Interactive menu
./vps-manage.sh
```

## 🔐 Security Features

- ✓ Magic link authentication (passwordless)
- ✓ Rate limiting on API endpoints
- ✓ CORS protection
- ✓ Environment-based configuration
- ✓ Database encryption at rest
- ✓ Secure password storage
- ✓ SSL/TLS support (Nginx reverse proxy included)

## 📚 Documentation

- [VPS Deployment Guide](docs/VPS_DEPLOYMENT_GUIDE.md) - Complete setup and deployment instructions
- [Magic Links System](docs/MAGIC_LINKS_SYSTEM.md) - Authentication documentation
- [Changelog](docs/CHANGELOG.md) - Version history

## 🐳 Docker Services

All services run in Docker containers:

### Databases
- **PostgreSQL**: User and booking data
- **MongoDB**: Document storage
- **Redis**: Caching and sessions

### Applications
- **API Server**: Express.js backend
- **Admin Dashboard**: Admin management interface
- **Driver Portal**: Driver management app
- **Customer App**: Customer booking interface
- **Status Dashboard**: System monitoring

## ⚙️ Configuration

### VPS Setup

1. Edit `config/.env`:
```env
VPS_IP=5.249.164.40
POSTGRES_PASSWORD=YourSecurePassword123!
MONGO_PASSWORD=YourSecurePassword123!
REDIS_PASSWORD=YourSecurePassword123!
```

2. Run setup:
```bash
sudo ./scripts/vps-setup.sh 5.249.164.40
```

3. Deploy:
```bash
sudo ./scripts/vps-deploy.sh
```

### Environment Variables

- `VPS_IP` - Your VPS IP address
- `POSTGRES_PASSWORD` - PostgreSQL admin password
- `MONGO_PASSWORD` - MongoDB admin password
- `REDIS_PASSWORD` - Redis password
- `NODE_ENV` - Environment (production/development)

## 🔄 Deployment Workflow

```
vps-setup.sh   → Validate & configure
      ↓
vps-deploy.sh  → Start all services
      ↓
vps-manage.sh  → Monitor & manage
      ↓
nginx config   → Optional: Set up reverse proxy with SSL
```

## 📈 Scaling

To scale services:

```bash
cd config
# Scale API to 3 instances
docker-compose up -d --scale taxi-api=3
```

## 🐛 Troubleshooting

### Check service status:
```bash
./scripts/vps-manage.sh health
```

### View logs:
```bash
./scripts/vps-manage.sh logs
```

### Restart services:
```bash
./scripts/vps-manage.sh restart
```

## 📝 Backup & Recovery

### Automatic backups:
```bash
# Backup databases
./scripts/vps-manage.sh backup
```

Backups are stored in `backups/` directory.

### Schedule daily backups (cron):
```bash
0 2 * * * cd /workspaces/Proyecto/scripts && ./vps-manage.sh backup
```

## 🎯 Next Steps

1. ✓ Run `vps-setup.sh` with your VPS IP
2. ✓ Run `vps-deploy.sh` to start services
3. ✓ Access admin dashboard at http://VPS_IP:3001
4. ✓ Monitor system at http://VPS_IP:8080
5. ✓ Configure SSL with nginx (see config/nginx-vps.conf)
6. ✓ Set up automated backups

## 📞 Support

- Check logs: `./scripts/vps-manage.sh logs`
- Health status: `./scripts/vps-manage.sh health`
- System status: `./scripts/vps-manage.sh status`
- Full dashboard: `./scripts/vps-manage.sh`

## 📜 License

See [LICENSE](docs/LICENSE) for details.

---

**Swift Cab** - Production-Ready Taxi Booking System  
**VPS Ready**: Configured for public deployment  
**Last Updated**: 2025-12-21

