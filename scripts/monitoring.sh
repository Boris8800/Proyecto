#!/bin/bash

################################################################################
# Swift Cab Monitoring & Alerting System
# Comprehensive real-time monitoring for production environment
################################################################################

set -e

# Configuration
LOG_DIR="/root/Proyecto/logs"
MONITOR_LOG="$LOG_DIR/monitoring.log"
ALERT_LOG="$LOG_DIR/alerts.log"
METRICS_DB="$LOG_DIR/metrics.json"
CONFIG_FILE="/root/Proyecto/config/monitoring.conf"

# Default alert thresholds
CPU_THRESHOLD=${CPU_THRESHOLD:-80}
MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-85}
DISK_THRESHOLD=${DISK_THRESHOLD:-90}
RESPONSE_TIME_THRESHOLD=${RESPONSE_TIME_THRESHOLD:-1000} # ms
ERROR_RATE_THRESHOLD=${ERROR_RATE_THRESHOLD:-5} # %
RESTART_THRESHOLD=${RESTART_THRESHOLD:-5} # restarts per hour

# Services to monitor
SERVICES=("admin-dashboard" "driver-portal" "customer-app")
PORTS=(3001 3002 3003)
BACKEND_PORTS=(3000 8080)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Initialize log files
init_logs() {
    mkdir -p "$LOG_DIR"
    touch "$MONITOR_LOG" "$ALERT_LOG" "$METRICS_DB"
    chmod 644 "$MONITOR_LOG" "$ALERT_LOG" "$METRICS_DB"
}

# Log function
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$MONITOR_LOG"
}

# Alert function
send_alert() {
    local severity=$1
    local service=$2
    local message=$3
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    alert_msg="[$timestamp] [$severity] [$service] $message"
    echo "$alert_msg" >> "$ALERT_LOG"
    
    case $severity in
        CRITICAL)
            echo -e "${RED}$alert_msg${NC}"
            # Could integrate with email/Slack/PagerDuty here
            ;;
        WARNING)
            echo -e "${YELLOW}$alert_msg${NC}"
            ;;
        INFO)
            echo -e "${BLUE}$alert_msg${NC}"
            ;;
    esac
    
    log_message "$severity" "[$service] $message"
}

# Check if service is running
check_service_status() {
    local service=$1
    local port=$2
    
    if nc -z localhost "$port" 2>/dev/null; then
        echo "online"
    else
        echo "offline"
    fi
}

# Get response time
measure_response_time() {
    local port=$1
    
    response_time=$(curl -s -o /dev/null -w "%{time_total}" http://localhost:$port/api/health 2>/dev/null || echo "0")
    echo "scale=3; $response_time * 1000" | bc 2>/dev/null || echo "0"
}

# Check CPU usage
check_cpu_usage() {
    local service=$1
    
    if command -v ps &> /dev/null; then
        cpu_usage=$(ps aux | grep "[n]ode.*server" | grep "$service" | awk '{sum+=$3} END {print sum}' 2>/dev/null || echo "0")
        echo "$cpu_usage"
    else
        echo "0"
    fi
}

# Check memory usage
check_memory_usage() {
    local service=$1
    
    if command -v ps &> /dev/null; then
        memory_usage=$(ps aux | grep "[n]ode.*server" | grep "$service" | awk '{sum+=$6} END {print sum}' 2>/dev/null || echo "0")
        echo "$memory_usage"
    else
        echo "0"
    fi
}

# Check system resources
check_system_resources() {
    local resource=$1
    
    case $resource in
        cpu)
            top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d'.' -f1
            ;;
        memory)
            free | grep Mem | awk '{printf("%.0f", $3/$2 * 100)}'
            ;;
        disk)
            df /root/Proyecto | awk 'NR==2 {print $5}' | sed 's/%//'
            ;;
    esac
}

# Check error rates in logs
check_error_rates() {
    local log_file=$1
    local window=${2:-3600} # Default 1 hour
    
    if [ ! -f "$log_file" ]; then
        echo "0"
        return
    fi
    
    local cutoff_time=$(($(date +%s) - window))
    local total_lines=$(tail -c 10000 "$log_file" 2>/dev/null | wc -l)
    local error_lines=$(tail -c 10000 "$log_file" 2>/dev/null | grep -i "error\|warn\|fail" | wc -l)
    
    if [ "$total_lines" -eq 0 ]; then
        echo "0"
    else
        echo "scale=2; $error_lines / $total_lines * 100" | bc 2>/dev/null || echo "0"
    fi
}

# Monitor database connections
check_database_connections() {
    if nc -z localhost 5432 2>/dev/null; then
        # PostgreSQL is running
        echo "postgresql: online"
    else
        echo "postgresql: offline"
    fi
    
    if nc -z localhost 27017 2>/dev/null; then
        # MongoDB is running
        echo "mongodb: online"
    else
        echo "mongodb: offline"
    fi
    
    if nc -z localhost 6379 2>/dev/null; then
        # Redis is running
        echo "redis: online"
    else
        echo "redis: offline"
    fi
}

