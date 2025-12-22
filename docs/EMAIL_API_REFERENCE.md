# Swift Cab Email & Services API Integration

## Email API Endpoints

### 1. Email Configuration Management

#### Get Email Configuration
```http
GET /api/email/config
Authorization: Bearer <token> (optional)
```

**Success Response (200):**
```json
{
  "provider": "smtp",
  "smtp": {
    "host": "smtp.gmail.com",
    "port": 587,
    "secure": false,
    "from": "noreply@swiftcab.com",
    "replyTo": "support@swiftcab.com",
    "auth": {
      "user": "your-email@gmail.com"
    }
  },
  "sendgrid": {
    "fromEmail": "noreply@swiftcab.com",
    "fromName": "Swift Cab"
  },
  "mailgun": {
    "domain": "mg.swiftcab.com",
    "fromEmail": "noreply@swiftcab.com"
  }
}
```

#### Update Email Configuration
```http
POST /api/email/config
Content-Type: application/json

{
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
  }
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Email configuration updated"
}
```

#### Send Test Email
```http
POST /api/email/test
Content-Type: application/json

{
  "to": "test@example.com",
  "subject": "Test Email from Swift Cab",
  "message": "This is a test email to verify email configuration"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Test email sent successfully to test@example.com",
  "messageId": "<20251222233000.abc123@gmail.com>"
}
```

**Error Response (500):**
```json
{
  "success": false,
  "message": "Failed to send email: Invalid credentials"
}
```

---

## Services & APIs Configuration

### Maps Service Configuration

#### Get Maps Configuration
```http
GET /api/services/config
```

**Response:**
```json
{
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
```

#### Update Maps Configuration
```http
POST /api/services/config
Content-Type: application/json

{
  "maps": {
    "provider": "google",
    "apiKey": "AIza...",
    "enabled": true
  }
}
```

#### Test Maps/Route Calculation
```http
POST /api/maps/test
Content-Type: application/json

{
  "origin": "Times Square, New York, NY",
  "destination": "Central Park, New York, NY"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Route calculated successfully",
  "data": {
    "origin": "Times Square, New York, NY",
    "destination": "Central Park, New York, NY",
    "distance": "5.2 km",
    "duration": "12 mins",
    "status": "OK"
  }
}
```

---

## Email Service Class (Node.js)

### Installation

```bash
npm install nodemailer@^6.9.7
```

### Usage

```javascript
const EmailService = require('./api/email-service.js');
const fs = require('fs');

// Load configuration
const config = JSON.parse(fs.readFileSync('./config/email-config.json', 'utf8'));
const emailService = new EmailService(config);

// Send welcome email
await emailService.sendWelcomeEmail('user@example.com', 'John Doe');

// Send booking confirmation
await emailService.sendBookingConfirmation('user@example.com', {
    bookingId: 'BOOK12345',
    pickupLocation: 'Times Square',
    destination: 'Central Park',
    estimatedFare: '25.50',
    driverName: 'John Smith'
});

// Send custom email
await emailService.send({
    to: 'user@example.com',
    subject: 'Custom Subject',
    html: '<h1>Hello</h1><p>Custom HTML</p>'
});
```

### Email Service Methods

| Method | Description | Parameters |
|--------|-------------|------------|
| `sendWelcomeEmail()` | Send welcome to new user | email, name |
| `sendBookingConfirmation()` | Send booking details | email, bookingDetails |
| `sendPasswordReset()` | Send password reset link | email, resetLink, name |
| `sendOTPEmail()` | Send OTP code | email, otp, name |
| `sendTripCompletedEmail()` | Send trip completion | email, tripDetails |
| `sendAdminNotification()` | Send admin alert | email, subject, message |
| `send()` | Send custom email | options |
| `verify()` | Test email connection | none |

---

## JavaScript/Frontend Integration

### Email Configuration API Client

```javascript
class EmailConfigClient {
    constructor(baseUrl = 'http://localhost:8080') {
        this.baseUrl = baseUrl;
    }

    async getConfig() {
        const response = await fetch(`${this.baseUrl}/api/email/config`);
        return response.json();
    }

    async updateConfig(config) {
        const response = await fetch(`${this.baseUrl}/api/email/config`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(config)
        });
        return response.json();
    }

    async sendTestEmail(to, subject, message) {
        const response = await fetch(`${this.baseUrl}/api/email/test`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ to, subject, message })
        });
        return response.json();
    }
}

// Usage
const emailClient = new EmailConfigClient('http://5.249.164.40:8080');
const config = await emailClient.getConfig();
console.log('Current email provider:', config.provider);
```

