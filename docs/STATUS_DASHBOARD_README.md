# Status Dashboard - Operations & Configuration Center

## Overview

The Swift Cab Status Dashboard is the central hub for system monitoring, email configuration, and external API management. It provides a user-friendly interface for managing all production systems.

## Access

```
http://YOUR_VPS_IP:8080
```

**Default Port:** 8080  
**VPS IP:** 5.249.164.40 (configurable)

## Features

### 1. Status Tab
- **System Health Monitoring**
  - Real-time uptime tracking
  - Memory usage statistics
  - CPU core count
  - Platform and architecture info
  
- **Service Status**
  - All services listed with port numbers
  - Running/offline status indicators
  - Quick service overview

### 2. Email Configuration Tab
- **Multi-Provider Support**
  - SMTP (Gmail, Outlook, Custom)
  - SendGrid
  - Mailgun

- **Configuration Management**
  - Save configurations securely
  - Reload current settings
  - Test email functionality
  - Detailed provider setup guides

- **Test Features**
  - Send test emails
  - Verify credentials
  - Check email delivery

### 3. Services & APIs Tab
- **Maps Service**
  - Provider selection (Google, OpenStreetMap, Mapbox)
  - API key management
  - Route calculation testing
  - Enable/disable toggle

- **Payment Service**
  - Provider selection (Stripe, PayPal, Square)
  - API key configuration
  - Service enable/disable
  
- **SMS/Notification Service**
  - Provider options (Twilio, Nexmo, AWS SNS)
  - Configuration storage
  - Future integration ready

## Running the Dashboard

### Start Manually
```bash
cd /workspaces/Proyecto
node web/status/server.js
```

### With PM2 (Recommended)
```bash
pm2 start web/status/server.js --name "status-dashboard"
pm2 save
pm2 startup
```

### Check Status
```bash
pm2 status
pm2 logs status-dashboard
```

## API Endpoints

All endpoints are RESTful JSON APIs available on port 8080.

### Health & Status
- `GET /api/health` - System health info
- `GET /api/services` - Service port list
- `GET /api/containers` - Docker containers status

### Email
- `GET /api/email/config` - Get email configuration
- `POST /api/email/config` - Update email settings
- `POST /api/email/test` - Send test email

### Services
- `GET /api/services/config` - Get services configuration
- `POST /api/services/config` - Update services
- `POST /api/maps/test` - Test route calculation

## Configuration File

Location: `/config/email-config.json`

```json
{
  "email": {
    "provider": "smtp",
    "smtp": { ... },
    "sendgrid": { ... },
    "mailgun": { ... }
  },
  "services": {
    "maps": { ... },
    "payment": { ... },
    "sms": { ... }
  }
}
```

**Important:** This file contains sensitive API keys. Add to `.gitignore` and never commit to version control.

## Email Provider Setup

### SMTP (Gmail)
1. Enable 2-factor authentication on Gmail
2. Go to https://myaccount.google.com/apppasswords
3. Generate password for "Mail" app
4. Copy the 16-character password
5. In Status Dashboard:
   - Select SMTP provider
   - Host: `smtp.gmail.com`
   - Port: `587`
   - TLS/SSL: No
   - Email: Your Gmail address
   - Password: Your app password
6. Click Save & Test

### SMTP (Outlook/Office 365)
- Host: `smtp.office365.com`
- Port: `587`
- Security: TLS
- Email: Your Outlook email
- Password: Your Outlook password

### SendGrid
1. Create SendGrid account
2. Generate API key
3. In Status Dashboard:
   - Select SendGrid provider
   - API Key: Your SendGrid key
   - From Email: Your company email
   - From Name: Your company name
4. Click Save & Test

### Mailgun
1. Create Mailgun account
2. Configure domain
3. In Status Dashboard:
   - Select Mailgun provider
   - API Key: Your Mailgun API key
   - Domain: Your Mailgun domain
   - From Email: Your company email
4. Click Save & Test

## Maps Service Setup

### Google Maps
1. Get API key from Google Cloud Console
2. Enable Maps APIs:
   - Directions API
   - Distance Matrix API
   - Maps JavaScript API
3. In Status Dashboard:
   - Select Google provider
   - Enter API key
   - Click "Enable Maps Service"
   - Test with "Calculate Route" button

### Mapbox
1. Create Mapbox account
2. Get access token
3. In Status Dashboard:
   - Select Mapbox provider
   - Enter access token
   - Enable service
   - Test route calculation

## Monitoring & Logging

### Dashboard Logs
```bash
pm2 logs status-dashboard
```

### Check Email Status
```bash
tail -f logs/email.log
```

### Monitor Email Sent
```javascript
// In logs, look for:
[EMAIL] Email sent to user@example.com: <message-id>
```

## Troubleshooting

