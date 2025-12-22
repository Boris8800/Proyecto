# Email Server & Configuration Guide

## Overview

The Swift Cab system now includes a comprehensive email server with support for multiple email providers and API configuration management through the Status Dashboard.

## Features

✅ **Email Providers**
- SMTP (Gmail, Outlook, Custom)
- SendGrid
- Mailgun

✅ **Pre-built Email Templates**
- Welcome email
- Booking confirmation
- Password reset
- OTP verification
- Trip completion
- Admin notifications

✅ **API Configuration Dashboard**
- Email provider selection and setup
- Maps service configuration
- Payment service configuration
- SMS service configuration
- Test email sending
- Route calculation testing

✅ **Configuration Management**
- Secure configuration storage
- API key management
- Enable/disable services
- Per-provider settings

## Quick Start

### 1. Access Status Dashboard

```
http://YOUR_VPS_IP:8080
```

### 2. Configure Email Provider

#### SMTP (Gmail Example)

1. Go to **Email Configuration** tab
2. Select **SMTP** provider
3. Enter these settings:
   - **Host:** smtp.gmail.com
   - **Port:** 587
   - **TLS/SSL:** No (TLS on port 587)
   - **Email:** your-email@gmail.com
   - **Password:** Your app-specific password (not regular password)
   - **From Email:** noreply@swiftcab.com
   - **Reply-To:** support@swiftcab.com

**Getting Gmail App Password:**
1. Go to https://myaccount.google.com/security
2. Enable 2-factor authentication
3. Go to App passwords
4. Generate password for "Mail" and "Windows Computer"
5. Use this 16-character password

4. Click **Save Configuration**
5. Click **Send Test Email** to verify

#### SendGrid

1. Get API key from SendGrid dashboard
2. Select **SendGrid** provider
3. Enter:
   - **API Key:** Your SendGrid API key (starts with SG.)
   - **From Email:** noreply@swiftcab.com
   - **From Name:** Swift Cab
4. Click **Save Configuration**

#### Mailgun

1. Get API key from Mailgun dashboard
2. Select **Mailgun** provider
3. Enter:
   - **Domain:** mg.yourdomain.com
   - **API Key:** Your Mailgun API key
   - **From Email:** noreply@yourdomain.com
4. Click **Save Configuration**

### 3. Test Email

1. Go to **Email Configuration** → **Test Email**
2. Enter:
   - **Recipient:** test@example.com
   - **Subject:** Test Email
   - **Message:** Test message
3. Click **Send Test Email**
4. Check your inbox for the test email

## API Endpoints

### Email Configuration

**GET /api/email/config**
- Returns current email configuration (safe data only)

**POST /api/email/config**
- Update email configuration
- Body: `{ smtp: {...} }` or `{ sendgrid: {...} }` or `{ mailgun: {...} }`

**POST /api/email/test**
- Send test email
- Body: `{ to, subject, message }`

### Services Configuration

**GET /api/services/config**
- Returns all services configuration

**POST /api/services/config**
- Update services configuration
- Body: `{ maps: {...} }` or `{ payment: {...} }`

**POST /api/maps/test**
- Test maps service
- Body: `{ origin, destination }`

## Using Email Service in Code

### Import Email Service

```javascript
const EmailService = require('./api/email-service.js');
const config = require('../config/email-config.json');
const emailService = new EmailService(config);
```

### Send Welcome Email

```javascript
await emailService.sendWelcomeEmail('user@example.com', 'John Doe');
```

### Send Booking Confirmation

```javascript
await emailService.sendBookingConfirmation('user@example.com', {
    bookingId: 'BOOK123',
    pickupLocation: 'Times Square',
    destination: 'Central Park',
    estimatedFare: '25.50',
    driverName: 'John Smith'
});
```

### Send Password Reset

```javascript
await emailService.sendPasswordReset(
    'user@example.com',
    'https://app.com/reset?token=xxx',
    'John Doe'
);
```

### Send OTP

```javascript
await emailService.sendOTPEmail('user@example.com', '123456', 'John Doe');
```

### Send Trip Completed

```javascript
await emailService.sendTripCompletedEmail('user@example.com', {
    tripId: 'TRIP789',
    duration: '15 mins',
    distance: '5.2 km',
    totalFare: '18.50',
    driverRating: '5'
});
```

### Send Custom Email

```javascript
await emailService.send({
    to: 'user@example.com',
    subject: 'Your Subject',
    html: '<h1>Hello</h1><p>This is HTML content</p>'
});
```

## Configuration File

Configuration is stored in: `/config/email-config.json`

