#!/bin/bash

###############################################
# COMPLETE API CONFIGURATION SETUP SCRIPT
# Setup all APIs: Google, Email, SMS, Payments
###############################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# Functions
# ============================================

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Create .env from example if doesn't exist
create_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        print_info "Creating .env file from template..."
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        print_success ".env file created at $ENV_FILE"
        print_warning "Please edit $ENV_FILE and add your API keys"
    else
        print_warning ".env file already exists, skipping creation"
    fi
}

# ============================================
# API SETUP FUNCTIONS
# ============================================

setup_google_apis() {
    print_header "GOOGLE APIS SETUP"

    echo -e "${YELLOW}Google APIs include:${NC}"
    echo "  1. Google Maps API - Display maps in driver app"
    echo "  2. Google Geocoding API - Convert addresses to coordinates"
    echo "  3. Google Directions API - Calculate routes and ETAs"
    echo "  4. Google Places API - Address autocomplete"
    echo ""
    
    read -p "Do you want to configure Google APIs? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter Google Maps API Key: " google_maps_key
        if [ ! -z "$google_maps_key" ]; then
            sed -i "s|GOOGLE_MAPS_API_KEY=.*|GOOGLE_MAPS_API_KEY=$google_maps_key|" "$ENV_FILE"
            print_success "Google Maps API Key saved"
        fi

        read -p "Enter Google Geocoding API Key: " google_geocoding_key
        if [ ! -z "$google_geocoding_key" ]; then
            sed -i "s|GOOGLE_GEOCODING_API_KEY=.*|GOOGLE_GEOCODING_API_KEY=$google_geocoding_key|" "$ENV_FILE"
            print_success "Google Geocoding API Key saved"
        fi

        read -p "Enter Google Directions API Key: " google_directions_key
        if [ ! -z "$google_directions_key" ]; then
            sed -i "s|GOOGLE_DIRECTIONS_API_KEY=.*|GOOGLE_DIRECTIONS_API_KEY=$google_directions_key|" "$ENV_FILE"
            print_success "Google Directions API Key saved"
        fi

        read -p "Enter Google Places API Key: " google_places_key
        if [ ! -z "$google_places_key" ]; then
            sed -i "s|GOOGLE_PLACES_API_KEY=.*|GOOGLE_PLACES_API_KEY=$google_places_key|" "$ENV_FILE"
            print_success "Google Places API Key saved"
        fi
    fi
}

