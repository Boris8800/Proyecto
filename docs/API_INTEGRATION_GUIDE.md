# Real Booking API Integration Guide

## Overview

This guide explains how to integrate the Swift Cab web clients (Customer App, Driver Portal, Admin Dashboard) with the real booking API backend.

## Quick Start

### 1. Initialize API Clients

```javascript
// Import the API client
import { BookingAPIClient, UserAPIClient, DriverAPIClient } from './api/booking-api-client.js';

// Create instances
const userAPI = new UserAPIClient();
const bookingAPI = new BookingAPIClient();
const driverAPI = new DriverAPIClient(); // For driver portal
```

### 2. Authenticate User

```javascript
// Sign up
const user = await userAPI.signup({
  email: 'user@example.com',
  password: 'secure-password',
  firstName: 'John',
  lastName: 'Doe',
  phone: '+1234567890'
});

// Or login
const user = await userAPI.login({
  email: 'user@example.com',
  password: 'password'
});

// Set token for authenticated requests
bookingAPI.setToken(user.token);
```

### 3. Use API Methods

```javascript
// Get fare estimate
const estimate = await bookingAPI.getEstimate({
  pickupLocation: { lat: 40.7128, lng: -74.0060 },
  dropoffLocation: { lat: 40.7589, lng: -73.9851 },
  rideType: 'economy'
});

// Create booking
const booking = await bookingAPI.createBooking({
  pickupLocation: { lat: 40.7128, lng: -74.0060 },
  dropoffLocation: { lat: 40.7589, lng: -73.9851 },
  passengers: 1,
  rideType: 'economy',
  paymentMethod: 'card'
});
```

## API Classes

### BookingAPIClient

Core API client for booking operations. Used in customer app and admin dashboard.

#### Methods

**createBooking(bookingData)**
- Creates a new booking request
- Parameters:
  - `pickupLocation`: { lat, lng } - Pickup coordinates
  - `dropoffLocation`: { lat, lng } - Dropoff coordinates
  - `scheduledTime`: ISO 8601 timestamp (optional)
  - `passengers`: Number of passengers (default: 1)
  - `rideType`: 'economy', 'comfort', 'premium', 'xl' (default: economy)
  - `specialRequests`: String (optional)
  - `paymentMethod`: 'card', 'cash', 'wallet' (default: card)
  - `promoCode`: String (optional)

- Returns: `{ id, status, estimatedFare, estimatedTime, driver, ... }`

**getBooking(bookingId)**
- Get detailed booking information
- Returns: `{ id, status, pickup, dropoff, driver, fare, ... }`

**cancelBooking(bookingId, reason)**
- Cancel an active booking
- Returns: Updated booking object with status='cancelled'

**acceptBooking(bookingId)** (Driver only)
- Driver accepts a booking
- Returns: Booking with driver info

**rejectBooking(bookingId, reason)** (Driver only)
- Driver rejects a booking
- Returns: Updated booking

**getAvailableDrivers(location, options)**
- Get list of drivers near location
- Parameters:
  - `location`: { lat, lng }
  - `options`: { rideType, passengers }
- Returns: `[{ id, name, rating, vehicle, location, ... }]`

**getEstimate(route)**
- Get fare estimate and ETA
- Returns: `{ fare, baseFare, distanceFare, surgeFactor, estimatedTime, ... }`

**updateTripStatus(bookingId, status, data)**
- Update trip status (driver action)
- Statuses: 'arrived_at_pickup', 'trip_started', 'trip_completed'
- Returns: Updated booking

**rateTrip(bookingId, rating)**
- Submit trip rating and feedback
- Parameters:
  - `driverRating`: 1-5 stars
  - `driverFeedback`: String
  - `driverTips`: Number
- Returns: Booking with rating

**getBookingHistory(options)**
- Get user's booking history
- Parameters:
  - `limit`: Results per page (default: 10)
  - `offset`: Pagination offset (default: 0)
  - `status`: Filter by status
  - `sort`: Sort order
