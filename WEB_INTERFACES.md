# Taxi System Web Interfaces

## Overview
The Taxi System has **3 modern web interfaces** running on Node.js Express servers with complete HTML/CSS/JavaScript frontends.

## Interfaces

### 1. **Admin Dashboard** (Port 3001)
- **Location**: `/web/admin/index.html`
- **Server**: `server-admin.js`
- **URL**: `http://5.249.164.40:3001`
- **Features**:
  - User management
  - Ride statistics and analytics
  - Driver/Customer monitoring
  - System settings
  - Revenue reports

### 2. **Driver Portal** (Port 3002)
- **Location**: `/web/driver/index.html`
- **Server**: `server-driver.js`
- **URL**: `http://5.249.164.40:3002`
- **Features**:
  - Accept/reject ride requests
  - Real-time ride tracking
  - Driver earnings
  - Customer ratings
  - Trip history

### 3. **Customer App** (Port 3003)
- **Location**: `/web/customer/index.html`
- **Server**: `server-customer.js`
- **URL**: `http://5.249.164.40:3003`
- **Features**:
  - Book a ride
  - Track driver location
  - Payment methods
  - Ride history
  - Rate drivers and trips

## Supporting Interfaces

### Authentication Portal (Port 80)
- **Location**: `/web/auth/index.html`
- **Features**: User login/registration with magic links system

### System Status Page
- **Location**: `/web/status/index.html`
- **Features**: System health monitoring, service status

## Architecture

```
web/
├── server-admin.js       (Port 3001)
├── server-driver.js      (Port 3002)
├── server-customer.js    (Port 3003)
├── admin/
│   ├── index.html        (733 lines - full dashboard UI)
│   ├── css/
│   │   └── style.css
│   └── js/
│       ├── main.js
│       └── magic-links-client.js
├── driver/
│   ├── index.html        (756 lines - full driver portal UI)
│   ├── css/
│   │   └── style.css
│   └── js/
│       ├── main.js
│       └── magic-links-client.js
├── customer/
│   ├── index.html        (785 lines - full booking app UI)
│   ├── css/
│   │   ├── style.css
│   │   └── booking.css
│   └── js/
│       ├── main.js
│       ├── booking.js
│       └── magic-links-client.js
├── auth/
│   └── index.html        (Authentication portal)
├── api/
│   └── magic-links-server.js (Magic links API)
├── js/
│   └── magic-links-client.js (Shared auth client)
├── status/
│   ├── index.html
│   └── server.js
└── logs/
    ├── admin.log
    ├── driver.log
    └── customer.log
```

## Running Interfaces

### Manual Start
```bash
cd /root/Proyecto/web

# Start individual servers
node server-admin.js
node server-driver.js
node server-customer.js
```

### Automated Start (via fresh installation)
All servers are started automatically during fresh installation as the `taxi` user.

### View Logs
```bash
tail -f /root/Proyecto/logs/admin.log
tail -f /root/Proyecto/logs/driver.log
tail -f /root/Proyecto/logs/customer.log
```

### Stop Services
```bash
pkill -f "server-admin.js"
pkill -f "server-driver.js"
pkill -f "server-customer.js"
```

## Features

### Common Features (All Interfaces)
- ✅ Responsive design
- ✅ Modern UI with gradient backgrounds
- ✅ Font Awesome icons
- ✅ Real-time status updates
- ✅ Magic links authentication
- ✅ Mobile-friendly layout

### Admin Features
- 📊 Analytics dashboard
- 👥 User management
- 💰 Payment tracking
- 📈 Revenue reports
- 🚗 Fleet management

### Driver Features
- 📍 Real-time tracking
- 📲 Ride notifications
- 💵 Earnings dashboard
- ⭐ Customer ratings
- 📋 Trip history

### Customer Features
- 🚖 Quick booking
- 📍 Live tracking
- 💳 Multiple payment options
- ⭐ Rate & review
- 📱 Mobile responsive

## Technology Stack

- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **Backend**: Node.js with Express.js
- **Authentication**: Magic Links system
- **API Communication**: RESTful with CORS enabled
- **Styling**: Custom CSS with CSS variables for theming

## Accessing the Services

After fresh installation completes, all interfaces are running as the `taxi` user on ports:
- **3001**: Admin Dashboard
- **3002**: Driver Portal  
- **3003**: Customer App

Access from browser:
- `http://5.249.164.40:3001` - Admin
- `http://5.249.164.40:3002` - Driver
- `http://5.249.164.40:3003` - Customer

## Troubleshooting

### Interfaces not loading?
1. Check if servers are running: `lsof -ti:3001,3002,3003`
2. Check logs: `tail -f logs/*.log`
3. Verify permissions: `ls -la /root/Proyecto/web`
4. Restart servers: `pkill -f server-*.js && npm start`

### Permission issues?
- Ensure taxi user owns the web directory: `sudo chown -R taxi:taxi /root/Proyecto/web`
- Verify logs directory is writable: `sudo chmod 755 /root/Proyecto/logs`

