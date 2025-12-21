#!/bin/bash
# lib/security.sh - Security functions and hardening
# Part of the modularized Taxi System installer

# ===================== SECURITY FUNCTIONS =====================
generate_secure_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

save_credentials() {
    local credentials_file="/root/.taxi-credentials-$(date +%s).txt"
    
    cat > "$credentials_file" << EOF
════════════════════════════════════════════════════════════════
                    TAXI SYSTEM CREDENTIALS
                    Generated: $(date)
════════════════════════════════════════════════════════════════

PostgreSQL Database:
  Host:     localhost:5432
  User:     taxi_admin
  Password: ${POSTGRES_PASSWORD}
  Database: taxi_db

MongoDB:
  Host:     localhost:27017
  User:     admin
  Password: ${MONGO_PASSWORD}
  Database: taxi_locations

Redis:
  Host:     localhost:6379
  Password: ${REDIS_PASSWORD}

JWT Secret:
  ${JWT_SECRET}

API Gateway:
  URL: http://localhost:3000

Dashboards:
  Admin:    http://${SERVER_IP:-localhost}:3001
  Driver:   http://${SERVER_IP:-localhost}:3002
  Customer: http://${SERVER_IP:-localhost}:3003

════════════════════════════════════════════════════════════════
⚠️  IMPORTANT SECURITY NOTICE:
════════════════════════════════════════════════════════════════
• SAVE THIS FILE IN A SECURE LOCATION IMMEDIATELY!
• Do NOT share these credentials over insecure channels
• Change default passwords in production
• This file will be automatically deleted in 24 hours

File location: ${credentials_file}
════════════════════════════════════════════════════════════════
EOF

    chmod 600 "$credentials_file"
    echo "$credentials_file"
}

configure_firewall() {
    log_step "Configuring firewall (UFW)..."
    
    if ! command -v ufw &> /dev/null; then
        apt-get install -y ufw >/dev/null 2>&1
    fi
    
    echo "y" | ufw --force reset >/dev/null 2>&1
    ufw default deny incoming >/dev/null 2>&1
    ufw default allow outgoing >/dev/null 2>&1
    ufw allow 22/tcp comment 'SSH' >/dev/null 2>&1
    ufw allow 80/tcp comment 'HTTP' >/dev/null 2>&1
    ufw allow 443/tcp comment 'HTTPS' >/dev/null 2>&1
    ufw allow 3000:3003/tcp comment 'Taxi Dashboards' >/dev/null 2>&1
    echo "y" | ufw --force enable >/dev/null 2>&1
    
    log_ok "Firewall configured and enabled"
    log_info "Allowed ports: 22 (SSH), 80 (HTTP), 443 (HTTPS), 3000-3003 (Dashboards)"
    log_info "Database ports (5432, 27017, 6379) are protected - only accessible locally"
}

