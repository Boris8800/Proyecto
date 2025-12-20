#!/bin/bash
set -euo pipefail

# Cargar librerías
source "$(dirname "$0")/lib/colors.sh"
source "$(dirname "$0")/lib/logging.sh"
source "$(dirname "$0")/lib/error_handling.sh"

# Cargar configuración
test -f "$(dirname "$0")/../config/defaults.conf" && source "$(dirname "$0")/../config/defaults.conf"

test -f "$(dirname "$0")/../config/override.conf" && source "$(dirname "$0")/../config/override.conf"

# Parsear argumentos
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --domain=*) DOMAIN="${1#*=}" ;;
            --email=*) EMAIL="${1#*=}" ;;
            --auto) AUTO_INSTALL=true ;;
            --dev) DEV_MODE=true ;;
            --dry-run) DRY_RUN=true ;;
            --help) show_help; exit 0 ;;
            *) log_error "Opción desconocida: $1"; exit 1 ;;
        esac
        shift
    done
}

main() {
    log_header "🚕 TAXI SYSTEM INSTALLER v2.0"
    local modules=(
        "01_preflight"
        "02_security"
        "03_docker"
        "04_database"
        "05_services"
        "06_monitoring"
        "07_backup"
        "08_postinstall"
    )
    for module in "${modules[@]}"; do
        log_step "Ejecutando módulo: ${module#*_}"
        source "modules/${module}.sh"
        run_${module#*_}
    done
    log_success "✅ Instalación completada exitosamente!"
}

parse_arguments "$@"
main
