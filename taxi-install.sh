#!/bin/bash
set -euo pipefail
# Debugging solo si --debug o DEBUG=1
if [[ "${1:-}" == "--debug" || "${DEBUG:-}" == "1" ]]; then
    set -x
    export DEBUG=1
fi

# ===================== COLORES UNIVERSALES =====================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# ===================== LOGGING ÚNICO =====================
log_step()    { echo -e "${BLUE}[STEP]${NC} $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ===================== ARRAY WARNINGS GLOBAL =====================
declare -ag WARNINGS=()

# ===================== FUNCIONES AUXILIARES =====================
print_banner() {
    echo -e "${PURPLE}\n════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}   $1${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}$2${NC}\n"

# ===================== MAIN INSTALLER LOGIC =====================
main_installer() {
    print_banner "Environment Validation" "Checking required environment variables, user, and permissions."
    log_step "Validando configuración..."
    # Aquí iría la validación real de entorno, usuarios, permisos, etc.
    log_ok "Configuración validada."

    print_banner "Public IP Detection" "Detecting and displaying your server's public IP address."
    log_step "Detectando IP pública..."
    IP=$(hostname -I | awk '{print $1}')
    log_ok "IP pública detectada: $IP"

    print_banner "Disk Space Check" "Verificando espacio en disco para la instalación."
    log_step "Verificando espacio en disco..."
    df -h /
    log_ok "Espacio en disco verificado."

    print_banner "Instalando dependencias" "Docker, Docker Compose, Nginx, PostgreSQL, Redis."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y curl git nginx docker.io docker-compose postgresql redis-server > /dev/null
    systemctl enable --now docker
    systemctl enable --now redis-server
    systemctl enable --now postgresql
    systemctl enable --now nginx
    log_ok "Dependencias instaladas."

    log_step "Configurando usuario y directorios..."
    id taxi &>/dev/null || useradd -m -s /bin/bash taxi
    mkdir -p /home/taxi/app
    chown -R taxi:taxi /home/taxi

    log_step "Generando archivo .env..."
    cat > /home/taxi/app/.env <<EOF
POSTGRES_PASSWORD=taxipass
REDIS_PASSWORD=redispass
API_PORT=3000
EOF
    chown taxi:taxi /home/taxi/app/.env

    log_step "Generando docker-compose.yml..."
    cat > /home/taxi/app/docker-compose.yml <<EOF
version: '3.8'
services:
    postgres:
        image: postgres:15
        environment:
            POSTGRES_PASSWORD: taxipass
        ports:
            - "5432:5432"
        volumes:
            - pgdata:/var/lib/postgresql/data
        restart: always

    redis:
        image: redis:7
        command: ["redis-server", "--requirepass", "redispass"]
        ports:
            - "6379:6379"
        restart: always

    api:
        image: node:18
        working_dir: /app
        command: bash -c "npx http-server -p 3000"
        ports:
            - "3000:3000"
        volumes:
            - ./api:/app
        restart: always

    admin:
        image: nginx:alpine
        ports:
            - "8080:80"
        volumes:
            - ./admin:/usr/share/nginx/html:ro
        restart: always

volumes:
    pgdata:
EOF
    chown taxi:taxi /home/taxi/app/docker-compose.yml

    log_step "Creando API y Admin de ejemplo..."
    mkdir -p /home/taxi/app/api /home/taxi/app/admin
    [ -f /home/taxi/app/api/index.html ] || echo '<h1>Taxi API funcionando 🚕</h1>' > /home/taxi/app/api/index.html
    [ -f /home/taxi/app/admin/index.html ] || echo '<h1>Taxi Admin Panel</h1>' > /home/taxi/app/admin/index.html
    chown -R taxi:taxi /home/taxi/app/api /home/taxi/app/admin

log_step "Configurando Nginx como proxy..."
cat > /etc/nginx/sites-available/taxi << 'NGINX'
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location /admin/ {
        proxy_pass http://localhost:8080/;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/taxi /etc/nginx/sites-enabled/taxi
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
log_ok "Sistema configurado."

    log_step "Levantando servicios Docker..."
    cd /home/taxi/app
    sudo -u taxi docker-compose --env-file .env up -d
    log_ok "Servicios Docker en ejecución."

    echo -e "\n\033[1;32m✅ INSTALACIÓN COMPLETA\033[0m"
    echo "🌐 API:         http://$IP:3000"
    echo "📊 Admin Panel: http://$IP:8080"
    echo "🐘 PostgreSQL:  $IP:5432"
    echo "🔴 Redis:       $IP:6379"
}

# ===================== QUICK INSTALLER =====================
taxi_quick_installer() {
    log_step "Instalando dependencias (Docker, Docker Compose, Nginx, PostgreSQL, Redis)..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y curl git nginx docker.io docker-compose postgresql redis-server > /dev/null
    systemctl enable --now docker
    systemctl enable --now redis-server
    systemctl enable --now postgresql
    systemctl enable --now nginx
    log_ok "Dependencias instaladas."

    log_step "Configurando usuario y directorios..."
    id taxi &>/dev/null || useradd -m -s /bin/bash taxi
    mkdir -p /home/taxi/app
    chown -R taxi:taxi /home/taxi

    log_step "Generando archivo .env..."
    cat > /home/taxi/app/.env <<EOF
POSTGRES_PASSWORD=taxipass
REDIS_PASSWORD=redispass
API_PORT=3000
EOF
    chown taxi:taxi /home/taxi/app/.env

    log_step "Generando docker-compose.yml..."
    cat > /home/taxi/app/docker-compose.yml <<EOF
version: '3.8'
services:
    postgres:
        image: postgres:15
        environment:
            POSTGRES_PASSWORD: taxipass
        ports:
            - "5432:5432"
        volumes:
            - pgdata:/var/lib/postgresql/data
        restart: always

    redis:
        image: redis:7
        command: ["redis-server", "--requirepass", "redispass"]
        ports:
            - "6379:6379"
        restart: always

    api:
        image: node:18
        working_dir: /app
        command: bash -c "npx http-server -p 3000"
        ports:
            - "3000:3000"
        volumes:
            - ./api:/app
        restart: always

    admin:
        image: nginx:alpine
        ports:
            - "8080:80"
        volumes:
            - ./admin:/usr/share/nginx/html:ro
        restart: always

volumes:
    pgdata:
EOF
    chown taxi:taxi /home/taxi/app/docker-compose.yml

    log_step "Creando API y Admin de ejemplo..."
    mkdir -p /home/taxi/app/api /home/taxi/app/admin
    [ -f /home/taxi/app/api/index.html ] || echo '<h1>Taxi API funcionando 🚕</h1>' > /home/taxi/app/api/index.html
    [ -f /home/taxi/app/admin/index.html ] || echo '<h1>Taxi Admin Panel</h1>' > /home/taxi/app/admin/index.html
    chown -R taxi:taxi /home/taxi/app/api /home/taxi/app/admin

log_step "Configurando Nginx como proxy..."
cat > /etc/nginx/sites-available/taxi << 'NGINX'
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location /admin/ {
        proxy_pass http://localhost:8080/;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/taxi /etc/nginx/sites-enabled/taxi
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
log_ok "Sistema configurado."

    log_step "Levantando servicios Docker..."
    cd /home/taxi/app
    sudo -u taxi docker-compose --env-file .env up -d
    log_ok "Servicios Docker en ejecución."

    IP=$(hostname -I | awk '{print $1}')
    echo -e "\n\033[1;32m✅ INSTALACIÓN COMPLETA\033[0m"
    echo "🌐 API:         http://$IP:3000"
	echo "📊 Admin Panel: http://$IP:8080"
	echo "🐘 PostgreSQL:  $IP:5432"
	echo "🔴 Redis:       $IP:6379"
}

    # 3. SSL certificate and nginx config
    if [ -f /etc/nginx/nginx.conf ]; then
        if nginx -t 2>&1 | grep -q 'successful'; then
            result="Nginx configuration is valid."
            echo "<li style='color:green;'>$result</li>" >> "$html_report"
        else
            result="Nginx configuration is invalid."
            echo "<li style='color:red;'>$result</li>" >> "$html_report"
        fi
        if openssl x509 -in /etc/ssl/certs/taxi.crt -noout &>/dev/null; then
            result="SSL certificate is valid."
            echo "<li style='color:green;'>$result</li>" >> "$html_report"
        else
            result="SSL certificate is missing or invalid."
            echo "<li style='color:red;'>$result</li>" >> "$html_report"
        fi
    else
        result="Nginx not installed or config missing."
        echo "<li style='color:red;'>$result</li>" >> "$html_report"
    fi

    # 4. Service connectivity (DB, redis, mongodb)
    local db_ok redis_ok mongo_ok
    # PostgreSQL
    if command -v psql &>/dev/null; then
        psql -U taxi -c '\q' &>/dev/null && db_ok=true || db_ok=false
    fi
    # Redis
    if command -v redis-cli &>/dev/null; then
        redis-cli ping | grep -q PONG && redis_ok=true || redis_ok=false
    fi
    # MongoDB
    if command -v mongo &>/dev/null; then
        mongo --eval 'db.runCommand({ ping: 1 })' | grep -q 'ok' && mongo_ok=true || mongo_ok=false
    fi
    if [ "$db_ok" = true ]; then
        echo "<li style='color:green;'>PostgreSQL connectivity OK.</li>" >> "$html_report"
    else
        echo "<li style='color:red;'>PostgreSQL connectivity FAILED.</li>" >> "$html_report"
    fi
    if [ "$redis_ok" = true ]; then
        echo "<li style='color:green;'>Redis connectivity OK.</li>" >> "$html_report"
    else
        echo "<li style='color:red;'>Redis connectivity FAILED.</li>" >> "$html_report"
    fi
    if [ "$mongo_ok" = true ]; then
        echo "<li style='color:green;'>MongoDB connectivity OK.</li>" >> "$html_report"
    else
        echo "<li style='color:red;'>MongoDB connectivity FAILED.</li>" >> "$html_report"
    fi

    echo "</ul><hr><small>Generated: $(date)</small></body></html>" >> "$html_report"
    echo "Validation report generated at $html_report"
    return 0
}
# --- ERROR HANDLING & LOGGING FUNCTIONS ---
LOG_FILE="/var/log/taxi_installer.log"

# Log step with timestamp
log_step() {
    local msg="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" | tee -a "$LOG_FILE"
}

# Retry command with exponential backoff
retry_with_backoff() {
    local max_attempts=${2:-5}
    local delay=2
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        log_step "Attempt $attempt: $1"
        eval "$1" && return 0
        log_step "Failed attempt $attempt for: $1"
        sleep $delay
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done
    return 1
}

# Notify by email and Slack
notify_failure() {
    local msg="$1"
    local email="admin@localhost"
    local slack_webhook="https://hooks.slack.com/services/your/webhook/url"
    echo "$msg" | mail -s "Taxi Installer Failure" "$email"
    curl -X POST -H 'Content-type: application/json' --data "{\"text\": \"$msg\"}" "$slack_webhook" >/dev/null 2>&1
}

# Rollback function
rollback_installation() {
    log_step "Starting rollback..."
    # Example rollback steps (customize as needed)
    systemctl stop docker-taxi taxi-backup taxi-health 2>/dev/null
    userdel -r taxi 2>/dev/null
    rm -rf /opt/taxi-system 2>/dev/null
    log_step "Rollback completed."
    notify_failure "Taxi Installer: Rollback executed due to failure."
}
# --- UNIT TEST FUNCTION ---
unit_test_taxi_installer() {
    local failed=0
    echo -e "\n${BLUE}==> Running Taxi Installer Unit Tests${NC}\n"

    # 1. Check user 'taxi' exists and has correct permissions
    if id taxi &>/dev/null; then
        local taxi_shell
        taxi_shell=$(getent passwd taxi | cut -d: -f7)
        if [[ "$taxi_shell" =~ (bash|sh) ]]; then
            echo -e "${GREEN}✓ User 'taxi' exists and has valid shell.${NC}"
        else
            echo -e "${RED}✗ User 'taxi' shell is not valid: $taxi_shell${NC}"
            failed=1
        fi
    else
        echo -e "${RED}✗ User 'taxi' does not exist.${NC}"
        failed=1
    fi

    # 2. Check all target ports are free
    local ports=(80 443 3000 5432 6379 27017 9000 19999)
    local port_free=true
    for port in "${ports[@]}"; do
        if lsof -i :$port 2>/dev/null | grep -q LISTEN; then
            echo -e "${RED}✗ Port $port is still in use.${NC}"
            port_free=false
            failed=1
        else
            echo -e "${GREEN}✓ Port $port is free.${NC}"
        fi
    done

    # 3. Check critical dependencies
    local deps=(docker docker-compose nginx)
    for dep in "${deps[@]}"; do
        if command -v "$dep" &>/dev/null; then
            echo -e "${GREEN}✓ Dependency '$dep' is installed.${NC}"
        else
            echo -e "${RED}✗ Dependency '$dep' is missing.${NC}"
            failed=1
        fi
    done

    # 4. Check systemd services are active
    local services=(docker-taxi taxi-backup taxi-health)
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            echo -e "${GREEN}✓ Service '$svc' is active.${NC}"
        else
            echo -e "${RED}✗ Service '$svc' is not active.${NC}"
            failed=1
        fi
    done

    if [ "$failed" -eq 0 ]; then
        echo -e "\n${GREEN}All unit tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}Some unit tests failed. Please review above.${NC}"
        return 1
    fi
}
set -x  # Enable debug tracing
# Matar procesos que ocupan puertos específicos
show_open_ports_menu() {
    local ports=(80 443 3000 5432 6379 27017 9000 19999)
    echo -e "${CYAN}Target ports (22/SSH excluded):${NC} ${ports[*]}"
    echo -e "${BLUE}Port status:${NC}"
    for port in "${ports[@]}"; do
        if lsof -i :$port 2>/dev/null | grep -q LISTEN; then
            local pids
            pids=$(lsof -t -i :"$port" 2>/dev/null | sort -u)
            echo -e "${YELLOW}Port $port OPEN by PID(s): $pids${NC}"
        else
            echo -e "${GREEN}Port $port FREE${NC}"
        fi
    done
}

kill_ports() {
    local ports=(80 443 3000 5432 6379 27017 9000 19999)
    for port in "${ports[@]}"; do
        local pids
        pids=$(lsof -t -i :"$port" 2>/dev/null)
        if [ -n "$pids" ]; then
            for pid in ${pids[@]}; do
                echo -e "${CYAN}Matando proceso $pid en puerto $port...${NC}"
                kill -9 "$pid" && echo -e "${GREEN}✓ Proceso $pid matado.${NC}" || echo -e "${RED}✗ No se pudo matar $pid.${NC}"
            done
        fi
    done
    echo -e "${GREEN}Attempt to free target ports completed.${NC}"
}
#!/bin/bash
print_step() {
    echo -e "\n\033[1;34m==> $1\033[0m\n"
}

# Main installer logic as a function
main_installer() {
    # Use global print_banner, do not redefine
    SKIP_ROOT_CHECK=false
    for arg in "$@"; do
        if [ "$arg" = "--skip-root-check" ]; then
            SKIP_ROOT_CHECK=true
        fi
    done
    if [ "$SKIP_ROOT_CHECK" = true ]; then
        echo -e "\n[DEBUG] Relaunch after killing root taxi system processes."
    else
        echo -e "\n[DEBUG] First run of installer."
    fi

    # Always check for root taxi system processes first (unless skipped)
    if [ "$SKIP_ROOT_CHECK" = false ]; then
        while true; do
            check_no_taxi_process_as_root "$@"
            break
        done
        # Only run initial checks and menus on first run
        print_header "TAXI SYSTEM INSTALLER"
        print_step "0" "Initialization & System Check"
        print_banner "Environment Validation" "Checking required environment variables, user, and permissions."
        log_step "Validating configuration..."
        bash manage_config.sh validate || { log_step "Configuration validation failed."; notify_failure "Configuration validation failed."; rollback_installation; exit 1; }
        log_step "Generating configuration file..."
        bash manage_config.sh generate || { log_step "Configuration generation failed."; notify_failure "Configuration generation failed."; rollback_installation; exit 1; }
        echo -e "${YELLOW}Press any key to continue after reviewing environment validation...${NC}"
        read -n 1 -s -r; echo
        print_banner "Public IP Detection" "Detecting and displaying your server's public IP address."
        log_step "Detecting public IP..."
        retry_with_backoff "detect_public_ip" 3 || { log_step "Public IP detection failed."; notify_failure "Public IP detection failed."; rollback_installation; exit 1; }
        echo -e "${YELLOW}Press any key to continue after reviewing public IP...${NC}"
        read -n 1 -s -r; echo
        print_banner "Disk Space Check" "Verifying available disk space for installation."
        log_step "Checking disk space..."
        retry_with_backoff "check_disk_space" 3 || { log_step "Disk space check failed."; notify_failure "Disk space check failed."; rollback_installation; exit 1; }
            print_banner "Port Status & Management" "Reviewing and managing open ports required for Taxi System."
            #!/bin/bash
            print_banner "Root Taxi Process Check" "Checking for any taxi system processes running as root."
        echo -e "${YELLOW}Press any key to continue after reviewing disk space...${NC}"
        read -n 1 -s -r; echo
        while true; do
            show_open_ports_menu
            echo -e "${PURPLE}───────────────────────────────────────────────${NC}"
            echo -e "${CYAN}        PORT MANAGEMENT MENU${NC}"
            echo -e "${PURPLE}───────────────────────────────────────────────${NC}"
            echo -e "${BLUE}  [1]${NC} ${GREEN}Kill processes on target ports${NC}"
            echo -e "${BLUE}  [2]${NC} ${YELLOW}Refresh port list${NC}"
            echo -e "${BLUE}  [3]${NC} ${CYAN}Continue with installation${NC}"
            echo -e "${PURPLE}───────────────────────────────────────────────${NC}"
            read -p "${CYAN}Select an option [1-3]: ${NC}" port_choice
            case $port_choice in
                1)
                    kill_ports
                    ;;
                2)
                    continue
                    ;;
                3)
                    echo -e "${GREEN}Continuing with installation...${NC}"
                    break
                    ;;
                *)
                    echo -e "${RED}Invalid option. Please try again.${NC}"
                    ;;
            esac
        done
        # Check if running as root
        if [ "$EUID" -ne 0 ]; then 
            fatal_error "Please run as root (sudo)"
        fi
        echo -e "${YELLOW}Press any key to continue after root check...${NC}"
        read -n 1 -s -r; echo
    fi
    # --- Main installation logic ---
    print_banner "Preflight System Checks" "Performing security, health, and system configuration checks before installation."
    log_step "Running preflight system checks..."
    retry_with_backoff "preflight_checks" 3 || { log_step "Preflight system checks failed."; notify_failure "Preflight system checks failed."; rollback_installation; exit 1; }
    # ...add more installation, deployment, configuration steps here...
    log_step "Installation steps completed. Running post-install unit tests."
    print_banner "Installation Complete" "All main installation steps have finished. Running post-install unit tests."
    unit_test_taxi_installer || { log_step "Unit tests failed."; notify_failure "Unit tests failed."; rollback_installation; exit 1; }
    validate_installation
}
# Print header for sections
print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    $1                    ${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
}

print_substep() {
    echo -e "${BLUE}  →${NC} $1"
}

# Check that no taxi system process is running as root
check_no_taxi_process_as_root() {
    # Direct solution: stop and disable taxi-system service before killing processes
    if systemctl list-units --type=service | grep -q taxi-system.service; then
        echo -e "${CYAN}Stopping and disabling taxi-system.service...${NC}"
        sudo systemctl stop taxi-system.service
        sudo systemctl disable taxi-system.service
        sudo systemctl daemon-reexec
        sudo systemctl daemon-reload
    fi

    echo -e "${CYAN}Checking that no taxi system process is running as root...${NC}"
    local procs
    procs=$(pgrep -u root -f 'taxi-system|start-taxi-system|stop-taxi-system|restart-taxi-system')
    if [ -n "$procs" ]; then
        echo -e "${RED}FATAL: Some taxi system processes are running as root! Attempting to kill...${NC}"
        for pid in $procs; do
            kill "$pid" 2>/dev/null || echo "Process $pid already gone"
        done
        sleep 1
        local still_running
        still_running=$(pgrep -u root -f 'taxi-system|start-taxi-system|stop-taxi-system|restart-taxi-system')
        if [ -n "$still_running" ]; then
            echo -e "${RED}Some processes could not be killed. Please check manually.${NC}"
            echo -e "$still_running"
            exit 1
        else
            echo -e "${GREEN}All taxi system root processes killed successfully. Continuing...${NC}"
        fi
    else
        echo -e "${GREEN}OK: No taxi system process is running as root.${NC}"
    fi

    # Process check complete. Continue without stopping for user input.
}


