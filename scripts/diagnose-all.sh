#!/bin/bash

################################################################################
# DIAGNOSTIC - PORT 8080 ISSUE
# Helps identify what's wrong with port 8080
################################################################################

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        DIAGNÓSTICO - PUERTO 8080 Y TODOS LOS SERVICIOS        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# 1. Docker Status
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "1. ESTADO DE DOCKER"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "Versión de Docker:"
docker --version 2>/dev/null || echo "❌ Docker no disponible"
echo ""

echo "Contenedores corriendo:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "Todos los contenedores (incluyendo detenidos):"
docker ps -a --format "table {{.Names}}\t{{.Status}}"
echo ""

# ============================================================================
# 2. Port Status
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "2. PUERTOS ESCUCHANDO"
echo "═══════════════════════════════════════════════════════════════"
echo ""

netstat -tuln 2>/dev/null | grep -E ":(3000|3001|3002|3003|8080)" || echo "No hay servicios escuchando"
echo ""

# ============================================================================
# 3. HTTP Response Tests
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "3. PRUEBAS DE RESPUESTA HTTP"
echo "═══════════════════════════════════════════════════════════════"
echo ""

for port in 8080 3001 3002 3003 3000; do
    echo -n "Puerto $port: "
    RESULT=$(timeout 3 curl -s -w "%{http_code}" -o /dev/null http://127.0.0.1:$port/ 2>&1)
    if [ -z "$RESULT" ]; then
        echo "❌ TIMEOUT o no responde"
    elif [ "$RESULT" = "200" ]; then
        echo "✓ RESPONDIENDO (HTTP 200)"
    else
        echo "⚠️  HTTP $RESULT"
    fi
done
echo ""

# ============================================================================
# 4. Node.js Processes
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "4. PROCESOS NODE.JS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

ps aux | grep -E "node|npm" | grep -v grep | awk '{print $2, $11, $12, $13}' | head -20 || echo "No hay procesos Node.js"
echo ""

# ============================================================================
# 5. Docker Logs
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "5. LOGS DE DOCKER"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "--- taxi-status (último 10 líneas) ---"
docker logs taxi-status 2>&1 | tail -10 || echo "❌ No existe contenedor taxi-status"
echo ""

echo "--- taxi-api (último 10 líneas) ---"
docker logs taxi-api 2>&1 | tail -10 || echo "❌ No existe contenedor taxi-api"
echo ""

echo "--- taxi-postgres (último 10 líneas) ---"
docker logs taxi-postgres 2>&1 | tail -10 || echo "❌ No existe contenedor taxi-postgres"
echo ""

# ============================================================================
# 6. File System Check
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "6. ARCHIVOS DEL PROYECTO"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -d "/root/Proyecto" ]; then
    echo "✓ Proyecto existe en: /root/Proyecto"
    echo ""
    echo "Estructura:"
    ls -la /root/Proyecto/ | grep -E "web|config|scripts|logs" | awk '{print "  " $9, "(" $5 " bytes)"}'
else
    echo "❌ Proyecto NO existe en /root/Proyecto"
fi
echo ""

# ============================================================================
# 7. Summary
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "7. RESUMEN"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "Para más información:"
echo "  docker ps -a              # Ver todos los contenedores"
echo "  docker logs taxi-status   # Ver logs de status dashboard"
echo "  netstat -tuln             # Ver puertos escuchando"
echo "  ps aux | grep node        # Ver procesos Node.js"
echo ""

echo "Para arreglar:"
echo "  bash /root/Proyecto/scripts/fix-puerto-8080.sh      # Arreglar solo puerto 8080"
echo "  bash /root/Proyecto/scripts/fix-all-vps.sh          # Arreglar todos los servicios"
echo "  docker-compose restart    # Reiniciar contenedores"
echo ""
