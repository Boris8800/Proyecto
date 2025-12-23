# Complete API Configuration System

**All-in-One API Management** for Google Maps, Email, SMS, Payments, Push Notifications, and Analytics.

---

## Quick Start

### 1. Run Interactive Setup

```bash
./scripts/setup-apis.sh
```

This will guide you through configuring:
- ✅ Google APIs (Maps, Geocoding, Directions, Places)
- ✅ Email Service (Gmail, SendGrid, Mailgun, AWS SES)
- ✅ SMS Service (Twilio, Vonage, AWS SNS)
- ✅ Payment Gateways (Stripe, PayPal, Square)
- ✅ Push Notifications (Firebase, OneSignal)
- ✅ Analytics (Sentry, LogRocket)

### 2. Fill in Your API Keys

Copy `.env.example` to `.env` and add your keys:

```bash
cp .env.example .env
nano .env
```

### 3. Use APIs in Your Code

```javascript
const apiConfig = require('./config/api-config');

// Send email
await apiConfig.email.sendEmail({
  to: 'user@example.com',
  subject: 'Hello',
  html: '<h1>Hello</h1>'
});

// Send SMS
await apiConfig.sms.sendSMS({
  to: '+1-555-0123',
  message: 'Hello from Node.js'
});

// Geocode address
const location = await apiConfig.google.geocodeAddress('123 Main St');

// Get directions
const route = await apiConfig.google.getDirections(
  '123 Main St',
  '456 Park Ave'
);
```

---

## Files Included

### Configuration Files
- **`.env.example`** - Template with all API keys needed
- **`config/api-config.js`** - Main configuration module with all API methods
- **`scripts/setup-apis.sh`** - Interactive setup wizard

### Usage & Examples
- **`web/api/api-usage-examples.js`** - Complete usage examples for all APIs

---

## API Services Overview

### 1. Google APIs

```javascript
// Geocode address to coordinates
const result = await apiConfig.google.geocodeAddress('123 Main St');

// Reverse geocode coordinates to address
const address = await apiConfig.google.reverseGeocode(40.7128, -74.0060);

// Get directions and route info
const route = await apiConfig.google.getDirections(
  '123 Main St, New York',
  '456 Park Ave, New York',
  'driving'
);

// Get place predictions (autocomplete)
const predictions = await apiConfig.google.getPlacePredictions('123 Main');
```

**Required Keys:**
- `GOOGLE_MAPS_API_KEY` - For displaying maps
- `GOOGLE_GEOCODING_API_KEY` - For address ↔ coordinates
- `GOOGLE_DIRECTIONS_API_KEY` - For route calculation
- `GOOGLE_PLACES_API_KEY` - For address autocomplete

**Get Keys:** https://console.cloud.google.com/

---

### 2. Email Service

**Supports 4 services:**

#### Gmail (SMTP)
```javascript
// Set in .env:
// EMAIL_SERVICE=gmail
// EMAIL_USER=your_email@gmail.com
// EMAIL_PASSWORD=your_app_password

await apiConfig.email.sendEmail({
  to: 'recipient@example.com',
  subject: 'Subject',
  html: '<h1>HTML Content</h1>'
});
```

#### SendGrid
```javascript
// Set in .env:
// EMAIL_SERVICE=sendgrid
// SENDGRID_API_KEY=sg_...
// SENDGRID_FROM_EMAIL=noreply@yourdomain.com

await apiConfig.email.sendEmail({
  to: 'user@example.com',
  subject: 'Hello',
  html: '<p>Content</p>'
});
```

#### Mailgun
```javascript
// Set in .env:
// EMAIL_SERVICE=mailgun
// MAILGUN_API_KEY=key-...
// MAILGUN_DOMAIN=yourdomain.mailgun.org

await apiConfig.email.sendEmail({
  to: 'user@example.com',
  subject: 'Hello',
  html: '<p>Content</p>'
});
```

#### AWS SES
```javascript
// Set in .env:
// EMAIL_SERVICE=aws-ses
// AWS_SES_ACCESS_KEY_ID=AKIA...
// AWS_SES_SECRET_ACCESS_KEY=...
// AWS_SES_REGION=us-east-1

await apiConfig.email.sendEmail({
  to: 'user@example.com',
  subject: 'Hello',
  html: '<p>Content</p>'
});
```

---

### 3. SMS Service

**Supports 3 services:**

#### Twilio
```javascript
// Set in .env:
// TWILIO_ACCOUNT_SID=AC...
// TWILIO_AUTH_TOKEN=...
// TWILIO_PHONE_NUMBER=+1234567890

await apiConfig.sms.sendSMS({
  to: '+1-555-0123',
  message: 'Your verification code is 123456'
});
```

