#!/bin/bash
# lib/common.sh - Common variables and basic utilities
# Part of the modularized Taxi System installer

# ===================== COLOR CODES =====================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# ===================== CONFIGURATION =====================
export TAXI_USER="taxi"
export TAXI_PASS="12345"
export TAXI_HOME="/home/$TAXI_USER"
export SSH_PORT="22"
export TMPDIR="/tmp"
export SHMDIR="/dev/shm"
export MINSPACE=100000  # 100MB in KB

# ===================== LOGGING =====================
export LOG_FILE="/tmp/taxi-install-$(date +%Y%m%d_%H%M%S).log"
export INSTALL_LOG="$TAXI_HOME/taxi_install.log"
export ERROR_LOG="$TAXI_HOME/taxi_errors.log"

export CURRENT_PHASE=0
export TOTAL_PHASES=9

# ===================== LOGGING FUNCTIONS =====================
log_step() { 
    echo -e "${BLUE}[STEP]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [STEP] $1" >> "$LOG_FILE" 2>/dev/null
}

log_ok() { 
    echo -e "${GREEN}[OK]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [OK] $1" >> "$LOG_FILE" 2>/dev/null
}

log_error() { 
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE" 2>/dev/null
}

log_warn() { 
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$LOG_FILE" 2>/dev/null
}

log_info() { 
    echo -e "${CYAN}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE" 2>/dev/null
}

log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# ===================== BANNER & MESSAGES =====================
print_banner() {
    echo -e "${PURPLE}\n════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}   $1${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}${2:-}${NC}\n"
}

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    $1                    ${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
}

print_substep() {
    echo -e "${BLUE}  →${NC} $1"
}

print_step() {
    local phase_num=$1
    local phase_name=$2
    CURRENT_PHASE=$phase_num
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}PHASE $phase_num/$TOTAL_PHASES: $phase_name${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

end_phase() {
    local phase_name=$1
    echo ""
    log_ok "Phase $CURRENT_PHASE completed: $phase_name"
    echo ""
}

# ===================== SPINNER & PROGRESS =====================
spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='|/-\'
    
    echo -ne "${BLUE}${message}${NC} "
    while kill -0 "$pid" 2>/dev/null; do
        for i in $(seq 0 3); do
            echo -ne "\b${spinstr:$i:1}"
            sleep "$delay"
        done
    done
    wait "$pid"
    local status=$?
    if [ $status -eq 0 ]; then
        echo -ne "\b${GREEN}✓${NC}\n"
    else
        echo -ne "\b${RED}✗${NC}\n"
    fi
    return $status
}

run_with_spinner() {
    local message=$1
    shift
    ("$@" >/dev/null 2>&1) &
    spinner $! "$message"
}

show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    printf "\r${CYAN}[${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%$((width-filled))s" | tr ' ' '-'
    printf "${CYAN}]${NC} ${percentage}%% - ${message}"
}

# ===================== UTILITY FUNCTIONS =====================
fatal_error() {
    echo -e "${RED}FATAL: $1${NC}"
    echo -e "${YELLOW}See logs for more details. Suggestions:${NC}"
    echo -e "- Check your network connection."
    echo -e "- Ensure all dependencies are installed."
    echo -e "- Review disk space and permissions."
    exit 1
}
