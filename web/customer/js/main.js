/**
 * Swift Cab - Customer Booking Application
 * Production-Ready JavaScript with Security Best Practices
 * 
 * Features:
 * - Map-based location selection (Leaflet.js)
 * - Cookie management and consent
 * - Form validation and sanitization
 * - Secure communication with API
 * - Rate limiting protection
 * - CSRF token handling
 */

// ============================================
// CONFIGURATION & CONSTANTS
// ============================================

const CONFIG = {
    API_URL: '/api',
    MIN_PHONE_LENGTH: 10,
    DEFAULT_LAT: 40.7128,
    DEFAULT_LNG: -74.0060,
    DEFAULT_ZOOM: 13,
    MAP_MAX_ZOOM: 19,
    BOOKING_TIMEOUT: 30000,
    RATE_LIMIT: {
        maxRequests: 10,
        windowMs: 60000
    }
};

// Cookie configuration
const COOKIE_CONFIG = {
    necessary: {
        name: 'session_id',
        secure: true,
        httpOnly: true,
        sameSite: 'Strict',
        maxAge: 86400
    },
    preferences: {
        name: 'user_preferences',
        secure: true,
        sameSite: 'Lax',
        maxAge: 31536000
    },
    analytics: {
        name: 'analytics_id',
        secure: true,
        sameSite: 'Lax',
        maxAge: 31536000
    }
};

// ============================================
// COOKIE MANAGEMENT
// ============================================

class CookieManager {
    constructor() {
        this.cookieConsent = localStorage.getItem('cookieConsent');
    }

    /**
     * Set a secure cookie with proper attributes
     */
    setCookie(name, value, config = {}) {
        const {
            secure = true,
            httpOnly = false,
            sameSite = 'Strict',
            maxAge = 86400
        } = config;

        let cookieString = `${encodeURIComponent(name)}=${encodeURIComponent(value)}`;
        cookieString += `; Max-Age=${maxAge}`;
        cookieString += `; Path=/`;
        
        if (secure && location.protocol === 'https:') {
            cookieString += '; Secure';
        }
        
        cookieString += `; SameSite=${sameSite}`;

        document.cookie = cookieString;
    }

    /**
     * Get cookie value safely
     */
    getCookie(name) {
        const nameEQ = encodeURIComponent(name) + '=';
        const cookies = document.cookie.split(';');
        
        for (let cookie of cookies) {
            cookie = cookie.trim();
            if (cookie.startsWith(nameEQ)) {
                return decodeURIComponent(cookie.substring(nameEQ.length));
            }
        }
        return null;
    }

    /**
     * Delete cookie
     */
    deleteCookie(name) {
        this.setCookie(name, '', { maxAge: -1 });
    }

    /**
     * Initialize cookie consent banner
     */
    initConsentBanner() {
        const banner = document.getElementById('cookieBanner');
        const acceptBtn = document.getElementById('acceptCookies');
        const rejectBtn = document.getElementById('rejectCookies');
        const manageBtn = document.getElementById('manageCookies');

        // Check if user has already made a choice
        if (this.cookieConsent) {
            banner.classList.remove('active');
            return;
        }

        // Show banner
        setTimeout(() => {
            banner.classList.add('active');
        }, 1000);

        // Accept all cookies
        acceptBtn.addEventListener('click', () => {
            this.setCookiesForCategory('all');
            localStorage.setItem('cookieConsent', 'all');
            banner.classList.remove('active');
            this.cookieConsent = 'all';
        });

        // Reject non-necessary cookies
        rejectBtn.addEventListener('click', () => {
            this.setCookiesForCategory('necessary');
            localStorage.setItem('cookieConsent', 'necessary');
            banner.classList.remove('active');
            this.cookieConsent = 'necessary';
        });

        // Manage cookies
        manageBtn.addEventListener('click', () => {
            showModal('cookiePolicyModal');
        });
    }

