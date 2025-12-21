// Customer Dashboard JavaScript
document.addEventListener('DOMContentLoaded', function() {
    console.log('Customer Dashboard Loaded');
    
    // Check if accessing via magic link
    checkMagicLinkAuth();
    
    // Setup magic link form
    setupMagicLinkAuth();
    
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
    document.getElementById('loginScreen').innerHTML = `
        <div class="magic-link-card" style="text-align: center;">
            <i class="fas fa-spinner fa-spin" style="font-size: 3rem; color: var(--primary);"></i>
            <h3 style="margin-top: 1rem; color: var(--dark);">Verifying your magic link...</h3>
        </div>
    `;
    
    // Simulate API verification
    setTimeout(() => {
        // In production:
        // fetch('/api/auth/verify-magic-link', {
        //     method: 'POST',
        //     headers: { 'Content-Type': 'application/json' },
        //     body: JSON.stringify({ token })
        // })
        
        // Success - show dashboard
        document.getElementById('loginScreen').style.display = 'none';
        document.getElementById('mainDashboard').style.display = 'flex';
        
        // Store auth token
        localStorage.setItem('customerAuthToken', token);
        localStorage.setItem('customerEmail', 'demo@customer.com');
        
        console.log('Magic link verified - access granted');
    }, 1500);
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
}

// Format currency
function formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
    }).format(amount);
}

// Calculate distance (demo)
function calculateDistance(pickup, destination) {
    // In real app, use Google Maps Distance Matrix API
    return Math.random() * 20 + 2; // Random distance between 2-22 km
}