#### Vonage (Nexmo)
```javascript
// Set in .env:
// VONAGE_API_KEY=...
// VONAGE_API_SECRET=...
// VONAGE_FROM_NUMBER=YourBrand

await apiConfig.sms.sendSMS({
  to: '+1-555-0123',
  message: 'Your verification code is 123456'
});
```

#### AWS SNS
```javascript
// Set in .env:
// AWS_SNS_ACCESS_KEY_ID=AKIA...
// AWS_SNS_SECRET_ACCESS_KEY=...
// AWS_SNS_REGION=us-east-1

await apiConfig.sms.sendSMS({
  to: '+1-555-0123',
  message: 'Your verification code is 123456'
});
```

---

### 4. Payment Gateways

#### Stripe
```javascript
const stripe = require('stripe')(apiConfig.payment.stripe.secretKey);

const paymentIntent = await stripe.paymentIntents.create({
  amount: 2550, // $25.50 in cents
  currency: 'usd',
  metadata: { jobId: 'JOB-001' }
});
```

#### PayPal
```javascript
const paypalSdk = require('@paypal/checkout-server-sdk');
// Use apiConfig.payment.paypal.clientId and clientSecret
```

#### Square
```javascript
const squareClient = require('square');
const client = new squareClient.Client({
  accessToken: apiConfig.payment.square.accessToken,
  environment: 'production'
});
```

---

### 5. Push Notifications

#### Firebase Cloud Messaging
```javascript
// Requires:
// FIREBASE_PROJECT_ID
// FIREBASE_PRIVATE_KEY
// FIREBASE_CLIENT_EMAIL

// Use firebase-admin SDK
const admin = require('firebase-admin');
```

#### OneSignal
```javascript
// Requires:
// ONESIGNAL_APP_ID
// ONESIGNAL_API_KEY

const OneSignal = require('onesignal-node');
```

---

### 6. Analytics & Monitoring

#### Sentry (Error Tracking)
```javascript
// Set in .env:
// SENTRY_DSN=https://...@sentry.io/...

const Sentry = require('@sentry/node');
Sentry.init({ dsn: apiConfig.analytics.sentry.dsn });
```

#### LogRocket (Session Recording)
```javascript
// Set in .env:
// LOGROCKET_APP_ID=your-app-id

// In frontend:
<script src="https://cdn.lr-ingest.com/LogRocket.min.js" crossorigin="anonymous"></script>
<script>window.LogRocket && window.LogRocket.init('your-app-id');</script>
```

---

## Complete Job Flow Example

```javascript
// 1. Payment confirmed → Create magic link and notify driver
app.post('/api/payment/confirm', async (req, res) => {
  const { jobId, driverId, driverEmail, driverPhone, pickupAddr, dropoffAddr, fare } = req.body;

  try {
    // 2. Geocode addresses
    const pickup = await apiConfig.google.geocodeAddress(pickupAddr);
    const dropoff = await apiConfig.google.geocodeAddress(dropoffAddr);

    // 3. Get route and ETA
    const route = await apiConfig.google.getDirections(
      pickupAddr,
      dropoffAddr
    );

    // 4. Create magic link (from job-magic-links.js)
    const magicLink = `http://localhost:3001/driver/job?token=${generateToken()}`;

    // 5. Send email notification
    await apiConfig.email.sendEmail({
      to: driverEmail,
      subject: `New Job: ${jobId}`,
      html: `
        <h2>New Job Assignment</h2>
        <p>Pickup: ${pickup.formatted_address}</p>
        <p>Dropoff: ${dropoff.formatted_address}</p>
        <p>Distance: ${route.distance.text}</p>
        <p>ETA: ${route.duration.text}</p>
        <p>Fare: $${fare}</p>
        <a href="${magicLink}" style="background: #667eea; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          Accept Job
        </a>
      `
    });

    // 6. Send SMS notification
    await apiConfig.sms.sendSMS({
      to: driverPhone,
      message: `New job ${jobId}! ${route.distance.text}, ${route.duration.text}. Fare: $${fare}. Accept: ${magicLink}`
    });

    // 7. Fire push notification (if using Firebase/OneSignal)
    // await sendPushNotification(driverId, ...);

    res.json({ success: true, magicLink });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
