/**
 * Integration Example: Job Magic Links with Payment System
 * 
 * Shows how to integrate magic link creation with your payment processing
 * workflow in the admin dashboard or backend
 */

// ============================================================================
// EXAMPLE 1: Admin Dashboard - Create Magic Link After Payment
// ============================================================================

class PaymentProcessor {
  constructor() {
    // Include the job magic links client
    this.jobClient = new JobMagicLinksClient({
      apiUrl: 'http://localhost:3334/api/job-magic-links'
    });

    // Include email client for sending links
    this.emailClient = new EmailServiceClient({
      apiUrl: 'http://localhost:3333/api/email'
    });
  }

  /**
   * Process booking payment and create magic link for driver
   * Called when customer payment is confirmed
   */
  async processBookingPayment(booking) {
    try {
      // Step 1: Charge customer
      console.log('💳 Processing payment...');
      const payment = await this.chargeCard(booking.paymentDetails);
      
      if (!payment.success) {
        throw new Error('Payment failed: ' + payment.error);
      }
      console.log('✅ Payment successful');

      // Step 2: Assign driver (from your driver assignment logic)
      console.log('🚗 Assigning driver...');
      const driver = await this.assignDriver(booking);
      console.log(`✅ Driver assigned: ${driver.name}`);

      // Step 3: Create magic link for driver
      console.log('🔗 Creating magic link...');
      const magicLink = await this.jobClient.createJobMagicLink({
        jobId: booking.id,
        driverEmail: driver.email,
        driverName: driver.name,
        driverPhone: driver.phone,
        pickupAddress: booking.pickupAddress,
        pickupLat: booking.pickupLat,
        pickupLng: booking.pickupLng,
        dropoffAddress: booking.dropoffAddress,
        dropoffLat: booking.dropoffLat,
        dropoffLng: booking.dropoffLng,
        jobTime: booking.scheduledTime,
        fare: booking.totalFare,
        expiryHours: 24  // Link valid for 24 hours
      });
      console.log(`✅ Magic link created: ${magicLink.link}`);

      // Step 4: Send link to driver
      console.log('📧 Sending link to driver...');
      await this.sendLinkToDriver(driver, magicLink, booking);
      console.log(`✅ Link sent to ${driver.email}`);

      // Step 5: Send confirmation to customer
      console.log('📧 Sending confirmation to customer...');
      await this.sendConfirmationToCustomer(booking, driver);
      console.log(`✅ Confirmation sent to customer`);

      // Step 6: Update booking status
      await this.updateBookingStatus(booking.id, 'driver_assigned');

      return {
        success: true,
        message: 'Payment processed and driver assigned',
        jobId: booking.id,
        driverId: driver.id,
        magicLink: magicLink.link
      };

    } catch (error) {
      console.error('❌ Error processing payment:', error);
      
      // Refund if driver assignment failed
      if (error.message.includes('driver')) {
        await this.refundPayment(booking.paymentId);
      }
      
      throw error;
    }
  }

  /**
   * Send magic link to driver via email
   */
  async sendLinkToDriver(driver, magicLink, booking) {
    return this.emailClient.sendEmail({
      to: driver.email,
      subject: `New Job Assigned - ${booking.id}`,
      template: 'driver-job-assignment',
      data: {
        driverName: driver.name,
        jobId: booking.id,
        magicLink: magicLink.link,
        pickupAddress: booking.pickupAddress,
        dropoffAddress: booking.dropoffAddress,
        scheduledTime: booking.scheduledTime,
        fare: booking.totalFare,
        expiresAt: magicLink.expiresAt
      }
    });
  }

  /**
   * Send confirmation to customer
   */
  async sendConfirmationToCustomer(booking, driver) {
    return this.emailClient.sendEmail({
      to: booking.customerEmail,
      subject: `Booking Confirmed - ${booking.id}`,
      template: 'customer-booking-confirmed',
      data: {
        customerName: booking.customerName,
        jobId: booking.id,
        driverName: driver.name,
        driverRating: driver.rating,
        driverPhone: driver.phone,
        vehicleInfo: driver.vehicleInfo,
        pickupAddress: booking.pickupAddress,
        dropoffAddress: booking.dropoffAddress,
        scheduledTime: booking.scheduledTime,
        fare: booking.totalFare
      }
    });
  }

