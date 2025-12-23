/**
 * ============================================
 * API CONFIGURATION USAGE EXAMPLES
 * ============================================
 * 
 * This file shows how to use all APIs from the config
 */

const apiConfig = require('../config/api-config');

// ============================================
// 1. USING GOOGLE APIS
// ============================================

// Example 1: Geocode an address
async function example_geocodeAddress() {
  try {
    const result = await apiConfig.google.geocodeAddress('123 Main St, New York, NY');
    console.log('Geocoding result:', result);
    // Returns: {
    //   geometry: { location: { lat: 40.7..., lng: -74.0... } },
    //   formatted_address: "123 Main St, New York, NY 10001, USA",
    //   address_components: [...]
    // }
  } catch (error) {
    console.error('Geocoding error:', error.message);
  }
}

// Example 2: Reverse geocode (get address from coordinates)
async function example_reverseGeocode() {
  try {
    const result = await apiConfig.google.reverseGeocode(40.7128, -74.0060);
    console.log('Address at coordinates:', result.formatted_address);
  } catch (error) {
    console.error('Reverse geocoding error:', error.message);
  }
}

// Example 3: Get directions and route
async function example_getDirections() {
  try {
    const result = await apiConfig.google.getDirections(
      '123 Main St, New York',
      '456 Park Ave, New York',
      'driving'
    );
    console.log('Route:', result);
    // Returns: {
    //   distance: { text: "1.2 km", value: 1234 },
    //   duration: { text: "5 mins", value: 300 },
    //   steps: [...]
    // }
  } catch (error) {
    console.error('Directions error:', error.message);
  }
}

// Example 4: Get place predictions (autocomplete)
async function example_getPlacePredictions() {
  try {
    const results = await apiConfig.google.getPlacePredictions('123 Main St');
    console.log('Place suggestions:', results);
  } catch (error) {
    console.error('Places error:', error.message);
  }
}

// ============================================
// 2. USING EMAIL SERVICE
// ============================================

// Example 1: Send simple email
async function example_sendEmail() {
  try {
    await apiConfig.email.sendEmail({
      to: 'driver@example.com',
      subject: 'New Job Assignment',
      text: 'You have a new job assignment',
      html: '<h1>New Job</h1><p>You have a new paid job!</p>'
    });
    console.log('Email sent successfully');
  } catch (error) {
    console.error('Email error:', error.message);
  }
}

// Example 2: Send job assignment email
async function example_sendJobEmail() {
  try {
    const jobDetails = {
      jobId: 'JOB-2025-001',
      pickupAddress: '123 Main St',
      dropoffAddress: '456 Park Ave',
      fare: 25.50,
      magicLink: 'http://localhost:3001/driver/job?token=abc123...'
    };

    const htmlTemplate = `
      <h2>New Job Assignment</h2>
      <p>Job ID: <strong>${jobDetails.jobId}</strong></p>
      <p>Pickup: ${jobDetails.pickupAddress}</p>
      <p>Dropoff: ${jobDetails.dropoffAddress}</p>
      <p>Fare: $${jobDetails.fare}</p>
      <a href="${jobDetails.magicLink}" style="background: #667eea; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
        Accept Job
      </a>
    `;

    await apiConfig.email.sendEmail({
      to: 'driver@example.com',
      subject: `New Job: ${jobDetails.jobId}`,
      html: htmlTemplate
    });
    console.log('Job email sent');
  } catch (error) {
    console.error('Email error:', error.message);
  }
}

// ============================================
// 3. USING SMS SERVICE
// ============================================

// Example 1: Send simple SMS
async function example_sendSMS() {
  try {
    await apiConfig.sms.sendSMS({
      to: '+1-555-0123',
      message: 'You have a new job assignment. Click the link to accept: http://...'
    });
    console.log('SMS sent successfully');
  } catch (error) {
    console.error('SMS error:', error.message);
  }
}

// Example 2: Send job notification SMS
async function example_sendJobSMS() {
  try {
    await apiConfig.sms.sendSMS({
      to: '+1-555-0123',
      message: 'New job JOB-2025-001 from 123 Main St to 456 Park Ave. Fare: $25.50. Accept now!'
    });
    console.log('Job SMS sent');
  } catch (error) {
    console.error('SMS error:', error.message);
  }
}

// ============================================
// 4. INTEGRATION WITH JOB MAGIC LINKS
// ============================================