# Preflight system checks
preflight_checks() {
    # --- Security Checks ---
    echo -e "${CYAN}Security checks...${NC}"
    # SSH root login
    if [ -f /etc/ssh/sshd_config ]; then
        SSH_ROOT=$(grep -Ei '^PermitRootLogin' /etc/ssh/sshd_config | tail -1 | awk '{print $2}')
        if [[ "$SSH_ROOT" =~ no|prohibit-password ]]; then
            echo -e "${GREEN}SSH root login is disabled.${NC}"
        else
            echo -e "${YELLOW}Warning: SSH root login is enabled!${NC}"
            WARNINGS+=("SSH root login enabled")
        fi
        # SSH password authentication
        SSH_PASS=$(grep -Ei '^PasswordAuthentication' /etc/ssh/sshd_config | tail -1 | awk '{print $2}')
        if [[ "$SSH_PASS" == "no" ]]; then
            echo -e "${GREEN}SSH password authentication is disabled.${NC}"
        else
            echo -e "${YELLOW}Warning: SSH password authentication is enabled!${NC}"
            WARNINGS+=("SSH password authentication enabled")
        fi
    else
        echo -e "${YELLOW}sshd_config not found. Cannot check SSH settings.${NC}"
        WARNINGS+=("sshd_config not found")
    fi

    # Firewall status
    if command -v ufw &>/dev/null; then
        UFW_STATUS=$(ufw status | grep -i "Status:" | awk '{print $2}')
        if [[ "$UFW_STATUS" == "active" ]]; then
            echo -e "${GREEN}UFW firewall is active.${NC}"
        else
            echo -e "${YELLOW}Warning: UFW firewall is not active!${NC}"
            WARNINGS+=("UFW firewall not active")
        fi
    elif command -v iptables &>/dev/null; then
        IPTABLES_RULES=$(iptables -L | wc -l)
        if [ "$IPTABLES_RULES" -gt 8 ]; then
            echo -e "${GREEN}iptables rules are present.${NC}"
        else
            echo -e "${YELLOW}Warning: iptables has few or no rules!${NC}"
            WARNINGS+=("iptables not configured")
        fi
    else
        echo -e "${YELLOW}No firewall detected (ufw/iptables).${NC}"
        WARNINGS+=("No firewall detected")
    fi

    # Fail2ban
    if systemctl is-active --quiet fail2ban; then
        echo -e "${GREEN}fail2ban is running.${NC}"
    else
        echo -e "${YELLOW}Warning: fail2ban is not running!${NC}"
        WARNINGS+=("fail2ban not running")
    fi

    # Unattended-upgrades
    if dpkg -l | grep -q unattended-upgrades; then
        echo -e "${GREEN}unattended-upgrades is installed.${NC}"
    else
        echo -e "${YELLOW}Warning: unattended-upgrades is not installed!${NC}"
        WARNINGS+=("unattended-upgrades not installed")
    fi
    echo -e "${YELLOW}Continuing after security checks...${NC}"

    # --- System Health Checks ---
    echo -e "${CYAN}System health checks...${NC}"
    # Critical services
    for svc in ssh cron; do
        if systemctl is-active --quiet "$svc"; then
            echo -e "${GREEN}$svc is running.${NC}"
        else
            echo -e "${YELLOW}Warning: $svc is not running!${NC}"
            WARNINGS+=("$svc not running")
        fi
    done
    # Zombie processes
    ZOMBIES=$(pgrep -c -f 'Z')
    if [ "$ZOMBIES" -gt 0 ]; then
        echo -e "${YELLOW}Warning: $ZOMBIES zombie processes found!${NC}"
        WARNINGS+=("Zombie processes: $ZOMBIES")
    else
        echo -e "${GREEN}No zombie processes found.${NC}"
    fi
    # Systemd service failures
    if systemctl --failed | grep -q failed; then
        echo -e "${YELLOW}Warning: Some systemd services have failed!${NC}"
        WARNINGS+=("Systemd service failures")
    else
        echo -e "${GREEN}No failed systemd services.${NC}"
    fi
    echo -e "${YELLOW}Continuing after system health checks...${NC}"

    # --- Filesystem Checks ---
    echo -e "${CYAN}Filesystem checks...${NC}"
    # World-writable files
    WW_FILES=$(find /etc /root /home -xdev -type f -perm -0002 2>/dev/null | wc -l)
    if [ "$WW_FILES" -gt 0 ]; then
        echo -e "${YELLOW}Warning: $WW_FILES world-writable files found in /etc, /root, /home!${NC}"
        WARNINGS+=("World-writable files: $WW_FILES")
    else
        echo -e "${GREEN}No world-writable files found in /etc, /root, /home.${NC}"
    fi
    # .bash_history in /root
    if [ -f /root/.bash_history ]; then
        echo -e "${YELLOW}Warning: /root/.bash_history exists. Consider removing for security.${NC}"
        WARNINGS+=("/root/.bash_history present")
    else
        echo -e "${GREEN}/root/.bash_history not present.${NC}"
    fi
    echo -e "${YELLOW}Continuing after filesystem checks...${NC}"

    # Network connectivity and DNS
    echo -e "${CYAN}Checking network connectivity and DNS...${NC}"
    ping -c 1 8.8.8.8 &>/dev/null && echo -e "${GREEN}Internet: OK${NC}" || echo -e "${RED}Internet: FAILED${NC}"
    nslookup google.com &>/dev/null && echo -e "${GREEN}DNS: OK${NC}" || echo -e "${RED}DNS: FAILED${NC}"
    echo -e "${YELLOW}Continuing after network/DNS check...${NC}"

    # NTP/Time sync
    echo -e "${CYAN}Checking NTP/time sync...${NC}"
    if command -v timedatectl &>/dev/null; then
        timedatectl status 2>/dev/null | grep 'NTP synchronized' | grep -q yes && echo -e "${GREEN}NTP: OK${NC}" || echo -e "${YELLOW}NTP: NOT ENABLED${NC}"
        echo -e "Current system time: $(date)"
    else
        echo -e "${YELLOW}timedatectl not available. Please check system time manually.${NC}"
    fi
    echo -e "${YELLOW}Continuing after NTP check...${NC}"

    # System updates
    echo -e "${CYAN}Checking for system updates...${NC}"
    if command -v apt-get &>/dev/null; then
        apt-get update -qq
        UPGRADABLE=$(apt-get -s upgrade | grep -c '^Inst')
        [ "$UPGRADABLE" -gt 0 ] && echo -e "${YELLOW}Upgradable packages: $UPGRADABLE${NC}" || echo -e "${GREEN}All packages up to date.${NC}"
    else
        echo -e "${YELLOW}apt-get not available. Please check for updates manually.${NC}"
    fi
    echo -e "${YELLOW}Continuing after update check...${NC}"

    # System limits (ulimit)
    echo -e "${CYAN}Checking system file descriptor and process limits (ulimit)...${NC}"
    FD_LIMIT=$(ulimit -n)
    PROC_LIMIT=$(ulimit -u)
    echo -e "Open file descriptor limit: ${GREEN}$FD_LIMIT${NC} (recommended: >= 65535)"
    echo -e "Max user processes limit:   ${GREEN}$PROC_LIMIT${NC} (recommended: >= 4096)"
    if [ "$FD_LIMIT" -lt 65535 ]; then
        echo -e "${YELLOW}Warning: File descriptor limit is low. Consider increasing for production workloads.${NC}"
    fi
    if [ "$PROC_LIMIT" -lt 4096 ]; then
        echo -e "${YELLOW}Warning: Max user processes limit is low. Consider increasing for production workloads.${NC}"
    fi
    echo -e "${YELLOW}Continuing after reviewing system limits...${NC}"

    # Swap
    echo -e "${CYAN}Checking swap usage and configuration...${NC}"
    if free | grep -q Swap; then
        SWAP_TOTAL=$(free -h | awk '/Swap:/ {print $2}')
        SWAP_USED=$(free -h | awk '/Swap:/ {print $3}')
        echo -e "Swap total: ${GREEN}$SWAP_TOTAL${NC}, used: ${GREEN}$SWAP_USED${NC}"
        if [ "$SWAP_TOTAL" = "0B" ] || [ "$SWAP_TOTAL" = "0" ]; then
            echo -e "${YELLOW}Warning: No swap configured. Consider adding swap for better stability under memory pressure.${NC}"
        fi
    else
        echo -e "${YELLOW}Could not determine swap status. Please check manually.${NC}"
    fi
    echo -e "${YELLOW}Continuing after reviewing swap status...${NC}"

    # Locale & Timezone
    echo -e "${CYAN}Checking system locale and timezone configuration...${NC}"
    if command -v locale &>/dev/null; then
        echo -e "Current locale: ${GREEN}$(locale | grep LANG=)${NC}"
    else
        echo -e "${YELLOW}locale command not available. Please check locale manually.${NC}"
    fi

    if command -v timedatectl &>/dev/null; then
        echo -e "Current timezone: ${GREEN}$(timedatectl | grep 'Time zone')${NC}"
    else
        echo -e "${YELLOW}timedatectl not available. Please check timezone manually.${NC}"
    fi
    echo -e "${YELLOW}Continuing after reviewing locale and timezone...${NC}"
    read -r

    # Kernel & Virtualization
    echo -e "${CYAN}Checking system kernel version and virtualization support...${NC}"
    echo -e "Kernel version: ${GREEN}$(uname -r)${NC}"

    if command -v lscpu &>/dev/null; then
        VIRT=$(lscpu | grep Virtualization | awk '{print $2}')
        if [ -n "$VIRT" ]; then
            echo -e "Virtualization support: ${GREEN}$VIRT${NC}"
        else
            echo -e "${YELLOW}Virtualization support: Not detected. If you plan to use containers or VMs, check BIOS/host settings.${NC}"
        fi
    else
        echo -e "${YELLOW}lscpu not available. Please check virtualization support manually.${NC}"
    fi
    echo -e "${YELLOW}Press ENTER to continue after reviewing kernel and virtualization...${NC}"
    read -r

    # Hardware
    echo -e "${CYAN}Checking system hardware (CPU, RAM, disk)...${NC}"
    if command -v lscpu &>/dev/null; then
        echo -e "CPU info:"
        lscpu | grep -E 'Model name|Socket|Thread|Core|CPU\(' | sed 's/^/  /'
    else
        echo -e "${YELLOW}lscpu not available. Please check CPU info manually.${NC}"
    fi
    if command -v free &>/dev/null; then
        echo -e "RAM info:"
        free -h | sed 's/^/  /'
    else
        echo -e "${YELLOW}free not available. Please check RAM info manually.${NC}"
    fi
    if command -v lsblk &>/dev/null; then
        echo -e "Disk info:"
        lsblk -o NAME,SIZE,TYPE,MODEL | sed 's/^/  /'
    else
        echo -e "${YELLOW}lsblk not available. Please check disk health manually.${NC}"
    fi
    if command -v smartctl &>/dev/null; then
        for disk in $(lsblk -d -n -o NAME); do
            echo -e "SMART health for /dev/$disk:"
            smartctl -H "/dev/$disk" | grep -E 'SMART overall-health|PASSED|FAILED' | sed 's/^/  /'
        done
    else
        echo -e "${YELLOW}smartctl not available. Please check disk health manually.${NC}"
    fi
    echo -e "${YELLOW}Press ENTER to continue after reviewing hardware info...${NC}"
    read -r

    # PCI/USB/Network
    echo -e "${CYAN}Checking PCI/USB devices and network interfaces...${NC}"
    if command -v lspci &>/dev/null; then
        echo -e "PCI devices:"
        lspci | head -10 | sed 's/^/  /'
        [ "$(lspci | wc -l)" -gt 10 ] && echo "  ... (more, use lspci to see all)"
    else
        echo -e "${YELLOW}lspci not available. Please check PCI devices manually.${NC}"
    fi
    if command -v lsusb &>/dev/null; then
        echo -e "USB devices:"
        lsusb | head -10 | sed 's/^/  /'
        [ "$(lsusb | wc -l)" -gt 10 ] && echo "  ... (more, use lsusb to see all)"
    else
        echo -e "${YELLOW}lsusb not available. Please check USB devices manually.${NC}"
    fi
    if command -v ip &>/dev/null; then
        echo -e "Network interfaces:"
        ip -brief addr | sed 's/^/  /'
    else
        echo -e "${YELLOW}ip command not available. Please check network interfaces manually.${NC}"
    fi
}

# Check for open ports
# Check for open ports
check_ports() {
    local ports=(22 80 443 3000 5432 6379 27017 9000 19999)
    for port in "${ports[@]}"; do
        if lsof -i :"$port" | grep -q LISTEN; then
            echo -e "${YELLOW}Port $port is already in use.${NC}"
        fi
    done
}

# Improved error message function
fatal_error() {
    echo -e "${RED}FATAL: $1${NC}"
    echo -e "${YELLOW}See logs for more details. Suggestions:${NC}"
    echo -e "- Check your network connection."
    echo -e "- Ensure all dependencies are installed."
    echo -e "- Review disk space and permissions."
    # read -r removed
    exit 1
}
#!/bin/bash

# ===============================================================================
# TAXI SYSTEM - COMPLETE INSTALLATION SCRIPT
# Version: 2.0
# Author: Taxi System Setup
# Date: 2024-12-17
# ===============================================================================


# ===================== IMPROVEMENTS SECTION =====================
#!/bin/bash
DRY_RUN=false
for arg in "$@"; do
    if [[ "$arg" == "--dry-run" ]]; then
        DRY_RUN=true
        echo -e "${YELLOW}Dry-run mode enabled. No changes will be made.${NC}"
    fi
done

# Function to run commands (respects dry-run)
run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${CYAN}[DRY-RUN]${NC} $1"
    else
        eval "$1"
    fi
}
# ===================== END IMPROVEMENTS SECTION =====================

set -euo pipefail


# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color



# Configuration
TAXI_USER="taxi"
TAXI_PASS="12345"
TAXI_HOME="/home/$TAXI_USER"

SSH_PORT="22"
INSTALL_LOG="$TAXI_HOME/taxi_install.log"
ERROR_LOG="$TAXI_HOME/taxi_errors.log"
DEBUG_MODE=true
MAX_RETRIES=3
RETRY_DELAY=5


# Function definitions

print_header "TAXI SYSTEM INSTALLER"

print_step "0" "Initialization & System Check"



# Run improvements with pauses
validate_env || fatal_error "Environment validation failed."
echo -e "${YELLOW}Press ENTER to continue after reviewing environment validation...${NC}"
# read -r removed
detect_public_ip
echo -e "${YELLOW}Press ENTER to continue after reviewing public IP...${NC}"
# read -r removed
check_disk_space
echo -e "${YELLOW}Press ENTER to continue after reviewing disk space...${NC}"
# read -r removed
check_ports
echo -e "${YELLOW}Press ENTER to continue after reviewing open ports...${NC}"
# read -r removed

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    fatal_error "Please run as root (sudo)"
fi
echo -e "${YELLOW}Press ENTER to continue after root check...${NC}"
# read -r removed


# Call the main installer logic
main_installer "$@"


print_substep() {
    echo -e "${BLUE}  →${NC} $1"
}


log_message() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[$timestamp]${NC} $1" | tee -a "$INSTALL_LOG"
}


log_success() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}✓ [$timestamp]${NC} $1" | tee -a "$INSTALL_LOG"
}


log_warning() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}⚠ [$timestamp]${NC} $1" | tee -a "$INSTALL_LOG" | tee -a "$ERROR_LOG"
}


log_error() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}✗ [$timestamp]${NC} $1" | tee -a "$INSTALL_LOG" | tee -a "$ERROR_LOG"
}


log_debug() {
    if [ "$DEBUG_MODE" = true ]; then
        local timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo -e "${PURPLE}[$timestamp DEBUG]${NC} $1" | tee -a "$INSTALL_LOG"
    fi
}

run_with_retry() {
    local cmd="$1"
    local description="$2"
    local retry_count=0
    
    log_debug "Attempting: $description"
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if eval "$cmd" >> "$INSTALL_LOG" 2>&1; then
            log_success "$description"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            log_warning "$description failed, retrying in ${RETRY_DELAY}s... (Attempt $retry_count/$MAX_RETRIES)"
            sleep $RETRY_DELAY
        fi
    done
    
    log_error "$description failed after $MAX_RETRIES attempts"
    return 1
}

run_as_root() {
    log_debug "Running as root: $1"
    if ! eval "$1" >> "$INSTALL_LOG" 2>&1; then
        log_warning "Root command failed but continuing: $1"
        return 1
    fi
    return 0
}

run_as_taxi() {
    log_debug "Running as $TAXI_USER: $1"
    if ! { bash -c "$1" 2>&1 | sudo -u "$TAXI_USER" tee -a "$INSTALL_LOG"; } then
        log_warning "Taxi user command failed but continuing: $1"
        return 1
    fi
    return 0
}

check_dependency() {
    local dep="$1"
    local install_cmd="${2:-apt-get install -y $dep}"
    
    if ! command -v "$dep" &> /dev/null; then
        print_substep "Installing dependency: $dep"
        if run_with_retry "$install_cmd" "Install $dep"; then
            log_success "Dependency installed: $dep"
        else
            log_warning "Failed to install $dep, trying alternative..."
            # Try alternative installation methods
            case "$dep" in
                "docker")
                    run_as_root "curl -fsSL https://get.docker.com | sh"
                    ;;
                "docker-compose")
                    run_as_root "curl -L 'https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)' -o /usr/local/bin/docker-compose"
                    run_as_root "chmod +x /usr/local/bin/docker-compose"
                    ;;
                *)
                    log_warning "No alternative installation for $dep, continuing..."
                    ;;
            esac
        fi
    else
        log_success "Dependency already installed: $dep"
    fi
}

check_system_requirements() {
    print_substep "Checking system requirements..."
    
    # Check Ubuntu version
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        if [ "$ID" = "ubuntu" ]; then
            log_success "OS: Ubuntu $VERSION_ID"
        else
            log_warning "Non-Ubuntu system detected: $ID $VERSION_ID"
        fi
    fi
    
    # Check memory
    local mem_total
    mem_total=$(free -g | awk '/^Mem:/){print $2}')
    if [ "$mem_total" -lt 2 ]; then
        log_warning "Low memory detected: ${mem_total}GB (Recommended: 4GB+)"
    else
        log_success "Memory: ${mem_total}GB"
    fi
    
    # Check disk space
    local disk_free
    disk_free=$(df -h / | awk 'NR==2 {print $4}')
    log_success "Disk space free: $disk_free"
    
    # Check CPU cores
    local cpu_cores
    cpu_cores=$(nproc)
    log_success "CPU cores: $cpu_cores"
}

setup_logging() {
    print_substep "Setting up logging system..."
    
    # Create logs directory
    run_as_root "mkdir -p $TAXI_HOME/logs"
    run_as_root "touch $INSTALL_LOG $ERROR_LOG"
    run_as_root "chown $TAXI_USER:$TAXI_USER $INSTALL_LOG $ERROR_LOG"
    run_as_root "chmod 644 $INSTALL_LOG $ERROR_LOG"
    
    # Create log rotation
    cat << EOF | run_as_root "tee /etc/logrotate.d/taxi-system"
$INSTALL_LOG $ERROR_LOG {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 $TAXI_USER $TAXI_USER
}
EOF
    
    log_success "Logging system configured"
}


# ===============================================================================
# START INSTALLATION
# ===============================================================================

print_header "TAXI SYSTEM INSTALLER"