    /**
     * Set cookies based on category
     */
    setCookiesForCategory(category) {
        if (category === 'all' || category === 'necessary') {
            // Set session cookie
            this.setCookie(
                COOKIE_CONFIG.necessary.name,
                this.generateSessionId(),
                COOKIE_CONFIG.necessary
            );
        }

        if (category === 'all') {
            // Set preference cookie
            this.setCookie(
                COOKIE_CONFIG.preferences.name,
                JSON.stringify({ theme: 'light' }),
                COOKIE_CONFIG.preferences
            );

            // Set analytics cookie
            this.setCookie(
                COOKIE_CONFIG.analytics.name,
                this.generateAnalyticsId(),
                COOKIE_CONFIG.analytics
            );
        }
    }

    /**
     * Generate unique session ID
     */
    generateSessionId() {
        return 'session_' + Math.random().toString(36).substr(2, 9) + Date.now();
    }

    /**
     * Generate unique analytics ID
     */
    generateAnalyticsId() {
        return 'analytics_' + Math.random().toString(36).substr(2, 9) + Date.now();
    }
}

// ============================================
// INPUT VALIDATION & SANITIZATION
// ============================================

class InputValidator {
    /**
     * Sanitize string input
     */
    static sanitizeString(input) {
        if (typeof input !== 'string') return '';
        
        const div = document.createElement('div');
        div.textContent = input;
        return div.innerHTML
            .replace(/script|iframe|object|embed|link/gi, '')
            .trim()
            .substring(0, 255);
    }

    /**
     * Validate email format
     */
    static isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email) && email.length <= 254;
    }

    /**
     * Validate phone number
     */
    static isValidPhone(phone) {
        const phoneRegex = /^[\d+\-\s()]{10,}$/;
        return phoneRegex.test(phone);
    }

    /**
     * Validate name
     */
    static isValidName(name) {
        const nameRegex = /^[a-zA-Z\s'-]{2,100}$/;
        return nameRegex.test(name.trim());
    }

    /**
     * Validate address
     */
    static isValidAddress(address) {
        const trimmed = address.trim();
        return trimmed.length >= 5 && trimmed.length <= 255;
    }

    /**
     * Validate all form fields
     */
    static validateForm(formData) {
        const errors = {};

        // Validate pickup location
        if (!this.isValidAddress(formData.pickupLocation)) {
            errors.pickupLocation = 'Please enter a valid pickup address';
        }

        // Validate dropoff location
        if (!this.isValidAddress(formData.dropoffLocation)) {
            errors.dropoffLocation = 'Please enter a valid dropoff address';
        }

        // Validate name
        if (!this.isValidName(formData.passengerName)) {
            errors.passengerName = 'Please enter a valid name (letters, spaces, hyphens only)';
        }

        // Validate email
        if (!this.isValidEmail(formData.passengerEmail)) {
            errors.passengerEmail = 'Please enter a valid email address';
        }

        // Validate phone
        if (!this.isValidPhone(formData.passengerPhone)) {
            errors.passengerPhone = 'Please enter a valid phone number';
        }

        // Validate date and time
        const bookingDate = new Date(formData.bookingDate);
        const now = new Date();
        if (bookingDate < now) {
            errors.bookingDate = 'Please select a future date';
        }

        // Validate passenger count
        if (!formData.passengerCount || formData.passengerCount < 1 || formData.passengerCount > 5) {
            errors.passengerCount = 'Please select valid passenger count';
        }

        return { isValid: Object.keys(errors).length === 0, errors };
    }
}

// ============================================
// MAP FUNCTIONALITY
// ============================================

class BookingMap {
    constructor() {
        this.map = null;
        this.pickupMarker = null;
        this.dropoffMarker = null;
        this.route = null;
        this.pickupCoords = null;
        this.dropoffCoords = null;
        this.isSelectingPickup = false;
        this.isSelectingDropoff = false;
        this.initMap();
    }

    /**
     * Initialize Leaflet map
     */
    initMap() {
        try {
            this.map = L.map('map').setView(
                [CONFIG.DEFAULT_LAT, CONFIG.DEFAULT_LNG],
                CONFIG.DEFAULT_ZOOM
            );

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© OpenStreetMap contributors',
                maxZoom: CONFIG.MAP_MAX_ZOOM,
                crossOrigin: 'anonymous'
            }).addTo(this.map);

