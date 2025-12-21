#!/bin/bash
# lib/docker.sh - Docker installation and configuration
# Part of the modularized Taxi System installer

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ===================== DOCKER MIRROR CONFIGURATION =====================
configure_docker_mirror() {
    log_info "Setting up Docker registry mirror..."
    
    # Create docker config directory
    mkdir -p /etc/docker
    
    # Configure daemon.json with proper settings
    # Note: We use the default Docker Hub without mirrors to avoid misconfigurations
    cat > /etc/docker/daemon.json << 'EOF'
{
  "dns": ["8.8.8.8", "1.1.1.1", "114.114.114.114"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    
    # Reload daemon
    systemctl daemon-reload >/dev/null 2>&1 || true
    
    # Restart Docker if running
    if systemctl is-active --quiet docker; then
        systemctl restart docker >/dev/null 2>&1 || true
        sleep 3
    fi
    
    log_ok "Docker configured"
}

# ===================== DOCKER INSTALLATION FUNCTIONS =====================
install_docker() {
    log_step "Installing Docker and Docker Compose..."
    
    if command -v docker &> /dev/null; then
        log_ok "Docker already installed"
        return 0
    fi
    
    # Install Docker dependencies
    apt-get update >/dev/null 2>&1
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        >/dev/null 2>&1
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >/dev/null 2>&1
    
    # Add Docker repository
    echo \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt-get update >/dev/null 2>&1
    apt-get install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
    
    # Start Docker service
    systemctl start docker >/dev/null 2>&1
    systemctl enable docker >/dev/null 2>&1
    
    log_ok "Docker installed successfully"
}

install_docker_compose() {
    log_step "Installing Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        log_ok "Docker Compose already installed"
        return 0
    fi
    
    # Download and install docker-compose
    local compose_version
    compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    
    curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose >/dev/null 2>&1
    
    chmod +x /usr/local/bin/docker-compose
    
    # Verify installation
    if docker-compose --version >/dev/null 2>&1; then
        log_ok "Docker Compose installed successfully"
    else
        log_error "Failed to install Docker Compose"
        return 1
    fi
}

setup_docker_permissions() {
    log_step "Setting up Docker permissions..."
    
    local taxi_user="${1:-taxi}"
    
    # Create docker group if it doesn't exist
    if ! getent group docker >/dev/null; then
        groupadd docker >/dev/null 2>&1
    fi
    
    # Add user to docker group
    if [ -n "$taxi_user" ]; then
        usermod -aG docker "$taxi_user" >/dev/null 2>&1
        log_ok "User $taxi_user added to docker group"
    fi
    
    # Set Docker socket permissions for broader access (needed for compose)
    chmod 666 /var/run/docker.sock >/dev/null 2>&1
    log_ok "Docker socket permissions configured"
}

verify_docker_installation() {
    log_step "Verifying Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        return 1
    fi
    
    if ! systemctl is-active --quiet docker; then
        log_warn "Docker service is not running. Starting it..."
        systemctl start docker >/dev/null 2>&1
    fi
    
    # Test docker command
    if docker ps >/dev/null 2>&1; then
        log_ok "Docker is running and accessible"
        
        # Display versions
        local docker_version
        docker_version=$(docker --version | awk '{print $3}' | tr -d ',')
        log_info "Docker version: $docker_version"
        
        if command -v docker-compose &> /dev/null; then
            local compose_version
            compose_version=$(docker-compose --version | awk '{print $3}')
            log_info "Docker Compose version: $compose_version"
        fi
        return 0
    else
        log_error "Cannot access Docker. Check permissions."
        return 1
    fi
}

setup_docker_compose() {
    log_step "Configuring Docker Compose..."
    
    local project_dir="${1:-.}"
    local compose_file="${project_dir}/docker-compose.yml"
    
    if [ ! -f "$compose_file" ]; then
        log_warn "docker-compose.yml not found in $project_dir"
        return 1
    fi
    
    log_info "Docker Compose configuration found at: $compose_file"
    
    # Validate compose file
    if docker-compose -f "$compose_file" config >/dev/null 2>&1; then
        log_ok "Docker Compose file is valid"
        return 0
    else
        log_error "Docker Compose file validation failed"
        return 1
    fi
}

pull_docker_images() {
    log_step "Pulling Docker images..."
    
    local images=(
        "postgres:15-alpine"
        "mongo:6-alpine"
        "redis:7-alpine"
        "node:18-alpine"
        "nginx:alpine"
    )
    
    for image in "${images[@]}"; do
        log_info "Pulling $image..."
        if docker pull "$image" >/dev/null 2>&1; then
            log_ok "✓ $image"
        else
            log_warn "⚠ Failed to pull $image (will retry during compose up)"
        fi
    done
}

cleanup_docker() {
    log_step "Cleaning up Docker resources..."
    
    # Remove dangling images
    log_info "Removing dangling images..."
    docker image prune -f --filter "dangling=true" >/dev/null 2>&1
    
    # Remove stopped containers
    log_info "Removing stopped containers..."
    docker container prune -f >/dev/null 2>&1
    
    log_ok "Docker cleanup completed"
}

docker_status() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              📦 DOCKER STATUS REPORT${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Docker service status
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}✅ Docker service is running${NC}"
    else
        echo -e "${RED}❌ Docker service is NOT running${NC}"
    fi
    
    # Docker version
    if command -v docker &> /dev/null; then
        local docker_ver
        docker_ver=$(docker --version)
        echo -e "${BLUE}📌 ${docker_ver}${NC}"
    fi
    
    # Docker Compose version
    if command -v docker-compose &> /dev/null; then
        local compose_ver
        compose_ver=$(docker-compose --version)
        echo -e "${BLUE}📌 ${compose_ver}${NC}"
    fi
    
    # Running containers
    echo ""
    echo -e "${CYAN}Running Containers:${NC}"
    local running_count
    running_count=$(docker ps -q 2>/dev/null | wc -l)
    
    if [ "$running_count" -eq 0 ]; then
        echo "  None"
    else
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tail -n +2 | while read -r line; do
            echo "  $line"
        done
    fi
    
    # Disk usage
    echo ""
    echo -e "${CYAN}Docker Disk Usage:${NC}"
    docker system df --format "table {{.Type}}\t{{.Size}}" 2>/dev/null | tail -n +2 | while read -r line; do
        echo "  $line"
    done
    
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

troubleshoot_docker() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           🔧 DOCKER TROUBLESHOOTING${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local issues=0
    
    # Check 1: Docker daemon
    echo "Checking Docker daemon..."
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}✅ Docker daemon is running${NC}"
    else
        echo -e "${RED}❌ Docker daemon is NOT running${NC}"
        issues=$((issues + 1))
        echo "   Fix: sudo systemctl start docker"
    fi
    
    # Check 2: Docker socket
    echo ""
    echo "Checking Docker socket..."
    if [ -e "/var/run/docker.sock" ]; then
        echo -e "${GREEN}✅ Docker socket exists${NC}"
        
        local socket_perms
        socket_perms=$(stat -c %a /var/run/docker.sock 2>/dev/null)
        echo "   Permissions: $socket_perms"
    else
        echo -e "${RED}❌ Docker socket not found${NC}"
        issues=$((issues + 1))
    fi
    
    # Check 3: Docker access
    echo ""
    echo "Checking Docker access..."
    if docker ps >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Can access Docker${NC}"
    else
        echo -e "${RED}❌ Cannot access Docker${NC}"
        issues=$((issues + 1))
        echo "   Fix: sudo usermod -aG docker \$USER && newgrp docker"
    fi
    
    # Check 4: Disk space
    echo ""
    echo "Checking available disk space..."
    local available_gb
    available_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    if [ "$available_gb" -gt 5 ]; then
        echo -e "${GREEN}✅ Sufficient disk space (${available_gb}GB available)${NC}"
    else
        echo -e "${YELLOW}⚠️  Low disk space (${available_gb}GB available)${NC}"
        issues=$((issues + 1))
    fi
    
    # Check 5: Network connectivity
    echo ""
    echo "Checking network connectivity..."
    if ping -c 1 -W 2 docker.io >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Can reach Docker registry${NC}"
    else
        echo -e "${YELLOW}⚠️  Cannot reach Docker registry${NC}"
        issues=$((issues + 1))
    fi
    
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}All Docker checks passed!${NC}"
    else
        echo -e "${YELLOW}Found ${issues} issue(s). See details above.${NC}"
    fi
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}