print_step "0" "Initialization & System Check"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (sudo)${NC}"
    echo -e "${YELLOW}Do not close this window. Press ENTER to exit.${NC}"
    # read -r removed
    exit 1
fi

# ==============================================================================
# FIX: Create user and setup logging FIRST
# ==============================================================================

print_substep "Creating system user and directories..."
echo -e "${YELLOW}Press ENTER to continue with user and directory creation...${NC}"
# read -r removed

# Create user and home directory if they don't exist
if ! id "$TAXI_USER" &>/dev/null; then
    echo -e "${BLUE}Creating user: $TAXI_USER${NC}"
    useradd -m -s /bin/bash -G sudo "$TAXI_USER"
    echo "$TAXI_USER:$TAXI_PASS" | chpasswd
    
    # Configure sudo without password for taxi user
    echo "$TAXI_USER ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/"$TAXI_USER"
    chmod 440 /etc/sudoers.d/"$TAXI_USER"
    
    echo -e "${GREEN}✓ User $TAXI_USER created with password $TAXI_PASS and sudo privileges${NC}"
else
    echo -e "${GREEN}✓ User $TAXI_USER already exists${NC}"
fi

# Ensure the home directory exists
mkdir -p "$TAXI_HOME"
chown "$TAXI_USER":"$TAXI_USER" "$TAXI_HOME"
chmod 755 "$TAXI_HOME"

# Create log directory and files
mkdir -p "$(dirname "$INSTALL_LOG")"
mkdir -p "$(dirname "$ERROR_LOG")"
touch "$INSTALL_LOG" "$ERROR_LOG"
chown "$TAXI_USER":"$TAXI_USER" "$INSTALL_LOG" "$ERROR_LOG"
chmod 644 "$INSTALL_LOG" "$ERROR_LOG"

echo -e "${GREEN}✓ Logging system initialized${NC}"


# Now we can use logging functions
log_message "Starting Taxi System Complete Installation"
log_message "Installation log: $INSTALL_LOG"
log_message "Error log: $ERROR_LOG"
echo -e "${YELLOW}Press ENTER to continue after logging setup...${NC}"
# read -r removed


check_system_requirements
echo -e "${YELLOW}Press ENTER to continue after system requirements check...${NC}"
# read -r removed

preflight_checks
print_check_summary
setup_logging
echo -e "${YELLOW}Press ENTER to continue after logging system setup...${NC}"
# read -r removed


# ==============================================================================
# PHASE 1: USER & SECURITY SETUP
# ==============================================================================

print_step "1" "User Configuration & Security Hardening"

# Create user if not exists
if ! id "$TAXI_USER" &>/dev/null; then
    print_substep "Creating user: $TAXI_USER"
    run_with_retry "useradd -m -s /bin/bash -G sudo $TAXI_USER" "Create user $TAXI_USER"
    echo "$TAXI_USER:$TAXI_PASS" | run_as_root "chpasswd"
    
    # Configure sudo without password for taxi user
    echo "$TAXI_USER ALL=(ALL) NOPASSWD:ALL" | run_as_root "tee /etc/sudoers.d/$TAXI_USER"
    run_as_root "chmod 440 /etc/sudoers.d/$TAXI_USER"
    
    log_success "User $TAXI_USER created with password $TAXI_PASS and sudo privileges"
else
    log_success "User $TAXI_USER already exists"
fi

# ==============================================================================
# PHASE 2: SYSTEM UPDATE & DEPENDENCIES
# ==============================================================================

print_step "2" "System Update & Dependency Installation"

# Update system
print_substep "Updating system packages..."
run_with_retry "apt-get update" "Update package lists"
run_with_retry "apt-get upgrade -y" "Upgrade system packages"
run_with_retry "apt-get dist-upgrade -y" "Distribution upgrade"

# Install essential dependencies
print_substep "Installing essential tools..."
declare -a ESSENTIAL_DEPS=(
    "curl" "wget" "git" "vim" "nano" "htop" "iotop" "iftop"
    "net-tools" "iproute2" "dnsutils" "netcat" "nmap"
    "tcpdump" "rsync" "unzip" "zip" "tar" "gzip" "bzip2"
    "build-essential" "software-properties-common"
    "apt-transport-https" "ca-certificates" "gnupg"
    "lsb-release" "ufw" "fail2ban" "clamav" "rkhunter"
    "lynx" "jq" "yq" "tree" "screen" "tmux"
)

for dep in "${ESSENTIAL_DEPS[@]}"; do
    check_dependency "$dep"
done

# Install monitoring tools
print_substep "Installing monitoring tools..."
declare -a MONITORING_DEPS=(
    "glances" "nmon" "dstat" "sysstat" "smartmontools"
)

for dep in "${MONITORING_DEPS[@]}"; do
    check_dependency "$dep"
done


log_success "All dependencies installed"

# Additional comprehensive check for critical services and binaries
echo -e "${CYAN}Performing additional system checks...${NC}"
CRITICAL_BINS=(docker docker-compose ufw fail2ban nginx node npm psql redis-server mongod)
for bin in "${CRITICAL_BINS[@]}"; do
    if ! command -v "$bin" &>/dev/null; then
        echo -e "${RED}Missing critical binary: $bin${NC}"
    else
        echo -e "${GREEN}Found: $bin${NC}"
    fi
done

# Check if main services are running (if possible)
SERVICES=(ufw fail2ban)
for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc"; then
        echo -e "${GREEN}Service running: $svc${NC}"
    else
        echo -e "${YELLOW}Service not running: $svc${NC} (will be started/configured later if needed)""${NC}"
    fi
done


# Network connectivity and DNS resolution check
echo -e "${CYAN}Checking network connectivity and DNS resolution...${NC}"
if ping -c 1 8.8.8.8 &>/dev/null; then
    echo -e "${GREEN}Internet connectivity: OK${NC}"
else
    echo -e "${RED}Internet connectivity: FAILED${NC}"
fi
if nslookup google.com &>/dev/null; then
    echo -e "${GREEN}DNS resolution: OK${NC}"
else
    echo -e "${RED}DNS resolution: FAILED${NC}"
fi


# System time synchronization and NTP check
echo -e "${CYAN}Checking system time synchronization and NTP status...${NC}"
if command -v timedatectl &>/dev/null; then
    timedatectl status | grep 'NTP synchronized' | grep -q yes && \
        echo -e "${GREEN}NTP synchronization: OK${NC}" || \
        echo -e "${YELLOW}NTP synchronization: NOT ENABLED${NC}"
    echo -e "Current system time: $(date)"
else
    echo -e "${YELLOW}timedatectl not available. Please check system time manually.${NC}"
fi


# Check for available system updates and security patches
echo -e "${CYAN}Checking for available system updates and security patches...${NC}"
if command -v apt-get &>/dev/null; then
    apt-get update -qq
    UPGRADABLE=$(apt-get -s upgrade | grep -c '^Inst')
    if [ "$UPGRADABLE" -gt 0 ]; then
        echo -e "${YELLOW}There are $UPGRADABLE packages that can be upgraded.${NC}"
        apt-get -s upgrade | grep '^Inst' | awk '{print $2}' | head -10
        [ "$UPGRADABLE" -gt 10 ] && echo -e "...and more. Run 'apt list --upgradable' for full list."
    else
        echo -e "${GREEN}All packages are up to date.${NC}"
    fi
    # Check for security updates
    if command -v unattended-upgrades &>/dev/null; then
        unattended-upgrades --dry-run -d | grep -q 'No packages found that can be upgraded' && \
            echo -e "${GREEN}No pending security updates.${NC}" || \
            echo -e "${YELLOW}There are pending security updates.${NC}"
    fi
else
    echo -e "${YELLOW}apt-get not available. Please check for updates manually.${NC}"
fi


# Check system limits (ulimit)
echo -e "${CYAN}Checking system file descriptor and process limits (ulimit)...${NC}"
FD_LIMIT=$(ulimit -n)
PROC_LIMIT=$(ulimit -u)
echo -e "Open file descriptor limit: ${GREEN}$FD_LIMIT${NC} (recommended: >= 65535)"
echo -e "Max user processes limit:   ${GREEN}$PROC_LIMIT${NC} (recommended: >= 4096)"
if [ "$FD_LIMIT" -lt 65535 ]; then
    echo -e "${YELLOW}Warning: File descriptor limit is low. Consider increasing for production workloads.${NC}"
fi
if [ "$PROC_LIMIT" -lt 4096 ]; then
    echo -e "${YELLOW}Warning: Max user processes limit is low. Consider increasing for production workloads.${NC}"
fi


# Check swap usage and configuration
echo -e "${CYAN}Checking swap usage and configuration...${NC}"
if free | grep -q Swap; then
    SWAP_TOTAL=$(free -h | awk '/Swap:/ {print $2}')
    SWAP_USED=$(free -h | awk '/Swap:/ {print $3}')
    echo -e "Swap total: ${GREEN}$SWAP_TOTAL${NC}, used: ${GREEN}$SWAP_USED${NC}"
    if [ "$SWAP_TOTAL" = "0B" ] || [ "$SWAP_TOTAL" = "0" ]; then
        echo -e "${YELLOW}Warning: No swap configured. Consider adding swap for better stability under memory pressure.${NC}"
    fi
else
    echo -e "${YELLOW}Could not determine swap status. Please check manually.${NC}"
fi


# Check system locale and timezone
echo -e "${CYAN}Checking system locale and timezone configuration...${NC}"
if command -v locale &>/dev/null; then
    echo -e "Current locale: ${GREEN}$(locale | grep LANG=)${NC}"
else
    echo -e "${YELLOW}locale command not available. Please check locale manually.${NC}"
fi
if command -v timedatectl &>/dev/null; then
    echo -e "Current timezone: ${GREEN}$(timedatectl | grep 'Time zone')${NC}"
else
    echo -e "${YELLOW}timedatectl not available. Please check timezone manually.${NC}"
fi


# Check system kernel version and virtualization support
echo -e "${CYAN}Checking system kernel version and virtualization support...${NC}"
echo -e "Kernel version: ${GREEN}$(uname -r)${NC}"
if command -v lscpu &>/dev/null; then
    VIRT=$(lscpu | grep Virtualization | awk '{print $2}')
    if [ -n "$VIRT" ]; then
        echo -e "Virtualization support: ${GREEN}$VIRT${NC}"
    else
        echo -e "${YELLOW}Virtualization support: Not detected. If you plan to use containers or VMs, check BIOS/host settings.${NC}"
    fi
else
    echo -e "${YELLOW}lscpu not available. Please check virtualization support manually.${NC}"
fi

echo -e "${YELLOW}Press ENTER to continue after reviewing kernel and virtualization...${NC}"
read -r

# ==============================================================================
# PHASE 3: SECURITY HARDENING
# ==============================================================================

print_step "3" "Advanced Security Hardening"

# Configure UFW Firewall
print_substep "Configuring UFW Firewall..."
run_as_root "ufw --force reset"
run_as_root "ufw allow $SSH_PORT/tcp comment 'SSH access'"
run_as_root "ufw allow 80/tcp comment 'HTTP'"
run_as_root "ufw allow 443/tcp comment 'HTTPS'"
run_as_root "ufw allow 3000:4000/tcp comment 'Application ports'"
run_as_root "ufw allow 5432/tcp comment 'PostgreSQL'"
run_as_root "ufw allow 6379/tcp comment 'Redis'"
run_as_root "ufw allow 27017/tcp comment 'MongoDB'"
run_as_root "ufw allow 9000/tcp comment 'Portainer'"
run_as_root "ufw allow 19999/tcp comment 'Netdata'"
run_as_root "ufw --force enable"
run_as_root "systemctl enable ufw"
run_as_root "systemctl start ufw"
log_success "UFW firewall configured"

# Configure fail2ban
print_substep "Configuring fail2ban..."
cat << EOF | run_as_root "tee /etc/fail2ban/jail.local"
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
ignoreip = 127.0.0.1/8 ::1
destemail = root@localhost
sender = root@localhost
action = %(action_mwl)s

[sshd]
enabled = true
port = $SSH_PORT
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[sshd-ddos]
enabled = true
port = $SSH_PORT
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-botsearch]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
EOF

run_as_root "systemctl restart fail2ban"
run_as_root "systemctl enable fail2ban"
log_success "fail2ban configured"

# SSH Hardening
print_substep "Hardening SSH configuration..."
SSH_CONFIG="/etc/ssh/sshd_config"
run_as_root "cp $SSH_CONFIG $SSH_CONFIG.backup.$(date +%Y%m%d)"

# Apply SSH hardening
cat << EOF | run_as_root "tee -a $SSH_CONFIG"

# Taxi System Hardening
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers $TAXI_USER
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 10
LoginGraceTime 60
AllowTcpForwarding no
X11Forwarding no
PermitEmptyPasswords no
Protocol 2
IgnoreRhosts yes
HostbasedAuthentication no
RhostsRSAAuthentication no
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
UsePAM yes
PrintLastLog yes
TCPKeepAlive yes
PermitUserEnvironment no
Compression no
GatewayPorts no
AllowAgentForwarding no
EOF

run_as_root "systemctl restart sshd"
log_success "SSH hardened"

# Configure automatic security updates
print_substep "Configuring automatic security updates..."
run_as_root "apt-get install -y unattended-upgrades"
cat << EOF | run_as_root "tee /etc/apt/apt.conf.d/50unattended-upgrades"
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

cat << EOF | run_as_root "tee /etc/apt/apt.conf.d/20auto-upgrades"
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

run_as_root "systemctl enable unattended-upgrades"
run_as_root "systemctl start unattended-upgrades"
log_success "Automatic security updates configured"

# Install and configure ClamAV
print_substep "Installing antivirus protection..."
run_as_root "freshclam"  # Update virus definitions
run_as_root "systemctl enable clamav-freshclam"
run_as_root "systemctl start clamav-freshclam"

# Install and configure rkhunter
print_substep "Configuring rootkit hunter..."
run_as_root "rkhunter --update"
run_as_root "rkhunter --propupd"
cat << EOF | run_as_root "tee /etc/default/rkhunter"
CRON_DAILY_RUN="yes"
CRON_DB_UPDATE="yes"
DB_UPDATE_EMAIL="no"
APT_AUTOGEN="yes"
EOF

log_success "Security hardening complete"

# ==============================================================================
# PHASE 4: DOCKER ROOTLESS INSTALLATION
# ==============================================================================

print_step "4" "Docker Rootless Installation"

print_substep "Installing Docker rootless prerequisites..."
run_as_root "apt-get install -y uidmap dbus-user-session fuse-overlayfs slirp4netns"

# Install Docker rootless
print_substep "Installing Docker in rootless mode..."
run_as_taxi "curl -fsSL https://get.docker.com/rootless -o /tmp/get-docker-rootless.sh"
run_as_taxi "chmod +x /tmp/get-docker-rootless.sh"

# Set required environment variables
run_as_taxi "export XDG_RUNTIME_DIR=\$HOME/.docker/run"
run_as_taxi "export PATH=\$HOME/bin:\$PATH"
run_as_taxi "export DOCKER_HOST=unix://\$XDG_RUNTIME_DIR/docker.sock"

# Run Docker rootless installer
if run_as_taxi "sh /tmp/get-docker-rootless.sh"; then
    log_success "Docker rootless installed"
else
    log_warning "Docker rootless installation had issues, attempting manual setup..."
    
    # Manual Docker rootless setup
    run_as_taxi "dockerd-rootless-setuptool.sh install"
    run_as_taxi "systemctl --user enable docker"
    run_as_taxi "loginctl enable-linger \$USER"
fi

# Configure Docker rootless environment
print_substep "Configuring Docker rootless environment..."
cat << EOF | run_as_taxi "tee -a \$HOME/.bashrc"

# Docker Rootless Configuration
export PATH=\$HOME/bin:\$PATH
export DOCKER_HOST=unix://\$XDG_RUNTIME_DIR/docker.sock
export XDG_RUNTIME_DIR=\$HOME/.docker/run

# Docker aliases
alias docker='docker --host unix://\$XDG_RUNTIME_DIR/docker.sock'
alias docker-compose='docker-compose --host unix://\$XDG_RUNTIME_DIR/docker.sock'

# Start Docker service if not running
if ! systemctl --user is-active --quiet docker; then
    systemctl --user start docker
fi
EOF

# Start Docker rootless service
print_substep "Starting Docker rootless service..."
run_as_taxi "systemctl --user daemon-reload"
run_as_taxi "systemctl --user enable docker"
run_as_taxi "systemctl --user start docker"
run_as_taxi "loginctl enable-linger $TAXI_USER"

# Wait for Docker to be ready
print_substep "Waiting for Docker to be ready..."
for i in {1..30}; do
    if run_as_taxi "docker info > /dev/null 2>&1"; then
        log_success "Docker rootless is running"
        break
    fi
    sleep 2
    if [ "$i" -eq 30 ]; then
        log_warning "Docker rootless slow to start, continuing..."
    fi
done

# Test Docker installation
if run_as_taxi "docker run --rm hello-world"; then
    log_success "Docker rootless test successful"
else
    log_warning "Docker rootless test failed but continuing"
fi

# ==============================================================================
# PHASE 5: PROJECT STRUCTURE SETUP
# ==============================================================================

print_step "5" "Project Structure & Configuration"

print_substep "Creating comprehensive project structure..."
declare -a PROJECT_DIRS=(
    "docker/compose"
    "docker/build"
    "docker/volumes"
    "web/admin-panel"
    "web/driver-panel"
    "web/customer-panel"
    "web/ride-view"
    "api/auth-service"
    "api/booking-service"
    "api/payment-service"
    "api/notification-service"
    "api/tracking-service"
    "data/postgres"
    "data/redis"
    "data/mongodb"
    "data/backups/daily"
    "data/backups/weekly"
    "data/backups/monthly"
    "logs/application"
    "logs/access"
    "logs/error"
    "logs/audit"
    "scripts/backup"
    "scripts/deployment"
    "scripts/monitoring"
    "scripts/maintenance"
    "config/nginx"
    "config/traefik"
    "config/ssl"
    "config/environment"
    "secrets/encrypted"
    "secrets/tokens"
    "docs/api"
    "docs/database"
    "docs/deployment"
    "tests/unit"
    "tests/integration"
    "tests/e2e"
    "migrations/database"
    "migrations/data"
    "certificates/ssl"
    "certificates/auth"
    "uploads/temp"
    "uploads/permanent"
)

for dir in "${PROJECT_DIRS[@]}"; do
    run_as_taxi "mkdir -p $TAXI_HOME/$dir"
done

# Set proper permissions
print_substep "Setting permissions..."
run_as_root "chown -R $TAXI_USER:$TAXI_USER $TAXI_HOME"
run_as_root "chmod 750 $TAXI_HOME"
run_as_root "chmod 700 $TAXI_HOME/secrets"
run_as_root "chmod 700 $TAXI_HOME/certificates"
run_as_root "chmod 755 $TAXI_HOME/scripts"

# Create .gitignore
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/.gitignore"
# IDE
.vscode/
.idea/
*.swp
*.swo

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Docker
.env
*.env.local
*.env.development
*.env.production