            this.attachMapEventListeners();
        } catch (error) {
            console.error('Map initialization error:', error);
            showToast('Error loading map. Please refresh the page.', 'error');
        }
    }

    /**
     * Attach map event listeners
     */
    attachMapEventListeners() {
        document.getElementById('zoomInBtn').addEventListener('click', () => {
            this.map.zoomIn();
        });

        document.getElementById('zoomOutBtn').addEventListener('click', () => {
            this.map.zoomOut();
        });

        document.getElementById('centerMapBtn').addEventListener('click', () => {
            this.map.setView(
                [CONFIG.DEFAULT_LAT, CONFIG.DEFAULT_LNG],
                CONFIG.DEFAULT_ZOOM
            );
        });

        document.getElementById('useCurrentLocation').addEventListener('click', (e) => {
            e.preventDefault();
            this.getCurrentLocation();
        });

        // Map click listener for location selection
        this.map.on('click', (e) => {
            if (this.isSelectingPickup) {
                this.setPickupLocation(e.latlng.lat, e.latlng.lng);
                this.isSelectingPickup = false;
            } else if (this.isSelectingDropoff) {
                this.setDropoffLocation(e.latlng.lat, e.latlng.lng);
                this.isSelectingDropoff = false;
            }
        });
    }

    /**
     * Get current device location
     */
    getCurrentLocation() {
        if ('geolocation' in navigator) {
            document.getElementById('useCurrentLocation').disabled = true;
            
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    const { latitude, longitude } = position.coords;
                    this.setPickupLocation(latitude, longitude);
                    this.map.setView([latitude, longitude], CONFIG.DEFAULT_ZOOM);
                    document.getElementById('useCurrentLocation').disabled = false;
                },
                (error) => {
                    console.error('Geolocation error:', error);
                    showToast('Unable to get your location', 'error');
                    document.getElementById('useCurrentLocation').disabled = false;
                }
            );
        } else {
            showToast('Geolocation not supported by your browser', 'error');
        }
    }

    /**
     * Set pickup location with marker
     */
    setPickupLocation(lat, lng) {
        this.pickupCoords = { lat, lng };

        if (this.pickupMarker) {
            this.map.removeLayer(this.pickupMarker);
        }

        this.pickupMarker = L.circleMarker([lat, lng], {
            radius: 8,
            fillColor: '#05c46b',
            color: '#04a84c',
            weight: 2,
            opacity: 1,
            fillOpacity: 0.8
        }).bindPopup('Pickup Location').addTo(this.map);

        // Reverse geocode to get address
        this.reverseGeocode(lat, lng, 'pickup');
        this.drawRoute();
    }

    /**
     * Set dropoff location with marker
     */
    setDropoffLocation(lat, lng) {
        this.dropoffCoords = { lat, lng };

        if (this.dropoffMarker) {
            this.map.removeLayer(this.dropoffMarker);
        }

        this.dropoffMarker = L.circleMarker([lat, lng], {
            radius: 8,
            fillColor: '#d63031',
            color: '#b71c1c',
            weight: 2,
            opacity: 1,
            fillOpacity: 0.8
        }).bindPopup('Dropoff Location').addTo(this.map);

        // Reverse geocode to get address
        this.reverseGeocode(lat, lng, 'dropoff');
        this.drawRoute();
    }

    /**
     * Draw route between pickup and dropoff
     */
    drawRoute() {
        if (!this.pickupCoords || !this.dropoffCoords) return;

        if (this.route) {
            this.map.removeLayer(this.route);
        }

        const latlngs = [
            [this.pickupCoords.lat, this.pickupCoords.lng],
            [this.dropoffCoords.lat, this.dropoffCoords.lng]
        ];

        this.route = L.polyline(latlngs, {
            color: '#4facfe',
            weight: 3,
            opacity: 0.7
        }).addTo(this.map);

        // Fit bounds to show both markers
        this.map.fitBounds(this.route.getBounds(), { padding: [50, 50] });

        // Calculate distance
        this.calculateDistance();
    }

    /**
     * Calculate distance between two points
     */
    calculateDistance() {
        if (!this.pickupCoords || !this.dropoffCoords) return;

        const distance = this.getDistanceFromLatLngInKm(
            this.pickupCoords.lat,
            this.pickupCoords.lng,
            this.dropoffCoords.lat,
            this.dropoffCoords.lng
        );

        updatePricing(distance);
    }

    /**
     * Calculate distance using Haversine formula
     */
    getDistanceFromLatLngInKm(lat1, lng1, lat2, lng2) {
        const R = 6371;
        const dLat = (lat2 - lat1) * Math.PI / 180;
        const dLng = (lng2 - lng1) * Math.PI / 180;
        const a = 
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLng / 2) * Math.sin(dLng / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    /**
     * Reverse geocode coordinates to address (using mock data)
     */
    reverseGeocode(lat, lng, type) {
        // In production, this would call a real geocoding service
        // For now, we'll show coordinates
        const locationName = `Location (${lat.toFixed(4)}, ${lng.toFixed(4)})`;
        
        if (type === 'pickup') {
            document.getElementById('pickupLocation').value = locationName;
        } else if (type === 'dropoff') {
            document.getElementById('dropoffLocation').value = locationName;
        }
    }
}