```json
{
  "email": {
    "provider": "smtp",
    "smtp": {
      "host": "smtp.gmail.com",
      "port": 587,
      "secure": false,
      "auth": {
        "user": "your-email@gmail.com",
        "pass": "your-app-password"
      },
      "from": "noreply@swiftcab.com",
      "replyTo": "support@swiftcab.com"
    },
    "sendgrid": {
      "apiKey": "SG.xxx",
      "fromEmail": "noreply@swiftcab.com",
      "fromName": "Swift Cab"
    },
    "mailgun": {
      "apiKey": "key-xxx",
      "domain": "mg.swiftcab.com",
      "fromEmail": "noreply@swiftcab.com"
    }
  },
  "services": {
    "maps": {
      "provider": "google",
      "apiKey": "your-google-maps-api-key",
      "enabled": false
    },
    "payment": {
      "provider": "stripe",
      "apiKey": "your-stripe-api-key",
      "enabled": false
    },
    "sms": {
      "provider": "twilio",
      "apiKey": "your-twilio-api-key",
      "enabled": false
    }
  }
}
```

## Integration with Web Servers

### Server Example

```javascript
const EmailService = require('./api/email-service.js');
const express = require('express');
const fs = require('fs');

const app = express();
const configFile = '/path/to/config/email-config.json';
const config = JSON.parse(fs.readFileSync(configFile, 'utf8'));
const emailService = new EmailService(config);

// Send email on booking creation
app.post('/api/bookings', async (req, res) => {
    const booking = req.body;
    
    // Create booking...
    
    // Send confirmation email
    await emailService.sendBookingConfirmation(booking.userEmail, {
        bookingId: booking.id,
        pickupLocation: booking.pickup,
        destination: booking.destination,
        estimatedFare: booking.fare,
        driverName: booking.driver.name
    });
    
    res.json({ success: true });
});
```

## Status Dashboard Features

### Email Configuration Tab
- ✅ Switch between providers
- ✅ Configure each provider's settings
- ✅ Save configuration
- ✅ Test email sending
- ✅ Secure password handling (not returned)

### Services & APIs Tab
- ✅ Enable/disable Maps service
- ✅ Enable/disable Payment service
- ✅ Configure Maps API keys
- ✅ Test route calculation
- ✅ SMS service configuration (coming soon)

### Status Tab
- ✅ System health monitoring
- ✅ Service status overview
- ✅ Memory and CPU usage

## Troubleshooting

### Email Not Sending

1. **Check provider credentials**
   - Verify API key or password is correct
   - For Gmail, use app-specific password, not account password

2. **Check configuration**
   - Verify SMTP host and port
   - For TLS: port 587, secure=false
   - For SSL: port 465, secure=true

3. **Test transporter**
   - Use test email feature in dashboard
   - Check browser console for errors
   - Check server logs

4. **Verify email service**
   ```javascript
   const result = await emailService.verify();
   console.log(result);
   ```

### API Configuration Not Saving

1. Check if `/config` directory exists
2. Verify file write permissions
3. Check server logs for errors
4. Reload dashboard to verify save

### Dashboard Not Responding

1. Verify Status Dashboard is running: `pm2 status`
2. Check port 8080 is open
3. Restart dashboard: `pm2 restart status-dashboard`
4. Check logs: `pm2 logs status-dashboard`

## Security Best Practices

⚠️ **Important Security Notes:**

1. **Never commit credentials**
   - Keep `email-config.json` out of version control
   - Add to `.gitignore`

2. **Use environment variables for sensitive data**
   ```javascript
   const config = {
       email: {
           smtp: {
               auth: {
                   user: process.env.EMAIL_USER,
                   pass: process.env.EMAIL_PASS
               }
           }
       }
   };
   ```

3. **Restrict dashboard access**
   - Use Nginx reverse proxy with authentication
   - Limit access by IP
   - Use HTTPS only

4. **Rotate API keys regularly**
   - Change passwords every 3 months
   - Use service-specific API keys, not master keys

5. **Monitor email logs**
   - Track sent emails
   - Alert on failures
   - Log suspicious activity

## Integration Checklist

- [ ] Install nodemailer: `npm install nodemailer`
- [ ] Configure email provider in dashboard
- [ ] Test email sending
- [ ] Configure Maps API (if using)
- [ ] Configure Payment API (if using)
- [ ] Set environment variables for production
- [ ] Add email-config.json to .gitignore
- [ ] Add email sending to booking flow
- [ ] Add email sending to user registration
- [ ] Add email sending to password reset
- [ ] Test in production environment
- [ ] Set up email monitoring/logging
- [ ] Document team email procedures

## Support & Documentation

- **API Docs:** [See API Endpoints](#api-endpoints)
- **Configuration:** [See Configuration File](#configuration-file)
- **Examples:** [See Code Examples](#using-email-service-in-code)
- **Dashboard:** http://YOUR_VPS_IP:8080

## Next Steps

1. ✅ Email server configured and running
2. ⏭️ Integrate email into booking flow
3. ⏭️ Add email templates for different events
4. ⏭️ Implement email logging/tracking
5. ⏭️ Set up email alerts for admins
6. ⏭️ Configure Maps API integration
7. ⏭️ Add SMS notifications

---

**Created:** December 22, 2025  
**Swift Cab Status Dashboard & Email Server**