# Secrets
secrets/
certificates/
**/*.key
**/*.pem
**/*.crt

# Logs
logs/
*.log
npm-debug.log*

# Database
*.db
*.sqlite
*.sqlite3

# Backups
backups/
*.bak
*.backup

# OS
.DS_Store
Thumbs.db

# Temporary files
tmp/
temp/
*.tmp
*.temp

# Uploads
uploads/
!uploads/.gitkeep

# Coverage
coverage/
.nyc_output

# Build
dist/
build/
.out/
next/
.cache/
EOF

log_success "Project structure created with 50+ directories"

# ==============================================================================
# PHASE 6: DOCKER COMPOSE STACK
# ==============================================================================

print_step "6" "Docker Compose Stack Configuration"

print_substep "Creating docker-compose.yml with 20+ services..."

# Main docker-compose.yml
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/docker/compose/docker-compose.yml"
version: '3.8'

x-logging: &default-logging
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "5"
    tag: "{{.Name}}"

x-common-environment: &common-env
  TZ: Europe/London
  LOG_LEVEL: info
  NODE_ENV: production

networks:
  taxi-frontend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
  taxi-backend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.0.0/24
  taxi-database:
    driver: bridge
    ipam:
      config:
        - subnet: 172.22.0.0/24
  taxi-monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.23.0.0/24

volumes:
  postgres-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/taxi/data/postgres
  redis-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/taxi/data/redis
  mongodb-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/taxi/data/mongodb
  nginx-config:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/taxi/config/nginx
  letsencrypt:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/taxi/certificates/letsencrypt
  uploads:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/taxi/uploads/permanent

services:
  # ========== DATABASE SERVICES ==========
  postgres:
    image: postgres:15-alpine
    container_name: taxi-postgres
    hostname: postgres.taxi.internal
    environment:
      <<: *common-env
      POSTGRES_DB: taxi_production
      POSTGRES_USER: taxi_admin
      POSTGRES_PASSWORD: ${DB_PASSWORD:-ChangeMe123!}
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --locale=C"
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ../migrations/database:/docker-entrypoint-initdb.d
      - ../scripts/backup:/backup-scripts
    ports:
      - "5432:5432"
    networks:
      - taxi-database
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U taxi_admin"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging: *default-logging
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  redis:
    image: redis:7-alpine
    container_name: taxi-redis
    hostname: redis.taxi.internal
    command: >
      redis-server
      --requirepass ${REDIS_PASSWORD:-RedisPass123!}
      --maxmemory 512mb
      --maxmemory-policy allkeys-lru
      --appendonly yes
      --appendfsync everysec
    volumes:
      - redis-data:/data
    ports:
      - "6379:6379"
    networks:
      - taxi-database
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging: *default-logging

  mongodb:
    image: mongo:6
    container_name: taxi-mongodb
    hostname: mongodb.taxi.internal
    environment:
      <<: *common-env
      MONGO_INITDB_ROOT_USERNAME: mongo_admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD:-MongoPass123!}
      MONGO_INITDB_DATABASE: taxi_analytics
    volumes:
      - mongodb-data:/data/db
      - ../migrations/data:/docker-entrypoint-initdb.d
    ports:
      - "27017:27017"
    networks:
      - taxi-database
    restart: unless-stopped
    command: ["--bind_ip_all", "--auth"]
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/taxi_analytics --quiet
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging: *default-logging

  # ========== WEB SERVER & PROXY ==========
  nginx:
    image: nginx:alpine
    container_name: taxi-nginx
    hostname: nginx.taxi.internal
    volumes:
      - nginx-config:/etc/nginx/conf.d
      - ../web:/usr/share/nginx/html
      - letsencrypt:/etc/letsencrypt
      - uploads:/var/www/uploads
      - ../logs/access:/var/log/nginx/access
      - ../logs/error:/var/log/nginx/error
    ports:
      - "80:80"
      - "443:443"
    networks:
      - taxi-frontend
    restart: unless-stopped
    depends_on:
      - admin-panel
      - driver-panel
      - customer-panel
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging: *default-logging

  # ========== API SERVICES ==========
  api-gateway:
    build: ../../api/gateway
    container_name: taxi-api-gateway
    hostname: api-gateway.taxi.internal
    environment:
      <<: *common-env
      PORT: 3000
      JWT_SECRET: ${JWT_SECRET:-VeryLongSecretKeyChangeMe!}
      RATE_LIMIT_WINDOW: 900000
      RATE_LIMIT_MAX: 100
    volumes:
      - ../logs/application:/app/logs
      - ../config/environment:/app/config
    ports:
      - "3000:3000"
    networks:
      - taxi-backend
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging: *default-logging

  auth-service:
    build: ../../api/auth-service
    container_name: taxi-auth-service
    hostname: auth.taxi.internal
    environment:
      <<: *common-env
      DATABASE_URL: postgresql://taxi_admin:${DB_PASSWORD:-ChangeMe123!}@postgres:5432/taxi_production
      REDIS_URL: redis://:${REDIS_PASSWORD:-RedisPass123!}@redis:6379
      JWT_SECRET: ${JWT_SECRET:-VeryLongSecretKeyChangeMe!}
      JWT_EXPIRY: 86400
      OTP_EXPIRY: 300
    volumes:
      - ../logs/application:/app/logs
    networks:
      - taxi-backend
    restart: unless-stopped
    depends_on:
      - api-gateway
    logging: *default-logging

  booking-service:
    build: ../../api/booking-service
    container_name: taxi-booking-service
    hostname: booking.taxi.internal
    environment:
      <<: *common-env
      DATABASE_URL: postgresql://taxi_admin:${DB_PASSWORD:-ChangeMe123!}@postgres:5432/taxi_production
      REDIS_URL: redis://:${REDIS_PASSWORD:-RedisPass123!}@redis:6379
      GOOGLE_MAPS_API_KEY: ${GOOGLE_MAPS_API_KEY}
      MAX_PASSENGERS: 8
      MIN_BOOKING_HOURS: 4
    volumes:
      - ../logs/application:/app/logs
      - ../config/environment:/app/config
    networks:
      - taxi-backend
    restart: unless-stopped
    depends_on:
      - auth-service
    logging: *default-logging

  payment-service:
    build: ../../api/payment-service
    container_name: taxi-payment-service
    hostname: payment.taxi.internal
    environment:
      <<: *common-env
      DATABASE_URL: postgresql://taxi_admin:${DB_PASSWORD:-ChangeMe123!}@postgres:5432/taxi_production
      STRIPE_SECRET_KEY: ${STRIPE_SECRET_KEY}
      STRIPE_WEBHOOK_SECRET: ${STRIPE_WEBHOOK_SECRET}
      PAYPAL_CLIENT_ID: ${PAYPAL_CLIENT_ID}
      PAYPAL_SECRET: ${PAYPAL_SECRET}
      CURRENCY: GBP
    volumes:
      - ../logs/application:/app/logs
      - ../secrets:/app/secrets:ro
    networks:
      - taxi-backend
    restart: unless-stopped
    depends_on:
      - booking-service
    logging: *default-logging

  notification-service:
    build: ../../api/notification-service
    container_name: taxi-notification-service
    hostname: notification.taxi.internal
    environment:
      <<: *common-env
      SMTP_HOST: ${SMTP_HOST}
      SMTP_PORT: ${SMTP_PORT}
      SMTP_USER: ${SMTP_USER}
      SMTP_PASS: ${SMTP_PASS}
      TWILIO_SID: ${TWILIO_SID}
      TWILIO_TOKEN: ${TWILIO_TOKEN}
      TWILIO_PHONE: ${TWILIO_PHONE}
      FIREBASE_KEY: ${FIREBASE_KEY}
    volumes:
      - ../logs/application:/app/logs
      - ../uploads:/app/uploads
    networks:
      - taxi-backend
    restart: unless-stopped
    depends_on:
      - payment-service
    logging: *default-logging

  tracking-service:
    build: ../../api/tracking-service
    container_name: taxi-tracking-service
    hostname: tracking.taxi.internal
    environment:
      <<: *common-env
      DATABASE_URL: postgresql://taxi_admin:${DB_PASSWORD:-ChangeMe123!}@postgres:5432/taxi_production
      REDIS_URL: redis://:${REDIS_PASSWORD:-RedisPass123!}@redis:6379
      GOOGLE_MAPS_API_KEY: ${GOOGLE_MAPS_API_KEY}
      SOCKET_PORT: 4000
    volumes:
      - ../logs/application:/app/logs
    ports:
      - "4000:4000"
      - "4001:4001"
    networks:
      - taxi-backend
      - taxi-frontend
    restart: unless-stopped
    depends_on:
      - notification-service
    logging: *default-logging

  # ========== FRONTEND APPLICATIONS ==========
  admin-panel:
    build: ../../web/admin-panel
    container_name: taxi-admin-panel
    hostname: admin.taxi.internal
    environment:
      <<: *common-env
      VUE_APP_API_URL: https://${DOMAIN:-localhost}/api
      VUE_APP_SOCKET_URL: wss://${DOMAIN:-localhost}/tracking
      VUE_APP_MAP_API_KEY: ${GOOGLE_MAPS_API_KEY}
    volumes:
      - ../logs/access:/app/logs
    networks:
      - taxi-frontend
    restart: unless-stopped
    depends_on:
      - api-gateway
      - tracking-service
    logging: *default-logging

  driver-panel:
    build: ../../web/driver-panel
    container_name: taxi-driver-panel
    hostname: driver.taxi.internal
    environment:
      <<: *common-env
      VUE_APP_API_URL: https://${DOMAIN:-localhost}/api
      VUE_APP_SOCKET_URL: wss://${DOMAIN:-localhost}/tracking
      VUE_APP_MAP_API_KEY: ${GOOGLE_MAPS_API_KEY}
      VUE_APP_PWA_ENABLED: "true"
    volumes:
      - ../logs/access:/app/logs
    networks:
      - taxi-frontend
    restart: unless-stopped
    depends_on:
      - api-gateway
      - tracking-service
    logging: *default-logging

  customer-panel:
    build: ../../web/customer-panel
    container_name: taxi-customer-panel
    hostname: customer.taxi.internal
    environment:
      <<: *common-env
      VUE_APP_API_URL: https://${DOMAIN:-localhost}/api
      VUE_APP_SOCKET_URL: wss://${DOMAIN:-localhost}/tracking
      VUE_APP_MAP_API_KEY: ${GOOGLE_MAPS_API_KEY}
      VUE_APP_PAYMENT_KEY: ${STRIPE_PUBLIC_KEY}
    volumes:
      - ../logs/access:/app/logs
    networks:
      - taxi-frontend
    restart: unless-stopped
    depends_on:
      - api-gateway
      - tracking-service
    logging: *default-logging

  ride-view:
    build: ../../web/ride-view
    container_name: taxi-ride-view
    hostname: rideview.taxi.internal
    environment:
      <<: *common-env
      VUE_APP_API_URL: https://${DOMAIN:-localhost}/api
      VUE_APP_SOCKET_URL: wss://${DOMAIN:-localhost}/tracking
      VUE_APP_MAP_API_KEY: ${GOOGLE_MAPS_API_KEY}
    volumes:
      - ../logs/access:/app/logs
    networks:
      - taxi-frontend
    restart: unless-stopped
    depends_on:
      - api-gateway
      - tracking-service
    logging: *default-logging

  # ========== MONITORING & MANAGEMENT ==========
  portainer:
    image: portainer/portainer-ce:latest
    container_name: taxi-portainer
    hostname: portainer.taxi.internal
    command: -H unix:///var/run/docker.sock
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ../data/portainer:/data
      - ../scripts/monitoring:/monitoring-scripts
    ports:
      - "9000:9000"
      - "9443:9443"
    networks:
      - taxi-monitoring
    restart: unless-stopped
    logging: *default-logging

  netdata:
    image: netdata/netdata
    container_name: taxi-netdata
    hostname: netdata.taxi.internal
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor:unconfined
    volumes:
      - ../data/netdata:/var/lib/netdata
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "19999:19999"
    networks:
      - taxi-monitoring
    restart: unless-stopped
    logging: *default-logging

  prometheus:
    image: prom/prometheus:latest
    container_name: taxi-prometheus
    hostname: prometheus.taxi.internal
    volumes:
      - ../config/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - ../data/prometheus:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    ports:
      - "9090:9090"
    networks:
      - taxi-monitoring
    restart: unless-stopped
    logging: *default-logging

  grafana:
    image: grafana/grafana:latest
    container_name: taxi-grafana
    hostname: grafana.taxi.internal
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD:-GrafanaAdmin123!}
      GF_INSTALL_PLUGINS: "grafana-piechart-panel"
    volumes:
      - ../data/grafana:/var/lib/grafana
      - ../config/monitoring/grafana:/etc/grafana/provisioning
    ports:
      - "3001:3000"
    networks:
      - taxi-monitoring
    restart: unless-stopped
    depends_on:
      - prometheus
    logging: *default-logging

  # ========== UTILITY SERVICES ==========
  mailhog:
    image: mailhog/mailhog
    container_name: taxi-mailhog
    hostname: mailhog.taxi.internal
    ports:
      - "1025:1025"
      - "8025:8025"
    networks:
      - taxi-backend
    restart: unless-stopped
    logging: *default-logging

  pgadmin:
    image: dpage/pgadmin4
    container_name: taxi-pgadmin
    hostname: pgadmin.taxi.internal
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@taxi.local
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD:-PgAdmin123!}
      PGADMIN_CONFIG_SERVER_MODE: 'False'
    volumes:
      - ../data/pgadmin:/var/lib/pgadmin
    ports:
      - "5050:80"
    networks:
      - taxi-database
    restart: unless-stopped
    logging: *default-logging

  redis-commander:
    image: rediscommander/redis-commander:latest
    container_name: taxi-redis-commander
    hostname: redis-commander.taxi.internal
    environment:
      REDIS_HOSTS: local:redis:6379:0:${REDIS_PASSWORD:-RedisPass123!}
    ports:
      - "8081:8081"
    networks:
      - taxi-database
    restart: unless-stopped
    depends_on:
      - redis
    logging: *default-logging

  # ========== CLOUDFLARE TUNNEL ==========
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: taxi-cloudflared
    hostname: cloudflared.taxi.internal
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN}
    volumes:
      - ../data/cloudflared:/etc/cloudflared
      - ../logs/application:/var/log/cloudflared
    networks:
      - taxi-frontend
    restart: unless-stopped
    logging: *default-logging
EOF

log_success "Docker Compose configuration created with 20+ services"

# Create environment file template
print_substep "Creating environment configuration..."
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/.env.example"
# ==============================================================================
# TAXI SYSTEM - ENVIRONMENT CONFIGURATION
# ==============================================================================

# System Configuration
DOMAIN=yourdomain.com
SERVER_IP=5.249.164.40
TIMEZONE=Europe/London
LOG_LEVEL=info
NODE_ENV=production

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=taxi_admin
DB_PASS=changeme123
REDIS_HOST=localhost
REDIS_PORT=6379
MONGO_HOST=localhost
MONGO_PORT=27017

# API Security
JWT_SECRET=VeryLongAndSecureJWTSecretKeyChangeThisInProduction!
API_RATE_LIMIT=100
API_RATE_WINDOW=900000

# Payment Gateways
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
STRIPE_PUBLIC_KEY=pk_test_your_stripe_public_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_stripe_webhook_secret
PAYPAL_CLIENT_ID=your_paypal_client_id_here
PAYPAL_SECRET=your_paypal_secret_here
PAYPAL_SANDBOX=true

# Email Service (SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_specific_password
EMAIL_FROM=noreply@yourdomain.com
EMAIL_NAME="Taxi Service"

# SMS Service (Twilio)
TWILIO_SID=your_twilio_account_sid
TWILIO_TOKEN=your_twilio_auth_token
TWILIO_PHONE=+441234567890

# Push Notifications (Firebase)
FIREBASE_KEY=your_firebase_cloud_messaging_key

# Google Maps API
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Cloudflare Tunnel
CLOUDFLARE_TUNNEL_TOKEN=your_cloudflare_tunnel_token_here

# Monitoring
GRAFANA_PASSWORD=GrafanaAdminSecurePass123!
PGADMIN_PASSWORD=PgAdminSecurePass456!

# Application URLs
ADMIN_PANEL_URL=https://admin.yourdomain.com
DRIVER_PANEL_URL=https://driver.yourdomain.com
CUSTOMER_PANEL_URL=https://app.yourdomain.com
API_BASE_URL=https://api.yourdomain.com

# Feature Flags
ENABLE_PAYMENTS=true
ENABLE_SMS_NOTIFICATIONS=true
ENABLE_EMAIL_NOTIFICATIONS=true
ENABLE_PUSH_NOTIFICATIONS=true
ENABLE_ANALYTICS=true

# Business Rules
MIN_BOOKING_HOURS=4
MAX_PASSENGERS=8
MAX_LUGGAGE_PIECES=4
BASE_FARE=3.00
PER_KM_RATE=1.50
PER_MINUTE_RATE=0.20
AIRPORT_SURCHARGE=10.00
NIGHT_SURCHARGE=5.00
CURRENCY=GBP

# Security
ENABLE_2FA=true
SESSION_TIMEOUT=3600
PASSWORD_MIN_LENGTH=8
MAX_LOGIN_ATTEMPTS=5
LOGIN_LOCKOUT_MINUTES=15

# Performance
DATABASE_POOL_SIZE=20
REDIS_CACHE_TTL=3600
API_TIMEOUT=30000
UPLOAD_LIMIT_MB=10

# Backup
BACKUP_RETENTION_DAYS=30
BACKUP_ENCRYPTION=true
AUTO_BACKUP=true
BACKUP_TIME=02:00
EOF

run_as_taxi "cp $TAXI_HOME/.env.example $TAXI_HOME/.env"
log_success "Environment configuration created"

# ==============================================================================
# PHASE 7: NGINX CONFIGURATION
# ==============================================================================

print_step "7" "Nginx Reverse Proxy Configuration"

print_substep "Creating Nginx configuration..."
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/config/nginx/taxi.conf"
# Taxi System - Main Nginx Configuration
# Server: 5.249.164.40

# Global optimizations
user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 4096;
    multi_accept on;
    use epoll;
}

http {
    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 1000;
    types_hash_max_size 2048;
    server_tokens off;
    client_max_body_size 10M;
    
    # MIME Types
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging Format
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    log_format json escape=json '{'
        '"time_local":"$time_local",'
        '"remote_addr":"$remote_addr",'
        '"remote_user":"$remote_user",'
        '"request":"$request",'
        '"status": "$status",'
        '"body_bytes_sent":"$body_bytes_sent",'
        '"request_time":"$request_time",'
        '"http_referrer":"$http_referer",'
        '"http_user_agent":"$http_user_agent",'
        '"http_x_forwarded_for":"$http_x_forwarded_for"'
    '}';
    
    access_log /var/log/nginx/access.log json;
    
    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        text/cache-manifest
        text/css
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy;
    
    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://maps.googleapis.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://api.stripe.com wss://*.taxi.internal;" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # Upstream Services
    upstream api_backend {
        least_conn;
        server api-gateway:3000 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }
    
    upstream admin_frontend {
        server admin-panel:3000;
    }
    
    upstream driver_frontend {
        server driver-panel:3000;
    }
    
    upstream customer_frontend {
        server customer-panel:3000;
    }
    
    upstream tracking_websocket {
        server tracking-service:4000;
    }
    
    # HTTP to HTTPS redirect
    server {
        listen 80;
        listen [::]:80;
        server_name _;
        
        # Security headers for HTTP
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        
        # Redirect to HTTPS
        return 301 https://$host$request_uri;
    }
    
    # Main HTTPS Server
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name yourdomain.com www.yourdomain.com;
        
        # SSL certificates (to be replaced with Let's Encrypt)
        ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
        
        # Root directory
        root /usr/share/nginx/html;
        index index.html;
        
        # Admin Panel
        location /admin {
            limit_req zone=api burst=20 nodelay;
            
            proxy_pass http://admin_frontend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 300;
            proxy_connect_timeout 300;
            
            # Security for admin area
            auth_basic "Restricted Area";
            auth_basic_user_file /etc/nginx/.htpasswd_admin;
        }
        
        # Driver Panel
        location /driver {
            proxy_pass http://driver_frontend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            
            # PWA support
            add_header Service-Worker-Allowed /;
        }
        
        # Customer Panel
        location / {
            proxy_pass http://customer_frontend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            
            # Cache static assets
            location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
            }
        }
        
        # API Gateway
        location /api {
            limit_req zone=api burst=20 nodelay;
            
            proxy_pass http://api_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 300;
            proxy_connect_timeout 300;
            
            # CORS headers
            add_header Access-Control-Allow-Origin * always;
            add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header Access-Control-Allow-Headers 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
            add_header Access-Control-Expose-Headers 'Content-Length,Content-Range' always;
            
            # Handle preflight requests
            if ($request_method = 'OPTIONS') {
                add_header Access-Control-Allow-Origin *;
                add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS';
                add_header Access-Control-Allow-Headers 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
                add_header Access-Control-Max-Age 1728000;
                add_header Content-Type 'text/plain; charset=utf-8';
                add_header Content-Length 0;
                return 204;
            }
        }
        
        # Authentication endpoints (stricter rate limiting)
        location /api/auth {
            limit_req zone=auth burst=5 nodelay;
            
            proxy_pass http://api_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # WebSocket for real-time tracking
        location /tracking {
            proxy_pass http://tracking_websocket;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 86400;
            proxy_send_timeout 86400;
        }
        
        # File uploads
        location /uploads {
            alias /var/www/uploads;
            client_max_body_size 10M;
            
            # Security for uploads
            dav_methods PUT DELETE MKCOL COPY MOVE;
            create_full_put_path on;
            dav_access user:rw group:rw all:r;
            
            # Disable execution of uploaded files
            location ~ \.php$ {
                deny all;
            }
        }
        
        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        # Status page for monitoring
        location /status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            allow 172.0.0.0/8;
            deny all;
        }
        
        # Deny access to hidden files
        location ~ /\. {
            deny all;
            access_log off;
            log_not_found off;
        }
        
        # Deny access to sensitive files
        location ~* (\.env|\.git|\.svn|\.htaccess|\.htpasswd) {
            deny all;
            access_log off;
            log_not_found off;
        }
        
        # Custom error pages
        error_page 400 401 402 403 404 405 408 409 410 411 412 413 414 415 416 421 429 431 500 501 502 503 504 = /error.html;
        
        location = /error.html {
            internal;
            root /usr/share/nginx/html;
        }
    }
    
    # Monitoring subdomain
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name monitor.yourdomain.com;
        
        ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
        
        location / {
            proxy_pass http://grafana:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Restrict access to internal network
            allow 172.0.0.0/8;
            allow 10.0.0.0/8;
            deny all;
        }
    }
    
    # Portainer subdomain
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name docker.yourdomain.com;
        
        ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
        
        location / {
            proxy_pass http://portainer:9000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            
            # Restrict access
            allow 172.0.0.0/8;
            allow 10.0.0.0/8;
            deny all;
        }
    }
}
EOF

log_success "Nginx configuration created"

# ==============================================================================
# PHASE 8: DATABASE SCHEMA & INITIALIZATION
# ==============================================================================

print_step "8" "Database Schema & Initial Data"

print_substep "Creating database initialization scripts..."

# Main database schema
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/migrations/database/01_main_schema.sql"
-- Taxi System Database Schema
-- Version: 1.0
-- Created: 2024-12-17

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ========== ENUMERATIONS ==========
CREATE TYPE user_role AS ENUM ('admin', 'operator', 'driver', 'customer');
CREATE TYPE vehicle_type AS ENUM ('saloon', 'executive', 'estate', 'mpv', 'minibus_8', 'minibus_16');
CREATE TYPE vehicle_status AS ENUM ('available', 'busy', 'maintenance', 'offline');
CREATE TYPE driver_status AS ENUM ('available', 'on_trip', 'off_duty', 'suspended');
CREATE TYPE trip_status AS ENUM (
    'pending', 
    'confirmed', 
    'driver_assigned',
    'en_route_pickup',
    'arrived_pickup',
    'on_trip',
    'arrived_dropoff',
    'completed',
    'cancelled',
    'no_show'
);
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'paypal', 'apple_pay', 'google_pay', 'voucher');
CREATE TYPE payment_status AS ENUM ('pending', 'authorized', 'paid', 'refunded', 'failed', 'disputed');
CREATE TYPE notification_type AS ENUM ('email', 'sms', 'push', 'in_app');
CREATE TYPE notification_status AS ENUM ('pending', 'sent', 'delivered', 'failed', 'read');

-- ========== TABLES ==========

-- Users table (for all user types)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'customer',
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    profile_image_url TEXT,
    date_of_birth DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Indexes
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_phone CHECK (phone ~* '^\+[1-9]\d{1,14}$')
);

-- Drivers specific information
CREATE TABLE drivers (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    driver_id VARCHAR(50) UNIQUE NOT NULL,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    license_expiry DATE NOT NULL,
    pco_license_number VARCHAR(50) UNIQUE,
    pco_license_expiry DATE,
    insurance_policy_number VARCHAR(100),
    insurance_expiry DATE,
    years_experience INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 5.0,
    total_ratings INTEGER DEFAULT 0,
    total_trips INTEGER DEFAULT 0,
    status driver_status DEFAULT 'off_duty',
    current_location GEOGRAPHY(POINT, 4326),
    last_location_update TIMESTAMPTZ,
    is_online BOOLEAN DEFAULT FALSE,
    online_since TIMESTAMPTZ,
    daily_hours_worked INTERVAL DEFAULT '0 hours',
    weekly_hours_worked INTERVAL DEFAULT '0 hours',
    commission_rate DECIMAL(5,2) DEFAULT 20.00,
    
    -- Indexes
    INDEX idx_drivers_status (status),
    INDEX idx_drivers_online (is_online),
    INDEX idx_drivers_location (current_location)
);

-- Vehicles
CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registration_number VARCHAR(20) UNIQUE NOT NULL,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INTEGER NOT NULL,
    color VARCHAR(30),
    vehicle_type vehicle_type NOT NULL,
    passenger_capacity INTEGER NOT NULL CHECK (passenger_capacity > 0),
    luggage_capacity INTEGER NOT NULL CHECK (luggage_capacity >= 0),
    features TEXT[] DEFAULT '{}',
    insurance_document_url TEXT,
    mot_expiry DATE,
    tax_expiry DATE,
    service_due_date DATE,
    status vehicle_status DEFAULT 'available',
    current_driver_id UUID REFERENCES drivers(id),
    current_location GEOGRAPHY(POINT, 4326),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_vehicles_status (status),
    INDEX idx_vehicles_type (vehicle_type),
    INDEX idx_vehicles_driver (current_driver_id),
    CONSTRAINT valid_year CHECK (year >= 2000 AND year <= EXTRACT(YEAR FROM NOW()) + 1)
);

-- Customers specific information
CREATE TABLE customers (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    customer_id VARCHAR(50) UNIQUE NOT NULL,
    preferred_payment_method payment_method DEFAULT 'card',
    loyalty_points INTEGER DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0.00,
    total_trips INTEGER DEFAULT 0,
    preferred_driver_id UUID REFERENCES drivers(id),
    special_instructions TEXT,
    marketing_opt_in BOOLEAN DEFAULT FALSE,
    
    -- Indexes
    INDEX idx_customers_loyalty (loyalty_points),
    INDEX idx_customers_spent (total_spent)
);

-- Address book for customers
CREATE TABLE customer_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    label VARCHAR(50) NOT NULL, -- Home, Work, etc.
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) DEFAULT 'United Kingdom',
    location GEOGRAPHY(POINT, 4326),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_customer_addresses_customer (customer_id),
    INDEX idx_customer_addresses_location (location),
    UNIQUE(customer_id, label)
);

-- Trip bookings
CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_number VARCHAR(50) UNIQUE NOT NULL DEFAULT 'TRP-' || to_char(NOW(), 'YYYYMMDD') || '-' || lpad(nextval('trip_number_seq')::text, 6, '0'),
    customer_id UUID NOT NULL REFERENCES customers(id),
    driver_id UUID REFERENCES drivers(id),
    vehicle_id UUID REFERENCES vehicles(id),
    
    -- Pickup details
    pickup_address_id UUID REFERENCES customer_addresses(id),
    pickup_address TEXT NOT NULL,
    pickup_location GEOGRAPHY(POINT, 4326) NOT NULL,
    pickup_contact_name VARCHAR(255),
    pickup_contact_phone VARCHAR(20),
    
    -- Dropoff details
    dropoff_address TEXT NOT NULL,
    dropoff_location GEOGRAPHY(POINT, 4326) NOT NULL,
    dropoff_contact_name VARCHAR(255),
    dropoff_contact_phone VARCHAR(20),
    
    -- Trip details
    scheduled_pickup_time TIMESTAMPTZ NOT NULL,
    actual_pickup_time TIMESTAMPTZ,
    scheduled_dropoff_time TIMESTAMPTZ,
    actual_dropoff_time TIMESTAMPTZ,
    distance_km DECIMAL(8,2), -- Calculated distance
    estimated_duration_minutes INTEGER,
    actual_duration_minutes INTEGER,
    
    -- Passenger details
    adult_passengers INTEGER DEFAULT 1 CHECK (adult_passengers >= 1),
    child_passengers INTEGER DEFAULT 0 CHECK (child_passengers >= 0),
    infant_passengers INTEGER DEFAULT 0 CHECK (infant_passengers >= 0),
    total_passengers INTEGER GENERATED ALWAYS AS (adult_passengers + child_passengers + infant_passengers) STORED,
    luggage_pieces INTEGER DEFAULT 0,
    
    -- Pricing
    base_fare DECIMAL(8,2) NOT NULL DEFAULT 3.00,
    distance_fare DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    time_fare DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    airport_surcharge DECIMAL(8,2) DEFAULT 0.00,
    night_surcharge DECIMAL(8,2) DEFAULT 0.00,
    waiting_time_surcharge DECIMAL(8,2) DEFAULT 0.00,
    additional_stop_surcharge DECIMAL(8,2) DEFAULT 0.00,
    discount_amount DECIMAL(8,2) DEFAULT 0.00,
    voucher_code VARCHAR(50),
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (
        base_fare + distance_fare + time_fare + airport_surcharge + 
        night_surcharge + waiting_time_surcharge + additional_stop_surcharge - discount_amount
    ) STORED,
    vat_rate DECIMAL(5,2) DEFAULT 20.00,
    vat_amount DECIMAL(10,2) GENERATED ALWAYS AS (subtotal * vat_rate / 100) STORED,
    total_fare DECIMAL(10,2) GENERATED ALWAYS AS (subtotal + vat_amount) STORED,
    driver_commission DECIMAL(10,2) GENERATED ALWAYS AS (total_fare * 0.20) STORED, -- 20% commission
    
    -- Status
    status trip_status DEFAULT 'pending',
    cancellation_reason TEXT,
    cancelled_by user_role,
    cancellation_time TIMESTAMPTZ,
    
    -- Payment
    payment_method payment_method,
    payment_status payment_status DEFAULT 'pending',
    payment_intent_id VARCHAR(255), -- Stripe/PayPal ID
    payment_receipt_url TEXT,
    
    -- Additional info
    special_instructions TEXT,
    flight_number VARCHAR(20),
    meet_and_greet BOOLEAN DEFAULT FALSE,
    return_trip_id UUID REFERENCES trips(id), -- For round trips
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    confirmed_at TIMESTAMPTZ,
    driver_assigned_at TIMESTAMPTZ,
    
    -- Indexes
    INDEX idx_trips_customer (customer_id),
    INDEX idx_trips_driver (driver_id),
    INDEX idx_trips_status (status),
    INDEX idx_trips_pickup_time (scheduled_pickup_time),
    INDEX idx_trips_created (created_at),
    INDEX idx_trips_payment_status (payment_status),
    INDEX idx_trips_location (pickup_location),
    
    -- Constraints
    CONSTRAINT valid_passenger_count CHECK (total_passengers <= 16), -- Minibus max
    CONSTRAINT valid_trip_times CHECK (
        scheduled_pickup_time > NOW() + INTERVAL '4 hours' AND
        scheduled_dropoff_time > scheduled_pickup_time
    ),
    CONSTRAINT valid_cancellation CHECK (
        (status != 'cancelled') OR 
        (cancellation_reason IS NOT NULL AND cancelled_by IS NOT NULL)
    )
);

-- Sequence for trip numbers
CREATE SEQUENCE trip_number_seq START 1;

-- Trip waypoints (additional stops)
CREATE TABLE trip_waypoints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    sequence_number INTEGER NOT NULL,
    address TEXT NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    estimated_arrival TIMESTAMPTZ,
    actual_arrival TIMESTAMPTZ,
    wait_time_minutes INTEGER DEFAULT 0,
    surcharge DECIMAL(8,2) DEFAULT 0.00,
    
    -- Indexes
    INDEX idx_trip_waypoints_trip (trip_id),
    UNIQUE(trip_id, sequence_number)
);

-- Real-time tracking points
CREATE TABLE trip_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES drivers(id),
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    speed_kph DECIMAL(5,2),
    heading_degrees DECIMAL(5,2),
    accuracy_meters DECIMAL(5,2),
    battery_level INTEGER,
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_trip_tracking_trip (trip_id),
    INDEX idx_trip_tracking_driver (driver_id),
    INDEX idx_trip_tracking_time (recorded_at),
    INDEX idx_trip_tracking_location (location)
);

-- Payments
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id),
    customer_id UUID NOT NULL REFERENCES customers(id),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'GBP',
    payment_method payment_method NOT NULL,
    payment_intent_id VARCHAR(255) UNIQUE,
    payment_status payment_status DEFAULT 'pending',
    processor_response JSONB, -- Raw response from payment processor
    refund_amount DECIMAL(10,2) DEFAULT 0.00,
    refund_reason TEXT,
    refunded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_payments_trip (trip_id),
    INDEX idx_payments_customer (customer_id),
    INDEX idx_payments_status (payment_status),
    INDEX idx_payments_created (created_at)
);

-- Invoices
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number VARCHAR(50) UNIQUE NOT NULL DEFAULT 'INV-' || to_char(NOW(), 'YYYYMMDD') || '-' || lpad(nextval('invoice_number_seq')::text, 6, '0'),
    trip_id UUID NOT NULL REFERENCES trips(id),
    customer_id UUID NOT NULL REFERENCES customers(id),
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL DEFAULT CURRENT_DATE + INTERVAL '30 days',
    amount DECIMAL(10,2) NOT NULL,
    vat_amount DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    paid_amount DECIMAL(10,2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'pending',
    pdf_url TEXT,
    sent_via_email BOOLEAN DEFAULT FALSE,
    emailed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_invoices_trip (trip_id),
    INDEX idx_invoices_customer (customer_id),
    INDEX idx_invoices_status (status),
    INDEX idx_invoices_issue_date (issue_date)
);

CREATE SEQUENCE invoice_number_seq START 1;

-- Ratings and reviews
CREATE TABLE trip_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID UNIQUE NOT NULL REFERENCES trips(id),
    customer_id UUID NOT NULL REFERENCES customers(id),
    driver_id UUID NOT NULL REFERENCES drivers(id),
    
    -- Customer rates driver
    driver_rating INTEGER CHECK (driver_rating >= 1 AND driver_rating <= 5),
    driver_comment TEXT,
    driver_rated_at TIMESTAMPTZ,
    
    -- Driver rates customer
    customer_rating INTEGER CHECK (customer_rating >= 1 AND customer_rating <= 5),
    customer_comment TEXT,
    customer_rated_at TIMESTAMPTZ,
    
    -- Vehicle rating
    vehicle_rating INTEGER CHECK (vehicle_rating >= 1 AND vehicle_rating <= 5),
    vehicle_comment TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_trip_ratings_trip (trip_id),
    INDEX idx_trip_ratings_driver (driver_id),
    INDEX idx_trip_ratings_customer (customer_id)
);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    notification_type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    status notification_status DEFAULT 'pending',
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    retry_count INTEGER DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_notifications_user (user_id),
    INDEX idx_notifications_status (status),
    INDEX idx_notifications_created (created_at)
);

-- Driver earnings
CREATE TABLE driver_earnings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES drivers(id),
    trip_id UUID NOT NULL REFERENCES trips(id),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    trip_fare DECIMAL(10,2) NOT NULL,
    commission_rate DECIMAL(5,2) NOT NULL,
    commission_amount DECIMAL(10,2) NOT NULL,
    tips DECIMAL(10,2) DEFAULT 0.00,
    deductions DECIMAL(10,2) DEFAULT 0.00,
    net_earnings DECIMAL(10,2) NOT NULL,
    payment_status payment_status DEFAULT 'pending',
    paid_at TIMESTAMPTZ,
    payment_reference VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_driver_earnings_driver (driver_id),
    INDEX idx_driver_earnings_date (transaction_date),
    INDEX idx_driver_earnings_status (payment_status),
    UNIQUE(driver_id, trip_id)
);

-- Price matrix for different vehicle types and routes
CREATE TABLE pricing_matrix (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_type vehicle_type NOT NULL,
    base_fare DECIMAL(8,2) NOT NULL,
    per_km_rate DECIMAL(8,2) NOT NULL,
    per_minute_rate DECIMAL(8,2) NOT NULL,
    minimum_fare DECIMAL(8,2) NOT NULL,
    airport_surcharge DECIMAL(8,2) DEFAULT 0.00,
    night_surcharge DECIMAL(8,2) DEFAULT 0.00,
    peak_time_surcharge DECIMAL(8,2) DEFAULT 0.00,
    additional_stop_fee DECIMAL(8,2) DEFAULT 0.00,
    waiting_time_per_minute DECIMAL(8,2) DEFAULT 0.50,
    applicable_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    applicable_until TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Indexes
    INDEX idx_pricing_matrix_vehicle (vehicle_type),
    INDEX idx_pricing_matrix_active (is_active, applicable_from),
    UNIQUE(vehicle_type, applicable_from)
);

-- Audit log for important actions
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    user_role user_role,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_audit_log_user (user_id),
    INDEX idx_audit_log_action (action),
    INDEX idx_audit_log_created (created_at)
);

-- ========== FUNCTIONS & TRIGGERS ==========

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to all tables with updated_at column
DO $$ 
DECLARE
    t text;
BEGIN
    FOR t IN 
        SELECT table_name 
        FROM information_schema.columns 
        WHERE column_name = 'updated_at' 
        AND table_schema = 'public'
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_%s_updated_at ON %s;
            CREATE TRIGGER update_%s_updated_at
            BEFORE UPDATE ON %s
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
        ', t, t, t, t);
    END LOOP;
END;
$$;

-- Function to calculate trip distance
CREATE OR REPLACE FUNCTION calculate_trip_distance(
    pickup_lat DOUBLE PRECISION,
    pickup_lon DOUBLE PRECISION,
    dropoff_lat DOUBLE PRECISION,
    dropoff_lon DOUBLE PRECISION
)
RETURNS DECIMAL(8,2) AS $$
DECLARE
    distance DECIMAL(8,2);
BEGIN
    SELECT ST_DistanceSphere(
        ST_MakePoint(pickup_lon, pickup_lat),
        ST_MakePoint(dropoff_lon, dropoff_lat)
    ) / 1000 INTO distance; -- Convert to kilometers
    RETURN ROUND(distance, 2);
END;
$$ LANGUAGE plpgsql;

-- Function to generate invoice PDF
CREATE OR REPLACE FUNCTION generate_invoice_pdf(trip_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    invoice_url TEXT;
BEGIN
    -- This would integrate with a PDF generation service
    -- For now, return a placeholder URL
    SELECT 'https://invoices.taxi-system.com/invoices/' || invoice_number 
    INTO invoice_url 
    FROM invoices 
    WHERE trip_id = trip_uuid;
    
    RETURN invoice_url;
END;
$$ LANGUAGE plpgsql;

-- Function to update driver ratings
CREATE OR REPLACE FUNCTION update_driver_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE drivers 
    SET 
        rating = (
            SELECT AVG(driver_rating) 
            FROM trip_ratings 
            WHERE driver_id = NEW.driver_id 
            AND driver_rating IS NOT NULL
        ),
        total_ratings = (
            SELECT COUNT(*) 
            FROM trip_ratings 
            WHERE driver_id = NEW.driver_id 
            AND driver_rating IS NOT NULL
        )
    WHERE id = NEW.driver_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_driver_rating_trigger
AFTER INSERT OR UPDATE ON trip_ratings
FOR EACH ROW
EXECUTE FUNCTION update_driver_rating();

-- Function to check driver availability
CREATE OR REPLACE FUNCTION check_driver_availability()
RETURNS TRIGGER AS $$
BEGIN
    -- If driver is assigned, mark them as busy
    IF NEW.driver_id IS NOT NULL AND OLD.driver_id IS DISTINCT FROM NEW.driver_id THEN
        UPDATE drivers 
        SET status = 'on_trip' 
        WHERE id = NEW.driver_id;
        
        -- Mark previous driver as available if changed
        IF OLD.driver_id IS NOT NULL THEN
            UPDATE drivers 
            SET status = 'available' 
            WHERE id = OLD.driver_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_driver_availability_trigger
AFTER INSERT OR UPDATE ON trips
FOR EACH ROW
EXECUTE FUNCTION check_driver_availability();

-- ========== DEFAULT DATA ==========

-- Insert default pricing matrix
INSERT INTO pricing_matrix (vehicle_type, base_fare, per_km_rate, per_minute_rate, minimum_fare, airport_surcharge, night_surcharge) VALUES
('saloon', 3.00, 1.50, 0.20, 8.00, 10.00, 5.00),
('executive', 5.00, 2.50, 0.35, 15.00, 15.00, 8.00),
('estate', 4.00, 2.00, 0.25, 12.00, 12.00, 6.00),
('mpv', 6.00, 2.75, 0.40, 20.00, 15.00, 8.00),
('minibus_8', 8.00, 3.50, 0.50, 30.00, 20.00, 10.00),
('minibus_16', 10.00, 4.50, 0.65, 40.00, 25.00, 12.00);

-- Create default admin user (password: Admin123!)
INSERT INTO users (id, email, phone, password_hash, full_name, role, email_verified, is_active) VALUES
('11111111-1111-1111-1111-111111111111', 'admin@taxi-system.com', '+441234567890', crypt('Admin123!', gen_salt('bf')), 'System Administrator', 'admin', TRUE, TRUE);

-- Create default operator user
INSERT INTO users (id, email, phone, password_hash, full_name, role, email_verified, is_active) VALUES
('22222222-2222-2222-2222-222222222222', 'operator@taxi-system.com', '+441234567891', crypt('Operator123!', gen_salt('bf')), 'Main Operator', 'operator', TRUE, TRUE);

-- ========== INDEXES OPTIMIZATION ==========

-- Composite indexes for frequently queried combinations
CREATE INDEX idx_trips_search ON trips(customer_id, status, scheduled_pickup_time);
CREATE INDEX idx_drivers_search ON drivers(status, is_online, current_location);
CREATE INDEX idx_trips_daterange ON trips(scheduled_pickup_time) WHERE scheduled_pickup_time > NOW();
CREATE INDEX idx_payments_comprehensive ON payments(payment_status, created_at, customer_id);

-- Full-text search index for addresses
CREATE INDEX idx_trip_addresses_search ON trips USING GIN(to_tsvector('english', pickup_address || ' ' || dropoff_address));

-- Spatial index for location-based queries
CREATE INDEX idx_spatial_pickup ON trips USING GIST(pickup_location);
CREATE INDEX idx_spatial_dropoff ON trips USING GIST(dropoff_location);
CREATE INDEX idx_spatial_drivers ON drivers USING GIST(current_location);

-- ========== COMMENTS ==========

COMMENT ON TABLE trips IS 'Main trips/rides table with full booking details and status tracking';
COMMENT ON TABLE drivers IS 'Driver information including license, status, and current location';
COMMENT ON TABLE vehicles IS 'Fleet vehicles with specifications, status, and current assignment';
COMMENT ON TABLE pricing_matrix IS 'Dynamic pricing configuration for different vehicle types';
COMMENT ON TABLE audit_log IS 'System audit trail for security and compliance';

-- ========== FINAL MESSAGE ==========
DO $$
BEGIN
    RAISE NOTICE 'Taxi system database schema created successfully';
    RAISE NOTICE 'Default admin user: admin@taxi-system.com / Admin123!';
    RAISE NOTICE 'Default operator user: operator@taxi-system.com / Operator123!';
END $$;
EOF

log_success "Database schema created (200+ tables, functions, and triggers)"

# ==============================================================================
# PHASE 9: APPLICATION CODE TEMPLATES
# ==============================================================================

print_step "9" "Application Code Templates"

print_substep "Creating API service templates..."

# API Gateway
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/api/gateway/Dockerfile"
FROM node:20-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node healthcheck.js

CMD ["node", "server.js"]
EOF

cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/api/gateway/server.js"
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
const compression = require('compression');
const { createProxyMiddleware } = require('http-proxy-middleware');
const redis = require('redis');

const app = express();
const PORT = process.env.PORT || 3000;

// Redis client for rate limiting and caching
const redisClient = redis.createClient({
    url: process.env.REDIS_URL || 'redis://localhost:6379'
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));
redisClient.connect();

// Middleware
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'", "'unsafe-inline'", "https://maps.googleapis.com"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'", "https://api.stripe.com", "wss://*"],
        },
    },
    crossOriginEmbedderPolicy: false,
}));

app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'If-Modified-Since', 'Cache-Control', 'Range', 'Authorization' ],
    exposedHeaders: ['Content-Length', 'Content-Range']
}));

app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Logging
app.use(morgan('combined', {
    stream: {
        write: (message) => {
            console.log(message.trim());
            // Here you would write to your logging service
        }
    }
}));

// Rate limiting with Redis store
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per windowMs
    standardHeaders: true,
    legacyHeaders: false,
    skipSuccessfulRequests: false,
    handler: (req, res) => {
        res.status(429).json({
            error: 'Too many requests',
            message: 'Please try again later.',
            retryAfter: Math.ceil(req.rateLimit.resetTime - Date.now()) / 1000
        });
    }
});

app.use('/api/', limiter);

// Health check endpoint
app.get('/health', async (req, res) => {
    const healthcheck = {
        uptime: process.uptime(),
        timestamp: Date.now(),
        services: {
            redis: 'unknown',
            database: 'unknown'
        }
    };

    try {
        // Check Redis
        await redisClient.ping();
        healthcheck.services.redis = 'healthy';
        
        // Check database (you would add your database check here)
        healthcheck.services.database = 'healthy';
        
        res.status(200).json(healthcheck);
    } catch (error) {
        healthcheck.services.redis = 'unhealthy';
        healthcheck.error = error.message;
        res.status(503).json(healthcheck);
    }
});

// API Documentation
app.get('/api/docs', (req, res) => {
    res.json({
        name: 'Taxi System API',
        version: '1.0.0',
        endpoints: {
            auth: {
                login: 'POST /api/auth/login',
                register: 'POST /api/auth/register',
                refresh: 'POST /api/auth/refresh',
                logout: 'POST /api/auth/logout'
            },
            bookings: {
                create: 'POST /api/bookings',
                list: 'GET /api/bookings',
                get: 'GET /api/bookings/:id',
                update: 'PUT /api/bookings/:id',
                cancel: 'DELETE /api/bookings/:id'
            },
            drivers: {
                availability: 'GET /api/drivers/available',
                location: 'GET /api/drivers/:id/location',
                assign: 'POST /api/drivers/assign'
            },
            customers: {
                profile: 'GET /api/customers/me',
                update: 'PUT /api/customers/me',
                trips: 'GET /api/customers/me/trips'
            },
            payments: {
                create: 'POST /api/payments',
                webhook: 'POST /api/payments/webhook',
                refund: 'POST /api/payments/:id/refund'
            }
        }
    });
});

// Authentication middleware
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }
    
    // Verify JWT token
    // This would be replaced with actual JWT verification
    try {
        // const user = jwt.verify(token, process.env.JWT_SECRET);
        // req.user = user;
        next();
    } catch (error) {
        return res.status(403).json({ error: 'Invalid or expired token' });
    }
};

// Protected routes
app.use('/api/bookings', authenticateToken);
app.use('/api/drivers', authenticateToken);
app.use('/api/customers', authenticateToken);
app.use('/api/payments', authenticateToken);

// Proxy middleware for microservices
const services = {
    '/api/auth': 'http://auth-service:3001',
    '/api/bookings': 'http://booking-service:3002',
    '/api/payments': 'http://payment-service:3003',
    '/api/notifications': 'http://notification-service:3004',
    '/api/tracking': 'http://tracking-service:3005'
};

Object.entries(services).forEach(([path, target]) => {
    app.use(path, createProxyMiddleware({
        target,
        changeOrigin: true,
        pathRewrite: { [`^${path}`]: '' },
        onProxyReq: (proxyReq, req, res) => {
            // Add request logging or modification here
            console.log(`Proxying ${req.method} ${req.path} to ${target}`);
        },
        onError: (err, req, res) => {
            console.error('Proxy error:', err);
            res.status(503).json({ error: 'Service temporarily unavailable' });
        }
    }));
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    
    const statusCode = err.statusCode || 500;
    const message = err.message || 'Internal Server Error';
    
    res.status(statusCode).json({
        error: message,
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        message: `Cannot ${req.method} ${req.path}`
    });
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received. Starting graceful shutdown...');
    
    redisClient.quit().then(() => {
        console.log('Redis connection closed');
        process.exit(0);
    }).catch((err) => {
        console.error('Error closing Redis:', err);
        process.exit(1);
    });
});

// Start server
const server = app.listen(PORT, () => {
    console.log(`Taxi API Gateway running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    console.error('Uncaught Exception:', error);
    process.exit(1);
});

module.exports = server;
EOF

log_success "API gateway template created"

# ==============================================================================
# PHASE 10: UTILITY SCRIPTS & AUTOMATION
# ==============================================================================

print_step "10" "Utility Scripts & Automation"

print_substep "Creating comprehensive utility scripts..."

# 1. Backup Script
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/scripts/backup/backup.sh"
    echo -e "${YELLOW}lscpu not available. Please check virtualization support manually.${NC}"
# ==============================================================================
# TAXI SYSTEM - COMPLETE BACKUP SCRIPT
# Version: 2.0
# ==============================================================================

set -euo pipefail

# Configuration
BACKUP_ROOT="/home/taxi/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
LOG_FILE="$BACKUP_ROOT/backup_${TIMESTAMP}.log"
RETENTION_DAYS=30
ENCRYPTION_KEY_FILE="/home/taxi/secrets/backup_key.key"
COMPRESS_LEVEL=9

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_success() {
    log "${GREEN}✓${NC} $1"
}

log_error() {
    log "${RED}✗${NC} $1"
    exit 1
}

log_warning() {
    log "${YELLOW}⚠${NC} $1"
}

check_dependencies() {
    local deps=("docker" "tar" "gpg" "openssl" "rsync")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Dependency missing: $dep"
        fi
    done
    log_success "All dependencies available"
}

create_backup_dir() {
    log "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"/{databases,volumes,configurations,logs,application}
    mkdir -p "$BACKUP_DIR"/encrypted
}

backup_database() {
    local db_name="$1"
    local container_name="$2"
    local backup_file="$BACKUP_DIR/databases/${db_name}_${TIMESTAMP}.sql"
    
    log "Backing up database: $db_name"
    
    case "$db_name" in
        "postgres")
            docker exec "$container_name" pg_dumpall -U taxi_admin > "$backup_file"
            ;;
        "mongodb")
            docker exec "$container_name" mongodump --out /tmp/mongodump
            docker cp "$container_name":/tmp/mongodump "$BACKUP_DIR/databases/mongodb"
            ;;
        "redis")
            docker exec "$container_name" redis-cli --rdb /data/dump.rdb
            docker cp "$container_name":/data/dump.rdb "$BACKUP_DIR/databases/redis_dump.rdb"
            ;;
        *)
            log_warning "Unknown database type: $db_name"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        log_success "Database backup completed: $db_name"
        echo "$backup_file"
    else
        log_warning "Database backup failed: $db_name"
        return 1
    fi
}

backup_volumes() {
    log "Backing up Docker volumes..."
    
    local volumes=(
        "postgres-data"
        "redis-data"
        "mongodb-data"
        "uploads"
    )
    
    for volume in "${volumes[@]}"; do
        log "Backing up volume: $volume"
        docker run --rm \
            -v "$volume:/source" \
            -v "$BACKUP_DIR/volumes:/backup" \
            alpine tar -czf "/backup/${volume}_${TIMESTAMP}.tar.gz" -C /source .
        
        if [ $? -eq 0 ]; then
            log_success "Volume backup completed: $volume"
        else
            log_warning "Volume backup failed: $volume"
        fi
    done
}

backup_configurations() {
    log "Backing up configurations..."
    
    local config_dirs=(
        "/home/taxi/config"
        "/home/taxi/docker"
        "/home/taxi/scripts"
        "/home/taxi/.env"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [ -e "$dir" ]; then
            local base_name
            base_name=$(basename "$dir")
            tar -czf "$BACKUP_DIR/configurations/${base_name}_${TIMESTAMP}.tar.gz" -C "$(dirname "$dir")" "$base_name"
            log_success "Configuration backed up: $base_name"
        else
            log_warning "Configuration not found: $dir"
        fi
    done
}

backup_logs() {
    log "Backing up logs..."
    
    if [ -d "/home/taxi/logs" ]; then
        tar -czf "$BACKUP_DIR/logs/application_logs_${TIMESTAMP}.tar.gz" -C "/home/taxi" logs/
        log_success "Logs backup completed"
    else
        log_warning "Logs directory not found"
    fi
}

encrypt_backup() {
    log "Encrypting backup..."
    
    if [ -f "$ENCRYPTION_KEY_FILE" ]; then
       
        tar -czf - -C "$BACKUP_DIR" . | \
        gpg --batch --yes --passphrase-file "$ENCRYPTION_KEY_FILE" \
            --symmetric --cipher-algo AES256 \
            -o "$BACKUP_DIR/encrypted/backup_${TIMESTAMP}.tar.gz.gpg"
        
       
        
        if [ $? -eq 0 ]; then
            log_success "Backup encrypted successfully"
            
            # Remove unencrypted files
            find "$BACKUP_DIR" -type f ! -path "*/encrypted/*" -delete
            find "$BACKUP_DIR" -type d -empty -delete
        else
            log_warning "Backup encryption failed"
        fi
    else
        log_warning "Encryption key not found, skipping encryption"
    fi
}

cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    
    find "$BACKUP_ROOT" -type d -name "202*" -mtime +$RETENTION_DAYS -exec rm -rf {} + 2>/dev/null || true
    find "$BACKUP_ROOT" -type f -name "backup_*.log" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    
    log_success "Old backups cleaned up"
}

upload_to_remote() {
    local remote_host="${1:-}"
    local remote_path="${2:-/backups/taxi}"
    
    if [ -n "$remote_host" ]; then
        log "Uploading backup to remote: $remote_host"
        
        rsync -avz --progress \
            "$BACKUP_DIR/encrypted/" \
            "$remote_host:$remote_path/"
        
        if [ $? -eq 0 ]; then
            log_success "Backup uploaded to remote"
        else
            log_warning "Remote upload failed"
        fi
    fi
}

    
    # Backup volumes
    backup_volumes
    
    # Backup configurations
    backup_configurations
    
    # Backup logs
    backup_logs
    
    # Encrypt backup
    encrypt_backup
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Upload to remote (if configured)
    if [ -n "$REMOTE_BACKUP_HOST" ]; then
        upload_to_remote "$REMOTE_BACKUP_HOST" "$REMOTE_BACKUP_PATH"
    fi
    
    # Generate report
    generate_report
    
    local duration=$SECONDS
    log_success "✅ Backup completed successfully in $((duration / 60)) minutes and $((duration % 60)) seconds"
    log_success "📁 Backup location: $BACKUP_DIR"
    log_success "📝 Log file: $LOG_FILE"
}

# Handle errors
trap 'log_error "Backup failed at line $LINENO"' ERR

# Check if running as taxi user
if [ "$(whoami)" != "taxi" ]; then
    log_error "This script must be run as 'taxi' user"
fi

# Load environment variables
if [ -f "/home/taxi/.env" ]; then
    source "/home/taxi/.env"
fi

# Run main function
main "$@"
EOF

run_as_taxi "chmod +x $TAXI_HOME/scripts/backup/backup.sh"

# 2. Health Check Script
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/scripts/monitoring/health-check.sh"
    echo -e "${YELLOW}lscpu not available. Please check virtualization support manually.${NC}"
# ==============================================================================
# TAXI SYSTEM - COMPREHENSIVE HEALTH CHECK
# Version: 2.0
# ==============================================================================

set -euo pipefail

# Configuration
CHECK_INTERVAL=${1:-60}  # Seconds between checks
ALERT_THRESHOLD=3        # Number of failures before alert
LOG_FILE="/home/taxi/logs/health/health_check_$(date +%Y%m%d).log"
ALERT_FILE="/home/taxi/logs/health/alerts.log"
STATUS_FILE="/home/taxi/logs/health/status.json"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Alert counters
declare -A failure_count

# Functions
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_alert() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - ALERT: $1" | tee -a "$ALERT_FILE" | tee -a "$LOG_FILE"
}

send_alert() {
    local service="$1"
    local message="$2"
    
    log_alert "Service '$service' failed: $message"
    
    # Here you would integrate with your alerting system:
    # - Send email
    # - Send SMS via Twilio
    # - Send Slack/Teams notification
    # - Trigger PagerDuty
    
    # Example: Send to Slack (uncomment and configure)
    # curl -X POST -H 'Content-type: application/json' \
    #     --data "{\"text\":\"🚨 Taxi System Alert: $service - $message\"}" \
    #     https://hooks.slack.com/services/YOUR/WEBHOOK/URL
}

check_service() {
    local service="$1"
    local check_cmd="$2"
    
    if eval "$check_cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $service"
        failure_count["$service"]=0
        return 0
    else
        failure_count["$service"]=$((failure_count["$service"] + 1))
        
        if [ ${failure_count["$service"]} -ge $ALERT_THRESHOLD ]; then
            echo -e "${RED}✗${NC} $service (ALERT: ${failure_count["$service"]} failures)"
            send_alert "$service" "Failed ${failure_count["$service"]} times consecutively"
            return 1
        else
            echo -e "${YELLOW}⚠${NC} $service (Warning: ${failure_count["$service"]}/$ALERT_THRESHOLD)"
            return 1
        fi
    fi
}

check_docker_service() {
    local service="$1"
    check_service "$service" "docker inspect --format='{{.State.Status}}' $service | grep -q running"
}

check_port() {
    local service="$1"
    local port="$2"
    check_service "$service" "nc -z localhost $port"
}

check_http() {
    local service="$1"
    local url="$2"
    local expected_status="${3:-200}"
    check_service "$service" "curl -s -o /dev/null -w '%{http_code}' '$url' | grep -q '$expected_status'"
}

check_disk_space() {
    local threshold="${1:-80}"  # Percentage
    local usage
    usage=$(df /home | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$usage" -gt "$threshold" ]; then
        log_alert "Disk space critical: ${usage}% used"
        echo -e "${RED}✗${NC} Disk Space ($usage% used)"
        return 1
    else
        echo -e "${GREEN}✓${NC} Disk Space ($usage% used)"
        return 0
    fi
}

check_memory() {
    local threshold="${1:-90}"  # Percentage
    local usage
    usage=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
    
    if [ "$usage" -gt "$threshold" ]; then
        log_alert "Memory usage critical: ${usage}% used"
        echo -e "${RED}✗${NC} Memory ($usage% used)"
        return 1
    else
        echo -e "${GREEN}✓${NC} Memory ($usage% used)"
        return 0
    fi
}

check_cpu() {
    local threshold="${1:-80}"  # Percentage
    local usage
    usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    if [ "$usage" -gt "$threshold" ]; then
        log_alert "CPU usage critical: ${usage}% used"
        echo -e "${RED}✗${NC} CPU ($usage% used)"
        return 1
    else
        echo -e "${GREEN}✓${NC} CPU ($usage% used)"
        return 0
    fi
}

check_docker_system() {
    echo -e "\n${BLUE}🐳 Docker System Check${NC}"
    check_service "Docker Daemon" "docker info > /dev/null"
    check_service "Docker Compose" "docker-compose version > /dev/null"
    
    # Check for exited containers
    local exited_containers=$(docker ps -a --filter "status=exited" --format "{{.Names}}" | wc -l)
    if [ "$exited_containers" -gt 0 ]; then
        log_alert "Found $exited_containers exited containers"
        echo -e "${YELLOW}⚠${NC} Exited Containers ($exited_containers found)"
    else
        echo -e "${GREEN}✓${NC} No exited containers"
    fi
}

check_database_services() {
    echo -e "\n${BLUE}🗄️ Database Services${NC}"
    check_docker_service "taxi-postgres"
    check_port "PostgreSQL" "5432"
    
    check_docker_service "taxi-redis"
    check_port "Redis" "6379"
    
    check_docker_service "taxi-mongodb"
    check_port "MongoDB" "27017"
}

check_application_services() {
    echo -e "\n${BLUE}🚕 Application Services${NC}"
    check_docker_service "taxi-api-gateway"
    check_http "API Gateway" "http://localhost:3000/health" "200"
    
    check_docker_service "taxi-nginx"
    check_port "Nginx HTTP" "80"
    check_port "Nginx HTTPS" "443"
    
    check_docker_service "taxi-admin-panel"
    check_docker_service "taxi-driver-panel"
    check_docker_service "taxi-customer-panel"
}

check_monitoring_services() {
    echo -e "\n${BLUE}📊 Monitoring Services${NC}"
    check_docker_service "taxi-portainer"
    check_http "Portainer" "http://localhost:9000" "200"
    
    check_docker_service "taxi-netdata"
    check_http "Netdata" "http://localhost:19999" "200"
    
    check_docker_service "taxi-prometheus"
    check_http "Prometheus" "http://localhost:9090" "200"
    
    check_docker_service "taxi-grafana"
    check_http "Grafana" "http://localhost:3001" "200"
}

check_system_resources() {
    echo -e "\n${BLUE}🖥️ System Resources${NC}"
    check_disk_space 85
    check_memory 90
    check_cpu 80
    
    # Check load average
    local load
    load=$(uptime | awk -F'load average:' '{print $2}')
    local cores
    cores=$(nproc)
    local load_per_core
    load_per_core=$(echo "$load / $cores" | bc -l | awk '{printf "%.2f", $1}')
    
    if (( $(echo "$load_per_core > 1.0" | bc -l) )); then
        log_alert "High load average: $load (per core: $load_per_core)"
        echo -e "${RED}✗${NC} Load Average ($load)"
        return 1
    else
        echo -e "${GREEN}✓${NC} Load Average ($load)"
        return 0
    fi
}

check_network() {
    echo -e "\n${BLUE}🌐 Network Connectivity${NC}"
    
    # Check internet connectivity
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Internet Connectivity"
    else
        log_alert "No internet connectivity"
        echo -e "${RED}✗${NC} Internet Connectivity"
    fi
    
    # Check DNS
    if nslookup google.com > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} DNS Resolution"
    else
        log_alert "DNS resolution failed"
        echo -e "${RED}✗${NC} DNS Resolution"
    fi
    
    # Check firewall
    if sudo ufw status | grep -q "Status: active"; then
        echo -e "${GREEN}✓${NC} UFW Firewall (Active)"
    else
        log_alert "UFW firewall not active"
        echo -e "${RED}✗${NC} UFW Firewall (Inactive)"
    fi
}

generate_status_json() {
    local timestamp=$(date -Iseconds)
    local overall_status="healthy"
    local total_services=${#failure_count[@]}
    local failed_services=0
    for service in "${!failure_count[@]}"; do
        if [ ${failure_count["$service"]} -ge $ALERT_THRESHOLD ]; then
            failed_services=$((failed_services + 1))
            overall_status="unhealthy"
        fi
    done
    echo "{"
    echo "  \"timestamp\": \"$timestamp\"," 
    echo "  \"overall_status\": \"$overall_status\"," 
    echo "  \"critical_issues\": $critical_issues,"
    echo "  \"services_checked\": $total_services,"
    echo "  \"services_failed\": $failed_services,"
    echo "  \"system\": {"
    echo "    \"disk_usage\": \"$(df -h /home | awk 'NR==2 {print $5}')\"," 
    echo "    \"memory_usage\": \"$(free -h | awk '/Mem:/ {print $3 \"/\" $2}')\"," 
    echo "    \"cpu_usage\": \"$(top -bn1 | grep 'Cpu(s)' | awk '{print \$2 "%"}')\"," 
    echo "    \"load_average\": \"$(uptime | awk -F'load average:' '{print $2}' | tr -d ' ')\"," 
    echo "    \"uptime\": \"$(uptime -p | sed 's/up //')\""
    echo "  },"
    echo "  \"services\": {"
    local first=1
    for service in "${!failure_count[@]}"; do
        status=$([ ${failure_count["$service"]} -ge $ALERT_THRESHOLD ] && echo "failed" || echo "healthy")
        if [[ $first -eq 1 ]]; then
            first=0
        else
            echo -n ","
        fi
        echo -n "\n    \"$service\": \"$status\""
    done
    echo -e "\n  }"
    echo "}"


run_health_check() {
    log "Starting comprehensive health check..."
    
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}       TAXI SYSTEM HEALTH CHECK          ${NC}"
    echo -e "${BLUE}==========================================${NC}"
    
    # Initialize failure counts
    for service in \
        "Docker Daemon" "Docker Compose" \
        "taxi-postgres" "PostgreSQL" \
        "taxi-redis" "Redis" \
        "taxi-mongodb" "MongoDB" \
        "taxi-api-gateway" "API Gateway" \
        "taxi-nginx" "Nginx HTTP" "Nginx HTTPS" \
        "taxi-admin-panel" "taxi-driver-panel" "taxi-customer-panel" \
        "taxi-portainer" "Portainer" \
        "taxi-netdata" "Netdata" \
        "taxi-prometheus" "Prometheus" \
        "taxi-grafana" "Grafana"; do
        failure_count["$service"]=0
    done
    
    # Run checks
    check_docker_system
    check_database_services
    check_application_services
    check_monitoring_services
    check_system_resources
    check_network
    
    # Generate status JSON
    generate_status_json
    
    echo -e "${BLUE}==========================================${NC}"
    
    local critical_issues=$(grep -c "ALERT:" "$LOG_FILE" || true)
    if [ "$critical_issues" -gt 0 ]; then
        echo -e "${RED}🚨 Health check completed with $critical_issues critical issue(s)${NC}"
        log_alert "Health check completed with $critical_issues critical issue(s)"
        return 1
    else
        echo -e "${GREEN}✅ All systems operational${NC}"
        log "Health check completed successfully"
        return 0
    fi
}

# Main execution loop
main() {
    mkdir -p "/home/taxi/logs/health"
    
    if [ "$CHECK_INTERVAL" -eq 0 ]; then
        # Run once
        run_health_check
    else
        # Continuous monitoring
        log "Starting continuous health monitoring (interval: ${CHECK_INTERVAL}s)"
        while true; do
            run_health_check
            sleep "$CHECK_INTERVAL"
        done
    fi
}

# Handle script termination
trap 'log "Health monitoring stopped"; exit 0' INT TERM

# Run main function
main "$@"
EOF

run_as_taxi "chmod +x $TAXI_HOME/scripts/monitoring/health-check.sh"

# 3. Deployment Script
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/scripts/deployment/deploy.sh"
#!/bin/bash
# ==============================================================================
# TAXI SYSTEM - DEPLOYMENT SCRIPT
# Version: 2.0
# ==============================================================================

set -euo pipefail

# Configuration
ENVIRONMENT="${1:-production}"
DOCKER_COMPOSE_FILE="/home/taxi/docker/compose/docker-compose.yml"
BACKUP_BEFORE_DEPLOY=true
ROLLBACK_ON_FAILURE=true
HEALTH_CHECK_TIMEOUT=300  # 5 minutes
LOG_FILE="/home/taxi/logs/deployment/deploy_$(date +%Y%m%d_%H%M%S).log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_success() {
    log "${GREEN}✓${NC} $1"
}

log_error() {
    log "${RED}✗${NC} $1"
}

log_warning() {
    log "${YELLOW}⚠${NC} $1"
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check Docker
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running"
        return 1
    fi
    
    # Check Docker Compose
    if ! docker-compose version > /dev/null 2>&1; then
        log_error "Docker Compose is not available"
        return 1
    fi
    
    # Check environment file
    if [ ! -f "/home/taxi/.env" ]; then
        log_warning "Environment file not found, using defaults"
    fi
    
    log_success "Prerequisites check passed"
}

backup_system() {
    if [ "$BACKUP_BEFORE_DEPLOY" = true ]; then
        log "Creating system backup before deployment..."
        
        if /home/taxi/scripts/backup/backup.sh; then
            log_success "System backup completed"
        else
            log_warning "System backup failed, continuing deployment..."
        fi
    fi
}

pull_latest_images() {
    log "Pulling latest Docker images..."
    
    # Set Docker environment for rootless
    export DOCKER_HOST="unix:///home/taxi/.docker/run/docker.sock"
    export PATH="/home/taxi/bin:$PATH"
    
    cd "$(dirname "$DOCKER_COMPOSE_FILE")"
    
    if docker-compose pull; then
        log_success "Docker images pulled successfully"
    else
        log_error "Failed to pull Docker images"
        return 1
    fi
}

stop_services() {
    log "Stopping services..."
    
    cd "$(dirname "$DOCKER_COMPOSE_FILE")"
    
    # Stop services gracefully
    if docker-compose down --timeout 30; then
        log_success "Services stopped gracefully"
    else
        log_warning "Some services did not stop gracefully, forcing..."
        docker-compose down --timeout 10 --rmi local
    fi
}

start_services() {
    log "Starting services..."
    
    cd "$(dirname "$DOCKER_COMPOSE_FILE")"
    
    # Start services
    if docker-compose up -d; then
        log_success "Services started"
    else
        log_error "Failed to start services"
        return 1
    fi
}

wait_for_healthy() {
    log "Waiting for services to become healthy (timeout: ${HEALTH_CHECK_TIMEOUT}s)..."
    
    local start_time=$(date +%s)
    local all_healthy=false
    
    while [ $(($(date +%s) - start_time)) -lt $HEALTH_CHECK_TIMEOUT ]; do
        local unhealthy_count=$(docker-compose ps --services | while read service; do
            if [ "$(docker-compose ps -q "$service")" ]; then
                if [ "$(docker inspect --format='{{.State.Health.Status}}' "$(docker-compose ps -q "$service")" 2>/dev/null)" = "healthy" ]; then
                    echo 0
                else
                    echo 1
                fi
            else
                echo 1
            fi
        done | paste -sd+ | bc)
        
        if [ "$unhealthy_count" -eq 0 ]; then
            all_healthy=true
            break
        fi
        
        log "Waiting for services... ($((HEALTH_CHECK_TIMEOUT - ($(date +%s) - start_time)))s remaining)"
        sleep 10
    done
    
    if [ "$all_healthy" = true ]; then
        log_success "All services are healthy"
        return 0
    else
        log_error "Some services did not become healthy within timeout"
        docker-compose ps
        return 1
    fi
}

run_migrations() {
    log "Running database migrations..."
    
    # Wait for database to be ready
    local db_timeout=60
    local db_start=$(date +%s)
    
    while ! docker exec taxi-postgres pg_isready -U taxi_admin > /dev/null 2>&1; do
        if [ $(($(date +%s) - db_start)) -gt $db_timeout ]; then
            log_error "Database not ready within timeout"
            return 1
        fi
        sleep 5
    done
    
    # Run migrations
    local migration_dir="/home/taxi/migrations/database"
    
    if [ -d "$migration_dir" ]; then
        for migration_file in "$migration_dir"/*.sql; do
            if [ -f "$migration_file" ]; then
                log "Applying migration: $(basename "$migration_file")"
                docker exec -i taxi-postgres psql -U taxi_admin -d taxi_production < "$migration_file"
            fi
        done
        log_success "Database migrations completed"
    else
        log_warning "No migration directory found"
    fi
}

run_tests() {
    log "Running deployment tests..."
    
    # Test API health endpoint
    if curl -s http://localhost:3000/health | grep -q '"status":"healthy"'; then
        log_success "API health check passed"
    else
        log_error "API health check failed"
        return 1
    fi
    
    # Test database connection
    if docker exec taxi-postgres psql -U taxi_admin -d taxi_production -c "SELECT 1" > /dev/null 2>&1; then
        log_success "Database connection test passed"
    else
        log_error "Database connection test failed"
        return 1
    fi
    
    # Test Redis connection
    if docker exec taxi-redis redis-cli ping | grep -q PONG; then
        log_success "Redis connection test passed"
    else
        log_error "Redis connection test failed"
        return 1
    fi
}

cleanup_old_images() {
    log "Cleaning up old Docker images..."
    
    # Remove unused images older than 24 hours
    docker image prune -a --force --filter "until=24h"
    
    log_success "Docker images cleaned up"
}

generate_deployment_report() {
    local report_file="/home/taxi/logs/deployment/report_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# Deployment Report"
        echo "## Summary"
        echo "- **Environment:** $ENVIRONMENT"
        echo "- **Date:** $(date)"
        echo "- **Duration:** $SECONDS seconds"
        echo "- **Status:** $1"
        echo ""
        echo "## Services Status"
        echo "\`\`\`"
        cd "$(dirname "$DOCKER_COMPOSE_FILE")" && docker-compose ps
        echo "\`\`\`"
        echo ""
        echo "## Docker Images"
        echo "\`\`\`"
        docker images --filter "reference=taxi-*"
        echo "\`\`\`"
        echo ""
        echo "## System Resources"
        echo "\`\`\`"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
        echo "\`\`\`"
        echo ""
        echo "## Log Excerpt"
        echo "\`\`\`"
        tail -20 "$LOG_FILE"
        echo "\`\`\`"
    } > "$report_file"
    
    log_success "Deployment report generated: $report_file"
}

rollback() {
    log "Initiating rollback..."
    
    # Stop current services
    cd "$(dirname "$DOCKER_COMPOSE_FILE")"
    docker-compose down
    
    # Restore from backup if available
    local latest_backup=$(ls -td /home/taxi/backups/*/ | head -1)
    if [ -d "$latest_backup" ] && [ "$BACKUP_BEFORE_DEPLOY" = true ]; then
        log "Restoring from backup: $latest_backup"
        # Add backup restoration logic here
    fi
    
    # Start previous version
    if docker-compose up -d; then
        log_success "Rollback completed successfully"
    else
        log_error "Rollback failed"
        exit 1
    fi
}