# Check SSL certificate expiration
check_ssl_expiration() {
    local cert_path=$1
    
    if [ ! -f "$cert_path" ]; then
        echo "not-found"
        return
    fi
    
    expiration_date=$(openssl x509 -enddate -noout -in "$cert_path" 2>/dev/null | cut -d= -f2)
    expiration_epoch=$(date -d "$expiration_date" +%s 2>/dev/null || echo "0")
    current_epoch=$(date +%s)
    days_left=$(( (expiration_epoch - current_epoch) / 86400 ))
    
    echo "$days_left"
}

# Monitor Nginx
check_nginx_status() {
    if systemctl is-active --quiet nginx; then
        echo "online"
    else
        echo "offline"
    fi
}

# Generate real-time dashboard
generate_dashboard() {
    clear
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          Swift Cab Monitoring Dashboard                        ║${NC}"
    echo -e "${BLUE}║          Last Updated: $timestamp                              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Web Services Status
    echo -e "${BLUE}┌─ Web Services ${NC}"
    for i in "${!SERVICES[@]}"; do
        local service="${SERVICES[$i]}"
        local port="${PORTS[$i]}"
        local status=$(check_service_status "$service" "$port")
        local response_time=$(measure_response_time "$port")
        
        if [ "$status" = "online" ]; then
            echo -e "│ ${GREEN}✓${NC} $service (Port $port): ${GREEN}ONLINE${NC} - Response: ${response_time}ms"
        else
            echo -e "│ ${RED}✗${NC} $service (Port $port): ${RED}OFFLINE${NC}"
        fi
    done
    echo ""
    
    # Backend Services
    echo -e "${BLUE}┌─ Backend Services ${NC}"
    echo -e "│ ${GREEN}✓${NC} API Server (3000): $(nc -z localhost 3000 2>/dev/null && echo "${GREEN}ONLINE${NC}" || echo "${RED}OFFLINE${NC}")"
    echo -e "│ ${GREEN}✓${NC} Status Dashboard (8080): $(nc -z localhost 8080 2>/dev/null && echo "${GREEN}ONLINE${NC}" || echo "${RED}OFFLINE${NC}")"
    echo ""
    
    # Database Services
    echo -e "${BLUE}┌─ Databases ${NC}"
    check_database_connections | while read line; do
        echo "│ $line"
    done
    echo ""
    
    # System Resources
    echo -e "${BLUE}┌─ System Resources ${NC}"
    local cpu=$(check_system_resources cpu)
    local memory=$(check_system_resources memory)
    local disk=$(check_system_resources disk)
    
    echo -e "│ CPU Usage: ${cpu}%"
    echo -e "│ Memory Usage: ${memory}%"
    echo -e "│ Disk Usage: ${disk}%"
    echo ""
    
    # SSL Certificates
    echo -e "${BLUE}┌─ SSL Certificates ${NC}"
    local cert_path="/etc/letsencrypt/live/yourdomain.com/fullchain.pem"
    if [ -f "$cert_path" ]; then
        local days_left=$(check_ssl_expiration "$cert_path")
        if [ "$days_left" -gt 30 ]; then
            echo -e "│ Certificate Expiration: ${GREEN}${days_left} days remaining${NC}"
        elif [ "$days_left" -gt 7 ]; then
            echo -e "│ Certificate Expiration: ${YELLOW}${days_left} days remaining (renew soon)${NC}"
        else
            echo -e "│ Certificate Expiration: ${RED}${days_left} days remaining (URGENT!)${NC}"
        fi
    else
        echo -e "│ Certificate: ${YELLOW}Not found at expected path${NC}"
    fi
    echo ""
    
    # Nginx Status
    echo -e "${BLUE}┌─ Nginx Reverse Proxy ${NC}"
    local nginx_status=$(check_nginx_status)
    if [ "$nginx_status" = "online" ]; then
        echo -e "│ Status: ${GREEN}RUNNING${NC}"
    else
        echo -e "│ Status: ${RED}STOPPED${NC}"
    fi
    echo ""
    
    # Error Rates
    echo -e "${BLUE}┌─ Error Rates (Last 24h) ${NC}"
    for log in /root/Proyecto/logs/*error.log; do
        if [ -f "$log" ]; then
            error_rate=$(check_error_rates "$log" 86400)
            service_name=$(basename "$log" -error.log)
            echo "│ $service_name: ${error_rate}%"
        fi
    done
    echo ""
    
    # Recent Alerts
    echo -e "${BLUE}┌─ Recent Alerts ${NC}"
    if [ -f "$ALERT_LOG" ]; then
        tail -5 "$ALERT_LOG" | while read line; do
            echo "│ $line"
        done
    else
        echo "│ No recent alerts"
    fi
    echo ""
    
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Monitoring active... (Update frequency: 30 seconds)"
}

# Continuous monitoring loop
start_monitoring() {
    log_message "INFO" "Monitoring system started"
    
    while true; do
        # Check all services
        for i in "${!SERVICES[@]}"; do
            local service="${SERVICES[$i]}"
            local port="${PORTS[$i]}"
            local status=$(check_service_status "$service" "$port")
            
            if [ "$status" = "offline" ]; then
                send_alert "CRITICAL" "$service" "Service is offline (Port $port)"
            fi
            
            local response_time=$(measure_response_time "$port")
            if (( $(echo "$response_time > $RESPONSE_TIME_THRESHOLD" | bc -l) )); then
                send_alert "WARNING" "$service" "Slow response time: ${response_time}ms"
            fi
        done
        
        # Check system resources
        local cpu=$(check_system_resources cpu)
        if [ "$cpu" -gt "$CPU_THRESHOLD" ]; then
            send_alert "WARNING" "system" "High CPU usage: ${cpu}%"
        fi
        
        local memory=$(check_system_resources memory)
        if [ "$memory" -gt "$MEMORY_THRESHOLD" ]; then
            send_alert "WARNING" "system" "High memory usage: ${memory}%"
        fi
        
        local disk=$(check_system_resources disk)
        if [ "$disk" -gt "$DISK_THRESHOLD" ]; then
            send_alert "CRITICAL" "system" "High disk usage: ${disk}%"
        fi
        
        # Check SSL certificate expiration
        local cert_path="/etc/letsencrypt/live/yourdomain.com/fullchain.pem"
        if [ -f "$cert_path" ]; then
            local days_left=$(check_ssl_expiration "$cert_path")
            if [ "$days_left" -lt 7 ] && [ "$days_left" -ge 0 ]; then
                send_alert "CRITICAL" "ssl-certificate" "Certificate expires in $days_left days"
            fi
        fi
        
        # Generate dashboard
        generate_dashboard
        
        # Wait before next check
        sleep 30
    done
}

# Cleanup function
cleanup() {
    log_message "INFO" "Monitoring system stopped"
    echo "Monitoring stopped."
    exit 0
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

COMMANDS:
    start               Start real-time monitoring dashboard
    status              Show current system status
    logs                Show recent monitoring logs
    alerts              Show recent alerts
    health              Quick health check
    config              Show configuration
    help                Show this help message

OPTIONS:
    --cpu-threshold N           CPU usage threshold (default: 80%)
    --memory-threshold N        Memory usage threshold (default: 85%)
    --disk-threshold N          Disk usage threshold (default: 90%)
    --response-time-threshold N Response time threshold (default: 1000ms)
    --error-rate-threshold N    Error rate threshold (default: 5%)

EXAMPLES:
    $0 start
    $0 status
    $0 logs
    $0 health
    $0 start --cpu-threshold 90 --memory-threshold 95

EOF
}

# Parse arguments
case "${1:-start}" in
    start)
        shift
        # Parse options
        while [[ $# -gt 0 ]]; do
            case $1 in
                --cpu-threshold)
                    CPU_THRESHOLD="$2"
                    shift 2
                    ;;
                --memory-threshold)
                    MEMORY_THRESHOLD="$2"
                    shift 2
                    ;;
                --disk-threshold)
                    DISK_THRESHOLD="$2"
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done
        
        init_logs
        trap cleanup SIGINT SIGTERM
        start_monitoring
        ;;
        
    status)
        init_logs
        generate_dashboard
        ;;
        
    logs)
        if [ -f "$MONITOR_LOG" ]; then
            echo "=== Monitoring Logs (Last 20 entries) ==="
            tail -20 "$MONITOR_LOG"
        fi
        ;;
        
    alerts)
        if [ -f "$ALERT_LOG" ]; then
            echo "=== Alerts (Last 20 entries) ==="
            tail -20 "$ALERT_LOG"
        fi
        ;;
        
    health)
        echo "Quick Health Check:"
        echo ""
        for i in "${!SERVICES[@]}"; do
            local service="${SERVICES[$i]}"
            local port="${PORTS[$i]}"
            local status=$(check_service_status "$service" "$port")
            echo "  $service: $status"
        done
        echo ""
        ;;
        
    config)
        echo "Monitoring Configuration:"
        echo "  CPU Threshold: ${CPU_THRESHOLD}%"
        echo "  Memory Threshold: ${MEMORY_THRESHOLD}%"
        echo "  Disk Threshold: ${DISK_THRESHOLD}%"
        echo "  Response Time Threshold: ${RESPONSE_TIME_THRESHOLD}ms"
        echo "  Error Rate Threshold: ${ERROR_RATE_THRESHOLD}%"
        echo "  Restart Threshold: ${RESTART_THRESHOLD} per hour"
        ;;
        
    help)
        usage
        ;;
        
    *)
        usage
        exit 1
        ;;
esac
