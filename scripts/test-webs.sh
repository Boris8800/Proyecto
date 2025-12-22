#!/bin/bash

# Swift Cab - Web Application Testing Script
# Comprehensive testing for production-ready web clients
# Usage: ./test-webs.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/root/Proyecto/web"
ADMIN_PORT=3001
DRIVER_PORT=3002
CUSTOMER_PORT=3003
API_PORT=3000
STATUS_PORT=8080

# Functions
print_header() {
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=====================================${NC}"
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

# Check if port is open
check_port() {
    local port=$1
    local service=$2
    
    if nc -zv localhost $port 2>/dev/null; then
        print_success "$service is running on port $port"
        return 0
    else
        print_error "$service is NOT running on port $port"
        return 1
    fi
}

# Test HTTP endpoint
test_endpoint() {
    local url=$1
    local expected_code=$2
    local name=$3
    
    echo -n "Testing $name... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$response" -eq "$expected_code" ]; then
        print_success "$name returned $response"
        return 0
    else
        print_error "$name returned $response (expected $expected_code)"
        return 1
    fi
}

# Test security headers
test_security_headers() {
    local url=$1
    local port=$2
    local name=$3
    
    print_header "Security Headers for $name (Port $port)"
    
    headers=$(curl -s -I "$url" 2>/dev/null)
    
    # Check each security header
    if echo "$headers" | grep -q "X-Content-Type-Options"; then
        print_success "X-Content-Type-Options header present"
    else
        print_warning "X-Content-Type-Options header missing"
    fi
    
    if echo "$headers" | grep -q "X-Frame-Options"; then
        print_success "X-Frame-Options header present"
    else
        print_warning "X-Frame-Options header missing"
    fi
    
    if echo "$headers" | grep -q "X-XSS-Protection"; then
        print_success "X-XSS-Protection header present"
    else
        print_warning "X-XSS-Protection header missing"
    fi
    
    if echo "$headers" | grep -q "Content-Security-Policy"; then
        print_success "Content-Security-Policy header present"
    else
        print_warning "Content-Security-Policy header missing"
    fi
    
    if echo "$headers" | grep -q "Referrer-Policy"; then
        print_success "Referrer-Policy header present"
    else
        print_warning "Referrer-Policy header missing"
    fi
    
    echo ""
}

# Test form validation
test_form_validation() {
    print_header "Form Validation Testing"
    
    echo "Testing customer app at http://localhost:3003"
    echo ""
    echo "Manual tests to perform:"
    echo "1. Enter invalid email format"
    echo "2. Enter phone with < 10 digits"
    echo "3. Enter name with numbers/special chars"
    echo "4. Leave required fields empty"
    echo "5. Submit form without accepting terms"
    echo "6. Check that appropriate error messages appear"
    echo ""
    print_warning "Please perform manual validation testing in browser"
}

# Test map functionality
test_map_functionality() {
    print_header "Map Functionality Testing"
    
    echo "Testing map at http://localhost:3003"
    echo ""
    echo "Manual tests to perform:"
    echo "1. Click on map to select pickup location"
    echo "2. Click on different location for dropoff"
    echo "3. Verify markers appear (green pickup, red dropoff)"
    echo "4. Verify route line connects both points"
    echo "5. Test zoom in/out buttons"
    echo "6. Test center map button"
    echo "7. Test geolocation button (allow location access)"
    echo "8. Verify pricing updates with distance"
    echo ""
    print_warning "Please perform manual map testing in browser"
}

# Test cookies
test_cookies() {
    print_header "Cookie Management Testing"
    
    echo "Testing cookies at http://localhost:3003"
    echo ""
    echo "Manual tests to perform:"
    echo "1. Open DevTools (F12) -> Application -> Cookies"
    echo "2. Refresh page and accept all cookies"
    echo "3. Verify 3 cookies are set:"
    echo "   - session_id (Necessary)"
    echo "   - user_preferences (Preferences)"
    echo "   - analytics_id (Analytics)"
    echo "4. Check cookie attributes:"
    echo "   - HttpOnly flag"
    echo "   - Secure flag (HTTPS only)"
    echo "   - SameSite=Strict or Lax"
    echo "5. Verify max-age values"
    echo ""
    print_warning "Please perform manual cookie testing in browser DevTools"
}

