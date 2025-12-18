# 🚕 Taxi System Installer

![GitHub](https://img.shields.io/github/license/Boris8800/Proyecto)
![GitHub stars](https://img.shields.io/github/stars/Boris8800/Proyecto)
![GitHub issues](https://img.shields.io/github/issues/Boris8800/Proyecto)
![GitHub code size](https://img.shields.io/github/languages/code-size/Boris8800/Proyecto)
![GitHub last commit](https://img.shields.io/github/last-commit/Boris8800/Proyecto)
![GitHub contributors](https://img.shields.io/github/contributors/Boris8800/Proyecto)

> Sistema completo de gestión de taxis con instalación automática en un solo comando

## ✨ Características

- ✅ **Instalación en 1 comando** - Todo automático
- ✅ **20+ servicios Docker** - Arquitectura de microservicios
- ✅ **Paneles múltiples** - Admin, Driver, Customer
- ✅ **Base de datos completa** - PostgreSQL + Redis + MongoDB
- ✅ **SSL automático** - Let's Encrypt integrado
- ✅ **Monitorización** - Grafana, Prometheus, Netdata
- ✅ **Backup automático** - Con encriptación
- ✅ **Seguridad empresarial** - Hardening completo

## 🚀 Instalación Rápida

```bash
git clone https://github.com/Boris8800/Proyecto.git
cd Proyecto
sudo ./src/taxi_installer.sh
```

## 📋 Requisitos

- Ubuntu 20.04/22.04 LTS
- 4GB RAM mínimo (8GB recomendado)
- 50GB disco libre
- Acceso root/sudo

## 🛠️ Uso

```bash
./src/taxi_installer.sh --help
```

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────┐
│                   Nginx (SSL)                   │
├───────────┬───────────┬───────────┬────────────┤
│  Admin    │  Driver   │ Customer  │   API      │
│  Panel    │  Panel    │  Panel    │  Gateway   │
├───────────┴───────────┴───────────┴────────────┤
│              Microservicios (Node.js)          │
├───────────┬───────────┬───────────┬────────────┤
│  Auth     │ Booking   │ Payment   │ Tracking   │
├───────────┴───────────┴───────────┴────────────┤
│         PostgreSQL ─ Redis ─ MongoDB           │
└─────────────────────────────────────────────────┘
```

## 📁 Estructura del Proyecto

```
src/
├── taxi_installer.sh          # Instalador principal
├── modules/                   # Módulos separados
│   ├── security.sh           # Configuración de seguridad
│   ├── docker.sh            # Configuración Docker
│   └── database.sh          # Configuración BD
└── functions/               # Funciones helper
configs/                     # Archivos de configuración
scripts/                     # Scripts de mantenimiento
tests/                       # Pruebas automáticas
docs/                        # Documentación
```

## 🔧 Opciones de línea de comandos

| Opción | Descripción |
|--------|-------------|
| `--auto` | Instalación automática sin preguntas |
| `--dev` | Modo desarrollo con menos recursos |
| `--security-only` | Solo configuración de seguridad |
| `--domain=DOMAIN` | Especificar dominio personalizado |
| `--email=EMAIL` | Email para SSL |
| `--dry-run` | Simular sin hacer cambios |
| `--help` | Mostrar ayuda |

## 🧪 Testing

```bash
# Ejecutar pruebas
./tests/test_installer.sh

# Validar sintaxis
bash -n src/taxi_installer.sh

# Análisis estático
shellcheck src/taxi_installer.sh
```

## 🤝 Contribuir

1. Fork el proyecto
2. Crear rama de feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

## 📄 Licencia

Distribuido bajo licencia MIT. Ver `LICENSE` para más información.

## 👨‍💻 Autor

**Boris8800**
- GitHub: [@Boris8800](https://github.com/Boris8800)

---

⭐ **Dale una estrella si te gusta este proyecto!**