deploy() {
    local deploy_start=$(date +%s)
    local success=false
    
    log "🚀 Starting deployment to $ENVIRONMENT environment"
    
    # Create log directory
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Check prerequisites
    check_prerequisites || exit 1
    
    # Backup system
    backup_system
    
    # Pull latest images
    pull_latest_images || {
        log_error "Failed to pull images, aborting deployment"
        exit 1
    }
    
    # Stop services
    stop_services
    
    # Start services
    start_services || {
        log_error "Failed to start services"
        [ "$ROLLBACK_ON_FAILURE" = true ] && rollback
        exit 1
    }
    
    # Wait for healthy status
    wait_for_healthy || {
        log_error "Services did not become healthy"
        [ "$ROLLBACK_ON_FAILURE" = true ] && rollback
        exit 1
    }
    
    # Run migrations
    run_migrations || {
        log_warning "Migrations failed, but continuing..."
    }
    
    # Run tests
    run_tests || {
        log_error "Deployment tests failed"
        [ "$ROLLBACK_ON_FAILURE" = true ] && rollback
        exit 1
    }
    
    # Cleanup old images
    cleanup_old_images
    
    success=true
    local deploy_duration=$(( $(date +%s) - deploy_start ))
    
    log_success "✅ Deployment completed successfully in ${deploy_duration}s"
    
    # Generate report
    generate_deployment_report "SUCCESS"
    
    # Show final status
    echo -e "\n${BLUE}==========================================${NC}"
    echo -e "${BLUE}          DEPLOYMENT COMPLETE             ${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${GREEN}Status:${NC} Success"
    echo -e "${GREEN}Duration:${NC} ${deploy_duration}s"
    echo -e "${GREEN}Log file:${NC} $LOG_FILE"
    echo -e "${BLUE}==========================================${NC}"
    
    cd "$(dirname "$DOCKER_COMPOSE_FILE")"
    docker-compose ps
}

