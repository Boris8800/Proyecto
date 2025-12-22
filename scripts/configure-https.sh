#!/bin/bash

# Swift Cab - HTTPS Configuration Script
# Generates SSL certificates and configures HTTPS servers
# Usage: ./configure-https.sh

set -e

CERT_DIR="/root/Proyecto/certs"
KEY_FILE="$CERT_DIR/server.key"
CERT_FILE="$CERT_DIR/server.crt"
CONFIG_DIR="/root/Proyecto/config"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Swift Cab HTTPS Configuration ===${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}⚠ Running without root. Some operations may fail.${NC}"
fi

# Create certificate directory
mkdir -p "$CERT_DIR"
echo -e "${GREEN}✓ Created certificate directory: $CERT_DIR${NC}"

# Function to generate self-signed certificate
generate_self_signed() {
    echo ""
    echo -e "${BLUE}Generating Self-Signed Certificate...${NC}"
    
    openssl req -x509 -newkey rsa:2048 -keyout "$KEY_FILE" -out "$CERT_FILE" \
        -days 365 -nodes \
        -subj "/C=US/ST=State/L=City/O=SwiftCab/CN=localhost"
    
    chmod 600 "$KEY_FILE"
    chmod 644 "$CERT_FILE"
    
    echo -e "${GREEN}✓ Self-signed certificate generated${NC}"
    echo "  Key: $KEY_FILE"
    echo "  Cert: $CERT_FILE"
}

# Function to use Let's Encrypt certificates
setup_lets_encrypt() {
    local domain=$1
    
    echo ""
    echo -e "${BLUE}Setting up Let's Encrypt certificates for: $domain${NC}"
    
    if ! command -v certbot &> /dev/null; then
        echo -e "${YELLOW}⚠ Certbot not found. Installing...${NC}"
        apt-get update && apt-get install -y certbot python3-certbot-nginx
    fi
    
    certbot certonly --standalone -d "$domain" \
        --non-interactive --agree-tos --email admin@"$domain"
    
    echo -e "${GREEN}✓ Let's Encrypt certificate installed${NC}"
    echo "  Cert: /etc/letsencrypt/live/$domain/fullchain.pem"
    echo "  Key: /etc/letsencrypt/live/$domain/privkey.pem"
}

# Function to update environment variables
setup_environment() {
    local env_file="/root/Proyecto/.env.production"
    
    echo ""
    echo -e "${BLUE}Creating production environment file...${NC}"
    
    cat > "$env_file" << 'EOF'
NODE_ENV=production
ADMIN_PORT=3001
DRIVER_PORT=3002
CUSTOMER_PORT=3003
API_PORT=3000

# HTTPS Configuration
USE_HTTPS=true
SSL_KEY_PATH=/root/Proyecto/certs/server.key
SSL_CERT_PATH=/root/Proyecto/certs/server.crt

# CORS Configuration
CORS_ORIGIN=https://yourdomain.com

# Security
SECURE_COOKIES=true
HSTS_MAX_AGE=31536000
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100
EOF
    
    echo -e "${GREEN}✓ Environment file created: $env_file${NC}"
}

# Function to create HTTPS-enabled servers
create_https_servers() {
    echo ""
    echo -e "${BLUE}Creating HTTPS-enabled server files...${NC}"
    
    # Create HTTPS wrapper for admin server
    cat > "/root/Proyecto/web/server-admin-https.js" << 'HTTPS_ADMIN'
#!/usr/bin/env node

const https = require('https');
const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.ADMIN_PORT || 3001;
const BASE_DIR = __dirname;

// SSL/TLS Configuration
const sslOptions = {
  key: fs.readFileSync(process.env.SSL_KEY_PATH || '/root/Proyecto/certs/server.key'),
  cert: fs.readFileSync(process.env.SSL_CERT_PATH || '/root/Proyecto/certs/server.crt')
};

// Security Headers Middleware
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Content-Security-Policy',
    "default-src 'self'; " +
    "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; " +
    "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; " +
    "img-src 'self' data: https:; " +
    "font-src 'self' https:; " +
    "connect-src 'self'; " +
    "frame-ancestors 'self'"
  );
  
  if (process.env.NODE_ENV === 'production') {
    res.setHeader('Strict-Transport-Security', 
      `max-age=${process.env.HSTS_MAX_AGE || 31536000}; includeSubDomains`);
  }
  
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
  
  next();
});

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'https://localhost:3001',
  credentials: true
}));
app.use(express.json());
app.use(express.static(path.join(BASE_DIR, 'admin')));

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok',
    service: 'admin-dashboard',
    protocol: 'https',
    timestamp: new Date().toISOString()
  });
});

// Serve index.html for all other routes (SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(BASE_DIR, 'admin', 'index.html'));
});

// HTTPS Server
https.createServer(sslOptions, app).listen(PORT, '0.0.0.0', () => {
  console.log(`[OK] Admin Dashboard running on https://0.0.0.0:${PORT}`);
  console.log(`[INFO] Access at: https://yourdomain.com:${PORT}`);
});

// Error handling
process.on('uncaughtException', (err) => {
  console.error('[ERROR] Uncaught Exception:', err);
  process.exit(1);
});
HTTPS_ADMIN
    
    chmod +x "/root/Proyecto/web/server-admin-https.js"
    echo -e "${GREEN}✓ Created HTTPS admin server${NC}"
    
    # Create HTTPS wrapper for driver server
    cat > "/root/Proyecto/web/server-driver-https.js" << 'HTTPS_DRIVER'