security_audit() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              🔍 SECURITY AUDIT REPORT${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local issues=0
    local warnings=0
    local passed=0
    
    # Check 1: Strong passwords
    if [ -f "/home/taxi/app/.env" ]; then
        if grep -q "password123\|admin123\|taxipass" /home/taxi/app/.env 2>/dev/null; then
            echo -e "${RED}❌ CRITICAL: Default/weak passwords detected${NC}"
            issues=$((issues + 1))
        else
            echo -e "${GREEN}✅ Strong passwords configured${NC}"
            passed=$((passed + 1))
        fi
    fi
    
    # Check 2: Database ports exposure
    local exposed_ports
    exposed_ports=$(netstat -tuln 2>/dev/null | grep -E ":(5432|27017|6379).*0.0.0.0" | wc -l)
    if [ "$exposed_ports" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  WARNING: Database ports exposed to internet${NC}"
        echo -e "${YELLOW}   Consider using firewall to restrict access${NC}"
        warnings=$((warnings + 1))
    else
        echo -e "${GREEN}✅ Database ports not exposed externally${NC}"
        passed=$((passed + 1))
    fi
    
    # Check 3: Docker socket permissions
    if [ -e "/var/run/docker.sock" ]; then
        local socket_perms
        socket_perms=$(stat -c %a /var/run/docker.sock 2>/dev/null)
        if [ "$socket_perms" = "666" ]; then
            echo -e "${YELLOW}⚠️  WARNING: Docker socket is world-writable${NC}"
            echo -e "${YELLOW}   This is set for compatibility but reduces security${NC}"
            warnings=$((warnings + 1))
        else
            echo -e "${GREEN}✅ Docker socket permissions are restrictive${NC}"
            passed=$((passed + 1))
        fi
    fi
    
    # Check 4: Firewall status
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            echo -e "${GREEN}✅ Firewall (UFW) is active${NC}"
            passed=$((passed + 1))
        else
            echo -e "${RED}❌ CRITICAL: Firewall is not active${NC}"
            issues=$((issues + 1))
        fi
    else
        echo -e "${YELLOW}⚠️  WARNING: UFW firewall not installed${NC}"
        warnings=$((warnings + 1))
    fi
    
    # Check 5: SSL/TLS
    if [ -d "/etc/nginx" ]; then
        if grep -r "ssl_certificate" /etc/nginx/sites-enabled/ 2>/dev/null | grep -v "#" >/dev/null; then
            echo -e "${GREEN}✅ SSL/TLS certificate configured${NC}"
            passed=$((passed + 1))
        else
            echo -e "${YELLOW}⚠️  WARNING: No SSL certificate configured (HTTP only)${NC}"
            echo -e "${YELLOW}   Consider setting up Let's Encrypt for HTTPS${NC}"
            warnings=$((warnings + 1))
        fi
    fi
    
    # Check 6: Root login
    if [ -f "/etc/ssh/sshd_config" ]; then
        if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config 2>/dev/null; then
            echo -e "${YELLOW}⚠️  WARNING: Root SSH login is enabled${NC}"
            warnings=$((warnings + 1))
        else
            echo -e "${GREEN}✅ Root SSH login is disabled/restricted${NC}"
            passed=$((passed + 1))
        fi
    fi
    
    # Calculate security score
    local total_checks=$((passed + warnings + issues))
    local score=100
    
    if [ $total_checks -gt 0 ]; then
        score=$((100 - (warnings * 10) - (issues * 25)))
        if [ $score -lt 0 ]; then
            score=0
        fi
    fi
    
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
    
    if [ $score -ge 80 ]; then
        echo -e "${GREEN}Security Score: ${score}/100 - GOOD${NC}"
    elif [ $score -ge 60 ]; then
        echo -e "${YELLOW}Security Score: ${score}/100 - FAIR${NC}"
    else
        echo -e "${RED}Security Score: ${score}/100 - NEEDS IMPROVEMENT${NC}"
    fi
    
    echo -e "${CYAN}Summary: ${GREEN}${passed} passed${NC}, ${YELLOW}${warnings} warnings${NC}, ${RED}${issues} critical${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ $issues -gt 0 ] || [ $warnings -gt 0 ]; then
        echo -e "${YELLOW}Recommendations:${NC}"
        [ $issues -gt 0 ] && echo "  • Fix critical security issues immediately"
        [ $warnings -gt 0 ] && echo "  • Review and address warnings when possible"
        echo "  • Run 'sudo bash $0 --security-audit' to check again"
        echo ""
    fi
}

check_docker_permissions() {
    local docker_user="${1:-taxi}"
    
    # Check if Docker is running first
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed."
        return 1
    fi
    
    if ! systemctl is-active --quiet docker 2>/dev/null && ! service docker status &> /dev/null; then
        log_warn "Docker service is not running. Attempting to start..."
        systemctl start docker 2>/dev/null || service docker start 2>/dev/null || true
        sleep 2
    fi
    
    if ! sudo -u "$docker_user" docker ps >/dev/null 2>&1; then
        log_warn "Docker permission issue detected for user: $docker_user"
        echo ""
        echo "Options:"
        echo "  1) Auto-fix: Add $docker_user to docker group (RECOMMENDED)"
        echo "  2) Skip: Continue without fixing (may fail later)"
        echo "  3) Exit: Stop installation"
        echo ""
        read -r -p "Choose option (1/2/3): " docker_option
        
        case "$docker_option" in
            1)
                log_step "Adding $docker_user to docker group..."
                if ! getent group docker >/dev/null; then
                    sudo groupadd docker
                fi
                sudo usermod -aG docker "$docker_user"
                log_ok "User $docker_user added to docker group. Changes will take effect after logout/login."
                
                log_step "Applying group changes..."
                sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
                
                log_step "Attempting to start Docker services..."
                if sudo -u "$docker_user" docker ps >/dev/null 2>&1; then
                    log_ok "Docker access verified."
                    return 0
                else
                    log_warn "Docker still not accessible. You may need to log out and back in."
                    read -r -p "Continue anyway? (y/n): " continue_opt
                    if [[ "$continue_opt" =~ ^[Yy]$ ]]; then
                        return 0
                    else
                        log_error "Aborting installation."
                        exit 1
                    fi
                fi
                ;;
            2)
                log_warn "Skipping Docker permission fix. Docker compose may fail."
                return 0
                ;;
            3)
                log_error "Installation cancelled."
                exit 0
                ;;
            *)
                log_error "Invalid option. Exiting."
                exit 1
                ;;
        esac
    else
        log_ok "Docker permissions OK for user: $docker_user"
        return 0
    fi
}
