#!/bin/bash

# SwiftCab Environment Setup for Ubuntu Server
# Run this once to configure all services

echo "╔════════════════════════════════════════════════════════╗"
echo "║      SWIFTCAB SETUP - Environment Configuration       ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Get project directory
PROJECT_DIR="$(pwd)"
echo "📁 Project directory: $PROJECT_DIR"
echo ""

# Create .env file with required variables
echo "Creating .env file with database credentials..."
cat > "$PROJECT_DIR/.env" << 'EOF'
# PostgreSQL Configuration
POSTGRES_USER=taxiuser
POSTGRES_PASSWORD=taxipass123!
POSTGRES_DB=swiftcab_db
POSTGRES_HOST=taxi-postgres
POSTGRES_PORT=5432

# Redis Configuration
REDIS_PASSWORD=redispass123!
REDIS_HOST=taxi-redis
REDIS_PORT=6379

# MongoDB Configuration
MONGO_INITDB_ROOT_USERNAME=mongouser
MONGO_INITDB_ROOT_PASSWORD=mongopass123!
MONGO_HOST=taxi-mongo
MONGO_PORT=27017
MONGO_DATABASE=swiftcab

# Node.js Environment
NODE_ENV=production
LOG_LEVEL=info

# Server Ports
API_PORT=3000
ADMIN_PORT=3001
DRIVER_PORT=3002
CUSTOMER_PORT=3003

# API Configuration
API_HOST=0.0.0.0
API_URL=http://localhost:3000

# Database URLs
DATABASE_URL=postgresql://taxiuser:taxipass123!@taxi-postgres:5432/swiftcab_db
REDIS_URL=redis://:redispass123!@taxi-redis:6379
MONGODB_URL=mongodb://mongouser:mongopass123!@taxi-mongo:27017/swiftcab

# JWT Secret
JWT_SECRET=swiftcab_jwt_secret_key_change_in_production_12345

# Session Configuration
SESSION_SECRET=swiftcab_session_secret_change_in_production

# Email Configuration (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=noreply@swiftcab.io

# Features
ENABLE_EMAIL_VERIFICATION=false
ENABLE_PAYMENT_PROCESSING=false
ENABLE_DRIVER_TRACKING=true

# Logging
LOG_FORMAT=json
LOG_TO_FILE=true
LOG_DIR=/var/log/swiftcab
EOF

echo "✓ .env file created"
echo ""

# Check if docker-compose.yml exists
if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found!"
    exit 1
fi

echo "Starting services with docker-compose..."
echo ""

# Stop any running containers first
echo "Stopping existing containers..."
docker-compose down 2>/dev/null

# Start services
echo "Starting all services..."
docker-compose up -d

echo ""
echo "Waiting for services to initialize..."
sleep 5

# Check status
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║              SERVICE STATUS                           ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

docker-compose ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SWIFTCAB SETUP COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 ACCESS YOUR SERVICES:"
echo "   Admin Dashboard  → http://$(hostname -I | awk '{print $1}'):3001"
echo "   Driver App       → http://$(hostname -I | awk '{print $1}'):3002"
echo "   Customer App     → http://$(hostname -I | awk '{print $1}'):3003"
echo "   Booking Page     → http://$(hostname -I | awk '{print $1}'):3003/booking.html"
echo "   Payment Page     → http://$(hostname -I | awk '{print $1}'):3003/payment.html"
echo ""
echo "📋 DATABASE CREDENTIALS (from .env):"
echo "   PostgreSQL User: taxiuser / Password: taxipass123!"
echo "   MongoDB User:    mongouser / Password: mongopass123!"
echo "   Redis Password:  redispass123!"
echo ""
echo "⚙️  USEFUL COMMANDS:"
echo "   View logs:     docker-compose logs -f"
echo "   Stop services: docker-compose down"
echo "   Restart:       docker-compose restart"
echo "   Status:        curl -s https://raw.githubusercontent.com/Boris8800/Proyecto/main/quick-status.sh | bash"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
