#!/bin/bash
# lib/dashboard.sh - Dashboard creation and deployment
# Part of the modularized Taxi System installer

# Source dependencies
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ===================== DASHBOARD FUNCTIONS =====================
create_all_dashboards() {
    log_step "Creating dashboard applications..."
    
    # Check if dashboards already exist from web directory
    if [ -n "${WEB_DIR:-}" ] && [ -d "$WEB_DIR" ]; then
        log_ok "Using existing dashboards from: $WEB_DIR"
        return 0
    fi
    
    # If no existing dashboards, create them
    log_info "Creating Admin Dashboard..."
    create_admin_dashboard
    
    log_info "Creating Driver Dashboard..."
    create_driver_dashboard
    
    log_info "Creating Customer Dashboard..."
    create_customer_dashboard
    
    log_ok "All dashboards created"
}

create_admin_dashboard() {
    local dashboard_path="${1:-/home/taxi/dashboards/admin}"
    
    mkdir -p "$dashboard_path"/{css,js,img}
    
    # Create index.html
    cat > "$dashboard_path/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Taxi System - Admin Dashboard</title>
    <link rel="stylesheet" href="css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css">
</head>
<body>
    <div class="admin-container">
        <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
            <div class="container-fluid">
                <span class="navbar-brand">🚕 Taxi System Admin</span>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNav">
                    <ul class="navbar-nav ms-auto">
                        <li class="nav-item"><a class="nav-link" href="#dashboard">Dashboard</a></li>
                        <li class="nav-item"><a class="nav-link" href="#users">Users</a></li>
                        <li class="nav-item"><a class="nav-link" href="#analytics">Analytics</a></li>
                        <li class="nav-item"><a class="nav-link" href="#settings">Settings</a></li>
                        <li class="nav-item"><a class="nav-link" href="#logout">Logout</a></li>
                    </ul>
                </div>
            </div>
        </nav>

        <div class="container-fluid mt-4">
            <div class="row mb-4">
                <div class="col-md-3">
                    <div class="card bg-primary text-white">
                        <div class="card-body">
                            <h5 class="card-title">Total Users</h5>
                            <p class="card-text" id="total-users">-</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-success text-white">
                        <div class="card-body">
                            <h5 class="card-title">Active Drivers</h5>
                            <p class="card-text" id="active-drivers">-</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-warning text-white">
                        <div class="card-body">
                            <h5 class="card-title">Today's Rides</h5>
                            <p class="card-text" id="today-rides">-</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-danger text-white">
                        <div class="card-body">
                            <h5 class="card-title">Revenue</h5>
                            <p class="card-text" id="revenue">-</p>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">Recent Rides</div>
                        <div class="card-body">
                            <table class="table table-sm">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Customer</th>
                                        <th>Driver</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody id="rides-table">
                                    <tr><td colspan="4" class="text-center">Loading...</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">System Status</div>
                        <div class="card-body">
                            <div class="status-item">
                                <span>API Gateway</span>
                                <span id="status-api" class="badge bg-secondary">Unknown</span>
                            </div>
                            <div class="status-item">
                                <span>Database</span>
                                <span id="status-db" class="badge bg-secondary">Unknown</span>
                            </div>
                            <div class="status-item">
                                <span>Cache</span>
                                <span id="status-cache" class="badge bg-secondary">Unknown</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="js/main.js"></script>
</body>
</html>
EOF
    
    # Create CSS
    cat > "$dashboard_path/css/style.css" << 'EOF'
:root {
    --primary: #4CAF50;
    --secondary: #2196F3;
    --danger: #f44336;
    --warning: #ff9800;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background-color: #f5f5f5;
}

.admin-container {
    min-height: 100vh;
}

.card {
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    border: none;
    margin-bottom: 20px;
}

.card-header {
    background-color: #f8f9fa;
    font-weight: 600;
    border-bottom: 1px solid #dee2e6;
}

.status-item {
    display: flex;
    justify-content: space-between;
    padding: 10px 0;
    border-bottom: 1px solid #eee;
}

.status-item:last-child {
    border-bottom: none;
}
EOF
    
    # Create JavaScript
    cat > "$dashboard_path/js/main.js" << 'EOF'
// Dashboard initialization
document.addEventListener('DOMContentLoaded', function() {
    loadDashboardData();
    setInterval(loadDashboardData, 30000); // Refresh every 30 seconds
});

async function loadDashboardData() {
    try {
        const response = await fetch('http://localhost:3000/api/admin/stats');
        const data = await response.json();
        
        document.getElementById('total-users').textContent = data.totalUsers || '-';
        document.getElementById('active-drivers').textContent = data.activeDrivers || '-';
        document.getElementById('today-rides').textContent = data.todayRides || '-';
        document.getElementById('revenue').textContent = '$' + (data.revenue || '0');
        
    } catch (error) {
        console.error('Error loading dashboard:', error);
    }
}
EOF
    
    log_ok "Admin Dashboard created at: $dashboard_path"
}

