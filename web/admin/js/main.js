// Admin Dashboard JavaScript
document.addEventListener('DOMContentLoaded', function() {
    console.log('Admin Dashboard Loaded');
    
    // Initialize dashboard
    initDashboard();
});

function initDashboard() {
    // Add event listeners
    setupNavigation();
    setupSearch();
    updateSystemStatus();
    
    // Update stats periodically
    setInterval(updateSystemStatus, 30000); // Every 30 seconds
}

function setupNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
        item.addEventListener('click', function(e) {
            // Don't prevent default for logout
            if (!this.querySelector('.fa-sign-out-alt')) {
                e.preventDefault();
                navItems.forEach(nav => nav.classList.remove('active'));
                this.classList.add('active');
            }
        });
    });
}

function setupSearch() {
    const searchInput = document.querySelector('.search-box input');
    if (searchInput) {
        searchInput.addEventListener('input', function(e) {
            const searchTerm = e.target.value.toLowerCase();
            // Implement search functionality here
            console.log('Searching for:', searchTerm);
        });
    }
}

function updateSystemStatus() {
    // This would normally fetch from your API
    fetch('/api/status')
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            console.log('System status updated:', data);
            updateStatusUI(data);
        })
        .catch(error => {
            console.warn('API not available, using demo mode:', error.message);
            // Demo mode - show default status
            updateStatusUI(null);
        });
}

function updateStatusUI(data) {
    // Update UI elements with status data or defaults
    const statusElements = document.querySelectorAll('[data-status]');
    statusElements.forEach(el => {
        if (data && data[el.dataset.status]) {
            el.textContent = data[el.dataset.status];
            el.classList.remove('status-offline');
            el.classList.add('status-online');
        } else {
            el.classList.add('status-demo');
        }
    });
}

// Utility function to format currency
function formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
    }).format(amount);
}

// Utility function to format time ago
function timeAgo(date) {
    const seconds = Math.floor((new Date() - date) / 1000);
    
    let interval = seconds / 31536000;
    if (interval > 1) return Math.floor(interval) + ' years ago';
    
    interval = seconds / 2592000;
    if (interval > 1) return Math.floor(interval) + ' months ago';
    
    interval = seconds / 86400;
    if (interval > 1) return Math.floor(interval) + ' days ago';
    
    interval = seconds / 3600;
    if (interval > 1) return Math.floor(interval) + ' hours ago';
    
    interval = seconds / 60;
    if (interval > 1) return Math.floor(interval) + ' min ago';
    
    return Math.floor(seconds) + ' sec ago';
}
