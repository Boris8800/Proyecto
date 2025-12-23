/**
 * Job Magic Links Client Library
 * Handles job magic link generation, validation, and driver tracking
 */

class JobMagicLinksClient {
  constructor(options = {}) {
    this.apiUrl = options.apiUrl || 'http://localhost:3334/api/job-magic-links';
    this.onLocationUpdate = options.onLocationUpdate || null;
    this.trackingInterval = null;
  }

  /**
   * Create Magic Link for a Paid Job
   * Call this after payment is confirmed
   *
   * @param {object} jobData Job information
   * @returns {Promise<object>} Created link details
   *
   * @example
   * const link = await jobClient.createJobMagicLink({
   *   jobId: 'JOB-2025-001',
   *   driverEmail: 'driver@example.com',
   *   driverName: 'John Driver',
   *   driverPhone: '+1-555-1234',
   *   pickupAddress: '123 Main St, New York',
   *   pickupLat: 40.7128,
   *   pickupLng: -74.0060,
   *   dropoffAddress: '456 Park Ave, New York',
   *   dropoffLat: 40.7589,
   *   dropoffLng: -73.9851,
   *   jobTime: '2025-12-25T18:00:00Z',
   *   fare: 25.50,
   *   expiryHours: 24
   * });
   */
  async createJobMagicLink(jobData) {
    try {
      const response = await fetch(`${this.apiUrl}/create-for-job`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(jobData)
      });

      const data = await response.json();

      if (!data.success) {
        throw new Error(data.error || 'Failed to create magic link');
      }

      return data;
    } catch (error) {
      console.error('Error creating job magic link:', error);
      throw error;
    }
  }

  /**
   * Validate Job Magic Link
   * Used by driver to accept job
   *
   * @param {string} token Magic link token
   * @returns {Promise<object>} Job details and session info
   */
  async validateJobLink(token) {
    try {
      const response = await fetch(`${this.apiUrl}/validate/${token}`);
      const data = await response.json();

      if (!data.success) {
        throw new Error(data.error || 'Failed to validate link');
      }

      return data;
    } catch (error) {
      console.error('Error validating job link:', error);
      throw error;
    }
  }

  /**
   * Get Job Details
   * Retrieve full job information
   *
   * @param {string} jobId Job ID
   * @returns {Promise<object>} Job details
   */
  async getJobDetails(jobId) {
    try {
      const response = await fetch(`${this.apiUrl}/job/${jobId}`);
      const data = await response.json();

      if (!data.success) {
        throw new Error(data.error || 'Failed to fetch job');
      }

      return data.job;
    } catch (error) {
      console.error('Error fetching job details:', error);
      throw error;
    }
  }

  /**
   * Get Driver Current Location
   * Real-time driver tracking for admin/customer
   *
   * @param {string} jobId Job ID
   * @returns {Promise<object>} Driver location
   *
   * @example
   * const location = await jobClient.getDriverLocation('JOB-2025-001');
   * console.log(location.location.latitude, location.location.longitude);
   */
  async getDriverLocation(jobId) {
    try {
      const response = await fetch(`${this.apiUrl}/driver-location/${jobId}`);
      const data = await response.json();

      if (!data.success) {
        throw new Error(data.error || 'Failed to fetch location');
      }

      return data;
    } catch (error) {
      console.error('Error fetching driver location:', error);
      throw error;
    }
  }

  /**
   * Start Tracking Driver
   * Poll driver location at intervals
   *
   * @param {string} jobId Job ID
   * @param {number} interval Polling interval in ms (default: 10000 = 10 seconds)
   *
   * @example
   * jobClient.startTracking('JOB-2025-001', 5000); // Update every 5 seconds
   */
  startTracking(jobId, interval = 10000) {
    if (this.trackingInterval) {
      clearInterval(this.trackingInterval);
    }

    this.trackingInterval = setInterval(async () => {
      try {
        const data = await this.getDriverLocation(jobId);
        if (this.onLocationUpdate) {
          this.onLocationUpdate(data.location);
        }
      } catch (error) {
        console.error('Error updating location:', error);
      }
    }, interval);
  }

  /**
   * Stop Tracking Driver
   */
  stopTracking() {
    if (this.trackingInterval) {
      clearInterval(this.trackingInterval);
      this.trackingInterval = null;
    }
  }

  /**
   * Complete Job
   * Mark job as completed (for driver)
   *
   * @param {string} jobId Job ID
   * @param {string} sessionToken Session token
   * @returns {Promise<object>} Confirmation
   */
  async completeJob(jobId, sessionToken) {
    try {
      const response = await fetch(`${this.apiUrl}/complete-job/${jobId}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ sessionToken })
      });

      const data = await response.json();

      if (!data.success) {
        throw new Error(data.error || 'Failed to complete job');
      }

      return data;
    } catch (error) {
      console.error('Error completing job:', error);
      throw error;
    }
  }

  /**
   * Get Statistics
   * Admin dashboard stats
   *
   * @returns {Promise<object>} Job statistics
   */
  async getStats() {
    try {
      const response = await fetch(`${this.apiUrl}/stats`);
      const data = await response.json();

      if (!data.success) {
        throw new Error(data.error || 'Failed to fetch stats');
      }

      return data.stats;
    } catch (error) {
      console.error('Error fetching statistics:', error);
      throw error;
    }
  }
}

// Export for use in Node.js
if (typeof module !== 'undefined' && module.exports) {
  module.exports = JobMagicLinksClient;
}
