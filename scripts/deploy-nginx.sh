#!/bin/bash

################################################################################
# Nginx Configuration & Deployment Script
# For Swift Cab Production Environment
# Supports: Configuration, SSL integration, and automated deployment
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NGINX_CONF_SRC="/root/Proyecto/config/nginx-production.conf"
NGINX_CONF_DEST="/etc/nginx/sites-available/swift-cab.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/swift-cab.conf"
DOMAIN=${DOMAIN:-"yourdomain.com"}
LOG_DIR="/var/log/nginx"

# Functions
print_header() {
    echo -e "\n${BLUE}========== $1 ==========${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Install Nginx if not present
install_nginx() {
    print_header "Installing Nginx"
    
    if ! command -v nginx &> /dev/null; then
        print_info "Nginx not found. Installing..."
        apt-get update
        apt-get install -y nginx certbot python3-certbot-nginx
        print_success "Nginx installed"
    else
        print_success "Nginx already installed"
        nginx -v
    fi
}

# Validate Nginx configuration
validate_nginx_config() {
    print_header "Validating Nginx Configuration"
    
    if nginx -t &> /dev/null; then
        print_success "Nginx configuration is valid"
        return 0
    else
        print_error "Nginx configuration has errors"
        nginx -t
        return 1
    fi
}

# Create log directories
setup_log_dirs() {
    print_header "Setting Up Log Directories"
    
    mkdir -p "$LOG_DIR"
    touch "$LOG_DIR/swift-cab-access.log"
    touch "$LOG_DIR/swift-cab-error.log"
    touch "$LOG_DIR/admin-dashboard-access.log"
    touch "$LOG_DIR/admin-dashboard-error.log"
    touch "$LOG_DIR/driver-portal-access.log"
    touch "$LOG_DIR/driver-portal-error.log"
    
    chown -R www-data:www-data "$LOG_DIR"
    chmod 755 "$LOG_DIR"
    
    print_success "Log directories created"
}

# Copy and update configuration
setup_nginx_config() {
    print_header "Setting Up Nginx Configuration"
    
    if [ ! -f "$NGINX_CONF_SRC" ]; then
        print_error "Source config file not found: $NGINX_CONF_SRC"
        return 1
    fi
    
    # Copy configuration
    cp "$NGINX_CONF_SRC" "$NGINX_CONF_DEST"
    print_success "Configuration file copied"
    
    # Update domain placeholder
    sed -i "s/yourdomain\.com/$DOMAIN/g" "$NGINX_CONF_DEST"
    print_success "Domain updated to: $DOMAIN"
    
    # Create symlink if not exists
    if [ ! -L "$NGINX_ENABLED" ]; then
        ln -s "$NGINX_CONF_DEST" "$NGINX_ENABLED"
        print_success "Configuration enabled"
    else
        print_success "Configuration already enabled"
    fi
}

# Setup SSL certificates
setup_ssl_certificates() {
    print_header "Setting Up SSL Certificates"
    
    local method=$1
    
    case $method in
        lets-encrypt)
            print_info "Using Let's Encrypt for SSL..."
            
            if command -v certbot &> /dev/null; then
                print_info "Obtaining certificate for: $DOMAIN"
                certbot certonly --standalone --non-interactive --agree-tos \
                    -m admin@$DOMAIN -d $DOMAIN -d www.$DOMAIN \
                    -d admin.$DOMAIN -d driver.$DOMAIN
                print_success "Let's Encrypt certificates obtained"
            else
                print_error "Certbot not found"
                return 1
            fi
            ;;
            
        self-signed)
            print_info "Generating self-signed certificates..."
            
            local cert_dir="/etc/letsencrypt/live/$DOMAIN"
            mkdir -p "$cert_dir"
            
            # Generate private key and certificate
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout "$cert_dir/privkey.pem" \
                -out "$cert_dir/fullchain.pem" \
                -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"
            
            cp "$cert_dir/fullchain.pem" "$cert_dir/chain.pem"
            
            print_success "Self-signed certificates generated"
            ;;
            
        *)
            print_error "Unknown SSL method: $method"
            print_info "Supported methods: lets-encrypt, self-signed"
            return 1
            ;;
    esac
}