  /**
   * Charge payment card
   * Implement with your payment gateway (Stripe, etc)
   */
  async chargeCard(paymentDetails) {
    // TODO: Implement with Stripe/PayPal/Square/etc
    return {
      success: true,
      transactionId: 'txn_' + Date.now()
    };
  }

  /**
   * Assign available driver to booking
   */
  async assignDriver(booking) {
    // TODO: Implement your driver assignment logic
    // Consider: distance, rating, availability, acceptance rate
    return {
      id: 'drv_123',
      name: 'John Smith',
      email: 'john@example.com',
      phone: '+1-555-0123',
      rating: 4.8,
      vehicleInfo: 'Honda Accord - XYZ123'
    };
  }

  /**
   * Update booking status in database
   */
  async updateBookingStatus(bookingId, status) {
    // TODO: Update your booking database
    console.log(`Updated booking ${bookingId} to ${status}`);
  }

  /**
   * Refund payment
   */
  async refundPayment(paymentId) {
    // TODO: Process refund with payment gateway
    console.log(`Refunded payment ${paymentId}`);
  }
}

// ============================================================================
// EXAMPLE 2: Admin Dashboard - Track Driver in Real-Time
// ============================================================================

class AdminDashboard {
  constructor() {
    this.jobClient = new JobMagicLinksClient({
      apiUrl: 'http://localhost:3334/api/job-magic-links',
      onLocationUpdate: (location) => this.onDriverLocationUpdate(location)
    });

    this.activeTrackingSessions = {};
  }

  /**
   * Start tracking a driver for a job
   * Call after driver accepts job
   */
  startTrackingDriver(jobId, mapElement) {
    console.log(`📍 Starting tracking for job: ${jobId}`);

    // Create map if not exists
    if (!mapElement._leafletMap) {
      this.initializeMap(mapElement, jobId);
    }

    // Start polling driver location
    this.jobClient.startTracking(jobId, 5000);  // Update every 5 seconds

    // Store reference for cleanup
    this.activeTrackingSessions[jobId] = {
      startTime: new Date(),
      mapElement: mapElement
    };

    console.log(`✅ Tracking started for ${jobId}`);
  }

  /**
   * Stop tracking a driver
   * Call when job is completed
   */
  stopTrackingDriver(jobId) {
    console.log(`⏹ Stopping tracking for job: ${jobId}`);

    this.jobClient.stopTracking();
    delete this.activeTrackingSessions[jobId];

    console.log(`✅ Tracking stopped for ${jobId}`);
  }

  /**
   * Called when driver location updates
   */
  onDriverLocationUpdate(location) {
    console.log(`📍 Driver location: ${location.latitude}, ${location.longitude}`);
    
    // Update map marker
    this.updateDriverMarkerOnMap(location);

    // Calculate ETA
    this.calculateAndDisplayETA(location);

    // Update distance traveled
    this.updateDistanceTraveled(location);

    // Check if driver is off-route
    this.checkIfOffRoute(location);

    // Emit event for other UI updates
    this.emit('driverLocationUpdated', location);
  }

  /**
   * Initialize map with Leaflet
   */
  initializeMap(mapElement, jobId) {
    // Setup map...
    // This assumes map library is already loaded
  }

  /**
   * Update driver marker on map
   */
  updateDriverMarkerOnMap(location) {
    // Update blue marker with new location
    // Pan/zoom to show driver
  }

  /**
   * Calculate ETA to destination
   */
  calculateAndDisplayETA(location) {
    // Use distance matrix API to calculate ETA
    // Display to customer
  }