create_driver_dashboard() {
    local dashboard_path="${1:-/home/taxi/dashboards/driver}"
    
    mkdir -p "$dashboard_path"/{css,js,img}
    
    # Create index.html
    cat > "$dashboard_path/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Taxi System - Driver Dashboard</title>
    <link rel="stylesheet" href="css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body>
    <div class="driver-container">
        <nav class="navbar navbar-dark bg-dark">
            <div class="container-fluid">
                <span class="navbar-brand">🚕 Driver Dashboard</span>
                <span id="driver-name" class="text-white"></span>
            </div>
        </nav>

        <div class="container-fluid mt-4">
            <div class="row">
                <div class="col-md-8">
                    <div class="card">
                        <div class="card-header">Map Location</div>
                        <div class="card-body" id="map-container">
                            <div id="map" style="height: 400px; background: #e9ecef;">Map loading...</div>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card">
                        <div class="card-header">Driver Status</div>
                        <div class="card-body">
                            <button class="btn btn-success btn-lg w-100" id="btn-online">Go Online</button>
                            <button class="btn btn-danger btn-lg w-100 d-none" id="btn-offline">Go Offline</button>
                            <hr>
                            <div class="status-info">
                                <p><strong>Status:</strong> <span id="status" class="badge bg-danger">Offline</span></p>
                                <p><strong>Rating:</strong> <span id="rating">-</span></p>
                                <p><strong>Today's Rides:</strong> <span id="rides-count">0</span></p>
                                <p><strong>Earnings:</strong> <span id="earnings">$0</span></p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row mt-4">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">Available Rides</div>
                        <div class="card-body">
                            <div id="rides-list">
                                <p class="text-center text-muted">No available rides at the moment</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="js/main.js"></script>
</body>
</html>
EOF
    
    log_ok "Driver Dashboard created at: $dashboard_path"
}

create_customer_dashboard() {
    local dashboard_path="${1:-/home/taxi/dashboards/customer}"
    
    mkdir -p "$dashboard_path"/{css,js,img}
    
    # Create index.html
    cat > "$dashboard_path/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Taxi System - Customer Dashboard</title>
    <link rel="stylesheet" href="css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css">
</head>
<body>
    <div class="customer-container">
        <nav class="navbar navbar-dark bg-dark">
            <div class="container-fluid">
                <span class="navbar-brand">🚕 Taxi - Request a Ride</span>
                <span id="customer-name" class="text-white"></span>
            </div>
        </nav>

        <div class="container mt-4">
            <div class="row">
                <div class="col-md-8">
                    <div class="card">
                        <div class="card-header">Request a Ride</div>
                        <div class="card-body">
                            <form id="ride-form">
                                <div class="mb-3">
                                    <label class="form-label">Pickup Location</label>
                                    <input type="text" class="form-control" id="pickup" placeholder="Enter pickup address" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Dropoff Location</label>
                                    <input type="text" class="form-control" id="dropoff" placeholder="Enter dropoff address" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Ride Type</label>
                                    <select class="form-select" id="ride-type">
                                        <option value="economy">Economy</option>
                                        <option value="comfort">Comfort</option>
                                        <option value="premium">Premium</option>
                                    </select>
                                </div>
                                <button type="submit" class="btn btn-primary btn-lg w-100">Request Ride</button>
                            </form>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card">
                        <div class="card-header">Ride Details</div>
                        <div class="card-body">
                            <div id="ride-details">
                                <p class="text-muted">No active ride</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row mt-4">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">Ride History</div>
                        <div class="card-body">
                            <table class="table">
                                <thead>
                                    <tr>
                                        <th>Date</th>
                                        <th>From</th>
                                        <th>To</th>
                                        <th>Cost</th>
                                        <th>Rating</th>
                                    </tr>
                                </thead>
                                <tbody id="history-table">
                                    <tr><td colspan="5" class="text-center text-muted">No rides yet</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="js/main.js"></script>
</body>
</html>
EOF
    
    log_ok "Customer Dashboard created at: $dashboard_path"
}

deploy_dashboards() {
    log_step "Deploying dashboards to Nginx..."
    
    local dashboards_root="/var/www/taxi-dashboards"
    mkdir -p "$dashboards_root"
    
    # Try to copy from multiple possible locations
    if [ -n "${WEB_DIR:-}" ] && [ -d "$WEB_DIR" ]; then
        log_info "Copying dashboards from: $WEB_DIR"
        cp -r "$WEB_DIR"/* "$dashboards_root/" 2>/dev/null || true
    elif [ -d "/home/taxi/dashboards" ]; then
        log_info "Copying dashboards from: /home/taxi/dashboards"
        cp -r /home/taxi/dashboards/* "$dashboards_root/" 2>/dev/null || true
    elif [ -d "/root/web" ]; then
        log_info "Copying dashboards from: /root/web"
        cp -r /root/web/* "$dashboards_root/" 2>/dev/null || true
    elif [ -d "/workspaces/Proyecto/web" ]; then
        log_info "Copying dashboards from: /workspaces/Proyecto/web"
        cp -r /workspaces/Proyecto/web/* "$dashboards_root/" 2>/dev/null || true
    else
        log_warn "No web dashboard directory found. Creating empty structure..."
    fi
    
    # Set permissions
    chown -R www-data:www-data "$dashboards_root" 2>/dev/null || true
    chmod -R 755 "$dashboards_root" 2>/dev/null || true
    
    log_ok "Dashboards deployed to: $dashboards_root"
}

create_nginx_dashboard_config() {
    log_step "Creating Nginx dashboard configuration..."
    
    cat > /etc/nginx/sites-available/taxi-dashboards << 'EOF'
server {
    listen 3000;
    server_name localhost;

    root /var/www/taxi-dashboards;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:3100/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 3001;
    server_name localhost;

    root /var/www/taxi-dashboards/admin;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}

server {
    listen 3002;
    server_name localhost;

    root /var/www/taxi-dashboards/driver;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}

server {
    listen 3003;
    server_name localhost;

    root /var/www/taxi-dashboards/customer;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/taxi-dashboards /etc/nginx/sites-enabled/ 2>/dev/null || true
    
    log_ok "Nginx dashboard configuration created"
}