# Setup auto-renewal for Let's Encrypt
setup_ssl_renewal() {
    print_header "Setting Up SSL Auto-Renewal"
    
    if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        # Create renewal script
        cat > /root/Proyecto/scripts/renew-ssl.sh << 'EOF'
#!/bin/bash
# SSL Certificate Auto-Renewal Script

LOG_FILE="/var/log/ssl-renewal.log"

{
    echo "[$(date)] Starting SSL certificate renewal..."
    
    certbot renew --quiet --deploy-hook "systemctl reload nginx"
    
    if [ $? -eq 0 ]; then
        echo "[$(date)] SSL certificates renewed successfully"
    else
        echo "[$(date)] SSL certificate renewal failed"
    fi
} >> "$LOG_FILE" 2>&1
EOF
        
        chmod +x /root/Proyecto/scripts/renew-ssl.sh
        
        # Add to crontab (runs weekly)
        (crontab -l 2>/dev/null | grep -v renew-ssl.sh; echo "0 2 * * 0 /root/Proyecto/scripts/renew-ssl.sh") | crontab -
        
        print_success "SSL auto-renewal configured"
    fi
}

# Enable and start Nginx
start_nginx_service() {
    print_header "Starting Nginx Service"
    
    systemctl enable nginx
    systemctl start nginx
    
    if systemctl is-active --quiet nginx; then
        print_success "Nginx is running"
    else
        print_error "Failed to start Nginx"
        systemctl status nginx
        return 1
    fi
}

# Test Nginx health
test_nginx_health() {
    print_header "Testing Nginx Health"
    
    local test_urls=(
        "http://localhost:80"
        "http://localhost:3000"
        "http://localhost:3001"
        "http://localhost:3002"
        "http://localhost:3003"
    )
    
    for url in "${test_urls[@]}"; do
        if curl -s -o /dev/null -w "%{http_code}" "$url" > /dev/null 2>&1; then
            print_success "Endpoint responding: $url"
        else
            print_error "Endpoint not responding: $url"
        fi
    done
}