- Returns: `{ bookings: [...], total, pages, ... }`

**getDriverLocation(bookingId)**
- Get real-time driver location
- Returns: `{ latitude, longitude, eta, ... }`

**processPayment(bookingId, paymentData)**
- Process payment for booking
- Parameters:
  - `paymentMethod`: 'card', 'wallet', 'cash'
  - `cardToken`: Stripe token (for card payments)
  - `amount`: Payment amount
  - `currency`: 'USD', 'EUR', etc.
- Returns: `{ transactionId, status, receipt, ... }`

**sendMessage(bookingId, message)**
- Send message to driver/customer
- Returns: `{ messageId, timestamp, ... }`

**getMessages(bookingId)**
- Get conversation history
- Returns: `[{ id, sender, content, timestamp, ... }]`

### UserAPIClient

Handles user authentication and profile management.

#### Methods

**signup(userData)**
- Create new user account
- Parameters: email, password, firstName, lastName, phone
- Returns: `{ id, email, token, profile, ... }`

**login(credentials)**
- Authenticate user
- Parameters: email, password
- Returns: `{ id, email, token, profile, ... }`

**getProfile()**
- Get user profile data
- Returns: User profile object

**updateProfile(data)**
- Update user profile
- Parameters: firstName, lastName, phone, profilePhoto, etc.
- Returns: Updated profile

### DriverAPIClient

Extends BookingAPIClient with driver-specific methods.

#### Methods

**getAvailableBookings(options)**
- Get list of available bookings near driver
- Parameters:
  - `maxDistance`: Max distance in km (default: 10)
  - `minRating`: Minimum customer rating (default: 0)
  - `limit`: Max results (default: 10)
- Returns: `[{ id, pickup, dropoff, passengers, fare, ... }]`

**updateLocation(location, status)**
- Update driver's current location
- Parameters:
  - `location`: { lat, lng, accuracy }
  - `status`: { status, acceptBookings, availability }
- Returns: Confirmation object

**getEarnings(options)**
- Get driver earnings summary
- Parameters:
  - `startDate`: ISO date
  - `endDate`: ISO date
  - `period`: 'today', 'week', 'month', 'custom'
- Returns: `{ total, bookings, averagePerTrip, ... }`

**getRating()**
- Get driver's rating and feedback
- Returns: `{ averageRating, totalRatings, feedbacks, ... }`

## Integration Examples

### Customer App Booking Flow

```javascript
// 1. Initialize
const userAPI = new UserAPIClient();
const bookingAPI = new BookingAPIClient();

// 2. User login
const user = await userAPI.login({
  email: 'customer@example.com',
  password: 'password'
});

bookingAPI.setToken(user.token);

// 3. Get estimate when user enters locations
const estimate = await bookingAPI.getEstimate({
  pickupLocation: pickupCoords,
  dropoffLocation: dropoffCoords,
  rideType: selectedRideType
});

// Show estimate to user
document.getElementById('estimatedFare').textContent = `$${estimate.fare}`;
document.getElementById('estimatedTime').textContent = estimate.estimatedTime;

// 4. User confirms booking
const booking = await bookingAPI.createBooking({
  pickupLocation: pickupCoords,
  dropoffLocation: dropoffCoords,
  passengers: passengersCount,
  rideType: selectedRideType,
  paymentMethod: 'card'
});

// 5. Track driver location in real-time
const locationInterval = setInterval(async () => {
  const driverLocation = await bookingAPI.getDriverLocation(booking.id);
  updateMapMarker(driverLocation);
}, 5000); // Update every 5 seconds

// 6. Wait for completion
let bookingDetails = booking;
while (bookingDetails.status !== 'completed') {
  bookingDetails = await bookingAPI.getBooking(booking.id);
  updateUI(bookingDetails);
  
  if (bookingDetails.status === 'completed') {
    clearInterval(locationInterval);
    break;
  }
  
  await new Promise(r => setTimeout(r, 2000)); // Check every 2 seconds
}

// 7. Process payment
const payment = await bookingAPI.processPayment(booking.id, {
  paymentMethod: 'card',
  cardToken: stripeToken,
  amount: booking.fare
});

// 8. Rate trip
await bookingAPI.rateTrip(booking.id, {
  driverRating: 5,
  driverFeedback: 'Excellent driver!',
  driverTips: 2.50
});
```

