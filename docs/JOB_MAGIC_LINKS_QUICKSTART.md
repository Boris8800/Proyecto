# Job Magic Links - Quick Start Guide

## What is This?

After a customer pays for a job, automatically generate and send a **magic link** to the driver. The driver clicks the link (no login needed), sees the pickup/dropoff on a map, accepts the job, and you track their location in real-time.

---

## Components Created

### 1. **Job Magic Links API Server** (Port 3334)
📁 File: `web/api/job-magic-links.js`

- Generates unique magic links for paid jobs
- Validates tokens when driver clicks link
- Stores job details and driver locations
- Provides real-time location tracking

### 2. **Driver Job Page** (Driver-friendly UI)
📁 File: `web/driver/job.html`

- **No login needed** - Magic link grants instant access
- Shows job number and details
- **Interactive map** (Leaflet.js) showing:
  - Pickup location (🟢 green marker)
  - Dropoff location (🔴 red marker)
  - Driver location (🔵 blue marker)
  - Route line between points
- Accept job button
- Complete job button
- Call dispatcher button
- **Auto-tracking** - Sends GPS every 30 seconds

### 3. **JavaScript Client Library**
📁 File: `web/api/job-magic-links-client.js`

Use in admin dashboard to:
- Create magic links for paid jobs
- Track driver location in real-time
- Get job details and status
- Start/stop tracking

### 4. **Database** (SQLite)
📁 File: `/root/job_magic_links.db`

Tables:
- `jobs` - Job details and magic links
- `job_sessions` - Active driver sessions
- `driver_locations` - GPS location history

### 5. **Service Management**
Updated: `scripts/main.sh`

- Starts/stops job magic links service
- Manages all services together
- View logs and status

---

## Quick Usage

### For Admin Dashboard - Create a Magic Link

```javascript
// Include client library
<script src="/api/job-magic-links-client.js"></script>

<script>
  const jobClient = new JobMagicLinksClient();

  // After payment is confirmed
  const link = await jobClient.createJobMagicLink({
    jobId: 'JOB-2025-001',
    driverEmail: 'john@driver.com',
    driverName: 'John Smith',
    driverPhone: '+1-555-1234',
    pickupAddress: '123 Main St, New York',
    pickupLat: 40.7128,
    pickupLng: -74.0060,
    dropoffAddress: '456 Park Ave, New York',
    dropoffLat: 40.7589,
    dropoffLng: -73.9851,
    jobTime: '2025-12-25T18:00:00Z',
    fare: 25.50,
    expiryHours: 24
  });

  // Send link to driver (via email/SMS)
  console.log('Link:', link.link);
  // http://localhost:3001/driver/job?token=abc123...
</script>
```

### For Admin Dashboard - Track Driver

```javascript
// Start tracking
jobClient.onLocationUpdate = (location) => {
  updateMapMarker(location.latitude, location.longitude);
};

jobClient.startTracking('JOB-2025-001', 5000); // Update every 5 sec

// Stop when done
jobClient.stopTracking();
```

### For Driver

1. Click the magic link in email
2. Page opens at `/driver/job?token=...`
3. See job details and map
4. Click "Accept Job"
5. GPS tracking starts automatically
6. Complete job when done

---

## Workflow

```
┌─────────────────────────────────────────────────────────┐
│                  CUSTOMER BOOKS JOB                     │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                CUSTOMER PAYS                            │
│         (Payment confirmed in admin)                    │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│         CREATE MAGIC LINK FOR DRIVER                    │
│  jobClient.createJobMagicLink({...})                    │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│         SEND LINK TO DRIVER (Email/SMS)                 │
│   http://localhost:3001/driver/job?token=abc123...     │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              DRIVER CLICKS LINK                         │
│        (Opens in browser, no login needed)              │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│            DRIVER SEES JOB DETAILS                      │
│  - Pickup location on map                              │
│  - Dropoff location on map                             │
│  - Job number and fare                                 │
│  - Scheduled time                                      │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│            DRIVER CLICKS "ACCEPT JOB"                   │
│    - Job status changes to 'accepted'                   │
│    - Location tracking starts                          │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│          DRIVER LOCATION TRACKED                        │
│  - GPS updates sent every 30 seconds                    │
│  - Admin/customer see driver on map                     │
│  - Location history stored in database                 │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│       DRIVER COMPLETES JOB                              │
│  Clicks "Complete Job" button                           │
│  - Job marked as completed                             │
│  - Tracking stops                                      │
│  - Payment finalized                                   │
└─────────────────────────────────────────────────────────┘
```

---

## Starting Services

### Using main.sh Script

```bash
cd /workspaces/Proyecto
./scripts/main.sh

# Select: 1) Fresh Installation
# OR: 3) Service Management > 1) Start All Services
```

All services start automatically:
- Magic Links API (port 3333)
- **Job Magic Links API (port 3334)** ✨ NEW
- Admin Dashboard (port 3001)
- Driver Portal (port 3002)
- Customer App (port 3003)

### Manual Start

```bash
cd /workspaces/Proyecto/web/api
node job-magic-links.js
```

Check if running:
```bash
curl http://localhost:3334/health
# {"status":"ok","service":"Job Magic Links Server"}
```

---