# Test responsive design
test_responsive_design() {
    print_header "Responsive Design Testing"
    
    echo "Testing responsive layout at http://localhost:3003"
    echo ""
    echo "Manual tests to perform:"
    echo "1. Desktop (1024px+): Two-column layout"
    echo "2. Tablet (768px-1024px): Stacked panels"
    echo "3. Mobile (480px): Single column, full width"
    echo "4. Check font sizes are readable"
    echo "5. Check touch targets are 44px minimum"
    echo "6. Verify navigation is responsive"
    echo ""
    print_warning "Please perform manual responsive testing in DevTools"
}

# Test accessibility
test_accessibility() {
    print_header "Accessibility Testing"
    
    echo "Testing accessibility at http://localhost:3003"
    echo ""
    echo "Manual tests to perform:"
    echo "1. Tab through form - logical order"
    echo "2. All form fields have labels"
    echo "3. Focus indicators visible"
    echo "4. Color contrast sufficient (use WCAG analyzer)"
    echo "5. Keyboard shortcuts work"
    echo "6. Screen reader compatible (test with NVDA/JAWS)"
    echo "7. Check high contrast mode"
    echo ""
    print_warning "Please perform manual accessibility testing"
}

# Check npm dependencies
check_dependencies() {
    print_header "Checking Dependencies"
    
    if [ -d "$PROJECT_DIR/node_modules" ]; then
        print_success "node_modules directory exists"
    else
        print_warning "node_modules directory not found"
        echo "Run: cd $PROJECT_DIR && npm install"
    fi
    
    if [ -f "$PROJECT_DIR/package.json" ]; then
        print_success "package.json found"
    else
        print_error "package.json not found"
    fi
}

# Main testing flow
main() {
    clear
    print_header "Swift Cab Web Application Test Suite"
    
    echo "Project Directory: $PROJECT_DIR"
    echo "Test Date: $(date)"
    echo ""
    
    # Check dependencies
    check_dependencies
    echo ""
    
    # Port availability checks
    print_header "Service Availability"
    check_port $ADMIN_PORT "Admin Dashboard (3001)"
    check_port $DRIVER_PORT "Driver Portal (3002)"
    check_port $CUSTOMER_PORT "Customer Booking (3003)"
    check_port $API_PORT "API Server (3000)"
    check_port $STATUS_PORT "Status Dashboard (8080)"
    echo ""
    
    # HTTP endpoint tests
    print_header "HTTP Endpoint Tests"
    test_endpoint "http://localhost:$ADMIN_PORT/" 200 "Admin Dashboard"
    test_endpoint "http://localhost:$DRIVER_PORT/" 200 "Driver Portal"
    test_endpoint "http://localhost:$CUSTOMER_PORT/" 200 "Customer App"
    test_endpoint "http://localhost:$ADMIN_PORT/api/health" 200 "Admin Health Check"
    test_endpoint "http://localhost:$DRIVER_PORT/api/health" 200 "Driver Health Check"
    test_endpoint "http://localhost:$CUSTOMER_PORT/api/health" 200 "Customer Health Check"
    echo ""
    
    # Security headers
    test_security_headers "http://localhost:$ADMIN_PORT" $ADMIN_PORT "Admin Dashboard"
    test_security_headers "http://localhost:$DRIVER_PORT" $DRIVER_PORT "Driver Portal"
    test_security_headers "http://localhost:$CUSTOMER_PORT" $CUSTOMER_PORT "Customer App"
    
    # Manual testing guides
    test_form_validation
    test_map_functionality
    test_cookies
    test_responsive_design
    test_accessibility
    
    # Summary
    print_header "Test Summary"
    echo ""
    echo "✓ Automated tests completed"
    echo "⚠ Manual tests required for:"
    echo "  - Form validation"
    echo "  - Map functionality"
    echo "  - Cookie management"
    echo "  - Responsive design"
    echo "  - Accessibility features"
    echo ""
    echo "Next steps:"
    echo "1. Open http://localhost:3001 in browser (Admin)"
    echo "2. Open http://localhost:3002 in browser (Driver)"
    echo "3. Open http://localhost:3003 in browser (Customer)"
    echo "4. Perform manual tests as listed above"
    echo "5. Check DevTools for errors/warnings"
    echo "6. Verify all features work correctly"
    echo ""
    print_success "Test suite completed!"
}

# Run main function
main "$@"
