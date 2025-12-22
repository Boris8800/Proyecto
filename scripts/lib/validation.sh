#!/bin/bash
# lib/validation.sh - System validation and checks
# Part of the modularized Taxi System installer

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ===================== VALIDATION FUNCTIONS =====================
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

check_ubuntu() {
    if ! grep -qi "ubuntu\|debian" /etc/os-release; then
        log_error "This script is designed for Ubuntu/Debian systems only"
        exit 1
    fi
}

check_internet() {
    log_step "Checking internet connection..."
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_warn "No internet connection detected - offline mode"
        return 0
    fi
    log_ok "Internet connection verified"
}

check_space() {
    local dir="${1:-.}"
    local avail
    avail=$(df -k "$dir" | awk 'NR==2 {print $4}')
    local minspace=102400  # 100MB in KB
    
    if [ "$avail" -lt "$minspace" ]; then
        log_error "No sufficient disk space in $dir (${avail} KB available)"
        exit 1
    fi
    
    if [ ! -w "$dir" ]; then
        log_error "No write permissions in $dir"
        exit 1
    fi
}

check_system_requirements() {
    log_step "Checking system requirements..."
    
    # Check Ubuntu version
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        if [ "$ID" = "ubuntu" ]; then
            version_num="${VERSION_ID%.*}"
            if [ "$version_num" -lt 20 ]; then
                log_error "Ubuntu 20.04 or later required (found: $VERSION_ID)"
                exit 1
            fi
            log_ok "Ubuntu version: $VERSION_ID"
        fi
    fi
    
    # Check RAM
    local total_ram
    total_ram=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024/1024)}')
    if [ "$total_ram" -lt 4 ]; then
        log_warn "Low RAM detected (${total_ram}GB). Minimum recommended: 8GB"
    else
        log_ok "RAM check: ${total_ram}GB available"
    fi
    
    # Check disk space
    local disk_space
    disk_space=$(df /home | awk 'NR==2 {print int($4/1024/1024)}')
    if [ "$disk_space" -lt 50 ]; then
        log_error "Insufficient disk space (${disk_space}GB available). Minimum: 50GB"
        exit 1
    fi
    log_ok "Disk space check: ${disk_space}GB available"
}

kill_port() {
    local port="$1"
    local pid
    
    pid=$(netstat -tuln 2>/dev/null | grep ":$port " | awk '{print $NF}' | cut -d'/' -f1 | sort -u)
    
    if [ -n "$pid" ] && [ "$pid" != "-" ]; then
        log_info "Killing process on port $port (PID: $pid)"
        kill -9 "$pid" 2>/dev/null || true
        sleep 1
    fi
}

kill_all_ports() {
    local ports=(80 443 3000 3001 3002 3003 5432 27017 6379 9000 19999)
    
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            kill_port "$port"
        fi
    done
}

check_ports() {
    log_step "Checking port availability..."
    
    local ports=(80 443 3000 3001 3002 3003 5432 27017 6379)
    local in_use=()
    
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            in_use+=("$port")
        fi
    done
    
    if [ ${#in_use[@]} -gt 0 ]; then
        log_warn "Ports in use: ${in_use[*]}"
        read -r -p "Kill processes on these ports? (y/n): " kill_confirm
        if [[ "$kill_confirm" =~ ^[Yy]$ ]]; then
            for port in "${in_use[@]}"; do
                kill_port "$port"
            done
            log_ok "Ports cleared"
        fi
    else
        log_ok "All ports available"
    fi
}

system_status() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              📊 SYSTEM STATUS REPORT${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${BLUE}System Information:${NC}"
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        echo "  OS: $PRETTY_NAME"
    fi
    echo "  Hostname: $(hostname)"
    echo "  Kernel: $(uname -r)"
    echo "  Uptime: $(uptime -p)"
    echo ""
    
    echo -e "${BLUE}Resources:${NC}"
    local total_ram
    total_ram=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024/1024)}')
    local free_ram
    free_ram=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024/1024)}')
    echo "  Memory: ${free_ram}GB / ${total_ram}GB free"
    
    local disk_total
    disk_total=$(df /home | awk 'NR==2 {print int($2/1024/1024)}')
    local disk_used
    disk_used=$(df /home | awk 'NR==2 {print int($3/1024/1024)}')
    echo "  Disk: ${disk_used}GB / ${disk_total}GB used"
    
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}')
    echo "  Load Average: $load_avg"
    echo ""
    
    echo -e "${BLUE}Services:${NC}"
    if systemctl is-active --quiet docker; then
        echo -e "  Docker: ${GREEN}✅ Running${NC}"
    else
        echo -e "  Docker: ${RED}❌ Not running${NC}"
    fi
    
    if systemctl is-active --quiet nginx; then
        echo -e "  Nginx: ${GREEN}✅ Running${NC}"
    else
        echo -e "  Nginx: ${YELLOW}⚠️ Not running${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}
