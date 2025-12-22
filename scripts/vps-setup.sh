#!/bin/bash
# VPS Setup Script - Configure VPS IP and Deploy
# Usage: ./vps-setup.sh <VPS_IP_ADDRESS>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Validate VPS IP
validate_vps_ip() {
    local ip=$1
    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        print_error "Invalid IP address format: $ip"
        return 1
    fi
    
    # Validate each octet
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if (( octet > 255 )); then
            print_error "Invalid IP address: $ip"
            return 1
        fi
    done
    return 0
}

# Main setup function
main() {
    local vps_ip="${1:-}"
    
    # Get VPS IP if not provided
    if [ -z "$vps_ip" ]; then
        print_warning "No VPS IP provided. Using default: 5.249.164.40"
        vps_ip="5.249.164.40"
    fi
    
    # Validate IP
    if ! validate_vps_ip "$vps_ip"; then
        print_error "Setup failed: Invalid VPS IP"
        exit 1
    fi
    
    print_status "Starting VPS Setup for IP: $vps_ip"
    
    # Copy .env.example to .env if it doesn't exist
    if [ ! -f "$PROJECT_ROOT/config/.env" ]; then
        cp "$PROJECT_ROOT/config/.env.example" "$PROJECT_ROOT/config/.env"
        print_success "Created .env file"
    fi
    
    # Update VPS_IP in .env
    sed -i "s/^VPS_IP=.*/VPS_IP=$vps_ip/" "$PROJECT_ROOT/config/.env"
    sed -i "s|^API_BASE_URL=.*|API_BASE_URL=http://$vps_ip:3000|" "$PROJECT_ROOT/config/.env"
    print_success "Updated VPS_IP to: $vps_ip"
    
    # Check firewall ports
    print_status "Checking firewall rules..."
    check_firewall_rules "$vps_ip"
    
    # Display connection info
    print_status "VPS Configuration Complete!"
    echo ""
    echo -e "${GREEN}=== Access Points ===${NC}"
    echo -e "  Admin Dashboard:   ${BLUE}http://$vps_ip:3001${NC}"
    echo -e "  Driver Dashboard:  ${BLUE}http://$vps_ip:3002${NC}"
    echo -e "  Customer Portal:   ${BLUE}http://$vps_ip:3003${NC}"
    echo -e "  API Server:        ${BLUE}http://$vps_ip:3000${NC}"
    echo -e "  Status Dashboard:  ${BLUE}http://$vps_ip:8080${NC}"
    echo ""
    echo -e "${GREEN}=== Database Connections ===${NC}"
    echo -e "  PostgreSQL:  ${BLUE}$vps_ip:5432${NC}"
    echo -e "  MongoDB:     ${BLUE}$vps_ip:27017${NC}"
    echo -e "  Redis:       ${BLUE}$vps_ip:6379${NC}"
    echo ""
}

# Check firewall rules
check_firewall_rules() {
    local vps_ip=$1
    local ports=(3000 3001 3002 3003 8080 5432 27017 6379)
    
    print_status "Checking required ports..."
    for port in "${ports[@]}"; do
        if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
            if ! ufw show added | grep -q "$port"; then
                print_warning "Port $port may not be allowed by UFW firewall"
            fi
        fi
    done
    
    print_success "Firewall check complete"
}

main "$@"