setup_email_service() {
    print_header "EMAIL SERVICE SETUP"

    echo -e "${YELLOW}Choose email service:${NC}"
    echo "  1. Gmail (SMTP)"
    echo "  2. SendGrid"
    echo "  3. Mailgun"
    echo "  4. AWS SES"
    echo "  5. Skip"
    echo ""
    read -p "Select option (1-5): " email_option

    case $email_option in
        1)
            sed -i "s|EMAIL_SERVICE=.*|EMAIL_SERVICE=gmail|" "$ENV_FILE"
            read -p "Enter Gmail email address: " gmail_email
            read -sp "Enter Gmail app password: " gmail_password
            echo ""
            sed -i "s|EMAIL_USER=.*|EMAIL_USER=$gmail_email|" "$ENV_FILE"
            sed -i "s|EMAIL_PASSWORD=.*|EMAIL_PASSWORD=$gmail_password|" "$ENV_FILE"
            print_success "Gmail SMTP configured"
            ;;
        2)
            sed -i "s|EMAIL_SERVICE=.*|EMAIL_SERVICE=sendgrid|" "$ENV_FILE"
            read -p "Enter SendGrid API Key: " sendgrid_key
            read -p "Enter SendGrid from email: " sendgrid_email
            sed -i "s|SENDGRID_API_KEY=.*|SENDGRID_API_KEY=$sendgrid_key|" "$ENV_FILE"
            sed -i "s|SENDGRID_FROM_EMAIL=.*|SENDGRID_FROM_EMAIL=$sendgrid_email|" "$ENV_FILE"
            print_success "SendGrid configured"
            ;;
        3)
            sed -i "s|EMAIL_SERVICE=.*|EMAIL_SERVICE=mailgun|" "$ENV_FILE"
            read -p "Enter Mailgun API Key: " mailgun_key
            read -p "Enter Mailgun Domain: " mailgun_domain
            sed -i "s|MAILGUN_API_KEY=.*|MAILGUN_API_KEY=$mailgun_key|" "$ENV_FILE"
            sed -i "s|MAILGUN_DOMAIN=.*|MAILGUN_DOMAIN=$mailgun_domain|" "$ENV_FILE"
            print_success "Mailgun configured"
            ;;
        4)
            sed -i "s|EMAIL_SERVICE=.*|EMAIL_SERVICE=aws-ses|" "$ENV_FILE"
            read -p "Enter AWS Access Key ID: " aws_key_id
            read -sp "Enter AWS Secret Access Key: " aws_secret_key
            echo ""
            read -p "Enter AWS SES Region (default: us-east-1): " aws_region
            aws_region=${aws_region:-us-east-1}
            sed -i "s|AWS_SES_ACCESS_KEY_ID=.*|AWS_SES_ACCESS_KEY_ID=$aws_key_id|" "$ENV_FILE"
            sed -i "s|AWS_SES_SECRET_ACCESS_KEY=.*|AWS_SES_SECRET_ACCESS_KEY=$aws_secret_key|" "$ENV_FILE"
            sed -i "s|AWS_SES_REGION=.*|AWS_SES_REGION=$aws_region|" "$ENV_FILE"
            print_success "AWS SES configured"
            ;;
        *)
            print_warning "Email service skipped"
            ;;
    esac
}

setup_sms_service() {
    print_header "SMS SERVICE SETUP"

    echo -e "${YELLOW}Choose SMS service:${NC}"
    echo "  1. Twilio"
    echo "  2. Vonage (Nexmo)"
    echo "  3. AWS SNS"
    echo "  4. Skip"
    echo ""
    read -p "Select option (1-4): " sms_option

    case $sms_option in
        1)
            read -p "Enter Twilio Account SID: " twilio_sid
            read -sp "Enter Twilio Auth Token: " twilio_token
            echo ""
            read -p "Enter Twilio Phone Number (e.g., +1234567890): " twilio_phone
            sed -i "s|TWILIO_ACCOUNT_SID=.*|TWILIO_ACCOUNT_SID=$twilio_sid|" "$ENV_FILE"
            sed -i "s|TWILIO_AUTH_TOKEN=.*|TWILIO_AUTH_TOKEN=$twilio_token|" "$ENV_FILE"
            sed -i "s|TWILIO_PHONE_NUMBER=.*|TWILIO_PHONE_NUMBER=$twilio_phone|" "$ENV_FILE"
            print_success "Twilio configured"
            ;;
        2)
            read -p "Enter Vonage API Key: " vonage_key
            read -sp "Enter Vonage API Secret: " vonage_secret
            echo ""
            read -p "Enter Vonage Brand Name: " vonage_brand
            sed -i "s|VONAGE_API_KEY=.*|VONAGE_API_KEY=$vonage_key|" "$ENV_FILE"
            sed -i "s|VONAGE_API_SECRET=.*|VONAGE_API_SECRET=$vonage_secret|" "$ENV_FILE"
            sed -i "s|VONAGE_FROM_NUMBER=.*|VONAGE_FROM_NUMBER=$vonage_brand|" "$ENV_FILE"
            print_success "Vonage configured"
            ;;
        3)
            read -p "Enter AWS Access Key ID: " aws_sns_key
            read -sp "Enter AWS Secret Access Key: " aws_sns_secret
            echo ""
            read -p "Enter AWS SNS Region (default: us-east-1): " aws_sns_region
            aws_sns_region=${aws_sns_region:-us-east-1}
            sed -i "s|AWS_SNS_ACCESS_KEY_ID=.*|AWS_SNS_ACCESS_KEY_ID=$aws_sns_key|" "$ENV_FILE"
            sed -i "s|AWS_SNS_SECRET_ACCESS_KEY=.*|AWS_SNS_SECRET_ACCESS_KEY=$aws_sns_secret|" "$ENV_FILE"
            sed -i "s|AWS_SNS_REGION=.*|AWS_SNS_REGION=$aws_sns_region|" "$ENV_FILE"
            print_success "AWS SNS configured"
            ;;
        *)
            print_warning "SMS service skipped"
            ;;
    esac
}