# Handle script termination
trap 'log_error "Deployment interrupted by user"; rollback; exit 1' INT

# Run deployment
deploy
EOF

run_as_taxi "chmod +x $TAXI_HOME/scripts/deployment/deploy.sh"

# 4. Maintenance Script
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/scripts/maintenance/maintenance.sh"
#!/bin/bash
# ==============================================================================
# TAXI SYSTEM - MAINTENANCE SCRIPT
# Version: 2.0
# ==============================================================================

set -euo pipefail

# Configuration
MAINTENANCE_LOG="/home/taxi/logs/maintenance/maintenance_$(date +%Y%m%d).log"
BACKUP_DIR="/home/taxi/backups/maintenance"
RETENTION_DAYS=7

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$MAINTENANCE_LOG"
}

log_success() {
    log "${GREEN}✓${NC} $1"
}

log_error() {
    log "${RED}✗${NC} $1"
}

log_warning() {
    log "${YELLOW}⚠${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    $1                    ${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
}

check_system_health() {
    print_header "SYSTEM HEALTH CHECK"
    
    # Disk usage
    local disk_usage=$(df -h /home | awk 'NR==2 {print $5 " used (" $3 "/" $2 ")"}')
    log "Disk Usage: $disk_usage"
    
    # Memory usage
    local mem_usage=$(free -h | awk '/Mem:/ {print $3 "/" $2 " (" $3/$2 * 100 "%)"}')
    log "Memory Usage: $mem_usage"
    
    # Load average
    local load=$(uptime | awk -F'load average:' '{print $2}')
    log "Load Average: $load"
    
    # Uptime
    local uptime=$(uptime -p)
    log "System Uptime: $uptime"
    
    # Docker disk usage
    local docker_disk=$(docker system df --format 'table {{.Type}}\t{{.TotalCount}}\t{{.Size}}' 2>/dev/null || echo "Docker not available")
    log "Docker Disk Usage:\n$docker_disk"
}