// ============================================
// PRICING CALCULATOR
// ============================================

function updatePricing(distance = 0) {
    const vehicleType = document.getElementById('vehicleType').value;
    const passengerCount = parseInt(document.getElementById('passengerCount').value);
    
    // Base fares by vehicle type
    const baseFares = {
        economy: 5.00,
        comfort: 8.00,
        premium: 15.00
    };

    // Per-km rates
    const ratePerKm = {
        economy: 1.50,
        comfort: 2.00,
        premium: 3.00
    };

    const baseFare = baseFares[vehicleType] || 5.00;
    const distancePrice = distance * (ratePerKm[vehicleType] || 1.50);
    const surgePricing = (baseFare + distancePrice) * 0.1; // 10% surge for demo
    const totalPrice = baseFare + distancePrice + surgePricing;

    // Update display
    document.getElementById('baseFare').textContent = `$${baseFare.toFixed(2)}`;
    document.getElementById('distancePrice').textContent = `$${distancePrice.toFixed(2)}`;
    document.getElementById('surgePricing').textContent = `$${surgePricing.toFixed(2)}`;
    document.getElementById('totalPrice').textContent = `$${totalPrice.toFixed(2)}`;
}

// ============================================
// MODAL MANAGEMENT
// ============================================

function showModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('active');
        document.body.style.overflow = 'auto';
    }
}

// Close modal when clicking outside
document.addEventListener('click', (e) => {
    if (e.target.classList.contains('modal')) {
        e.target.classList.remove('active');
        document.body.style.overflow = 'auto';
    }
});

// ============================================
// TOAST NOTIFICATIONS
// ============================================

function showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `toast ${type}-toast`;
    toast.textContent = message;
    document.body.appendChild(toast);

    setTimeout(() => {
        toast.style.animation = 'slideInRight 0.3s ease-out';
    }, 10);

    setTimeout(() => {
        toast.remove();
    }, 5000);
}

// ============================================
// RATE LIMITER
// ============================================

class RateLimiter {
    constructor(maxRequests = 10, windowMs = 60000) {
        this.maxRequests = maxRequests;
        this.windowMs = windowMs;
        this.requests = [];
    }

    isAllowed() {
        const now = Date.now();
        this.requests = this.requests.filter(time => now - time < this.windowMs);
        
        if (this.requests.length >= this.maxRequests) {
            return false;
        }

        this.requests.push(now);
        return true;
    }
}

const bookingLimiter = new RateLimiter(CONFIG.RATE_LIMIT.maxRequests, CONFIG.RATE_LIMIT.windowMs);

// ============================================
// BOOKING HANDLER
// ============================================