// Example: Create job, send notification, track location
async function example_completeJobFlow() {
  try {
    const jobId = 'JOB-2025-001';
    const driverEmail = 'driver@example.com';
    const driverPhone = '+1-555-0123';
    const magicLink = 'http://localhost:3001/driver/job?token=abc123...';

    // Step 1: Geocode pickup and dropoff addresses
    const pickupGeo = await apiConfig.google.geocodeAddress('123 Main St, New York');
    const dropoffGeo = await apiConfig.google.geocodeAddress('456 Park Ave, New York');

    // Step 2: Get route and ETA
    const route = await apiConfig.google.getDirections(
      pickupGeo.formatted_address,
      dropoffGeo.formatted_address
    );

    const eta = route.duration.text;
    const distance = route.distance.text;

    // Step 3: Send email notification
    const emailBody = `
      <h2>New Job Assignment: ${jobId}</h2>
      <p>Pickup: ${pickupGeo.formatted_address}</p>
      <p>Dropoff: ${dropoffGeo.formatted_address}</p>
      <p>Estimated Distance: ${distance}</p>
      <p>Estimated Time: ${eta}</p>
      <p>Fare: $25.50</p>
      <a href="${magicLink}">Accept Job Now</a>
    `;

    await apiConfig.email.sendEmail({
      to: driverEmail,
      subject: `New Job Assignment: ${jobId}`,
      html: emailBody
    });

    // Step 4: Send SMS notification
    await apiConfig.sms.sendSMS({
      to: driverPhone,
      message: `New job ${jobId}! ${distance}, ${eta}. Fare: $25.50. Accept: ${magicLink}`
    });

    // Step 5: Get driver location for tracking
    // (This would be done later via driver's browser geolocation)

    console.log('Job notification sent via email and SMS');
    return {
      jobId,
      pickupGeo,
      dropoffGeo,
      route,
      eta,
      distance,
      magicLink
    };
  } catch (error) {
    console.error('Error in job flow:', error.message);
  }
}

// ============================================
// 5. USING PAYMENT CONFIGURATION
// ============================================

// Example: Payment processor integration
async function example_processPayment() {
  try {
    const stripe = require('stripe')(apiConfig.payment.stripe.secretKey);

    // Create payment intent after job is confirmed
    const paymentIntent = await stripe.paymentIntents.create({
      amount: 2550, // $25.50 in cents
      currency: 'usd',
      metadata: {
        jobId: 'JOB-2025-001',
        driverId: 'DRIVER-123'
      }
    });

    console.log('Payment intent created:', paymentIntent.id);

    // After payment successful, create magic link and send to driver
    // (See example_completeJobFlow above)

  } catch (error) {
    console.error('Payment error:', error.message);
  }
}

// ============================================
// 6. EXPRESS ROUTE EXAMPLES
// ============================================

// Example: Express endpoint using APIs
async function setupExpressRoutes(app) {
  // Route 1: Send job notification
  app.post('/api/jobs/notify', async (req, res) => {
    try {
      const { jobId, driverEmail, driverPhone, magicLink } = req.body;

      // Send email
      await apiConfig.email.sendEmail({
        to: driverEmail,
        subject: `New Job: ${jobId}`,
        html: `<p>You have a new job! <a href="${magicLink}">Accept Now</a></p>`
      });

      // Send SMS
      await apiConfig.sms.sendSMS({
        to: driverPhone,
        message: `New job ${jobId}! Accept: ${magicLink}`
      });

      res.json({ success: true, message: 'Notifications sent' });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  // Route 2: Geocode address
  app.post('/api/address/geocode', async (req, res) => {
    try {
      const { address } = req.body;
      const result = await apiConfig.google.geocodeAddress(address);
      res.json({ success: true, result });
    } catch (error) {
      res.status(400).json({ success: false, error: error.message });
    }
  });

  // Route 3: Get route and ETA
  app.post('/api/route/directions', async (req, res) => {
    try {
      const { origin, destination } = req.body;
      const result = await apiConfig.google.getDirections(origin, destination);
      res.json({ 
        success: true, 
        distance: result.distance,
        duration: result.duration,
        steps: result.steps
      });
    } catch (error) {
      res.status(400).json({ success: false, error: error.message });
    }
  });

  // Route 4: Check API configuration
  app.get('/api/config/status', (req, res) => {
    const status = apiConfig.checkStatus();
    res.json({ success: true, status });
  });
}

// ============================================
// 7. INITIALIZE AND RUN EXAMPLES
// ============================================

if (require.main === module) {
  (async () => {
    console.log('\n============================================');
    console.log('API CONFIGURATION EXAMPLES');
    console.log('============================================\n');

    // Print configuration status
    console.log('Current API Configuration Status:');
    apiConfig.printStatus();

    // Uncomment examples to run:

    // await example_geocodeAddress();
    // await example_reverseGeocode();
    // await example_getDirections();
    // await example_getPlacePredictions();
    // await example_sendEmail();
    // await example_sendJobEmail();
    // await example_sendSMS();
    // await example_sendJobSMS();
    // await example_completeJobFlow();
    // await example_processPayment();

    console.log('\nExamples created. Edit this file and uncomment examples to test.');
  })();
}

module.exports = {
  example_geocodeAddress,
  example_reverseGeocode,
  example_getDirections,
  example_getPlacePredictions,
  example_sendEmail,
  example_sendJobEmail,
  example_sendSMS,
  example_sendJobSMS,
  example_completeJobFlow,
  example_processPayment,
  setupExpressRoutes
};