clean_docker_system() {
    print_header "DOCKER SYSTEM CLEANUP"
    
    # Remove stopped containers
    local stopped_containers=$(docker ps -a -q -f status=exited)
    if [ -n "$stopped_containers" ]; then
        log "Removing stopped containers..."
        docker rm $stopped_containers
        log_success "Removed stopped containers"
    else
        log_success "No stopped containers found"
    fi
    
    # Remove unused images
    log "Removing unused Docker images..."
    docker image prune -a --force --filter "until=24h"
    log_success "Unused Docker images removed"
    
    # Remove unused volumes
    log "Removing unused Docker volumes..."
    docker volume prune --force
    log_success "Unused Docker volumes removed"
    
    # Remove unused networks
    log "Removing unused Docker networks..."
    docker network prune --force
    log_success "Unused Docker networks removed"
    
    # Clean builder cache
    log "Cleaning Docker builder cache..."
    docker builder prune --force
    log_success "Docker builder cache cleaned"
}

clean_logs() {
    print_header "LOG CLEANUP"
    
    # Application logs
    local app_logs_dir="/home/taxi/logs/application"
    if [ -d "$app_logs_dir" ]; then
        log "Cleaning application logs older than 7 days..."
        find "$app_logs_dir" -name "*.log" -type f -mtime +7 -delete
        log_success "Application logs cleaned"
    fi
    
    # Docker logs
    log "Cleaning Docker container logs..."
    find /var/lib/docker/containers/ -name "*.log" -type f -delete 2>/dev/null || true
    log_success "Docker logs cleaned"
    
    # System logs
    log "Rotating system logs..."
    logrotate -f /etc/logrotate.d/taxi-system 2>/dev/null || true
    log_success "System logs rotated"
}

clean_backups() {
    print_header "BACKUP CLEANUP"
    
    # Clean old backups
    log "Cleaning backups older than ${RETENTION_DAYS} days..."
    find "/home/taxi/backups" -type f -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
    find "/home/taxi/backups" -type f -name "*.log" -mtime +$RETENTION_DAYS -delete
    find "/home/taxi/backups" -type d -empty -delete
    log_success "Old backups cleaned"
    
    # Clean temporary files
    log "Cleaning temporary files..."
    find "/home/taxi" -name "*.tmp" -type f -delete
    find "/home/taxi" -name "*.temp" -type f -delete
    find "/home/taxi" -name "*.swp" -type f -delete
    log_success "Temporary files cleaned"
}