```

---

## Environment Variables Reference

### Google APIs
```
GOOGLE_MAPS_API_KEY=AIzaSyD...
GOOGLE_GEOCODING_API_KEY=AIzaSyD...
GOOGLE_DIRECTIONS_API_KEY=AIzaSyD...
GOOGLE_PLACES_API_KEY=AIzaSyD...
```

### Email Service
```
EMAIL_SERVICE=gmail|sendgrid|mailgun|aws-ses
EMAIL_USER=your_email@gmail.com
EMAIL_PASSWORD=your_app_password
SENDGRID_API_KEY=SG...
MAILGUN_API_KEY=key-...
MAILGUN_DOMAIN=yourdomain.mailgun.org
AWS_SES_ACCESS_KEY_ID=AKIA...
AWS_SES_SECRET_ACCESS_KEY=...
AWS_SES_REGION=us-east-1
```

### SMS Service
```
TWILIO_ACCOUNT_SID=AC...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=+1234567890
VONAGE_API_KEY=...
VONAGE_API_SECRET=...
VONAGE_FROM_NUMBER=YourBrand
AWS_SNS_ACCESS_KEY_ID=AKIA...
AWS_SNS_SECRET_ACCESS_KEY=...
AWS_SNS_REGION=us-east-1
```

### Payment Gateways
```
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
PAYPAL_CLIENT_ID=...
PAYPAL_CLIENT_SECRET=...
PAYPAL_MODE=sandbox|live
SQUARE_ACCESS_TOKEN=sq_...
SQUARE_LOCATION_ID=...
```

### Push Notifications
```
FIREBASE_PROJECT_ID=...
FIREBASE_PRIVATE_KEY=...
FIREBASE_CLIENT_EMAIL=...
ONESIGNAL_APP_ID=...
ONESIGNAL_API_KEY=...
```

### Analytics
```
SENTRY_DSN=https://...@sentry.io/...
LOGROCKET_APP_ID=...
```

---

## Testing APIs

### Check Configuration Status
```bash
node -e "const apiConfig = require('./config/api-config'); apiConfig.printStatus();"
```

### Run Examples
```bash
# Edit and run examples:
node web/api/api-usage-examples.js
```

### Test Email
```javascript
const apiConfig = require('./config/api-config');
apiConfig.email.sendEmail({
  to: 'test@example.com',
  subject: 'Test Email',
  html: '<p>Test</p>'
}).then(() => console.log('Email sent'));
```

### Test SMS
```javascript
const apiConfig = require('./config/api-config');
apiConfig.sms.sendSMS({
  to: '+1-555-0123',
  message: 'Test SMS from Node.js'
}).then(() => console.log('SMS sent'));
```

### Test Google Geocoding
```javascript
const apiConfig = require('./config/api-config');
apiConfig.google.geocodeAddress('123 Main St, New York').then(result => {
  console.log('Address:', result.formatted_address);
  console.log('Coordinates:', result.geometry.location);
});
```

---

## Troubleshooting

### "API key not configured"
- Check that your `.env` file exists
- Verify the key name matches the environment variable name
- Reload the module: `delete require.cache[require.resolve('./config/api-config')]`

### Email not sending
- Check SMTP settings (Gmail requires app passwords, not regular password)
- Verify sender email and credentials in `.env`
- Check email service is set correctly

### SMS not sending
- Verify phone numbers include country code (+1...)
- Check account has credits/balance
- Verify credentials in `.env`

### Google APIs not working
- Ensure APIs are enabled in Google Cloud Console
- Check API keys have correct restrictions
- Verify coordinate format (latitude, longitude)

### Payment gateway errors
- Verify account is in test/sandbox mode
- Check API keys haven't been revoked
- Ensure required fields are provided

---

## Getting API Keys

| Service | How to Get Key | Cost |
|---------|---|---|
| **Google Maps** | [Google Cloud Console](https://console.cloud.google.com/) | Pay-as-you-go |
| **Twilio SMS** | [Twilio Console](https://www.twilio.com/console) | ~$0.01/SMS |
| **SendGrid Email** | [SendGrid](https://sendgrid.com/) | Free tier: 100/day |
| **Stripe Payment** | [Stripe Dashboard](https://dashboard.stripe.com/) | 2.9% + $0.30 per transaction |
| **Firebase Push** | [Firebase Console](https://console.firebase.google.com/) | Free tier available |
| **Sentry Error Tracking** | [Sentry](https://sentry.io/) | Free tier: 5K errors/month |

---

## Support

- Run `./scripts/setup-apis.sh` for interactive setup
- Check `web/api/api-usage-examples.js` for code examples
- Review `config/api-config.js` for all available methods
- Check `.env.example` for all configuration options

---

## Security Tips

✅ **DO:**
- Store API keys in `.env` (never commit to git)
- Use environment variables in production
- Rotate keys regularly
- Use separate keys for development/production
- Restrict key permissions in API consoles

❌ **DON'T:**
- Commit `.env` file to git
- Hardcode API keys in source code
- Share API keys in Slack/Email
- Use production keys in development
- Expose keys in client-side code

---

## Architecture

```
config/api-config.js (Main module)
├── Google APIs (geocoding, directions, places)
├── Email Service (4 providers)
├── SMS Service (3 providers)
├── Payment Gateways (3 providers)
├── Push Notifications (2 providers)
└── Analytics (2 providers)

scripts/setup-apis.sh (Interactive setup wizard)
web/api/api-usage-examples.js (Complete examples)
.env (Your configuration - NOT in git)
.env.example (Template - in git)
```

---

**Status:** ✅ Complete & Production Ready

All APIs integrated and ready to use!