setup_payment_gateways() {
    print_header "PAYMENT GATEWAYS SETUP"

    echo -e "${YELLOW}Choose payment gateway:${NC}"
    echo "  1. Stripe"
    echo "  2. PayPal"
    echo "  3. Square"
    echo "  4. All of the above"
    echo "  5. Skip"
    echo ""
    read -p "Select option (1-5): " payment_option

    case $payment_option in
        1|4)
            read -sp "Enter Stripe Secret Key: " stripe_secret
            echo ""
            read -p "Enter Stripe Publishable Key: " stripe_publish
            read -sp "Enter Stripe Webhook Secret: " stripe_webhook
            echo ""
            sed -i "s|STRIPE_SECRET_KEY=.*|STRIPE_SECRET_KEY=$stripe_secret|" "$ENV_FILE"
            sed -i "s|STRIPE_PUBLISHABLE_KEY=.*|STRIPE_PUBLISHABLE_KEY=$stripe_publish|" "$ENV_FILE"
            sed -i "s|STRIPE_WEBHOOK_SECRET=.*|STRIPE_WEBHOOK_SECRET=$stripe_webhook|" "$ENV_FILE"
            print_success "Stripe configured"
            [[ $payment_option == 1 ]] && return
            ;;
    esac

    case $payment_option in
        2|4)
            read -p "Enter PayPal Client ID: " paypal_id
            read -sp "Enter PayPal Client Secret: " paypal_secret
            echo ""
            read -p "Enter PayPal Mode (sandbox/live): " paypal_mode
            sed -i "s|PAYPAL_CLIENT_ID=.*|PAYPAL_CLIENT_ID=$paypal_id|" "$ENV_FILE"
            sed -i "s|PAYPAL_CLIENT_SECRET=.*|PAYPAL_CLIENT_SECRET=$paypal_secret|" "$ENV_FILE"
            sed -i "s|PAYPAL_MODE=.*|PAYPAL_MODE=${paypal_mode:-sandbox}|" "$ENV_FILE"
            print_success "PayPal configured"
            [[ $payment_option == 2 ]] && return
            ;;
    esac

    case $payment_option in
        3|4)
            read -sp "Enter Square Access Token: " square_token
            echo ""
            read -p "Enter Square Location ID: " square_location
            sed -i "s|SQUARE_ACCESS_TOKEN=.*|SQUARE_ACCESS_TOKEN=$square_token|" "$ENV_FILE"
            sed -i "s|SQUARE_LOCATION_ID=.*|SQUARE_LOCATION_ID=$square_location|" "$ENV_FILE"
            print_success "Square configured"
            ;;
    esac
}

