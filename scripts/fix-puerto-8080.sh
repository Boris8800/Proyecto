#!/bin/bash

################################################################################
# SIMPLE PUERTO 8080 FIX - ONLY STATUS DASHBOARD
# Quick fix for port 8080 not responding
################################################################################

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              PUERTO 8080 - STATUS DASHBOARD FIX               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

PROJECT_ROOT="/root/Proyecto"
cd "$PROJECT_ROOT" || exit 1

# ============================================================================
# STEP 1: Check Docker Status
# ============================================================================
echo "[1] Verificando Docker..."
docker --version > /dev/null 2>&1 || {
    echo "❌ Docker no está instalado"
    exit 1
}

echo "✓ Docker está disponible"
echo ""

# ============================================================================
# STEP 2: Check if taxi-status container exists
# ============================================================================
echo "[2] Buscando contenedor taxi-status..."
CONTAINER=$(docker ps -a --format '{{.Names}}' | grep taxi-status)

if [ -z "$CONTAINER" ]; then
    echo "❌ Contenedor 'taxi-status' no encontrado"
    echo ""
    echo "Contenedores disponibles:"
    docker ps -a --format '{{.Names}}'
    echo ""
    echo "Creando contenedor..."
    cd "$PROJECT_ROOT/config"
    docker-compose -f docker-compose.yml up -d taxi-status
    sleep 10
else
    echo "✓ Contenedor 'taxi-status' encontrado"
    
    # Check if running
    RUNNING=$(docker ps --format '{{.Names}}' | grep taxi-status)
    if [ -z "$RUNNING" ]; then
        echo "⚠️  Contenedor no está corriendo"
        echo "Iniciando contenedor..."
        docker start taxi-status
        sleep 5
    else
        echo "✓ Contenedor está corriendo"
    fi
fi

echo ""

# ============================================================================
# STEP 3: Check Docker logs
# ============================================================================
echo "[3] Revisando logs de Docker..."
echo ""
docker logs taxi-status 2>&1 | tail -20
echo ""

# ============================================================================
# STEP 4: Check if port 8080 is listening
# ============================================================================
echo "[4] Verificando puerto 8080..."
if netstat -tuln 2>/dev/null | grep -q ":8080"; then
    echo "✓ Puerto 8080 está escuchando"
else
    echo "❌ Puerto 8080 NO está escuchando"
    echo "Reiniciando contenedor..."
    docker restart taxi-status
    sleep 5
fi

echo ""

# ============================================================================
# STEP 5: Test Response
# ============================================================================
echo "[5] Probando respuesta HTTP..."
RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null http://127.0.0.1:8080/ 2>&1)

if [ "$RESPONSE" = "200" ]; then
    echo "✓ Puerto 8080 respondiendo (HTTP $RESPONSE)"
else
    echo "❌ Puerto 8080 no respondiendo (HTTP $RESPONSE)"
    echo ""
    echo "Intentando reinicio fuerza..."
    docker kill taxi-status 2>/dev/null || true
    docker rm taxi-status 2>/dev/null || true
    sleep 2
    
    cd "$PROJECT_ROOT/config"
    docker-compose -f docker-compose.yml up -d taxi-status
    sleep 10
    
    RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null http://127.0.0.1:8080/ 2>&1)
    if [ "$RESPONSE" = "200" ]; then
        echo "✓ Puerto 8080 ahora respondiendo"
    fi
fi

echo ""

# ============================================================================
# STEP 6: Verify ALL Services
# ============================================================================
echo "[6] Verificando TODOS los servicios..."
echo ""

declare -a PORTS=(8080 3001 3002 3003)
declare -a NAMES=("Status Dashboard" "Admin Dashboard" "Driver Portal" "Customer App")

for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    NAME=${NAMES[$i]}
    RESP=$(curl -s -w "%{http_code}" -o /dev/null http://127.0.0.1:$PORT/ 2>&1)
    
    if [ "$RESP" = "200" ]; then
        echo "✓ Puerto $PORT ($NAME) - FUNCIONANDO"
    else
        echo "✗ Puerto $PORT ($NAME) - NO RESPONDE (HTTP $RESP)"
    fi
done

echo ""

# ============================================================================
# STEP 7: Final Status
# ============================================================================
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    ESTADO FINAL                               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "Contenedores Docker:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep taxi

echo ""
echo "Acceso a los servicios:"
echo "  - Status Dashboard: http://5.249.164.40:8080"
echo "  - Admin Dashboard:  http://5.249.164.40:3001"
echo "  - Driver Portal:    http://5.249.164.40:3002"
echo "  - Customer App:     http://5.249.164.40:3003"
echo ""

echo "Si continúan los problemas, revisar:"
echo "  docker logs taxi-status"
echo "  docker logs taxi-api"
echo "  docker logs taxi-postgres"
echo ""
