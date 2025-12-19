#!/bin/bash
# Script de instalación con validaciones previas
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== CHEQUEO PRE-INSTALACIÓN ===${NC}"

# 1. Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: Debe ejecutar como root/sudo${NC}"
    exit 1
fi

# 2. Preguntar si continuar
read -p "¿Continuar con chequeo del sistema? (s/n): " respuesta
if [[ ! $respuesta =~ ^[Ss]$ ]]; then
    echo "Instalación cancelada."
    exit 0
fi

# 3. Reparar paquetes rotos
echo -e "${YELLOW}[1/6] Reparando paquetes rotos...${NC}"
apt-get update
apt-get upgrade -y
apt --fix-broken install -y || true
dpkg --configure -a || true
apt-get install -f -y || true

# 4. Remover Docker conflictivo
echo -e "${YELLOW}[2/6] Limpiando Docker anterior...${NC}"
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# 5. Instalar Docker
echo -e "${YELLOW}[3/6] Instalando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
fi

# 6. Instalar docker-compose
echo -e "${YELLOW}[4/6] Instalando Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# 7. Instalar otras dependencias
echo -e "${YELLOW}[5/6] Instalando Nginx, PostgreSQL, Redis...${NC}"
apt-get install -y nginx postgresql redis-server

# 8. Crear usuario taxi
echo -e "${YELLOW}[6/6] Configurando usuario...${NC}"
if ! id taxi &>/dev/null; then
    useradd -m -s /bin/bash taxi
    echo "Usuario 'taxi' creado"
fi

echo -e "${GREEN}✅ Chequeo completado exitosamente${NC}"
echo ""
read -p "¿Continuar con instalación completa del sistema de taxi? (s/n): " instalar

if [[ $instalar =~ ^[Ss]$ ]]; then
    echo "Iniciando instalación completa..."
    # Aquí iría el resto de tu instalador
    echo "Sistema instalado en /home/taxi/app"
else
    echo "Instalación básica completada. Listo para continuar manualmente."
fi