### Driver Portal Booking Flow

```javascript
// 1. Initialize
const userAPI = new UserAPIClient();
const driverAPI = new DriverAPIClient();

// 2. Driver login
const driver = await userAPI.login({
  email: 'driver@example.com',
  password: 'password'
});

driverAPI.setToken(driver.token);

// 3. Go online
await driverAPI.updateLocation(
  { lat: currentLat, lng: currentLng },
  { status: 'online', acceptBookings: true }
);

// 4. Start location tracking
setInterval(async () => {
  const location = await getDeviceLocation();
  await driverAPI.updateLocation(location);
}, 10000); // Every 10 seconds

// 5. Poll for available bookings
const bookingCheckInterval = setInterval(async () => {
  const availableBookings = await driverAPI.getAvailableBookings({
    maxDistance: 5
  });
  
  if (availableBookings.length > 0) {
    showBookingNotification(availableBookings[0]);
  }
}, 5000); // Check every 5 seconds

// 6. Accept a booking
const selectedBooking = availableBookings[0];
const accepted = await driverAPI.acceptBooking(selectedBooking.id);

// 7. Navigate to pickup
showNavigation(accepted.pickup);

// 8. Update trip status
await driverAPI.updateTripStatus(accepted.id, 'arrived_at_pickup');

// Notify customer
await driverAPI.sendMessage(accepted.id, 'Arrived at pickup location');

// 9. Start trip
await driverAPI.updateTripStatus(accepted.id, 'trip_started');

// 10. Complete trip
const { distance, duration } = getGPSData();
await driverAPI.updateTripStatus(accepted.id, 'trip_completed', {
  fare: accepted.fare,
  distance: distance,
  duration: duration
});

// 11. View earnings
const dailyEarnings = await driverAPI.getEarnings({
  period: 'today'
});

console.log(`Today's earnings: $${dailyEarnings.total}`);
```

### Admin Dashboard Integration

```javascript
// 1. Initialize
const userAPI = new UserAPIClient();
const bookingAPI = new BookingAPIClient();

// 2. Admin login
const admin = await userAPI.login({
  email: 'admin@example.com',
  password: 'password'
});

bookingAPI.setToken(admin.token);

// 3. Load recent bookings
const recentBookings = await bookingAPI.getBookingHistory({
  limit: 50,
  sort: '-createdAt'
});

// 4. Display in table
displayBookingsTable(recentBookings.bookings);

// 5. Allow cancellation
async function cancelBooking(bookingId) {
  await bookingAPI.cancelBooking(bookingId, 'Admin cancellation');
  refreshBookingsList();
}

// 6. View booking details
async function viewBookingDetails(bookingId) {
  const booking = await bookingAPI.getBooking(bookingId);
  showDetailsModal(booking);
}

// 7. Track driver location
async function trackDriver(bookingId) {
  setInterval(async () => {
    const location = await bookingAPI.getDriverLocation(bookingId);
    updateMapView(location);
  }, 5000);
}
```

## Error Handling

All API methods throw exceptions on error. Always use try-catch:

```javascript
try {
  const booking = await bookingAPI.createBooking({
    pickupLocation: { lat: 40.7128, lng: -74.0060 },
    dropoffLocation: { lat: 40.7589, lng: -73.9851 },
    rideType: 'economy'
  });
} catch (error) {
  if (error.message.includes('Unauthorized')) {
    // Redirect to login
    window.location.href = '/login';
  } else if (error.message.includes('Too many requests')) {
    // Show rate limit message
    alert('Too many requests. Please try again later.');
  } else {
    // Show generic error
    console.error('Booking failed:', error.message);
  }
}
```

## Configuration

### API Base URL
```javascript
// Default: http://localhost:3000/api
// For production, set via environment variable:
const BASE_API_URL = process.env.API_BASE_URL || 'https://api.yourdomain.com/api';
```

### Request Timeout
```javascript
const REQUEST_TIMEOUT = 10000; // 10 seconds
```

### Retry Configuration
```javascript
const MAX_RETRIES = 3;
const RETRY_DELAY = 1000; // 1 second (with exponential backoff)
```

## Real-Time Updates

### WebSocket Connection (Optional)
For real-time updates, consider adding WebSocket support:

```javascript
const socket = io(BASE_API_URL);