### Dashboard Not Responding
```bash
# Check if running
pm2 status

# Restart
pm2 restart status-dashboard

# View error logs
pm2 logs status-dashboard --lines 100
```

### Email Not Sending
1. Verify credentials in configuration
2. Test with "Send Test Email"
3. Check server logs
4. For Gmail: Verify app-specific password
5. For SendGrid/Mailgun: Verify API key

### Configuration Not Saving
1. Check `/config` directory exists
2. Verify write permissions:
   ```bash
   ls -la /config/
   chmod 755 /config
   chmod 644 /config/email-config.json
   ```
3. Restart dashboard

### Maps Test Failing
1. Verify API key is correct
2. Check Maps service is enabled
3. Ensure API key has required permissions
4. Check request parameters (origin/destination)

## Security Best Practices

⚠️ **IMPORTANT:**

1. **Never commit `email-config.json`**
   ```bash
   # Add to .gitignore
   echo "config/email-config.json" >> .gitignore
   ```

2. **Use strong API keys**
   - Don't use weak or default credentials
   - Rotate keys regularly

3. **Limit dashboard access**
   ```nginx
   # In Nginx config
   location /api {
       allow 192.168.1.0/24;
       deny all;
   }
   ```

4. **Use HTTPS only**
   - Dashboard should run behind Nginx with SSL
   - Enable HSTS headers

5. **Monitor access logs**
   ```bash
   tail -f /var/log/nginx/access.log | grep "/api/"
   ```

## Environment Variables

Set these in production environment:

```bash
# Dashboard port
export STATUS_PORT=8080

# VPS IP for URLs
export VPS_IP=5.249.164.40

# Email defaults
export EMAIL_PROVIDER=smtp
export EMAIL_HOST=smtp.gmail.com
export EMAIL_PORT=587
export EMAIL_USER=your-email@gmail.com
```

## Docker Integration

If using Docker:

```bash
# Build image
docker build -t swift-cab-dashboard .

# Run container
docker run -d \
  --name status-dashboard \
  -p 8080:8080 \
  -v /path/to/config:/app/config \
  -e STATUS_PORT=8080 \
  swift-cab-dashboard

# Check logs
docker logs status-dashboard
```

## Integration with Web Servers

### Send Email from API Server
```javascript
const EmailService = require('./api/email-service.js');
const config = require('../config/email-config.json');
const emailService = new EmailService(config);

// Send email on booking
await emailService.sendBookingConfirmation(userEmail, bookingDetails);
```

### Get Maps Configuration
```javascript
const mapsConfig = await fetch('http://localhost:8080/api/services/config')
    .then(r => r.json());

if (mapsConfig.maps.enabled) {
    initializeMaps(mapsConfig.maps.apiKey);
}
```

## Performance Tips

1. **Cache configuration** locally to reduce API calls
2. **Use webhooks** for email status updates
3. **Implement retry logic** for failed emails
4. **Monitor memory usage** - check `/api/health`
5. **Set up alerts** for service failures

## Backup & Recovery

### Backup Configuration
```bash
cp /config/email-config.json /config/email-config.json.backup
cp /config/email-config.json /backups/email-config-$(date +%s).json
```

### Restore Configuration
```bash
cp /config/email-config.json.backup /config/email-config.json
pm2 restart status-dashboard
```

## Support & Documentation

- **Email Guide:** [EMAIL_SERVER_GUIDE.md](./EMAIL_SERVER_GUIDE.md)
- **API Reference:** [EMAIL_API_REFERENCE.md](./EMAIL_API_REFERENCE.md)
- **Full API Guide:** [API_INTEGRATION_GUIDE.md](./API_INTEGRATION_GUIDE.md)
- **Setup Script:** `scripts/setup-email.sh`

## Development

### Local Development
```bash
# Start dashboard in dev mode
node web/status/server.js

# With auto-reload
npx nodemon web/status/server.js
```

### Testing APIs
```bash
# Test health endpoint
curl http://localhost:8080/api/health

# Test email config
curl http://localhost:8080/api/email/config

# Send test email
curl -X POST http://localhost:8080/api/email/test \
  -H "Content-Type: application/json" \
  -d '{"to":"test@example.com","subject":"Test","message":"Hello"}'
```

## Future Enhancements

- [ ] Email template builder
- [ ] Email sending analytics
- [ ] Webhook support
- [ ] SMS integration
- [ ] Advanced rate limiting dashboard
- [ ] Email bounce handling
- [ ] Multi-tenant support
- [ ] SSO/OAuth integration

## Version History

- **v1.0.0** (Dec 22, 2025)
  - Initial release with email & services configuration
  - Status monitoring dashboard
  - Multi-provider email support
  - API configuration interface

---

**Last Updated:** December 22, 2025  
**Swift Cab Status Dashboard**
