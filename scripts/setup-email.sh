#!/bin/bash

#############################################################################
# Swift Cab - Email Server Setup Script
# Purpose: Install and configure email server for production
# Date: December 22, 2025
#############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERR]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log_info "Swift Cab Email Server Setup"
log_info "Project Root: $PROJECT_ROOT"

# 1. Install dependencies
log_info "Installing dependencies..."
cd "$PROJECT_ROOT"

if ! grep -q "nodemailer" package.json; then
    log_warning "nodemailer not found in package.json, adding..."
    npm install nodemailer@^6.9.7 --save
    log_success "nodemailer installed"
else
    log_info "nodemailer already in package.json"
    npm install 2>/dev/null || true
fi

# 2. Create config directory
log_info "Creating config directory..."
mkdir -p "$PROJECT_ROOT/config"
log_success "Config directory ready"

# 3. Initialize email configuration
log_info "Initializing email configuration..."
if [ ! -f "$PROJECT_ROOT/config/email-config.json" ]; then
    log_warning "email-config.json not found, creating default..."
    cat > "$PROJECT_ROOT/config/email-config.json" << 'EOF'
{
  "email": {
    "provider": "smtp",
    "smtp": {
      "host": "smtp.gmail.com",
      "port": 587,
      "secure": false,
      "auth": {
        "user": "your-email@gmail.com",
        "pass": "your-app-password"
      },
      "from": "noreply@swiftcab.com",
      "replyTo": "support@swiftcab.com"
    },
    "sendgrid": {
      "apiKey": "your-sendgrid-api-key",
      "fromEmail": "noreply@swiftcab.com",
      "fromName": "Swift Cab"
    },
    "mailgun": {
      "apiKey": "your-mailgun-api-key",
      "domain": "mg.swiftcab.com",
      "fromEmail": "noreply@swiftcab.com"
    }
  },
  "services": {
    "maps": {
      "provider": "google",
      "apiKey": "your-google-maps-api-key",
      "enabled": false
    },
    "payment": {
      "provider": "stripe",
      "apiKey": "your-stripe-api-key",
      "enabled": false
    },
    "sms": {
      "provider": "twilio",
      "apiKey": "your-twilio-api-key",
      "enabled": false
    }
  }
}
EOF
    log_success "Default email configuration created"
else
    log_success "email-config.json already exists"
fi

# 4. Create email service file if it doesn't exist
log_info "Checking email service file..."
if [ ! -f "$PROJECT_ROOT/web/api/email-service.js" ]; then
    log_warning "email-service.js not found"
else
    log_success "email-service.js exists"
fi

# 5. Create status dashboard if it doesn't exist
log_info "Checking status dashboard..."
if [ ! -f "$PROJECT_ROOT/web/status/server.js" ]; then
    log_warning "status/server.js not found"
else
    log_success "status/server.js exists"
fi

# 6. Add email-config to .gitignore
log_info "Updating .gitignore..."
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
    if ! grep -q "email-config.json" "$PROJECT_ROOT/.gitignore"; then
        echo "config/email-config.json" >> "$PROJECT_ROOT/.gitignore"
        log_success "Added email-config.json to .gitignore"
    else
        log_info "email-config.json already in .gitignore"
    fi
else
    echo "config/email-config.json" > "$PROJECT_ROOT/.gitignore"
    log_success "Created .gitignore with email-config.json"
fi

# 7. Display setup summary
log_success "Email Server Setup Complete!"
echo ""
echo "========================================="
echo "NEXT STEPS:"
echo "========================================="
echo ""
echo "1. Configure Email Provider:"
echo "   - Edit: $PROJECT_ROOT/config/email-config.json"
echo "   - Or use Status Dashboard: http://YOUR_VPS_IP:8080"
echo ""
echo "2. Choose Email Provider:"
echo "   a) SMTP (Gmail, Outlook, Custom)"
echo "      - Get app-specific password from Gmail"
echo "      - Set: host, port, user, pass, from"
echo ""
echo "   b) SendGrid"
echo "      - Get API key from SendGrid dashboard"
echo "      - Set: apiKey, fromEmail, fromName"
echo ""
echo "   c) Mailgun"
echo "      - Get API key from Mailgun dashboard"
echo "      - Set: apiKey, domain, fromEmail"
echo ""
echo "3. Start Status Dashboard:"
echo "   cd $PROJECT_ROOT"
echo "   node web/status/server.js"
echo ""
echo "4. Access Dashboard:"
echo "   http://YOUR_VPS_IP:8080"
echo ""
echo "5. Test Email:"
echo "   - Go to 'Email Configuration' tab"
echo "   - Fill in test recipient email"
echo "   - Click 'Send Test Email'"
echo ""
echo "6. Integrate into Web Servers:"
echo "   const EmailService = require('./api/email-service.js');"
echo "   const emailService = new EmailService(config);"
echo "   await emailService.sendWelcomeEmail(email, name);"
echo ""
echo "Documentation: $PROJECT_ROOT/docs/EMAIL_SERVER_GUIDE.md"
echo "========================================="
echo ""
log_success "Setup script completed successfully!"