### Services Configuration Client

```javascript
class ServicesConfigClient {
    constructor(baseUrl = 'http://localhost:8080') {
        this.baseUrl = baseUrl;
    }

    async getConfig() {
        const response = await fetch(`${this.baseUrl}/api/services/config`);
        return response.json();
    }

    async updateConfig(config) {
        const response = await fetch(`${this.baseUrl}/api/services/config`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(config)
        });
        return response.json();
    }

    async testMapsAPI(origin, destination) {
        const response = await fetch(`${this.baseUrl}/api/maps/test`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ origin, destination })
        });
        return response.json();
    }
}

// Usage
const servicesClient = new ServicesConfigClient();
const result = await servicesClient.testMapsAPI(
    'Times Square',
    'Central Park'
);
console.log('Route distance:', result.data.distance);
```

---

## Integration Examples

### Express.js Server Integration

```javascript
const express = require('express');
const EmailService = require('./api/email-service.js');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(express.json());

// Load email service
const config = JSON.parse(
    fs.readFileSync(path.join(__dirname, '../config/email-config.json'), 'utf8')
);
const emailService = new EmailService(config);

// Register new user
app.post('/api/auth/register', async (req, res) => {
    try {
        const { email, name, password } = req.body;
        
        // Create user in database
        const user = await createUser({ email, name, password });
        
        // Send welcome email
        await emailService.sendWelcomeEmail(email, name);
        
        res.json({ success: true, userId: user.id });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// Create booking
app.post('/api/bookings', async (req, res) => {
    try {
        const booking = req.body;
        const user = await getUser(booking.userId);
        
        // Create booking in database
        const newBooking = await createBooking(booking);
        
        // Send confirmation email
        await emailService.sendBookingConfirmation(user.email, {
            bookingId: newBooking.id,
            pickupLocation: booking.pickup,
            destination: booking.destination,
            estimatedFare: newBooking.estimatedFare,
            driverName: booking.driverName
        });
        
        res.json({ success: true, booking: newBooking });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// Complete trip
app.post('/api/trips/:id/complete', async (req, res) => {
    try {
        const trip = await getTrip(req.params.id);
        const user = await getUser(trip.userId);
        
        // Update trip status
        await updateTrip(trip.id, { status: 'completed' });
        
        // Send completion email
        await emailService.sendTripCompletedEmail(user.email, {
            tripId: trip.id,
            duration: trip.duration,
            distance: trip.distance,
            totalFare: trip.fare,
            driverRating: trip.driverRating
        });
        
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

app.listen(3000);
```

---

## Email Configuration Examples

### Gmail SMTP Configuration

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
        "pass": "your-16-char-app-password"
      },
      "from": "noreply@swiftcab.com",
      "replyTo": "support@swiftcab.com"
    }
  }
}
```

### SendGrid Configuration

```json
{
  "email": {
    "provider": "sendgrid",
    "sendgrid": {
      "apiKey": "SG.abc123def456...",
      "fromEmail": "noreply@swiftcab.com",
      "fromName": "Swift Cab"
    }
  }
}
```

### Mailgun Configuration

```json
{
  "email": {
    "provider": "mailgun",
    "mailgun": {
      "apiKey": "key-abc123def456...",
      "domain": "mg.swiftcab.com",
      "fromEmail": "noreply@swiftcab.com"
    }
  }
}
```

---

## Status Dashboard

Access the Status Dashboard to configure email and services:

```
http://YOUR_VPS_IP:8080
```

**Tabs:**
- **Status** - System health and services overview
- **Email Configuration** - Setup and test email providers
- **Services & APIs** - Configure Maps, Payment, SMS services

---

## Documentation Files

- [EMAIL_SERVER_GUIDE.md](./EMAIL_SERVER_GUIDE.md) - Complete email server guide
- [API_INTEGRATION_GUIDE.md](./API_INTEGRATION_GUIDE.md) - Full API reference
- [setup-email.sh](../scripts/setup-email.sh) - Automated setup script

---

**Created:** December 22, 2025  
**Swift Cab Email & Services API**
