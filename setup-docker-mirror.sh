#!/bin/bash
# Script para configurar Docker con espejo de Aliyun (funciona mejor que Docker Hub)

echo "════════════════════════════════════════════════════════════════"
echo "    🔧 CONFIGURAR DOCKER CON ESPEJO ALIYUN"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root (sudo)"
    exit 1
fi

# 1. Detener Docker
echo "1️⃣  Deteniendo Docker..."
systemctl stop docker 2>/dev/null || true
sleep 3

# 2. Crear directorio si no existe
mkdir -p /etc/docker

# 3. Configurar daemon.json con espejo
echo "2️⃣  Configurando Docker con espejo de Aliyun..."
cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://mirror.aliyun.com",
    "https://2qikv7nl.mirror.aliyuncs.com"
  ],
  "dns": ["8.8.8.8", "8.8.4.4", "114.114.114.114"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

echo "   ✅ Configuración guardada"

# 4. Recargar daemon
echo "3️⃣  Recargando daemon..."
systemctl daemon-reload

# 5. Iniciar Docker
echo "4️⃣  Iniciando Docker..."
systemctl start docker
sleep 5

# 6. Verificar estado
echo "5️⃣  Verificando estado..."
if systemctl is-active --quiet docker; then
    echo "   ✅ Docker activo"
else
    echo "   ❌ Docker NO está activo"
    systemctl start docker
    sleep 5
fi

# 7. Probar descarga
echo "6️⃣  Probando descarga de imagen..."
if timeout 120 docker pull alpine:latest >/dev/null 2>&1; then
    echo "   ✅ Descarga funciona"
    docker rmi alpine:latest 2>/dev/null || true
else
    echo "   ⚠️  Descarga aún falla - intenta manualmente:"
    echo "      docker pull mongo:6-alpine"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "    ✅ CONFIGURACIÓN COMPLETADA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Ahora intenta:"
echo "  sudo bash /root/Proyecto/main.sh --fresh"