  /**
   * Track total distance traveled
   */
  updateDistanceTraveled(location) {
    // Calculate distance from last known location
    // Add to total
  }

  /**
   * Check if driver went off-route
   */
  checkIfOffRoute(location) {
    // Validate driver is still on expected route
    // Alert if significantly off-course
  }

  /**
   * Event emitter
   */
  emit(event, data) {
    // Emit event for UI updates
    window.dispatchEvent(new CustomEvent(event, { detail: data }));
  }
}

// ============================================================================
// EXAMPLE 3: HTML Integration in Admin Dashboard
// ============================================================================

/*
// In your admin dashboard HTML:

<script src="/api/job-magic-links-client.js"></script>
<script src="/path/to/integration-example.js"></script>

<div id="jobsList">
  <!-- Dynamic job list -->
</div>

<div id="trackingMap" style="width: 100%; height: 500px;"></div>

<script>
  const paymentProcessor = new PaymentProcessor();
  const adminDash = new AdminDashboard();

  // When customer confirms booking
  document.addEventListener('bookingConfirmed', async (e) => {
    const booking = e.detail;
    
    try {
      const result = await paymentProcessor.processBookingPayment(booking);
      console.log('✅ Booking processed:', result);
      
      // Show success message
      showNotification(`Job ${result.jobId} assigned to driver!`, 'success');
    } catch (error) {
      console.error('❌ Error:', error);
      showNotification(`Failed to process booking: ${error.message}`, 'error');
    }
  });

  // When driver accepts job
  document.addEventListener('jobAccepted', (e) => {
    const jobId = e.detail.jobId;
    
    // Start tracking driver on map
    adminDash.startTrackingDriver(jobId, document.getElementById('trackingMap'));
  });

  // When job is completed
  document.addEventListener('jobCompleted', (e) => {
    const jobId = e.detail.jobId;
    
    // Stop tracking
    adminDash.stopTrackingDriver(jobId);
    
    // Show completion message
    showNotification(`Job ${jobId} completed!`, 'success');
  });

  // Listen for location updates
  window.addEventListener('driverLocationUpdated', (e) => {
    const location = e.detail;
    updateUIWithLocation(location);
  });
</script>
*/

// ============================================================================
// EXAMPLE 4: Backend Integration (Node.js/Express)
// ============================================================================

/**
 * Express route to handle payment webhook
 * 
 * const express = require('express');
 * const app = express();
 * const paymentProcessor = new PaymentProcessor();
 * 
 * // Webhook from payment processor (Stripe, Square, etc)
 * app.post('/api/webhooks/payment-confirmed', async (req, res) => {
 *   const paymentData = req.body;
 *   
 *   try {
 *     // Find booking in database
 *     const booking = await Booking.findById(paymentData.bookingId);
 *     
 *     // Process payment and create magic link
 *     const result = await paymentProcessor.processBookingPayment(booking);
 *     
 *     // Send response
 *     res.json({
 *       success: true,
 *       jobId: result.jobId,
 *       message: 'Driver assigned'
 *     });
 *     
 *   } catch (error) {
 *     console.error('Payment webhook error:', error);
 *     res.status(500).json({
 *       success: false,
 *       error: error.message
 *     });
 *   }
 * });
 */

// ============================================================================
// EXAMPLE 5: Email Template for Driver
// ============================================================================

/*
// HTML Email Template for Driver Job Assignment

Subject: New Job Assigned - {{jobId}}

Dear {{driverName}},

You have a new job assignment! 🚕

📍 PICKUP
{{pickupAddress}}

📍 DROPOFF
{{dropoffAddress}}

⏰ SCHEDULED TIME
{{scheduledTime}}

💰 FARE
${{fare}}

🔗 ACCEPT JOB
Click the link below to view job details and accept:
{{magicLink}}

⏳ LINK EXPIRES
{{expiresAt}}

---

This link is secure and expires automatically. You don't need to login.

Best regards,
Swift Cab System
*/

// Export for use
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { PaymentProcessor, AdminDashboard };
}