#!/usr/bin/env node

const https = require('https');
const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.DRIVER_PORT || 3002;
const BASE_DIR = __dirname;

// SSL/TLS Configuration
const sslOptions = {
  key: fs.readFileSync(process.env.SSL_KEY_PATH || '/root/Proyecto/certs/server.key'),
  cert: fs.readFileSync(process.env.SSL_CERT_PATH || '/root/Proyecto/certs/server.crt')
};

// Security Headers Middleware
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Content-Security-Policy',
    "default-src 'self'; " +
    "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; " +
    "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; " +
    "img-src 'self' data: https:; " +
    "font-src 'self' https:; " +
    "connect-src 'self'; " +
    "frame-ancestors 'self'"
  );
  
  if (process.env.NODE_ENV === 'production') {
    res.setHeader('Strict-Transport-Security', 
      `max-age=${process.env.HSTS_MAX_AGE || 31536000}; includeSubDomains`);
  }
  
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
  
  next();
});

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'https://localhost:3002',
  credentials: true
}));
app.use(express.json());
app.use(express.static(path.join(BASE_DIR, 'driver')));

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok',
    service: 'driver-dashboard',
    protocol: 'https',
    timestamp: new Date().toISOString()
  });
});

// Serve index.html for all other routes (SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(BASE_DIR, 'driver', 'index.html'));
});

// HTTPS Server
https.createServer(sslOptions, app).listen(PORT, '0.0.0.0', () => {
  console.log(`[OK] Driver Dashboard running on https://0.0.0.0:${PORT}`);
  console.log(`[INFO] Access at: https://yourdomain.com:${PORT}`);
});

// Error handling
process.on('uncaughtException', (err) => {
  console.error('[ERROR] Uncaught Exception:', err);
  process.exit(1);
});
HTTPS_DRIVER
    
    chmod +x "/root/Proyecto/web/server-driver-https.js"
    echo -e "${GREEN}✓ Created HTTPS driver server${NC}"
    
    # Create HTTPS wrapper for customer server
    cat > "/root/Proyecto/web/server-customer-https.js" << 'HTTPS_CUSTOMER'
#!/usr/bin/env node

const https = require('https');
const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.CUSTOMER_PORT || 3003;
const BASE_DIR = __dirname;

// SSL/TLS Configuration
const sslOptions = {
  key: fs.readFileSync(process.env.SSL_KEY_PATH || '/root/Proyecto/certs/server.key'),
  cert: fs.readFileSync(process.env.SSL_CERT_PATH || '/root/Proyecto/certs/server.crt')
};

// Security Headers Middleware
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Content-Security-Policy',
    "default-src 'self'; " +
    "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; " +
    "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; " +
    "img-src 'self' data: https:; " +
    "font-src 'self' https:; " +
    "connect-src 'self' https://api.example.com; " +
    "frame-ancestors 'none'"
  );
  
  if (process.env.NODE_ENV === 'production') {
    res.setHeader('Strict-Transport-Security', 
      `max-age=${process.env.HSTS_MAX_AGE || 31536000}; includeSubDomains`);
  }
  
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
  
  next();
});

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'https://localhost:3003',
  credentials: true
}));
app.use(express.json());
app.use(express.static(path.join(BASE_DIR, 'customer')));

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok',
    service: 'customer-app',
    protocol: 'https',
    timestamp: new Date().toISOString()
  });
});

// Serve index.html for all other routes (SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(BASE_DIR, 'customer', 'index.html'));
});

// HTTPS Server
https.createServer(sslOptions, app).listen(PORT, '0.0.0.0', () => {
  console.log(`[OK] Customer App running on https://0.0.0.0:${PORT}`);
  console.log(`[INFO] Access at: https://yourdomain.com:${PORT}`);
});

// Error handling
process.on('uncaughtException', (err) => {
  console.error('[ERROR] Uncaught Exception:', err);
  process.exit(1);
});
HTTPS_CUSTOMER
    
    chmod +x "/root/Proyecto/web/server-customer-https.js"
    echo -e "${GREEN}✓ Created HTTPS customer server${NC}"
}

# Main execution
case "${1:-self-signed}" in
    "self-signed")
        generate_self_signed
        setup_environment
        create_https_servers
        echo ""
        echo -e "${GREEN}✓ HTTPS Configuration Complete!${NC}"
        echo ""
        echo "To run with HTTPS:"
        echo "  export NODE_ENV=production"
        echo "  export SSL_KEY_PATH=$KEY_FILE"
        echo "  export SSL_CERT_PATH=$CERT_FILE"
        echo "  node web/server-admin-https.js &"
        echo "  node web/server-driver-https.js &"
        echo "  node web/server-customer-https.js &"
        ;;
    "letsencrypt")
        if [ -z "$2" ]; then
            echo "Usage: $0 letsencrypt yourdomain.com"
            exit 1
        fi
        setup_lets_encrypt "$2"
        setup_environment
        create_https_servers
        echo ""
        echo -e "${GREEN}✓ Let's Encrypt Configuration Complete!${NC}"
        ;;
    *)
        echo "Usage: $0 [self-signed|letsencrypt <domain>]"
        exit 1
        ;;
esac