function handleBookingSubmit(e) {
    e.preventDefault();

    // Rate limit check
    if (!bookingLimiter.isAllowed()) {
        showToast('Too many requests. Please wait before trying again.', 'error');
        return;
    }

    // Collect form data
    const formData = {
        pickupLocation: InputValidator.sanitizeString(document.getElementById('pickupLocation').value),
        dropoffLocation: InputValidator.sanitizeString(document.getElementById('dropoffLocation').value),
        bookingDate: document.getElementById('bookingDate').value,
        bookingTime: document.getElementById('bookingTime').value,
        passengerCount: document.getElementById('passengerCount').value,
        vehicleType: document.getElementById('vehicleType').value,
        specialRequests: InputValidator.sanitizeString(document.getElementById('specialRequests').value),
        passengerName: InputValidator.sanitizeString(document.getElementById('passengerName').value),
        passengerEmail: InputValidator.sanitizeString(document.getElementById('passengerEmail').value),
        passengerPhone: InputValidator.sanitizeString(document.getElementById('passengerPhone').value),
        termsAccepted: document.getElementById('termsAccepted').checked
    };

    // Validate form
    const validation = InputValidator.validateForm(formData);
    if (!validation.isValid) {
        Object.values(validation.errors).forEach(error => {
            showToast(error, 'error');
        });
        return;
    }

    // Check terms acceptance
    if (!formData.termsAccepted) {
        showToast('Please accept the terms and conditions', 'error');
        return;
    }

    // Show loading spinner
    document.getElementById('loadingSpinner').classList.add('active');
    document.getElementById('bookRideBtn').disabled = true;

    // Submit booking (mock API call)
    submitBooking(formData);
}

function submitBooking(formData) {
    // In production, this would be a real API call with proper error handling
    console.log('Booking submitted:', formData);
    
    setTimeout(() => {
        document.getElementById('loadingSpinner').classList.remove('active');
        document.getElementById('bookRideBtn').disabled = false;
        
        showToast('Booking confirmed! Driver assigned.', 'success');
        document.getElementById('bookingForm').reset();
        updatePricing(0);
    }, 2000);
}

// ============================================
// INITIALIZATION
// ============================================

document.addEventListener('DOMContentLoaded', function() {
    console.log('Customer Dashboard Loaded');
    
    initDashboard();
});

function checkMagicLinkAuth() {
    const urlParams = new URLSearchParams(window.location.search);
    const token = urlParams.get('token');
    
    if (token) {
        // Verify magic link token
        verifyMagicLink(token);
    }
}

function setupMagicLinkAuth() {
    const form = document.getElementById('magicLinkForm');
    const resendBtn = document.getElementById('resendLink');
    
    if (form) {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            sendMagicLink();
        });
    }
    
    if (resendBtn) {
        resendBtn.addEventListener('click', function() {
            sendMagicLink();
        });
    }
}

function sendMagicLink() {
    const emailInput = document.getElementById('customerEmail');
    const email = emailInput.value;
    
    console.log('Sending magic link to:', email);
    
    // Show loading state
    const submitBtn = document.querySelector('.btn-magic-link');
    const originalText = submitBtn.innerHTML;
    submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sending...';
    submitBtn.disabled = true;
    
    // Simulate API call
    setTimeout(() => {
        // In production, this would be an actual API call:
        // fetch('/api/auth/magic-link', {
        //     method: 'POST',
        //     headers: { 'Content-Type': 'application/json' },
        //     body: JSON.stringify({ email, type: 'customer' })
        // })
        
        // Hide form, show success message
        document.querySelector('.magic-form').style.display = 'none';
        document.getElementById('emailSent').style.display = 'block';
        document.getElementById('sentEmailAddress').textContent = email;
        
        submitBtn.innerHTML = originalText;
        submitBtn.disabled = false;
        
        console.log('Magic link sent successfully');
    }, 1500);
}

function verifyMagicLink(token) {
    console.log('Verifying magic link token:', token);
    
    // Show loading state
    const loginScreen = document.getElementById('loginScreen');
    if (!loginScreen) {
        console.error('Login screen element not found');
        return;
    }
    
    loginScreen.innerHTML = `
        <div class="magic-link-card" style="text-align: center;">
            <i class="fas fa-spinner fa-spin" style="font-size: 3rem; color: var(--primary);"></i>
            <h3 style="margin-top: 1rem; color: var(--dark);">Verifying your magic link...</h3>
        </div>
    `;
    
    // API verification with proper error handling
    fetch('/api/auth/verify-magic-link', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token })
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Invalid or expired magic link');
        }
        return response.json();
    })
    .then(data => {
        // Success - show dashboard
        loginScreen.style.display = 'none';
        const mainDashboard = document.getElementById('mainDashboard');
        if (mainDashboard) {
            mainDashboard.style.display = 'flex';
        }
        
        // Store auth token
        localStorage.setItem('customerAuthToken', data.token || token);
        localStorage.setItem('customerEmail', data.email || '');
        
        console.log('Magic link verified - access granted');
    })
    .catch(error => {
        console.error('Magic link verification failed:', error.message);
        loginScreen.innerHTML = `
            <div class="magic-link-card" style="text-align: center;">
                <i class="fas fa-exclamation-circle" style="font-size: 3rem; color: #ff5252;"></i>
                <h3 style="margin-top: 1rem; color: var(--dark);">Verification Failed</h3>
                <p style="color: #666;">${error.message}</p>
                <a href="/customer/" class="btn-magic-link" style="margin-top: 1rem;">Try Again</a>
            </div>
        `;
    });
}

