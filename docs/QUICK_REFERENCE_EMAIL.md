# Swift Cab Email Server - Quick Reference Card

## 🚀 Quick Start (2 minutes)

```bash
# 1. Install dependencies
cd /workspaces/Proyecto
npm install nodemailer

# 2. Start dashboard
node web/status/server.js

# 3. Access dashboard
# Open browser: http://5.249.164.40:8080
```

## 📧 Email Configuration

### Gmail SMTP
```
Host: smtp.gmail.com
Port: 587
Security: No (TLS)
Email: your@gmail.com
Password: 16-char app password (from myaccount.google.com/apppasswords)
```

### SendGrid
```
API Key: SG.xxxxx
From Email: noreply@swiftcab.com
From Name: Swift Cab
```

### Mailgun
```
Domain: mg.swiftcab.com
API Key: key-xxxxx
From Email: noreply@swiftcab.com
```

## 🔌 API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/health` | GET | System health |
| `/api/services` | GET | Service list |
| `/api/email/config` | GET/POST | Email settings |
| `/api/email/test` | POST | Send test email |
| `/api/services/config` | GET/POST | API settings |
| `/api/maps/test` | POST | Test route |

## 📨 Email Methods

```javascript
const emailService = new EmailService(config);

// Welcome
await emailService.sendWelcomeEmail(email, name);

// Booking
await emailService.sendBookingConfirmation(email, details);

// Password reset
await emailService.sendPasswordReset(email, link, name);

// OTP
await emailService.sendOTPEmail(email, otp, name);

// Trip done
await emailService.sendTripCompletedEmail(email, details);

// Custom
await emailService.send({ to, subject, html });
```

## 🎛️ Dashboard Tabs

1. **Status** - System monitoring
2. **Email Configuration** - Setup email providers
3. **Services & APIs** - Configure Maps, Payment, SMS

## 📁 Key Files

```
/config/email-config.json ........... Configuration (keep secret!)
/web/status/server.js ............... Dashboard server
/web/status/index.html .............. Dashboard UI
/web/api/email-service.js ........... Email class
/docs/EMAIL_SERVER_GUIDE.md ......... Full guide
/scripts/setup-email.sh ............. Setup script
```

## 🔐 Security Checklist

- [ ] Add `/config/email-config.json` to `.gitignore`
- [ ] Use app-specific passwords for Gmail
- [ ] Rotate API keys regularly
- [ ] Restrict dashboard access by IP
- [ ] Use HTTPS in production
- [ ] Monitor email logs

## ⚙️ PM2 Setup

```bash
# Start
pm2 start web/status/server.js --name "status-dashboard"

# Save
pm2 save

# Logs
pm2 logs status-dashboard

# Restart
pm2 restart status-dashboard
```

## 🧪 Testing

```bash
# Test health
curl http://localhost:8080/api/health

# Test email config
curl http://localhost:8080/api/email/config

# Send test email
curl -X POST http://localhost:8080/api/email/test \
  -H "Content-Type: application/json" \
  -d '{
    "to":"test@example.com",
    "subject":"Test",
    "message":"Hello"
  }'
```

## 🐛 Troubleshooting

**Email not sending?**
- Check credentials in dashboard
- Gmail: Verify app password (2FA required)
- SendGrid: Verify API key starts with "SG."
- Check firewall allows port 587 (SMTP)

**Dashboard not loading?**
- Check port 8080 is available
- Verify nodemailer installed: `npm list nodemailer`
- Restart: `pm2 restart status-dashboard`

**Config not saving?**
- Check permissions: `chmod 755 /config`
- Check disk space: `df -h`
- Verify directory exists: `ls -la /config/`

## 📚 Documentation

| File | Purpose |
|------|---------|
| EMAIL_SERVER_GUIDE.md | Complete setup guide |
| EMAIL_API_REFERENCE.md | API examples |
| STATUS_DASHBOARD_README.md | Operations manual |
| EMAIL_IMPLEMENTATION_SUMMARY.md | What was built |

## 🔗 Integration Example

```javascript
const express = require('express');
const EmailService = require('./api/email-service.js');
const config = require('../config/email-config.json');

const app = express();
const emailService = new EmailService(config);

// Send email on booking
app.post('/api/bookings', async (req, res) => {
    const booking = await createBooking(req.body);
    await emailService.sendBookingConfirmation(booking.userEmail, {
        bookingId: booking.id,
        pickupLocation: booking.pickup,
        destination: booking.destination,
        estimatedFare: booking.fare,
        driverName: booking.driver.name
    });
    res.json({ success: true });
});

app.listen(3000);
```

## 📊 System Requirements

- **Node.js** 14.0+
- **Port 8080** available
- **Disk Space** for logs
- **Internet** for external APIs
- **Email Account** (Gmail/SendGrid/Mailgun)

## 🎯 Email Templates Included

- ✅ Welcome Email
- ✅ Booking Confirmation
- ✅ Password Reset
- ✅ OTP Verification
- ✅ Trip Completion
- ✅ Admin Notification
- ✅ Custom Email

## 🚀 Production Checklist

- [ ] Configure email provider
- [ ] Test email sending
- [ ] Setup PM2 for auto-restart
- [ ] Configure Nginx reverse proxy
- [ ] Enable HTTPS/SSL
- [ ] Setup monitoring
- [ ] Configure backups
- [ ] Document procedures
- [ ] Train team
- [ ] Monitor logs

## 📞 Support Commands

```bash
# View logs
pm2 logs status-dashboard

# Full status
pm2 show status-dashboard

# CPU/Memory usage
pm2 monit

# Restart
pm2 restart status-dashboard

# Stop
pm2 stop status-dashboard

# Start
pm2 start web/status/server.js --name "status-dashboard"
```

## 🔄 Configuration Backup

```bash
# Backup
cp /config/email-config.json /config/email-config.backup

# Restore
cp /config/email-config.backup /config/email-config.json
pm2 restart status-dashboard
```

## 🌐 Environment Variables

```bash
export STATUS_PORT=8080
export VPS_IP=5.249.164.40
export NODE_ENV=production
```

## 📦 Dependencies

```json
{
  "express": "^4.18.2",
  "nodemailer": "^6.9.7",
  "cors": "^2.8.5"
}
```

---

**Quick Reference Card**  
**Swift Cab Email Server v1.0.0**  
**December 22, 2025**

For detailed documentation, see docs/ folder.  
Access Dashboard: http://YOUR_VPS_IP:8080