setup_push_notifications() {
    print_header "PUSH NOTIFICATIONS SETUP"

    echo -e "${YELLOW}Choose push notification service:${NC}"
    echo "  1. Firebase Cloud Messaging"
    echo "  2. OneSignal"
    echo "  3. Skip"
    echo ""
    read -p "Select option (1-3): " push_option

    case $push_option in
        1)
            read -p "Enter Firebase Project ID: " firebase_pid
            read -sp "Enter Firebase Private Key: " firebase_key
            echo ""
            read -p "Enter Firebase Client Email: " firebase_email
            sed -i "s|FIREBASE_PROJECT_ID=.*|FIREBASE_PROJECT_ID=$firebase_pid|" "$ENV_FILE"
            sed -i "s|FIREBASE_PRIVATE_KEY=.*|FIREBASE_PRIVATE_KEY=$firebase_key|" "$ENV_FILE"
            sed -i "s|FIREBASE_CLIENT_EMAIL=.*|FIREBASE_CLIENT_EMAIL=$firebase_email|" "$ENV_FILE"
            print_success "Firebase configured"
            ;;
        2)
            read -p "Enter OneSignal App ID: " onesignal_id
            read -sp "Enter OneSignal API Key: " onesignal_key
            echo ""
            sed -i "s|ONESIGNAL_APP_ID=.*|ONESIGNAL_APP_ID=$onesignal_id|" "$ENV_FILE"
            sed -i "s|ONESIGNAL_API_KEY=.*|ONESIGNAL_API_KEY=$onesignal_key|" "$ENV_FILE"
            print_success "OneSignal configured"
            ;;
        *)
            print_warning "Push notifications skipped"
            ;;
    esac
}

setup_analytics() {
    print_header "ANALYTICS SETUP"

    read -p "Do you want to configure Sentry (error tracking)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter Sentry DSN: " sentry_dsn
        sed -i "s|SENTRY_DSN=.*|SENTRY_DSN=$sentry_dsn|" "$ENV_FILE"
        print_success "Sentry configured"
    fi

    read -p "Do you want to configure LogRocket (session recording)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter LogRocket App ID: " logrocket_id
        sed -i "s|LOGROCKET_APP_ID=.*|LOGROCKET_APP_ID=$logrocket_id|" "$ENV_FILE"
        print_success "LogRocket configured"
    fi
}

# ============================================
# MAIN MENU
# ============================================

main_menu() {
    print_header "API CONFIGURATION SETUP WIZARD"

    echo -e "${YELLOW}Select what you want to configure:${NC}"
    echo ""
    echo "  1. Setup Google APIs"
    echo "  2. Setup Email Service"
    echo "  3. Setup SMS Service"
    echo "  4. Setup Payment Gateways"
    echo "  5. Setup Push Notifications"
    echo "  6. Setup Analytics"
    echo "  7. Configure All (Interactive)"
    echo "  8. Check Configuration Status"
    echo "  9. View Configuration File"
    echo "  0. Exit"
    echo ""
    read -p "Select option (0-9): " option

    case $option in
        1) setup_google_apis; main_menu ;;
        2) setup_email_service; main_menu ;;
        3) setup_sms_service; main_menu ;;
        4) setup_payment_gateways; main_menu ;;
        5) setup_push_notifications; main_menu ;;
        6) setup_analytics; main_menu ;;
        7)
            setup_google_apis
            setup_email_service
            setup_sms_service
            setup_payment_gateways
            setup_push_notifications
            setup_analytics
            main_menu
            ;;
        8)
            print_info "Checking configuration status..."
            node -e "const apiConfig = require('./config/api-config'); apiConfig.printStatus();"
            main_menu
            ;;
        9)
            cat "$ENV_FILE"
            main_menu
            ;;
        0)
            print_success "Configuration complete!"
            echo ""
            echo -e "${GREEN}Next steps:${NC}"
            echo "  1. Review your .env file: $ENV_FILE"
            echo "  2. Install npm dependencies: npm install"
            echo "  3. Start the API server: npm start"
            echo "  4. Test your configuration: npm test"
            echo ""
            exit 0
            ;;
        *)
            print_error "Invalid option"
            main_menu
            ;;
    esac
}

# ============================================
# SCRIPT ENTRY POINT
# ============================================

cd "$PROJECT_ROOT"

if [ ! -f "$ENV_EXAMPLE" ]; then
    print_error ".env.example file not found!"
    exit 1
fi

create_env_file
main_menu