// Listen for booking updates
socket.on('booking_status_changed', (bookingData) => {
  updateBookingUI(bookingData);
});

// Listen for driver location updates
socket.on('driver_location_updated', (locationData) => {
  updateMapMarker(locationData);
});
```

## Testing API Integration

### Using curl (Command Line)

```bash
# Test booking API
curl -X POST http://localhost:3000/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "pickupLocation": {"lat": 40.7128, "lng": -74.0060},
    "dropoffLocation": {"lat": 40.7589, "lng": -73.9851},
    "passengers": 1,
    "rideType": "economy"
  }'

# Test estimate endpoint
curl -X POST http://localhost:3000/api/bookings/estimate \
  -H "Content-Type: application/json" \
  -d '{
    "pickupLocation": {"lat": 40.7128, "lng": -74.0060},
    "dropoffLocation": {"lat": 40.7589, "lng": -73.9851},
    "rideType": "economy"
  }'

# Test authentication
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password"
  }'
```

### Using Postman

1. Import the API collection
2. Set environment variables (token, base URL)
3. Test endpoints individually
4. Create test scenarios for common workflows

## Production Deployment

### 1. Environment Variables
```bash
# .env
API_BASE_URL=https://api.yourdomain.com/api
API_TIMEOUT=10000
API_MAX_RETRIES=3
NODE_ENV=production
```

### 2. Token Storage
```javascript
// Secure token storage (using httpOnly cookies or secure localStorage)
const storeToken = (token) => {
  // Option 1: httpOnly cookie (recommended)
  document.cookie = `auth_token=${token}; Secure; SameSite=Strict`;
  
  // Option 2: Secure localStorage
  // localStorage.setItem('auth_token', token);
};

const getToken = () => {
  // Retrieve from cookie or localStorage
  return getCookie('auth_token') || localStorage.getItem('auth_token');
};
```

### 3. CORS Configuration
Ensure CORS is properly configured on backend:

```javascript
// Backend (Node.js/Express)
const cors = require('cors');
app.use(cors({
  origin: ['https://yourdomain.com', 'https://admin.yourdomain.com'],
  credentials: true
}));
```

### 4. Rate Limiting
Respect rate limits from backend:
- General API: 30 req/min per IP
- Auth endpoints: 5 attempts/15 min
- Booking endpoints: 10 req/min

## Troubleshooting

### Common Issues

**Q: "Unauthorized" error**
- A: Token expired or invalid. Re-authenticate with login.

**Q: "Too many requests" error**
- A: Rate limit exceeded. Implement exponential backoff.

**Q: Request timeout**
- A: Increase `REQUEST_TIMEOUT` or check network connectivity.

**Q: CORS errors**
- A: Check backend CORS configuration and allowed origins.

**Q: Real-time updates not working**
- A: Ensure WebSocket connections are allowed through firewalls/proxies.

## Support & Documentation

- **API Documentation**: https://api.yourdomain.com/docs
- **Status Page**: https://status.yourdomain.com
- **Support Email**: api-support@yourdomain.com
- **GitHub Issues**: https://github.com/yourorg/api/issues

---

**Last Updated**: 2025-12-22
**Version**: 1.0
**Status**: ✅ Production Ready
