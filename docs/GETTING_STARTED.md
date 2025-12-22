# 🚕 GETTING STARTED - Web Dashboards

## 5-Minute Quick Start

### Step 1: Install Dependencies
```bash
cd /workspaces/Proyecto
npm install
```

### Step 2: Start the Dashboards
Choose ONE method:

#### Method A: Interactive Setup (Recommended)
```bash
chmod +x start-dashboards.sh
./start-dashboards.sh
```
This will:
- Check Node.js
- Install dependencies
- Start all 3 servers
- Show access URLs

#### Method B: Using Management Script
```bash
chmod +x manage-dashboards.sh
./manage-dashboards.sh start
```

#### Method C: Individual Servers
```bash
# Terminal 1
node web/server-admin.js

# Terminal 2
node web/server-driver.js

# Terminal 3
node web/server-customer.js
```

### Step 3: Access the Dashboards

**In Your Browser:**
- 🟣 Admin Dashboard: http://localhost:3001
- 🔴 Driver Portal: http://localhost:3002
- 🔵 Customer App: http://localhost:3003

**Or Test via Command Line:**
```bash
curl http://localhost:3001/api/health
curl http://localhost:3002/api/health
curl http://localhost:3003/api/health
```

## What You'll See

### Admin Dashboard 🟣
- System monitoring with 6 KPI cards
- Status indicators
- Management controls
- Professional purple theme

### Driver Portal 🔴
- Earnings tracking
- Performance metrics
- Rating and acceptance rates
- Professional pink/red theme

### Customer App 🔵
- Ride booking interface
- Feature highlights
- Service benefits
- Professional blue theme

## Management Commands

```bash
# Check if servers are running
./manage-dashboards.sh status

# Stop all servers
./manage-dashboards.sh stop

# Restart all servers
./manage-dashboards.sh restart

# View logs
./manage-dashboards.sh logs admin
./manage-dashboards.sh logs driver
./manage-dashboards.sh logs customer
```

## Deploying to VPS (5.249.164.40)

```bash
# SSH to VPS
ssh root@5.249.164.40

# Go to taxi directory
cd /home/taxi

# Install dependencies
npm install

# Start servers
./manage-dashboards.sh start

# Check status
./manage-dashboards.sh status
```

Then access from browser:
- Admin: http://5.249.164.40:3001
- Driver: http://5.249.164.40:3002
- Customer: http://5.249.164.40:3003

## Documentation

- **Quick Start**: This file
- **Full Deployment**: DASHBOARDS_DEPLOYMENT.md
- **Testing Guide**: DASHBOARDS_TESTING.md
- **Complete Overview**: DASHBOARDS_COMPLETE.md
- **Summary**: DASHBOARDS_SUMMARY.txt

## Troubleshooting

**Port already in use?**
```bash
lsof -i :3001
kill -9 <PID>
```

**Node.js not found?**
```bash
node --version
# Install if needed:
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Dependencies missing?**
```bash
npm install
npm cache clean --force
```

## Status Check

All systems ready when you see:
```
✓ Admin Dashboard (Port 3001) - Running & Responding
✓ Driver Portal (Port 3002) - Running & Responding
✓ Customer App (Port 3003) - Running & Responding
```

## Next Steps

1. ✅ Get dashboards running locally
2. ✅ Test in browser
3. ✅ Deploy to VPS
4. ✅ Configure for production
5. ✅ Setup SSL/TLS
6. ✅ Integrate APIs

---

**Everything Ready!** 🚀

Start with: `./start-dashboards.sh`

---
