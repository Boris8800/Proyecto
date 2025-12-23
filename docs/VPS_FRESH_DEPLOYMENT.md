# VPS Fresh Deployment - Quick Start

## One-Liner Deployment

Replace `5.249.164.40` with your actual VPS IP address.

### Option 1: Using sudo with heredoc (Recommended)
```bash
sudo bash << 'DEPLOY'
cd /tmp
rm -rf Proyecto 2>/dev/null || true
git clone https://github.com/Boris8800/Proyecto.git
chmod -R 755 Proyecto
bash Proyecto/scripts/vps-deploy-fresh.sh 5.249.164.40
DEPLOYha
```

### Option 2: Auto-detect IP
```bash
sudo bash << 'DEPLOY'
cd /tmp
rm -rf Proyecto 2>/dev/null || true
git clone https://github.com/Boris8800/Proyecto.git
chmod -R 755 Proyecto
bash Proyecto/scripts/vps-deploy-fresh.sh
DEPLOY
```

## What Gets Installed

The `vps-deploy-fresh.sh` script handles:

| Component | Action |
|-----------|--------|
| System | Updates packages, upgrades system |
| Docker | Installs docker.io and docker-compose |
| Git | Installs for cloning repos |
| Node.js | Auto-installs via NVM if missing |
| npm | Verified and ready to use |
| .env | Created and configured with VPS IP |
| Logs | Directory created with proper permissions |

## Expected Output

```
╔════════════════════════════════════════╗
║ SWIFT CAB - VPS FRESH DEPLOYMENT      ║
╚════════════════════════════════════════╝

==> VPS IP: 5.249.164.40
==> Project Root: /tmp/Proyecto

Step 1: Updating system packages
✓ System updated

Step 2: Installing dependencies
✓ Docker installed and started

Step 3: Configuring environment
✓ Created .env from template
✓ Updated .env configuration

Step 4: Setting up log directory
✓ Log directory created

Step 5: Checking Node.js installation
✓ Node.js found: v18.x.x
✓ npm found: 9.x.x

╔════════════════════════════════════════╗
║ DEPLOYMENT COMPLETE                   ║
╚════════════════════════════════════════╝

=== Access Points ===
  Admin Dashboard:   http://5.249.164.40:3001
  Driver Dashboard:  http://5.249.164.40:3002
  Customer Portal:   http://5.249.164.40:3003
  API Server:        http://5.249.164.40:3000

=== Database Info ===
  PostgreSQL:  5.249.164.40:5432
  MongoDB:     5.249.164.40:27017
  Redis:       5.249.164.40:6379

Next steps:
  1. Start services: bash /tmp/Proyecto/scripts/1-main.sh
  2. Select 'Fresh Installation' from menu
  3. Wait for deployment to complete
```

## Next Steps After Deployment

Once the script completes:

1. **Start the menu system:**
   ```bash
   bash /tmp/Proyecto/scripts/1-main.sh
   ```

2. **Select option 1: Fresh Installation**
   - This will deploy all services
   - Configure databases
   - Start dashboard servers

3. **Monitor progress:**
   - Logs are in: `/tmp/Proyecto/logs/system.log`
   - Check Docker containers: `docker ps`

4. **Access dashboards:**
   - Admin: http://your-vps-ip:3001
   - Driver: http://your-vps-ip:3002
   - Customer: http://your-vps-ip:3003

## Troubleshooting

### If npm is still not found:
```bash
source ~/.nvm/nvm.sh
nvm install --latest-npm 18
```

### If Docker fails to start:
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### To view deployment logs:
```bash
tail -f /tmp/Proyecto/logs/system.log
```

### To see running services:
```bash
docker ps
ps aux | grep -E "node|npm|server"
```

## System Requirements

- Ubuntu 20.04 LTS or newer
- Minimum 2GB RAM
- 20GB disk space
- Ports available: 3000-3003, 5432, 27017, 6379

## Support

All deployment scripts are idempotent - you can run them multiple times safely.

If you encounter issues:
1. Check logs: `tail -f logs/system.log`
2. Verify Docker: `docker ps`
3. Check ports: `netstat -tulpn`