# Setup monitoring
setup_monitoring() {
    print_header "Setting Up Monitoring"
    
    # Create monitoring script
    cat > /root/Proyecto/scripts/monitor-nginx.sh << 'EOF'
#!/bin/bash

# Monitor Nginx Status Script

LOG_FILE="/var/log/nginx-monitor.log"
ALERT_EMAIL="admin@yourdomain.com"
THRESHOLD=80

check_nginx_status() {
    if ! systemctl is-active --quiet nginx; then
        echo "[$(date)] ERROR: Nginx is not running!" >> "$LOG_FILE"
        # Attempt restart
        systemctl restart nginx
        sleep 5
        
        if ! systemctl is-active --quiet nginx; then
            echo "[$(date)] CRITICAL: Nginx failed to restart" >> "$LOG_FILE"
            # Send alert (if mail configured)
            # echo "Nginx is down" | mail -s "Alert: Nginx Down" "$ALERT_EMAIL"
        fi
    fi
}

check_disk_space() {
    local usage=$(df /var/log/nginx | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$usage" -gt "$THRESHOLD" ]; then
        echo "[$(date)] WARNING: Log disk usage at ${usage}%" >> "$LOG_FILE"
        
        # Archive old logs
        find /var/log/nginx -name "*.log" -mtime +7 -exec gzip {} \;
    fi
}

check_backend_services() {
    local ports=(3000 3001 3002 3003)
    
    for port in "${ports[@]}"; do
        if ! nc -z localhost "$port" 2>/dev/null; then
            echo "[$(date)] WARNING: Service on port $port is not responding" >> "$LOG_FILE"
        fi
    done
}

# Run checks
check_nginx_status
check_disk_space
check_backend_services

# Output summary
echo "[$(date)] Monitoring check completed" >> "$LOG_FILE"
EOF
    
    chmod +x /root/Proyecto/scripts/monitor-nginx.sh
    
    # Add to crontab (runs every 5 minutes)
    (crontab -l 2>/dev/null | grep -v monitor-nginx.sh; echo "*/5 * * * * /root/Proyecto/scripts/monitor-nginx.sh") | crontab -
    
    print_success "Monitoring configured"
}

# Create status dashboard
create_status_page() {
    print_header "Creating Nginx Status Page"
    
    cat > /root/Proyecto/web/status/nginx-status.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nginx Status Dashboard</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            padding: 20px;
            margin: 0;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
        }
        
        h1 {
            color: #667eea;
            margin-top: 0;
        }
        
        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        
        .status-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        }
        
        .status-card h3 {
            margin: 0 0 10px 0;
            font-size: 14px;
            opacity: 0.9;
        }
        
        .status-card .value {
            font-size: 32px;
            font-weight: bold;
        }
        
        .status-card.online .value {
            color: #4ade80;
        }
        
        .status-card.offline .value {
            color: #f87171;
        }
        
        .info-section {
            margin: 30px 0;
            padding: 20px;
            background: #f5f5f5;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        
        .info-section h2 {
            margin-top: 0;
            color: #667eea;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }
        
        .info-item {
            padding: 10px;
            background: white;
            border-radius: 5px;
        }
        
        .info-item label {
            display: block;
            font-size: 12px;
            color: #666;
            margin-bottom: 5px;
        }
        
        .info-item value {
            display: block;
            font-size: 18px;
            font-weight: bold;
            color: #333;
        }
        
        .timestamp {
            color: #999;
            font-size: 12px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Nginx Status Dashboard</h1>
        
        <div class="status-grid">
            <div class="status-card online" id="nginx-status">
                <h3>Nginx</h3>
                <div class="value">●</div>
            </div>
            <div class="status-card online" id="api-status">
                <h3>API (3000)</h3>
                <div class="value">●</div>
            </div>
            <div class="status-card online" id="admin-status">
                <h3>Admin (3001)</h3>
                <div class="value">●</div>
            </div>
            <div class="status-card online" id="driver-status">
                <h3>Driver (3002)</h3>
                <div class="value">●</div>
            </div>
            <div class="status-card online" id="customer-status">
                <h3>Customer (3003)</h3>
                <div class="value">●</div>
            </div>
        </div>
        
        <div class="info-section">
            <h2>Server Information</h2>
            <div class="info-grid">
                <div class="info-item">
                    <label>Uptime</label>
                    <value id="uptime">--:--</value>
                </div>
                <div class="info-item">
                    <label>CPU Usage</label>
                    <value id="cpu">0%</value>
                </div>
                <div class="info-item">
                    <label>Memory Usage</label>
                    <value id="memory">0%</value>
                </div>
                <div class="info-item">
                    <label>Disk Usage</label>
                    <value id="disk">0%</value>
                </div>
            </div>
        </div>
        
        <div class="info-section">
            <h2>Configuration</h2>
            <div class="info-grid">
                <div class="info-item">
                    <label>Nginx Version</label>
                    <value id="nginx-version">--</value>
                </div>
                <div class="info-item">
                    <label>Worker Processes</label>
                    <value id="worker-processes">--</value>
                </div>
                <div class="info-item">
                    <label>Worker Connections</label>
                    <value id="worker-connections">--</value>
                </div>
                <div class="info-item">
                    <label>SSL/TLS</label>
                    <value id="ssl-status">Enabled</value>
                </div>
            </div>
        </div>
        
        <div class="timestamp">Last updated: <span id="last-update">--:--:--</span></div>
    </div>
    
    <script>
        function updateStatus() {
            const ports = [80, 3000, 3001, 3002, 3003];
            const portMap = {
                80: 'nginx-status',
                3000: 'api-status',
                3001: 'admin-status',
                3002: 'driver-status',
                3003: 'customer-status'
            };
            
            ports.forEach(port => {
                fetch(`http://localhost:${port}`, { method: 'HEAD' })
                    .then(() => {
                        document.getElementById(portMap[port]).classList.remove('offline');
                        document.getElementById(portMap[port]).classList.add('online');
                    })
                    .catch(() => {
                        document.getElementById(portMap[port]).classList.remove('online');
                        document.getElementById(portMap[port]).classList.add('offline');
                    });
            });
            
            document.getElementById('last-update').textContent = new Date().toLocaleTimeString();
        }
        
        // Update immediately and then every 5 seconds
        updateStatus();
        setInterval(updateStatus, 5000);
    </script>
</body>
</html>
EOF
    
    print_success "Status page created"
}

# Generate deployment report
generate_report() {
    print_header "Nginx Deployment Report"
    
    local report_file="/root/Proyecto/docs/NGINX_DEPLOYMENT_REPORT.md"
    
    cat > "$report_file" << EOF
# Nginx Reverse Proxy Deployment Report

**Date:** $(date)
**Domain:** $DOMAIN
**Server:** $(hostname)

## Deployment Summary

✓ Nginx installation verified
✓ Configuration files deployed
✓ SSL certificates configured
✓ Log directories created
✓ Health monitoring enabled
✓ Auto-renewal scheduled

## Configuration Details

### Main Domain
- URL: https://$DOMAIN
- Port: 443 (HTTPS)
- Backend: Customer App (localhost:3003)

### Subdomains
- Admin: https://admin.$DOMAIN → localhost:3001
- Driver: https://driver.$DOMAIN → localhost:3002

### SSL/TLS Configuration
- Protocol: TLS 1.2 and 1.3
- HSTS: Enabled (max-age=31536000)
- Cipher Suite: HIGH:!aNULL:!MD5
- Stapling: Enabled

## Security Headers Implemented

✓ Strict-Transport-Security
✓ X-Frame-Options: DENY/SAMEORIGIN
✓ X-Content-Type-Options: nosniff
✓ X-XSS-Protection: 1; mode=block
✓ Referrer-Policy: strict-origin-when-cross-origin
✓ Permissions-Policy: Restrictive
✓ Content-Security-Policy: Restrictive

## Rate Limiting

- API Zone: 10 requests/second (burst 100)
- General Zone: 30 requests/second
- Login Zone: 5 requests/minute

## Monitoring

✓ Health check: Every 5 minutes
✓ SSL renewal: Weekly
✓ Log rotation: Automatic
✓ Uptime monitoring: Enabled

## Service Status

Backend Services:
- API Server (3000): $(systemctl is-active api || echo "Check manually")
- Admin Dashboard (3001): $(systemctl is-active admin || echo "Check manually")
- Driver Portal (3002): $(systemctl is-active driver || echo "Check manually")
- Customer App (3003): $(systemctl is-active customer || echo "Check manually")

## Logs Location

- Access Logs: $LOG_DIR/swift-cab-access.log
- Error Logs: $LOG_DIR/swift-cab-error.log
- Renewal Logs: /var/log/ssl-renewal.log
- Monitor Logs: /var/log/nginx-monitor.log

## Next Steps

1. Test HTTPS connectivity: curl -I https://$DOMAIN
2. Monitor logs: tail -f $LOG_DIR/error.log
3. Update DNS records to point to this server
4. Set up backup strategy for certificates
5. Configure additional monitoring/alerting

## Useful Commands

### Check Configuration
\`\`\`bash
sudo nginx -t
\`\`\`

### View Logs
\`\`\`bash
sudo tail -f $LOG_DIR/swift-cab-access.log
sudo tail -f $LOG_DIR/swift-cab-error.log
\`\`\`

### Reload Configuration
\`\`\`bash
sudo systemctl reload nginx
\`\`\`

### Certificate Status
\`\`\`bash
sudo certbot certificates
\`\`\`

### Restart Service
\`\`\`bash
sudo systemctl restart nginx
\`\`\`

---

**Report Generated:** $(date)
EOF
    
    print_success "Deployment report created: $report_file"
}

# Main deployment function
deploy_nginx() {
    local ssl_method=${1:-"self-signed"}
    
    print_header "Swift Cab Nginx Deployment"
    
    check_root
    install_nginx
    setup_log_dirs
    setup_nginx_config
    
    if ! validate_nginx_config; then
        print_error "Configuration validation failed. Please fix errors above."
        return 1
    fi
    
    setup_ssl_certificates "$ssl_method"
    setup_ssl_renewal
    start_nginx_service
    
    if ! validate_nginx_config; then
        print_error "Nginx configuration is invalid"
        return 1
    fi
    
    test_nginx_health
    setup_monitoring
    create_status_page
    generate_report
    
    print_header "Deployment Complete!"
    print_success "Nginx is configured and running"
    print_info "Configuration file: $NGINX_CONF_DEST"
    print_info "Logs: $LOG_DIR"
    print_info "Status page: https://$DOMAIN/nginx-status.html"
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -d, --domain DOMAIN       Domain name (default: yourdomain.com)
    -s, --ssl METHOD          SSL method: self-signed or lets-encrypt (default: self-signed)
    -t, --test                Test configuration only
    -h, --help                Show this help message

EXAMPLES:
    # Deploy with self-signed certificates
    sudo $0 -d example.com -s self-signed
    
    # Deploy with Let's Encrypt
    sudo $0 -d example.com -s lets-encrypt
    
    # Test configuration
    $0 --test

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -s|--ssl)
            SSL_METHOD="$2"
            shift 2
            ;;
        -t|--test)
            validate_nginx_config
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Run deployment
deploy_nginx "${SSL_METHOD:-self-signed}"