## API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/create-for-job` | Create magic link for a paid job |
| GET | `/validate/:token` | Validate link (driver clicks it) |
| POST | `/update-location/:jobId` | Driver sends GPS location |
| GET | `/driver-location/:jobId` | Admin gets driver location |
| GET | `/job/:jobId` | Get job details |
| POST | `/complete-job/:jobId` | Mark job as completed |
| GET | `/stats` | Get statistics |

---

## Map Features

The driver job page includes an interactive Leaflet map:

- **🟢 Green Marker** = Pickup location
- **🔴 Red Marker** = Dropoff location  
- **🔵 Blue Marker** = Driver's current location (updates in real-time)
- **Dashed Line** = Route between pickup and dropoff
- **Auto-pan** = Map centers on driver when location updates
- **Zoom Controls** = Driver can zoom/pan manually

---

## Database

### Location: `/root/job_magic_links.db`

### Tables:

**jobs** - One row per job
```
- job_id: JOB-2025-001
- driver_email: john@example.com
- pickup_address, pickup_lat, pickup_lng
- dropoff_address, dropoff_lat, dropoff_lng
- job_time: 2025-12-25T18:00:00Z
- fare: 25.50
- job_status: accepted/completed
- magic_token: a1b2c3d4...
- expires_at: 2025-12-25T14:58:05Z
```

**job_sessions** - One row per active session
```
- session_token: x9y8z7w6v5u4...
- job_id: JOB-2025-001
- driver_email: john@example.com
- created_at, expires_at (24 hours)
- last_activity (tracks driver activity)
```

**driver_locations** - Multiple rows per job (GPS history)
```
- job_id: JOB-2025-001
- driver_email: john@example.com
- latitude, longitude (GPS coordinates)
- accuracy, heading, speed (GPS details)
- created_at (timestamp of location)
```

---

## Real-Time Tracking

### How It Works:

1. **Driver accepts job** → Location tracking starts
2. **Every 30 seconds** → Driver's GPS sent to server
3. **Server stores** → Location saved in database
4. **Admin queries** → Gets latest driver location
5. **Admin map updates** → Shows driver position
6. **Job completed** → Tracking stops

### Accuracy:

- GPS accuracy: ±5-10 meters (typical smartphone)
- Update frequency: Every 30 seconds (configurable)
- Storage: Complete history in database for analytics
- Privacy: Data only stored while job is active

---

## Security

✅ **Token-Based**: Each job gets unique 32-char token
✅ **One-Time Use**: Token expires after first validation
✅ **Session Cookies**: HTTP-only, can't be stolen by JavaScript
✅ **Expiry**: Links expire in 24 hours (configurable)
✅ **No Password**: Driver doesn't need password
✅ **Rate Limited**: Prevents brute force attacks
✅ **HTTPS Ready**: Secure flag for production

---

## Troubleshooting

### Job link returns "Invalid token"
- Token expired? Create a new link
- Already used? Each link works once
- Solution: Increase `expiryHours` when creating

### Driver location not updating
- Check browser location permission
- Need HTTPS for geolocation
- Move outdoors for better GPS signal
- Check logs: `tail -f /tmp/job-magic-links.log`

### Port 3334 already in use
```bash
lsof -i :3334
kill -9 <PID>
```

### Database permission error
```bash
sudo chown $(whoami) /root/job_magic_links.db
chmod 666 /root/job_magic_links.db
```

---

## Configuration

### Environment Variables

```bash
# Change port
export JOB_MAGIC_PORT=3334

# Change database location
export JOB_DB=/path/to/db.sqlite

# Production mode
export NODE_ENV=production
```

### Customization

In `job-magic-links.js`:

```javascript
// Change token length
const TOKEN_LENGTH = 32;

// Change default expiry
const DEFAULT_EXPIRY_DAYS = 3;

// Change location update interval (driver page)
// In job.html, line ~370:
trackingInterval = setInterval(async () => {
  // Update every 30000ms = 30 seconds
}, 30000);
```

---

## Next Steps

1. ✅ **Integrate with payment system**
   - After payment confirmed, call `createJobMagicLink()`

2. ✅ **Send email to driver**
   - Use existing email service to send magic link

3. ✅ **Track on admin dashboard**
   - Call `jobClient.startTracking()` to show driver location

4. ✅ **Show completion status**
   - Query job status when driver completes

---

## Files Reference

```
web/
├── api/
│   ├── job-magic-links.js (NEW) - API server
│   └── job-magic-links-client.js (NEW) - Client lib
├── driver/
│   └── job.html (NEW) - Driver job page with map
└── ...

scripts/
└── main.sh (UPDATED) - Service management

docs/
├── JOB_MAGIC_LINKS_GUIDE.md (NEW) - Full docs
└── ... (other docs)

Root:
└── /root/job_magic_links.db (NEW) - SQLite database
```

---

## Support

For issues or questions, check:
- Full guide: `docs/JOB_MAGIC_LINKS_GUIDE.md`
- Logs: `tail -f /tmp/job-magic-links.log`
- API docs: POST `/health` for health check
- Database: `sqlite3 /root/job_magic_links.db`

---

**Status**: ✅ Complete and Ready to Use
**Version**: 1.0
**Date**: December 23, 2025
