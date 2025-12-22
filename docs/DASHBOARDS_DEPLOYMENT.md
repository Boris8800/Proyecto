# 🚕 Web Dashboards Deployment Guide

## Overview

The Taxi System includes three modern, fully-functional web dashboards:
- **Admin Dashboard** (Port 3001) - System management and monitoring
- **Driver Portal** (Port 3002) - Driver earnings and ride management
- **Customer App** (Port 3003) - Customer booking interface

## Architecture

### Technology Stack
- **Framework**: Node.js / Express.js
- **Frontend**: Modern HTML5 + CSS3 with responsive design
- **Authentication**: Magic Links system (built-in)
- **API**: RESTful API endpoints
- **Features**: Real-time updates, CORS-enabled, SPA routing

### Server Files
```
/home/taxi/web/
├── server-admin.js          # Admin dashboard server (port 3001)
├── server-driver.js         # Driver portal server (port 3002)
├── server-customer.js       # Customer app server (port 3003)
├── admin/                   # Admin dashboard files
├── driver/                  # Driver portal files
└── customer/                # Customer app files
```

## Deployment Steps

### 1. Prerequisites

Ensure Node.js and npm are installed on the VPS:

```bash
# Check versions
node --version     # Should be v14 or higher
npm --version      # Should be v6 or higher

# If not installed, install Node.js:
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 2. Install Dependencies

```bash
cd /home/taxi
npm install

# Expected output:
# added 50 packages in 5s
# 25 packages are looking for funding
```

### 3. Start the Servers

#### Option A: Using the management script

```bash
# Make script executable
chmod +x /home/taxi/manage-dashboards.sh

# Start all three servers
./manage-dashboards.sh start

# Check status
./manage-dashboards.sh status

# View logs
./manage-dashboards.sh logs admin
./manage-dashboards.sh logs driver
./manage-dashboards.sh logs customer
```

#### Option B: Manual startup

```bash
# Start each server in separate terminals
cd /home/taxi

# Terminal 1 - Admin Dashboard
node web/server-admin.js

# Terminal 2 - Driver Portal
node web/server-driver.js

# Terminal 3 - Customer App
node web/server-customer.js
```

#### Option C: Using background processes with nohup

```bash
cd /home/taxi

nohup node web/server-admin.js > /var/log/taxi-admin.log 2>&1 &
nohup node web/server-driver.js > /var/log/taxi-driver.log 2>&1 &
nohup node web/server-customer.js > /var/log/taxi-customer.log 2>&1 &

# Get the process IDs
jobs -l
```

#### Option D: Using systemd services (Recommended for production)

Create `/etc/systemd/system/taxi-admin.service`:
```ini
[Unit]
Description=Taxi Admin Dashboard Server
After=network.target

[Service]
Type=simple
User=taxi
WorkingDirectory=/home/taxi
ExecStart=/usr/bin/node /home/taxi/web/server-admin.js
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/taxi-admin.log
StandardError=append:/var/log/taxi-admin.log

[Install]
WantedBy=multi-user.target
```

Create `/etc/systemd/system/taxi-driver.service`:
```ini
[Unit]
Description=Taxi Driver Portal Server
After=network.target

[Service]
Type=simple
User=taxi
WorkingDirectory=/home/taxi
ExecStart=/usr/bin/node /home/taxi/web/server-driver.js
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/taxi-driver.log
StandardError=append:/var/log/taxi-driver.log

[Install]
WantedBy=multi-user.target
```

Create `/etc/systemd/system/taxi-customer.service`:
```ini
[Unit]
Description=Taxi Customer App Server
After=network.target

[Service]
Type=simple
User=taxi
WorkingDirectory=/home/taxi
ExecStart=/usr/bin/node /home/taxi/web/server-customer.js
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/taxi-customer.log
StandardError=append:/var/log/taxi-customer.log

[Install]
WantedBy=multi-user.target
```

Enable and start the services:
```bash
# Reload systemd daemon
sudo systemctl daemon-reload

# Enable services (auto-start on boot)
sudo systemctl enable taxi-admin.service
sudo systemctl enable taxi-driver.service
sudo systemctl enable taxi-customer.service

# Start services
sudo systemctl start taxi-admin.service
sudo systemctl start taxi-driver.service
sudo systemctl start taxi-customer.service

# Check status
sudo systemctl status taxi-admin.service
sudo systemctl status taxi-driver.service
sudo systemctl status taxi-customer.service

# View logs
sudo journalctl -u taxi-admin.service -f
```

### 4. Verify Servers are Running

```bash
# Check if ports are listening
netstat -tlnp | grep -E ':(3001|3002|3003)'

# Test with curl
curl -I http://localhost:3001    # Admin
curl -I http://localhost:3002    # Driver
curl -I http://localhost:3003    # Customer

# Expected response: HTTP/1.1 200 OK
```

### 5. Access the Dashboards

Once servers are running, access them from your browser:

- **Admin Dashboard**: `http://5.249.164.40:3001`
- **Driver Portal**: `http://5.249.164.40:3002`
- **Customer App**: `http://5.249.164.40:3003`

