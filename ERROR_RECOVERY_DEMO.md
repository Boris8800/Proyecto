# 🔧 Sistema de Recuperación de Errores - Demo

## Cuando el Script se Detiene por un Error

El script ahora incluye un **menú interactivo de recuperación** que aparece automáticamente cuando ocurre un error durante la instalación.

---

## 📋 Ejemplo de Pantalla de Error

```
════════════════════════════════════════════════════════════════
           ⚠️  INSTALLATION ERROR DETECTED
════════════════════════════════════════════════════════════════

Error Details:
  Line Number:    3245
  Exit Code:      1
  Phase:          3/9
  Context:        Docker installation
  Log File:       /tmp/taxi-install-20251220_143052.log

What would you like to do?

  1) View Error Log (last 30 lines)
  2) View Full Log
  3) View Log by Phase
  4) Retry Installation (continue from menu)
  5) Clean & Restart (remove everything and start fresh)
  6) System Status Check
  7) Exit and Fix Manually

Choose an option (1-7): _
```

---

## 🎯 Opciones del Menú de Recuperación

### **Opción 1: Ver Últimas 30 Líneas del Log**
```bash
═══ Last 30 Lines of Log ═══
[2025-12-20 14:30:45] [STEP] Installing Docker...
[2025-12-20 14:30:46] [OK] Docker repository added
[2025-12-20 14:30:48] [ERROR] Failed to install docker-ce
[2025-12-20 14:30:48] Package docker-ce not found
...
```
- Muestra las últimas 30 líneas del log
- **Coloreado automático**: ERRORES en rojo, WARNINGS en amarillo, OK en verde
- Perfecto para ver el error reciente

---

### **Opción 2: Ver Log Completo**
```bash
Opening full log in less viewer...
(Use arrows to scroll, 'q' to quit)
```
- Abre el log completo en el visor `less`
- Permite navegar todo el historial de instalación
- Usa flechas ↑↓ para desplazar, `q` para salir

---

### **Opción 3: Ver Log por Fase**
```bash
Select Phase to View:
  1) Preflight Checks
  2) System Updates
  3) Docker Installation
  4) Database Setup
  5) Application Setup
  6) Configuration
  7) Services Start

Choose phase (1-7): _
```
- Filtra el log mostrando solo la fase específica
- Útil para diagnosticar problemas en una etapa particular
- Muestra las siguientes 50 líneas después de iniciar la fase

---

### **Opción 4: Reintentar Instalación**
```bash
Returning to main menu...

════════════════════════════════════════════════════════════════
         🚕 TAXI SYSTEM - INSTALLATION & MANAGEMENT
════════════════════════════════════════════════════════════════
```
- Vuelve al menú principal
- Permite intentar la instalación de nuevo
- Mantiene el log del error para referencia

---

### **Opción 5: Limpiar y Reiniciar**
```bash
This will remove all installations and start fresh!
Are you sure? Type 'yes' to confirm: yes

Step 1/8: Killing processes on ports...
  ✅ Port 80 freed (killed nginx)
  ✅ Port 443 freed
Step 2/8: Removing Docker containers...
...
════════════════════════════════════════════════════════════════
     ✅ SYSTEM CLEANUP COMPLETED SUCCESSFULLY!
════════════════════════════════════════════════════════════════
```
- Ejecuta limpieza completa del sistema (8 pasos)
- Elimina instalaciones anteriores
- Libera puertos automáticamente
- Regresa al menú principal para reintentar

---

### **Opción 6: Verificar Estado del Sistema**
```bash
Checking system status...

Installation Status:
  ✅ User 'taxi' exists
  ❌ Docker not installed
  ❌ App directory not found
  ❌ Services not running

Suggestions:
  → Docker installation failed
  → Try running cleanup and reinstall
```
- Diagnostica qué componentes están instalados
- Muestra servicios en ejecución
- Da sugerencias de solución

---

### **Opción 7: Salir y Reparar Manualmente**
```bash
Exiting. You can check the log at: /tmp/taxi-install-20251220_143052.log

To retry later, run:
  sudo bash install-taxi-system.sh

To start fresh:
  sudo bash install-taxi-system.sh --cleanup
```
- Sale del script
- Muestra la ubicación del log para análisis
- Proporciona comandos para reintentar después

---

## 🔍 Información Contextual del Error

El menú muestra automáticamente:

| Campo | Descripción | Ejemplo |
|-------|-------------|---------|
| **Line Number** | Línea exacta donde falló | `3245` |
| **Exit Code** | Código de salida del error | `1` (error general), `127` (comando no encontrado) |
| **Phase** | Fase de instalación actual | `3/9` = Instalando Docker |
| **Context** | Descripción de la fase | "Docker installation" |
| **Log File** | Ubicación del archivo de log | `/tmp/taxi-install-20251220_143052.log` |

---

## 📝 Contextos de Fase

El sistema identifica automáticamente en qué fase ocurrió el error:

| Fase | Contexto | Descripción |
|------|----------|-------------|
| 0 | Initial setup | Configuración inicial |
| 1 | Preflight checks | Verificaciones previas |
| 2 | System updates | Actualizaciones del sistema |
| 3 | Docker installation | Instalación de Docker |
| 4 | Database setup | Configuración de bases de datos |
| 5 | Application setup | Configuración de la aplicación |
| 6 | Configuration | Archivos de configuración |
| 7 | Services startup | Inicio de servicios |

---

## 🚀 Flujo de Recuperación Recomendado

### Si es un error temporal (red, permisos):
1. **Opción 1** → Ver últimas líneas del log
2. Identificar el problema específico
3. **Opción 4** → Reintentar instalación

### Si es un error persistente:
1. **Opción 6** → Verificar estado del sistema
2. **Opción 2** → Ver log completo
3. **Opción 5** → Limpiar y reiniciar desde cero

### Si necesitas investigar:
1. **Opción 3** → Ver log por fase específica
2. Anotar el error exacto
3. **Opción 7** → Salir y reparar manualmente
4. Consultar documentación o soporte

---

## 💡 Ventajas del Sistema de Recuperación

✅ **Sin pérdida de progreso**: El log se guarda automáticamente  
✅ **Diagnóstico rápido**: Ver errores coloreados y organizados  
✅ **Opciones claras**: No necesitas recordar comandos  
✅ **Recuperación inteligente**: Limpieza automática si es necesario  
✅ **Contexto completo**: Sabes exactamente dónde y por qué falló  

---

## 🎨 Ejemplo de Log Coloreado

Cuando usas la **Opción 1** (últimas 30 líneas):

```
[2025-12-20 14:30:45] [STEP] Installing Docker...          (azul)
[2025-12-20 14:30:46] [OK] Repository configured           (verde)
[2025-12-20 14:30:47] [WARN] Old Docker version found      (amarillo)
[2025-12-20 14:30:48] [ERROR] Package not available        (rojo)
```

Esto hace que los errores sean **inmediatamente visibles** y fáciles de identificar.

---

## 📞 Comandos Rápidos desde Terminal

Además del menú interactivo, puedes usar estos comandos:

```bash
# Ver el último log de instalación
ls -lt /tmp/taxi-install-*.log | head -1 | awk '{print $9}' | xargs tail -30

# Limpiar completamente el sistema
sudo bash install-taxi-system.sh --cleanup

# Verificar estado
sudo bash install-taxi-system.sh --status

# Mostrar menú principal
sudo bash install-taxi-system.sh --menu
```

---

**¡El sistema ahora maneja errores de forma profesional y te guía en la recuperación! 🎉**