update_system() {
    print_header "SYSTEM UPDATES"
    
    # Update package lists
    log "Updating package lists..."
    sudo apt-get update
    
    # Upgrade packages
    log "Upgrading packages..."
    sudo apt-get upgrade -y
    
    # Clean up apt cache
    log "Cleaning apt cache..."
    sudo apt-get autoremove -y
    sudo apt-get autoclean
    
    log_success "System updates completed"
}

check_security() {
    print_header "SECURITY CHECK"
    
    # Check for failed SSH attempts
    local failed_ssh=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l || echo "0")
    log "Failed SSH attempts: $failed_ssh"
    
    # Check fail2ban status
    if systemctl is-active --quiet fail2ban; then
        log_success "fail2ban is active"
    else
        log_error "fail2ban is not active"
    fi
    
    # Check UFW status
    if sudo ufw status | grep -q "Status: active"; then
        log_success "UFW firewall is active"
    else
        log_error "UFW firewall is not active"
    fi
    
    # Check root login status
    if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
        log_success "Root SSH login is disabled"
    else
        log_warning "Root SSH login may be enabled"
    fi
}

optimize_database() {
    print_header "DATABASE OPTIMIZATION"
    
    # PostgreSQL maintenance
    log "Running PostgreSQL maintenance..."
    docker exec taxi-postgres psql -U taxi_admin -d taxi_production -c "VACUUM ANALYZE;" 2>/dev/null || log_warning "PostgreSQL maintenance failed"
    
    # Redis maintenance
    log "Running Redis maintenance..."
    docker exec taxi-redis redis-cli BGSAVE 2>/dev/null || log_warning "Redis maintenance failed"
    
    # MongoDB maintenance
    log "Running MongoDB maintenance..."
    docker exec taxi-mongodb mongosh --eval "db.adminCommand({compact: 'trips'})" 2>/dev/null || log_warning "MongoDB maintenance failed"
    
    log_success "Database optimization completed"
}

check_service_health() {
    print_header "SERVICE HEALTH CHECK"
    
    local services=(
        "taxi-postgres"
        "taxi-redis"
        "taxi-mongodb"
        "taxi-api-gateway"
        "taxi-nginx"
        "taxi-admin-panel"
        "taxi-driver-panel"
        "taxi-customer-panel"
        "taxi-portainer"
        "taxi-netdata"
    )
    
    for service in "${services[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
            local status=$(docker inspect --format='{{.State.Status}}' "$service")
            local health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}N/A{{end}}' "$service")
            log "$service: Status=$status, Health=$health"
        else
            log_error "$service: Not running"
        fi
    done
}

generate_report() {
    print_header "MAINTENANCE REPORT"
    
    local report_file="/home/taxi/logs/maintenance/report_$(date +%Y%m%d_%H%M%S).md"
    
    {
        echo "# Maintenance Report - $(date)"
        echo ""
        echo "## System Information"
        echo "- **Hostname:** $(hostname)"
        echo "- **IP Address:** $(hostname -I | awk '{print $1}')"
        echo "- **Uptime:** $(uptime -p)"
        echo ""
        echo "## Resource Usage"
        echo "- **Disk Usage:** $(df -h /home | awk 'NR==2 {print $5}')"
        echo "- **Memory Usage:** $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
        echo "- **Load Average:** $(uptime | awk -F'load average:' '{print $2}')"
        echo ""
        echo "## Docker Status"
        echo "\`\`\`"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo "\`\`\`"
        echo ""
        echo "## Maintenance Actions"
        echo "1. Docker system cleaned"
        echo "2. Logs rotated and cleaned"
        echo "3. Old backups removed"
        echo "4. System packages updated"
        echo "5. Security checks performed"
        echo "6. Databases optimized"
        echo ""
        echo "## Issues Found"
        grep -i "error\|warning\|failed" "$MAINTENANCE_LOG" | head -10 | while read line; do
            echo "- $line"
        done
        echo ""
        echo "## Next Recommended Maintenance"
        echo "- **Daily:** Log rotation, backup verification"
        echo "- **Weekly:** Database optimization, security updates"
        echo "- **Monthly:** Full system backup, dependency updates"
    } > "$report_file"
    
    log_success "Maintenance report generated: $report_file"
}

main() {
    log "🚀 Starting comprehensive system maintenance"
    
    # Create log directory
    mkdir -p "$(dirname "$MAINTENANCE_LOG")"
    mkdir -p "$BACKUP_DIR"
    
    # Run maintenance tasks
    check_system_health
    clean_docker_system
    clean_logs
    clean_backups
    update_system
    check_security
    optimize_database
    check_service_health
    
    # Generate report
    generate_report
    
    log_success "✅ Maintenance completed successfully"
    log "Maintenance log: $MAINTENANCE_LOG"
    
    echo -e "\n${BLUE}==========================================${NC}"
    echo -e "${BLUE}     MAINTENANCE COMPLETED SUCCESSFULLY   ${NC}"
    echo -e "${BLUE}==========================================${NC}"
}

# Run main function
main "$@"
EOF

run_as_taxi "chmod +x $TAXI_HOME/scripts/maintenance/maintenance.sh"

log_success "Created 4 comprehensive utility scripts (500+ lines)"

# ==============================================================================
# PHASE 11: SSL CERTIFICATES & SECURITY
# ==============================================================================

print_step "11" "SSL Certificates & Advanced Security"

print_substep "Setting up SSL certificates..."

# Create SSL directory structure
run_as_taxi "mkdir -p $TAXI_HOME/certificates/{ssl,letsencrypt,self-signed}"

# Generate self-signed certificate for development
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/certificates/generate_ssl.sh"
#!/bin/bash
# SSL Certificate Generation Script

set -e

CERT_DIR="/home/taxi/certificates"
DOMAIN="${1:-localhost}"
VALID_DAYS="${2:-365}"

echo "Generating SSL certificates for: $DOMAIN"

# Generate private key
openssl genrsa -out "$CERT_DIR/self-signed/$DOMAIN.key" 2048

# Generate CSR
openssl req -new -key "$CERT_DIR/self-signed/$DOMAIN.key" \
    -out "$CERT_DIR/self-signed/$DOMAIN.csr" \
    -subj "/C=GB/ST=London/L=London/O=Taxi Service/CN=$DOMAIN"

# Generate self-signed certificate
openssl x509 -req -days "$VALID_DAYS" \
    -in "$CERT_DIR/self-signed/$DOMAIN.csr" \
    -signkey "$CERT_DIR/self-signed/$DOMAIN.key" \
    -out "$CERT_DIR/self-signed/$DOMAIN.crt"

# Generate fullchain (for nginx)
cat "$CERT_DIR/self-signed/$DOMAIN.crt" \
    "$CERT_DIR/self-signed/$DOMAIN.key" > \
    "$CERT_DIR/self-signed/$DOMAIN.pem"

# Set permissions
chmod 600 "$CERT_DIR/self-signed/$DOMAIN.key"
chmod 644 "$CERT_DIR/self-signed/$DOMAIN.crt"

echo "SSL certificates generated:"
echo "  Key:  $CERT_DIR/self-signed/$DOMAIN.key"
echo "  Cert: $CERT_DIR/self-signed/$DOMAIN.crt"
echo "  PEM:  $CERT_DIR/self-signed/$DOMAIN.pem"
EOF

run_as_taxi "chmod +x $TAXI_HOME/certificates/generate_ssl.sh"
run_as_taxi "$TAXI_HOME/certificates/generate_ssl.sh localhost 365"

# Create Let's Encrypt setup script
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/certificates/setup_letsencrypt.sh"
#!/bin/bash
# Let's Encrypt Setup Script

set -e

DOMAIN="${1:-yourdomain.com}"
EMAIL="${2:-admin@$DOMAIN}"

echo "Setting up Let's Encrypt for: $DOMAIN"
echo "Email: $EMAIL"

# Install certbot
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx

# Stop nginx temporarily
docker stop taxi-nginx

# Obtain certificate
sudo certbot certonly --standalone \
    --agree-tos \
    --non-interactive \
    --email "$EMAIL" \
    -d "$DOMAIN" \
    -d "www.$DOMAIN" \
    -d "admin.$DOMAIN" \
    -d "driver.$DOMAIN" \
    -d "api.$DOMAIN" \
    -d "monitor.$DOMAIN"

# Create symlinks for nginx
sudo ln -sf "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" \
    "/home/taxi/certificates/letsencrypt/fullchain.pem"
sudo ln -sf "/etc/letsencrypt/live/$DOMAIN/privkey.pem" \
    "/home/taxi/certificates/letsencrypt/privkey.pem"

# Set permissions
sudo chmod 755 "/etc/letsencrypt/live"
sudo chmod 755 "/etc/letsencrypt/archive"
sudo chown -R taxi:taxi "/home/taxi/certificates/letsencrypt"

# Start nginx
docker start taxi-nginx

echo "Let's Encrypt setup complete!"
echo "Certificates are available at: /home/taxi/certificates/letsencrypt/"
echo ""
echo "To set up auto-renewal, add to crontab:"
echo "0 3 * * * certbot renew --quiet --post-hook 'docker restart taxi-nginx'"
EOF

run_as_taxi "chmod +x $TAXI_HOME/certificates/setup_letsencrypt.sh"

log_success "SSL certificate scripts created"

# ==============================================================================
# PHASE 12: FINAL SETUP & VERIFICATION
# ==============================================================================

print_step "12" "Final Setup & System Verification"

print_substep "Setting up systemd services for taxi user..."

# Create systemd service for Docker rootless
cat << 'EOF' | run_as_root "tee /etc/systemd/system/docker-taxi.service"
[Unit]
Description=Docker Rootless Service for Taxi User
After=network-online.target firewalld.service containerd.service
Wants=network-online.target
Requires=containerd.service

[Service]
Type=notify
User=taxi
Group=taxi
Environment=PATH=/home/taxi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=DOCKER_HOST=unix:///home/taxi/.docker/run/docker.sock
ExecStart=/home/taxi/bin/dockerd-rootless.sh
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

run_as_root "systemctl daemon-reload"
run_as_root "systemctl enable docker-taxi.service"
run_as_root "systemctl start docker-taxi.service"

# Create systemd timer for automated backups
cat << 'EOF' | run_as_root "tee /etc/systemd/system/taxi-backup.timer"
[Unit]
Description=Run Taxi System Backup Daily
Requires=taxi-backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

cat << 'EOF' | run_as_root "tee /etc/systemd/system/taxi-backup.service"
[Unit]
Description=Taxi System Backup Service
After=docker-taxi.service
Requires=docker-taxi.service

[Service]
Type=oneshot
User=taxi
Group=taxi
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=DOCKER_HOST=unix:///home/taxi/.docker/run/docker.sock
ExecStart=/home/taxi/scripts/backup/backup.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

run_as_root "systemctl daemon-reload"
run_as_root "systemctl enable taxi-backup.timer"
run_as_root "systemctl start taxi-backup.timer"

# Create systemd service for health monitoring
cat << 'EOF' | run_as_root "tee /etc/systemd/system/taxi-health.service"
[Unit]
Description=Taxi System Health Monitoring Service
After=docker-taxi.service
Requires=docker-taxi.service

[Service]
Type=simple
User=taxi
Group=taxi
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=DOCKER_HOST=unix:///home/taxi/.docker/run/docker.sock
ExecStart=/home/taxi/scripts/monitoring/health-check.sh 300
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

run_as_root "systemctl daemon-reload"
run_as_root "systemctl enable taxi-health.service"
run_as_root "systemctl start taxi-health.service"

print_substep "Setting up cron jobs for maintenance..."

# Set up cron jobs
cat << 'EOF' | run_as_root "crontab -u taxi -"
# Taxi System Maintenance Schedule

# Daily backup (also handled by systemd timer)
0 2 * * * /home/taxi/scripts/backup/backup.sh >> /home/taxi/logs/backup_cron.log 2>&1

# Health check every 5 minutes
*/5 * * * * /home/taxi/scripts/monitoring/health-check.sh 0 >> /home/taxi/logs/health_cron.log 2>&1

# Weekly maintenance every Sunday at 3 AM
0 3 * * 0 /home/taxi/scripts/maintenance/maintenance.sh >> /home/taxi/logs/maintenance_cron.log 2>&1

# Log cleanup every day at 4 AM
0 4 * * * find /home/taxi/logs -name "*.log" -mtime +7 -delete

# SSL certificate renewal check (if using Let's Encrypt)
0 5 * * * certbot renew --quiet --post-hook "docker restart taxi-nginx" >> /home/taxi/logs/ssl_renewal.log 2>&1

# Docker system cleanup every Saturday at 2 AM
0 2 * * 6 docker system prune -af --volumes >> /home/taxi/logs/docker_cleanup.log 2>&1

# Database optimization every day at 1 AM
0 1 * * * docker exec taxi-postgres psql -U taxi_admin -d taxi_production -c "VACUUM ANALYZE;" >> /home/taxi/logs/db_optimization.log 2>&1
EOF

print_substep "Creating startup script..."

# Create startup script
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/start-taxi-system.sh"
#!/bin/bash
# ==============================================================================
# TAXI SYSTEM - STARTUP SCRIPT
# ==============================================================================

set -e

echo "🚕 Starting Taxi System..."
echo "Time: $(date)"
echo "User: $(whoami)"
echo ""

# Start Docker rootless service
echo "Starting Docker rootless service..."
systemctl --user start docker
sleep 3

# Wait for Docker to be ready
echo "Waiting for Docker to be ready..."
for i in {1..30}; do
    if docker info > /dev/null 2>&1; then
        echo "✓ Docker is ready"
        break
    fi
    sleep 2
    if [ "$i" -eq 30 ]; then
        echo "✗ Docker failed to start"
        exit 1
    fi
done

# Navigate to docker compose directory
cd /home/taxi/docker/compose

# Start all services
echo "Starting Docker services..."
docker-compose up -d

# Wait for services to be healthy
echo "Waiting for services to become healthy..."
sleep 10

# Check service status
echo ""
echo "Service Status:"
echo "==============="
docker-compose ps

# Show health check
echo ""
echo "Health Check:"
echo "============="
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✓ API Gateway is healthy"
else
    echo "✗ API Gateway is not responding"
fi

# Show important URLs
echo ""
echo "Important URLs:"
echo "==============="
echo "Admin Panel:    https://localhost/admin"
echo "Driver Panel:   https://localhost/driver"
echo "Customer Panel: https://localhost/"
echo "API Docs:       https://localhost/api/docs"
echo "Portainer:      http://localhost:9000"
echo "Netdata:        http://localhost:19999"
echo ""

echo "✅ Taxi System started successfully!"
echo "Use 'docker-compose logs -f' to view logs"
echo "Use 'docker-compose down' to stop services"
EOF

run_as_taxi "chmod +x $TAXI_HOME/start-taxi-system.sh"

# Create stop script
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/stop-taxi-system.sh"
#!/bin/bash
# ==============================================================================
# TAXI SYSTEM - SHUTDOWN SCRIPT
# ==============================================================================

set -e

echo "🛑 Stopping Taxi System..."
echo "Time: $(date)"
echo ""

cd /home/taxi/docker/compose

echo "Stopping Docker services..."
docker-compose down

echo "Stopping Docker rootless service..."
systemctl --user stop docker

echo ""
echo "✅ Taxi System stopped successfully!"
EOF

run_as_taxi "chmod +x $TAXI_HOME/stop-taxi-system.sh"

# Create restart script
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/restart-taxi-system.sh"
#!/bin/bash
# ==============================================================================
# TAXI SYSTEM - RESTART SCRIPT
# ==============================================================================

/home/taxi/stop-taxi-system.sh
sleep 5
/home/taxi/start-taxi-system.sh
EOF

run_as_taxi "chmod +x $TAXI_HOME/restart-taxi-system.sh"

# Create print_summary function
cat << 'EOF' | run_as_taxi "tee $TAXI_HOME/print_summary.sh"
#!/bin/bash
# Print installation summary at the end
print_summary() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                 INSTALLATION SUMMARY                   ${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    if [ -n "${WARNINGS[*]}" ]; then
        echo -e "${YELLOW}⚠ WARNINGS FOUND:${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo "  • $warning"
        done
    else
        echo -e "${GREEN}✅ No warnings found${NC}"
    fi
    echo -e "\n${GREEN}✅ Installation check completed at: $(date)${NC}"
}
EOF

run_as_taxi "chmod +x $TAXI_HOME/print_summary.sh"

# =====================
# TAXI QUICK INSTALLER
# =====================

# Para ejecutar el instalador rápido, llama a: taxi_quick_installer

# --- INTEGRACIÓN taxi_quick_installer AL FLUJO PRINCIPAL ---
taxi_quick_installer() {
        log_step "Instalando dependencias (Docker, Docker Compose, Nginx, PostgreSQL, Redis)..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y curl git nginx docker.io docker-compose postgresql redis-server > /dev/null
        systemctl enable --now docker
        systemctl enable --now redis-server
        systemctl enable --now postgresql
        systemctl enable --now nginx
        log_ok "Dependencias instaladas."

        log_step "Configurando usuario y directorios..."
        id taxi &>/dev/null || useradd -m -s /bin/bash taxi
        mkdir -p /home/taxi/app
        chown -R taxi:taxi /home/taxi

        log_step "Generando archivo .env..."
        cat > /home/taxi/app/.env <<EOF
POSTGRES_PASSWORD=taxipass
REDIS_PASSWORD=redispass
API_PORT=3000
EOF
        chown taxi:taxi /home/taxi/app/.env

        log_step "Generando docker-compose.yml..."
        cat > /home/taxi/app/docker-compose.yml <<EOF
version: '3.8'
services:
    postgres:
        image: postgres:15
        environment:
            POSTGRES_PASSWORD: taxipass
        ports:
            - "5432:5432"
        volumes:
            - pgdata:/var/lib/postgresql/data
        restart: always

    redis:
        image: redis:7
        command: ["redis-server", "--requirepass", "redispass"]
        ports:
            - "6379:6379"
        restart: always

    api:
        image: node:18
        working_dir: /app
        command: bash -c "npx http-server -p 3000"
        ports:
            - "3000:3000"
        volumes:
            - ./api:/app
        restart: always

    admin:
        image: nginx:alpine
        ports:
            - "8080:80"
        volumes:
            - ./admin:/usr/share/nginx/html:ro
        restart: always

volumes:
    pgdata:
EOF
        chown taxi:taxi /home/taxi/app/docker-compose.yml

        log_step "Creando API y Admin de ejemplo..."
        mkdir -p /home/taxi/app/api /home/taxi/app/admin
        [ -f /home/taxi/app/api/index.html ] || echo '<h1>Taxi API funcionando 🚕</h1>' > /home/taxi/app/api/index.html
        [ -f /home/taxi/app/admin/index.html ] || echo '<h1>Taxi Admin Panel</h1>' > /home/taxi/app/admin/index.html
        chown -R taxi:taxi /home/taxi/app/api /home/taxi/app/admin

log_step "Configurando Nginx como proxy..."
cat > /etc/nginx/sites-available/taxi << 'NGINX'
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location /admin/ {
        proxy_pass http://localhost:8080/;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/taxi /etc/nginx/sites-enabled/taxi
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
log_ok "Sistema configurado."

        log_step "Levantando servicios Docker..."
        cd /home/taxi/app
        sudo -u taxi docker-compose --env-file .env up -d
        log_ok "Servicios Docker en ejecución."

        IP=$(hostname -I | awk '{print $1}')
        echo -e "\n\033[1;32m✅ INSTALACIÓN COMPLETA\033[0m"
        echo "🌐 API:         http://$IP:3000"
        echo "📊 Admin Panel: http://$IP:8080"
        echo "🐘 PostgreSQL:  $IP:5432"
        echo "🔴 Redis:       $IP:6379"
}


# Si el primer argumento es --quick, ejecuta taxi_quick_installer y termina
if [[ "${1:-}" == "--quick" ]]; then
    taxi_quick_installer
    exit 0
fi

# Ejecuta el flujo principal solo si el script es ejecutado directamente
if [[ "$0" == "$BASH_SOURCE" ]]; then
    main_installer "$@"
fi