Or from within the VPS:
- **Admin Dashboard**: `http://localhost:3001`
- **Driver Portal**: `http://localhost:3002`
- **Customer App**: `http://localhost:3003`

## Features

### Admin Dashboard
- Real-time system monitoring
- Active drivers and rides tracking
- Revenue analytics
- Service area management
- System health status
- Driver management tools

### Driver Portal
- Earnings tracking
- Completed rides history
- Performance metrics
- Rating display
- Message notifications
- Application status

### Customer App
- One-tap ride booking
- Ride history
- Promotions and discounts
- Reward points tracking
- 24/7 support access
- Feature highlights

## Management Commands

### Using the Management Script

```bash
# Start all servers
./manage-dashboards.sh start

# Stop all servers
./manage-dashboards.sh stop

# Restart all servers
./manage-dashboards.sh restart

# Check status
./manage-dashboards.sh status

# View logs
./manage-dashboards.sh logs admin     # Admin logs
./manage-dashboards.sh logs driver    # Driver logs
./manage-dashboards.sh logs customer  # Customer logs
./manage-dashboards.sh logs all       # All logs

# Install dependencies
./manage-dashboards.sh install
```

### Manual Server Management

```bash
# Find running Node.js processes
ps aux | grep node

# Kill a specific server
kill -9 <PID>

# Kill all Node.js servers
pkill -f "node web/server-"

# Monitor resource usage
top

# Check port usage
lsof -i :3001    # Check port 3001
netstat -tlnp | grep 3001
```

## Troubleshooting

### Port Already in Use
```bash
# Find what's using the port
lsof -i :3001

# Kill the process
kill -9 <PID>

# Or change the port in the server file
nano web/server-admin.js  # Change const PORT = 3001;
```

### Node.js Not Found
```bash
# Check if Node.js is installed
which node

# Install Node.js if needed
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Module Not Found Error
```bash
# Reinstall dependencies
cd /home/taxi
npm install

# Clear npm cache
npm cache clean --force
npm install
```

### Server Crashes
```bash
# Check logs for errors
tail -f /var/log/taxi-admin.log

# Monitor with the management script
./manage-dashboards.sh logs admin

# Or use systemd logs
journalctl -u taxi-admin.service -n 50
```

### Slow Performance
```bash
# Check system resources
free -h      # Memory usage
df -h        # Disk usage
top          # Process usage

# Check network
netstat -s   # Network statistics
```

## Production Considerations

### Security
- Configure firewall rules to restrict access
- Use Nginx as reverse proxy with SSL
- Enable rate limiting
- Implement authentication tokens
- Use HTTPS instead of HTTP

### Performance
- Use Nginx for load balancing
- Enable gzip compression
- Cache static assets
- Use CDN for static files
- Monitor response times

### Monitoring
- Set up automated logs
- Alert on server crashes
- Monitor resource usage
- Track API performance
- Use application monitoring tools

### Backup
- Regular database backups
- Configuration file backups
- Code repository backups
- SSL certificate backups

## Environment Variables

Create `/home/taxi/.env` to configure servers:

```env
# Server Configuration
ADMIN_PORT=3001
DRIVER_PORT=3002
CUSTOMER_PORT=3003
NODE_ENV=production

# API Configuration
API_URL=http://localhost:3000
API_TIMEOUT=5000

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=taxi_db
DB_USER=taxi
DB_PASSWORD=your_password

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# Authentication
JWT_SECRET=your_secret_key
SESSION_SECRET=your_session_secret
```

## API Endpoints

Each server exposes the following endpoints:

```bash
# Health check (all servers)
GET /api/health
Response: { "status": "ok", "service": "admin/driver/customer", "timestamp": "2025-..." }

# Admin Dashboard
GET /                          # Admin dashboard HTML
GET /api/admin/stats          # Admin statistics
GET /api/admin/drivers        # List drivers
GET /api/admin/rides          # Ride history

# Driver Portal
GET /                          # Driver portal HTML
GET /api/driver/earnings      # Earnings data
GET /api/driver/rides         # Ride history
GET /api/driver/ratings       # Driver ratings

# Customer App
GET /                          # Customer app HTML
POST /api/customer/book       # Book a ride
GET /api/customer/rides       # Ride history
POST /api/customer/rate       # Rate a ride
```

## Frequently Asked Questions

**Q: Can I change the ports?**
A: Yes, edit the PORT variable in each server file (e.g., `const PORT = 3001;`)

**Q: How do I enable HTTPS?**
A: Use Nginx as reverse proxy with SSL certificates, or add `https` module to servers

**Q: Can I run all servers in one process?**
A: Yes, create a main server file that imports all three

**Q: What's the recommended Node.js version?**
A: Node.js 14+ (18+ recommended for security)

**Q: How do I integrate with the API?**
A: The dashboards support REST API calls via CORS-enabled Express servers

**Q: Can I customize the UI?**
A: Yes, edit the HTML files in `web/admin/`, `web/driver/`, `web/customer/`

## Contact & Support

For issues or questions about the Taxi System:
- Check logs: `./manage-dashboards.sh logs all`
- Review documentation in `/home/taxi/`
- Contact the development team

---

**Last Updated**: January 2025
**Version**: 1.0.0
