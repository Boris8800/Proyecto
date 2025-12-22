#!/usr/bin/env node

/**
 * Real Booking API Integration Module
 * Connects web clients to the booking backend API
 * 
 * Features:
 * - Booking creation and management
 * - Real-time status updates
 * - Payment processing
 * - Driver matching
 * - Trip tracking
 * - User authentication
 */

const BASE_API_URL = process.env.API_BASE_URL || 'http://localhost:3000/api';
const REQUEST_TIMEOUT = 10000; // 10 seconds
const MAX_RETRIES = 3;
const RETRY_DELAY = 1000; // 1 second

/**
 * Booking API Client
 * Handles all booking-related API operations
 */
class BookingAPIClient {
  constructor(token = null) {
    this.token = token;
    this.baseURL = BASE_API_URL;
    this.timeout = REQUEST_TIMEOUT;
    this.maxRetries = MAX_RETRIES;
  }

  /**
   * Set authentication token
   * @param {string} token JWT token
   */
  setToken(token) {
    this.token = token;
  }

  /**
   * Get common request headers
   * @returns {object} Headers object
   */
  getHeaders() {
    const headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };

    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    return headers;
  }

  /**
   * Make API request with retry logic
   * @param {string} endpoint API endpoint
   * @param {string} method HTTP method
   * @param {object} data Request body
   * @returns {Promise} Response data
   */
  async request(endpoint, method = 'GET', data = null) {
    let lastError;

    for (let attempt = 1; attempt <= this.maxRetries; attempt++) {
      try {
        const options = {
          method,
          headers: this.getHeaders(),
          timeout: this.timeout
        };

        if (data && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
          options.body = JSON.stringify(data);
        }

        const response = await fetch(`${this.baseURL}${endpoint}`, options);

        if (!response.ok) {
          if (response.status === 401) {
            throw new Error('Unauthorized - invalid or expired token');
          }
          if (response.status === 403) {
            throw new Error('Forbidden - insufficient permissions');
          }
          if (response.status === 429) {
            throw new Error('Too many requests - rate limited');
          }
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const responseData = await response.json();
        return responseData;

      } catch (error) {
        lastError = error;

        // Don't retry on client errors (4xx) except 429
        if (error.message.includes('HTTP 4') && !error.message.includes('429')) {
          throw error;
        }

        // Retry with exponential backoff
        if (attempt < this.maxRetries) {
          const delay = this.RETRY_DELAY * Math.pow(2, attempt - 1);
          console.log(`Retry attempt ${attempt}/${this.maxRetries} after ${delay}ms...`);
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }

    throw new Error(`API request failed after ${this.maxRetries} retries: ${lastError.message}`);
  }

  /**
   * CREATE BOOKING
   * Create a new booking request
   * 
   * @param {object} bookingData Booking details
   * @returns {Promise<object>} Created booking object
   * 
   * @example
   * const booking = await api.createBooking({
   *   pickupLocation: { lat: 40.7128, lng: -74.0060 },
   *   dropoffLocation: { lat: 40.7589, lng: -73.9851 },
   *   scheduledTime: '2025-12-22T18:00:00Z',
   *   passengers: 1,
   *   rideType: 'economy'
   * });
   */
  async createBooking(bookingData) {
    return this.request('/bookings', 'POST', {
      pickupLocation: bookingData.pickupLocation,
      dropoffLocation: bookingData.dropoffLocation,
      scheduledTime: bookingData.scheduledTime || new Date().toISOString(),
      passengers: bookingData.passengers || 1,
      rideType: bookingData.rideType || 'economy',
      specialRequests: bookingData.specialRequests || '',
      paymentMethod: bookingData.paymentMethod || 'card',
      promoCode: bookingData.promoCode || null
    });
  }

  /**
   * GET BOOKING DETAILS
   * Retrieve booking information
   * 
   * @param {string} bookingId Booking ID
   * @returns {Promise<object>} Booking details
   * 
   * @example
   * const booking = await api.getBooking('booking-123');
   * console.log(booking.status); // 'confirmed', 'driver_assigned', 'in_progress', 'completed'
   */
  async getBooking(bookingId) {
    return this.request(`/bookings/${bookingId}`, 'GET');
  }

  /**
   * CANCEL BOOKING
   * Cancel an existing booking
   * 
   * @param {string} bookingId Booking ID
   * @param {string} reason Cancellation reason
   * @returns {Promise<object>} Updated booking object
   * 
   * @example
   * const updated = await api.cancelBooking('booking-123', 'Customer request');
   */
  async cancelBooking(bookingId, reason = '') {
    return this.request(`/bookings/${bookingId}/cancel`, 'POST', { reason });
  }

  /**
   * ACCEPT DRIVER BOOKING
   * Driver accepts a booking
   * 
   * @param {string} bookingId Booking ID
   * @returns {Promise<object>} Updated booking with driver info
   * 
   * @example
   * const booking = await api.acceptBooking('booking-123');
   */
  async acceptBooking(bookingId) {
    return this.request(`/bookings/${bookingId}/accept`, 'POST');
  }

  /**
   * REJECT DRIVER BOOKING
   * Driver rejects a booking
   * 
   * @param {string} bookingId Booking ID
   * @param {string} reason Rejection reason
   * @returns {Promise<object>} Updated booking
   * 
   * @example
   * const booking = await api.rejectBooking('booking-123', 'Too far away');
   */
  async rejectBooking(bookingId, reason = '') {
    return this.request(`/bookings/${bookingId}/reject`, 'POST', { reason });
  }

  /**
   * GET AVAILABLE DRIVERS
   * Get list of available drivers for a route
   * 
   * @param {object} location Pickup location {lat, lng}
   * @param {object} options Additional options
   * @returns {Promise<array>} List of available drivers
   * 
   * @example
   * const drivers = await api.getAvailableDrivers(
   *   { lat: 40.7128, lng: -74.0060 },
   *   { rideType: 'economy', passengers: 2 }
   * );
   */
  async getAvailableDrivers(location, options = {}) {
    const params = new URLSearchParams({
      latitude: location.lat,
      longitude: location.lng,
      rideType: options.rideType || 'economy',
      passengers: options.passengers || 1
    });

    return this.request(`/drivers/available?${params.toString()}`, 'GET');
  }

  /**
   * GET TRIP ESTIMATE
   * Get fare estimate and ETA
   * 
   * @param {object} route Route details
   * @returns {Promise<object>} Estimate with fare and ETA
   * 
   * @example
   * const estimate = await api.getEstimate({
   *   pickupLocation: { lat: 40.7128, lng: -74.0060 },
   *   dropoffLocation: { lat: 40.7589, lng: -73.9851 },
   *   rideType: 'economy'
   * });
   * console.log(estimate.fare); // $15.50
   * console.log(estimate.estimatedTime); // "12 mins"
   */
  async getEstimate(route) {
    return this.request('/bookings/estimate', 'POST', {
      pickupLocation: route.pickupLocation,
      dropoffLocation: route.dropoffLocation,
      rideType: route.rideType || 'economy',
      passengers: route.passengers || 1
    });
  }

  /**
   * UPDATE TRIP STATUS
   * Update trip status (used by drivers)
   * 
   * @param {string} bookingId Booking ID
   * @param {string} status New status
   * @param {object} data Additional data
   * @returns {Promise<object>} Updated booking
   * 
   * @example
   * await api.updateTripStatus('booking-123', 'arrived_at_pickup');
   * await api.updateTripStatus('booking-123', 'trip_started');
   * await api.updateTripStatus('booking-123', 'trip_completed', {
   *   fare: 15.50,
   *   distance: 3.2,
   *   duration: 720
   * });
   */
  async updateTripStatus(bookingId, status, data = {}) {
    return this.request(`/bookings/${bookingId}/status`, 'PATCH', {
      status,
      ...data
    });
  }

  /**
   * SUBMIT TRIP RATING
   * Submit rating and feedback after trip
   * 
   * @param {string} bookingId Booking ID
   * @param {object} rating Rating details
   * @returns {Promise<object>} Updated booking
   * 
   * @example
   * await api.rateTrip('booking-123', {
   *   driverRating: 5,
   *   driverFeedback: 'Great driver, very professional',
   *   driverTips: 2.00
   * });
   */
  async rateTrip(bookingId, rating) {
    return this.request(`/bookings/${bookingId}/rate`, 'POST', {
      driverRating: rating.driverRating,
      driverFeedback: rating.driverFeedback || '',
      driverTips: rating.driverTips || 0,
      safetyRating: rating.safetyRating || rating.driverRating,
      cleanliness: rating.cleanliness || rating.driverRating
    });
  }

  /**
   * GET BOOKING HISTORY
   * Get user's booking history
   * 
   * @param {object} options Pagination and filtering options
   * @returns {Promise<object>} Bookings list with pagination
   * 
   * @example
   * const history = await api.getBookingHistory({
   *   limit: 10,
   *   offset: 0,
   *   status: 'completed'
   * });
   */
  async getBookingHistory(options = {}) {
    const params = new URLSearchParams({
      limit: options.limit || 10,
      offset: options.offset || 0,
      status: options.status || 'all',
      sort: options.sort || '-createdAt'
    });

    return this.request(`/bookings?${params.toString()}`, 'GET');
  }

  /**
   * GET DRIVER LOCATION
   * Get real-time driver location
   * 
   * @param {string} bookingId Booking ID
   * @returns {Promise<object>} Driver location and ETA
   * 
   * @example
   * const location = await api.getDriverLocation('booking-123');
   * console.log(location.latitude, location.longitude);
   * console.log(location.eta); // "3 mins"
   */
  async getDriverLocation(bookingId) {
    return this.request(`/bookings/${bookingId}/driver/location`, 'GET');
  }

  /**
   * PROCESS PAYMENT
   * Process booking payment
   * 
   * @param {string} bookingId Booking ID
   * @param {object} paymentData Payment details
   * @returns {Promise<object>} Payment confirmation
   * 
   * @example
   * const payment = await api.processPayment('booking-123', {
   *   paymentMethod: 'card',
   *   cardToken: 'tok_visa',
   *   amount: 15.50
   * });
   */
  async processPayment(bookingId, paymentData) {
    return this.request(`/bookings/${bookingId}/payment`, 'POST', {
      paymentMethod: paymentData.paymentMethod,
      cardToken: paymentData.cardToken || null,
      amount: paymentData.amount,
      currency: paymentData.currency || 'USD'
    });
  }

  /**
   * GET PAYMENT STATUS
   * Check payment status
   * 
   * @param {string} bookingId Booking ID
   * @returns {Promise<object>} Payment status
   */
  async getPaymentStatus(bookingId) {
    return this.request(`/bookings/${bookingId}/payment/status`, 'GET');
  }

  /**
   * REQUEST REFUND
   * Request refund for a booking
   * 
   * @param {string} bookingId Booking ID
   * @param {object} refundData Refund details
   * @returns {Promise<object>} Refund request
   * 
   * @example
   * const refund = await api.requestRefund('booking-123', {
   *   reason: 'Driver cancellation',
   *   amount: 15.50
   * });
   */
  async requestRefund(bookingId, refundData) {
    return this.request(`/bookings/${bookingId}/refund`, 'POST', {
      reason: refundData.reason,
      amount: refundData.amount,
      description: refundData.description || ''
    });
  }

  /**
   * SEND MESSAGE
   * Send message to driver/customer
   * 
   * @param {string} bookingId Booking ID
   * @param {string} message Message text
   * @returns {Promise<object>} Message confirmation
   * 
   * @example
   * await api.sendMessage('booking-123', 'Running 5 minutes late');
   */
  async sendMessage(bookingId, message) {
    return this.request(`/bookings/${bookingId}/messages`, 'POST', {
      content: message,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * GET MESSAGES
   * Get all messages for a booking
   * 
   * @param {string} bookingId Booking ID
   * @returns {Promise<array>} List of messages
   */
  async getMessages(bookingId) {
    return this.request(`/bookings/${bookingId}/messages`, 'GET');
  }
}

/**
 * User API Client
 * Handles user authentication and profile management
 */
class UserAPIClient {
  constructor() {
    this.baseURL = BASE_API_URL;
    this.token = null;
  }

  /**
   * SIGN UP
   * Create new user account
   * 
   * @param {object} userData User registration data
   * @returns {Promise<object>} User object with token
   * 
   * @example
   * const user = await userAPI.signup({
   *   email: 'user@example.com',
   *   password: 'secure-password',
   *   firstName: 'John',
   *   lastName: 'Doe',
   *   phone: '+1234567890'
   * });
   */
  async signup(userData) {
    const response = await fetch(`${this.baseURL}/auth/signup`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(userData)
    });

    if (!response.ok) throw new Error('Signup failed');

    const data = await response.json();
    this.token = data.token;
    return data;
  }

  /**
   * LOGIN
   * Authenticate user
   * 
   * @param {object} credentials Login credentials
   * @returns {Promise<object>} User object with token
   * 
   * @example
   * const user = await userAPI.login({
   *   email: 'user@example.com',
   *   password: 'password'
   * });
   */
  async login(credentials) {
    const response = await fetch(`${this.baseURL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(credentials)
    });

    if (!response.ok) throw new Error('Login failed');

    const data = await response.json();
    this.token = data.token;
    return data;
  }

  /**
   * GET PROFILE
   * Get user profile
   * 
   * @returns {Promise<object>} User profile
   */
  async getProfile() {
    const response = await fetch(`${this.baseURL}/users/profile`, {
      headers: {
        'Authorization': `Bearer ${this.token}`
      }
    });

    if (!response.ok) throw new Error('Failed to get profile');
    return response.json();
  }

  /**
   * UPDATE PROFILE
   * Update user profile
   * 
   * @param {object} data Profile data to update
   * @returns {Promise<object>} Updated profile
   */
  async updateProfile(data) {
    const response = await fetch(`${this.baseURL}/users/profile`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.token}`
      },
      body: JSON.stringify(data)
    });

    if (!response.ok) throw new Error('Failed to update profile');
    return response.json();
  }
}

/**
 * Driver API Client
 * Handles driver-specific operations
 */
class DriverAPIClient extends BookingAPIClient {
  /**
   * GET AVAILABLE BOOKINGS
   * Get list of available bookings for driver
   * 
   * @param {object} options Filter options
   * @returns {Promise<array>} List of available bookings
   * 
   * @example
   * const bookings = await driverAPI.getAvailableBookings({
   *   maxDistance: 5, // km
   *   minRating: 4.5
   * });
   */
  async getAvailableBookings(options = {}) {
    const params = new URLSearchParams({
      maxDistance: options.maxDistance || 10,
      minRating: options.minRating || 0,
      limit: options.limit || 10
    });

    return this.request(`/bookings/available?${params.toString()}`, 'GET');
  }

  /**
   * UPDATE DRIVER LOCATION
   * Update driver's current location
   * 
   * @param {object} location Location {lat, lng}
   * @param {object} status Status information
   * @returns {Promise<object>} Confirmation
   * 
   * @example
   * await driverAPI.updateLocation(
   *   { lat: 40.7128, lng: -74.0060 },
   *   { status: 'online', acceptBookings: true }
   * );
   */
  async updateLocation(location, status = {}) {
    return this.request('/drivers/location', 'POST', {
      latitude: location.lat,
      longitude: location.lng,
      accuracy: location.accuracy || null,
      ...status
    });
  }

  /**
   * GET DRIVER EARNINGS
   * Get driver earnings summary
   * 
   * @param {object} options Date range and filters
   * @returns {Promise<object>} Earnings data
   * 
   * @example
   * const earnings = await driverAPI.getEarnings({
   *   startDate: '2025-12-01',
   *   endDate: '2025-12-31'
   * });
   */
  async getEarnings(options = {}) {
    const params = new URLSearchParams({
      startDate: options.startDate || '',
      endDate: options.endDate || '',
      period: options.period || 'custom'
    });

    return this.request(`/drivers/earnings?${params.toString()}`, 'GET');
  }

  /**
   * GET DRIVER RATING
   * Get driver's rating and feedback
   * 
   * @returns {Promise<object>} Rating data
   * 
   * @example
   * const rating = await driverAPI.getRating();
   * console.log(rating.averageRating); // 4.8
   * console.log(rating.totalRatings); // 250
   */
  async getRating() {
    return this.request('/drivers/rating', 'GET');
  }
}

// Export for use in Node.js/browser
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    BookingAPIClient,
    UserAPIClient,
    DriverAPIClient,
    BASE_API_URL,
    REQUEST_TIMEOUT,
    MAX_RETRIES
  };
}

