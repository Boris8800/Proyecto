// Driver Dashboard JavaScript
document.addEventListener('DOMContentLoaded', function() {
    console.log('Driver Dashboard Loaded');
    
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
    const emailInput = document.getElementById('driverEmail');
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
        //     body: JSON.stringify({ email, type: 'driver' })
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
        localStorage.setItem('driverAuthToken', data.token || token);
        localStorage.setItem('driverEmail', data.email || '');
        
        console.log('Magic link verified - access granted');
    })
    .catch(error => {
        console.error('Magic link verification failed:', error.message);
        loginScreen.innerHTML = `
            <div class="magic-link-card" style="text-align: center;">
                <i class="fas fa-exclamation-circle" style="font-size: 3rem; color: #ff5252;"></i>
                <h3 style="margin-top: 1rem; color: var(--dark);">Verification Failed</h3>
                <p style="color: #666;">${error.message}</p>
                <a href="/driver/" class="btn-magic-link" style="margin-top: 1rem;">Try Again</a>
            </div>
        `;
    });
}

function initDashboard() {
    setupNavigation();
    setupOnlineToggle();
    setupRideActions();
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

function setupOnlineToggle() {
    const toggle = document.getElementById('onlineStatus');
    const statusText = document.querySelector('.status-text');
    
    if (toggle) {
        toggle.addEventListener('change', function() {
            if (this.checked) {
                statusText.textContent = 'Online';
                statusText.style.color = '#00d084';
                console.log('Driver is now online');
                // Call API to update online status
            } else {
                statusText.textContent = 'Offline';
                statusText.style.color = '#ff5252';
                console.log('Driver is now offline');
                // Call API to update offline status
            }
        });
    }
}

function setupRideActions() {
    // Accept buttons
    const acceptButtons = document.querySelectorAll('.btn-accept');
    acceptButtons.forEach(btn => {
        btn.addEventListener('click', function() {
            const rideItem = this.closest('.ride-request-item');
            console.log('Accepting ride request');
            // Call API to accept ride
            rideItem.style.borderColor = '#00d084';
            setTimeout(() => {
                rideItem.remove();
            }, 500);
        });
    });
    
    // Decline buttons
    const declineButtons = document.querySelectorAll('.btn-decline');
    declineButtons.forEach(btn => {
        btn.addEventListener('click', function() {
            const rideItem = this.closest('.ride-request-item');
            console.log('Declining ride request');
            // Call API to decline ride
            rideItem.style.borderColor = '#ff5252';
            setTimeout(() => {
                rideItem.remove();
            }, 500);
        });
    });
}

// Format currency
function formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
    }).format(amount);
}