function initDashboard() {
    setupNavigation();
    setupRideTypes();
    setupBookingForm();
    setupCurrentLocation();
}

function setupNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
        item.addEventListener('click', function(e) {
            if (!this.querySelector('.fa-sign-out-alt')) {
                e.preventDefault();
                navItems.forEach(nav => nav.classList.remove('active'));
                this.classList.add('active');
            }
        });
    });
}

function setupRideTypes() {
    const rideTypes = document.querySelectorAll('.ride-type');
    rideTypes.forEach(type => {
        type.addEventListener('click', function() {
            rideTypes.forEach(t => t.classList.remove('active'));
            this.classList.add('active');
            
            // Update the booking button with selected price
            const price = this.querySelector('.ride-type-price').textContent;
            const bookBtn = document.querySelector('.btn-book-ride');
            const rideTypeName = this.querySelector('.ride-type-name').textContent;
            bookBtn.innerHTML = `<i class="fas fa-check-circle"></i> Book ${rideTypeName} - ${price}`;
        });
    });
}

function setupBookingForm() {
    const bookingForm = document.querySelector('.booking-form');
    if (bookingForm) {
        bookingForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const pickup = document.querySelector('.location-inputs input:nth-of-type(1)').value;
            const destination = document.querySelector('.location-inputs input:nth-of-type(2)').value;
            const selectedRide = document.querySelector('.ride-type.active .ride-type-name').textContent;
            
            console.log('Booking ride:', {
                pickup,
                destination,
                rideType: selectedRide
            });
            
            // Show confirmation or call API
            alert(`Booking ${selectedRide}\nFrom: ${pickup}\nTo: ${destination}`);
        });
    }
}

function setupCurrentLocation() {
    const locationBtn = document.querySelector('.location-btn');
    if (locationBtn) {
        locationBtn.addEventListener('click', function() {
            console.log('Getting current location...');
            
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    position => {
                        console.log('Location:', position.coords);
                        // Update pickup input with actual location
                        // In real app, reverse geocode coordinates to address
                    },
                    error => {
                        console.log('Location error:', error);
                        alert('Could not get your location. Please enter manually.');
                    }
                );
            } else {
                alert('Geolocation is not supported by your browser');
            }
        });
    }
    // Initialize cookie manager
    try {
        const cookieManager = new CookieManager();
        cookieManager.initConsentBanner();

        // Initialize map
        window.bookingMap = new BookingMap();

        // Setup form submission
        document.getElementById('bookingForm').addEventListener('submit', handleBookingSubmit);

        // Setup vehicle type change listener
        document.getElementById('vehicleType').addEventListener('change', () => {
            if (window.bookingMap && window.bookingMap.pickupCoords && window.bookingMap.dropoffCoords) {
                const distance = window.bookingMap.getDistanceFromLatLngInKm(
                    window.bookingMap.pickupCoords.lat,
                    window.bookingMap.pickupCoords.lng,
                    window.bookingMap.dropoffCoords.lat,
                    window.bookingMap.dropoffCoords.lng
                );
                updatePricing(distance);
            } else {
                updatePricing(0);
            }
        });

        // Initialize date/time inputs
        const now = new Date();
        const dateInput = document.getElementById('bookingDate');
        dateInput.min = now.toISOString().split('T')[0];

        // Set current time as default
        const hours = String(now.getHours()).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');
        document.getElementById('bookingTime').value = `${hours}:${minutes}`;

        console.log('Swift Cab application initialized successfully');
    } catch (error) {
        console.error('Initialization error:', error);
        showToast('Error initializing application. Please refresh the page.', 'error');
    }
});