/**
 * USAGE EXAMPLE - Customer App
 * 
 * // Initialize
 * const userAPI = new UserAPIClient();
 * const bookingAPI = new BookingAPIClient();
 * 
 * // Sign up
 * const user = await userAPI.signup({
 *   email: 'customer@example.com',
 *   password: 'password123',
 *   firstName: 'John',
 *   lastName: 'Doe',
 *   phone: '+1234567890'
 * });
 * 
 * // Set token for booking API
 * bookingAPI.setToken(user.token);
 * 
 * // Get fare estimate
 * const estimate = await bookingAPI.getEstimate({
 *   pickupLocation: { lat: 40.7128, lng: -74.0060 },
 *   dropoffLocation: { lat: 40.7589, lng: -73.9851 },
 *   rideType: 'economy'
 * });
 * 
 * // Create booking
 * const booking = await bookingAPI.createBooking({
 *   pickupLocation: { lat: 40.7128, lng: -74.0060 },
 *   dropoffLocation: { lat: 40.7589, lng: -73.9851 },
 *   passengers: 1,
 *   rideType: 'economy',
 *   paymentMethod: 'card'
 * });
 * 
 * // Track driver
 * const location = await bookingAPI.getDriverLocation(booking.id);
 * 
 * // Rate trip
 * await bookingAPI.rateTrip(booking.id, {
 *   driverRating: 5,
 *   driverFeedback: 'Great driver!',
 *   driverTips: 2.00
 * });
 * 
 * 
 * USAGE EXAMPLE - Driver App
 * 
 * // Initialize
 * const userAPI = new UserAPIClient();
 * const driverAPI = new DriverAPIClient();
 * 
 * // Login
 * const user = await userAPI.login({
 *   email: 'driver@example.com',
 *   password: 'password123'
 * });
 * 
 * driverAPI.setToken(user.token);
 * 
 * // Go online
 * await driverAPI.updateLocation(
 *   { lat: 40.7128, lng: -74.0060 },
 *   { status: 'online', acceptBookings: true }
 * );
 * 
 * // Get available bookings
 * const bookings = await driverAPI.getAvailableBookings({
 *   maxDistance: 5
 * });
 * 
 * // Accept booking
 * const accepted = await driverAPI.acceptBooking(bookings[0].id);
 * 
 * // Update trip status
 * await driverAPI.updateTripStatus(accepted.id, 'arrived_at_pickup');
 * await driverAPI.updateTripStatus(accepted.id, 'trip_started');
 * 
 * // Update location in real-time
 * setInterval(async () => {
 *   const location = getCurrentLocation();
 *   await driverAPI.updateLocation(location);
 * }, 10000); // Every 10 seconds
 * 
 * // Complete trip
 * await driverAPI.updateTripStatus(accepted.id, 'trip_completed', {
 *   fare: 15.50,
 *   distance: 3.2,
 *   duration: 720
 * });
 * 
 * // Get earnings
 * const earnings = await driverAPI.getEarnings({
 *   startDate: '2025-12-01',
 *   endDate: '2025-12-31'
 * });
 */
