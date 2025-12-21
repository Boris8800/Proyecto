# Port Conflict Troubleshooting Guide

## Quick Diagnosis

Run the diagnostic tool to identify port conflicts:

```bash
sudo bash debug-ports.sh
```

This will show:
- ✓ Which ports are available
- ⚠️ Which ports are in use
- 🔍 What processes are using each port
- 🐳 Docker status and running containers

## Common Port Issues

### Port 80 (HTTP/Nginx) Already in Use

**Symptoms:**
- Error: "Port 80 (nginx (HTTP)) is already in use"
- Installation fails at port check

**Causes:**
- Apache, Nginx, or another web server is running
- Docker container with port binding still exists
- Leftover process from previous installation

**Solutions:**

1. **Quick Fix** - Stop all web servers:
   ```bash
   sudo pkill -9 nginx
   sudo pkill -9 apache2
   sudo pkill -9 httpd
   ```

2. **Docker Fix** - Stop Docker and clean:
   ```bash
   sudo systemctl stop docker
   sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true
   sudo docker system prune -af
   ```

3. **Force Release Port 80**:
   ```bash
   sudo fuser -k 80/tcp 2>/dev/null || true
   ```

4. **Full Cleanup**:
   ```bash
   # Kill all blocking processes
   sudo pkill -9 -f "nginx|apache|httpd|http-server"
   
   # Stop Docker
   sudo systemctl stop docker 2>/dev/null || true
   sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true
   
   # Clean Docker
   sudo docker system prune -af --volumes
   
   # Wait for ports to release
   sleep 3
   
   # Verify port is free
   sudo ss -tulpn | grep ":80\s"
   ```

### Port 443 (HTTPS/SSL) Already in Use

Same solutions as port 80, but target 443:
```bash
sudo fuser -k 443/tcp
```

### Port 5432 (PostgreSQL) Already in Use

```bash
sudo pkill -9 postgres
sudo fuser -k 5432/tcp
```

### Port 27017 (MongoDB) Already in Use

```bash
sudo pkill -9 mongod
sudo fuser -k 27017/tcp
```

### Port 6379 (Redis) Already in Use

```bash
sudo pkill -9 redis
sudo fuser -k 6379/tcp
```

### Ports 3000-3003 (Dashboard APIs) Already in Use

```bash
# Kill any Node.js processes
sudo pkill -9 node

# Or specific ports
sudo fuser -k 3000/tcp
sudo fuser -k 3001/tcp
sudo fuser -k 3002/tcp
sudo fuser -k 3003/tcp
```

## Automated Resolution

The installation script has built-in automatic port resolution that:

1. **Pre-cleanup** - Kills web servers and Docker processes before checking
2. **Auto-fix attempts** - Retries up to 3 times with 4-second delays
3. **Aggressive cleanup** - Uses multiple methods to release ports
4. **Fallback guidance** - Provides manual commands if auto-fix fails

If the automatic fix still fails, you'll see:
```
[ERROR] Port conflicts could not be resolved

Please manually resolve conflicts:
  • Stop conflicting services: sudo pkill -9 nginx
  • Stop Docker: sudo docker stop $(sudo docker ps -aq)
  • Clean Docker: sudo docker system prune -af
  • Check ports: sudo ss -tulpn | grep -E ':(80|443|3000|3001|3002|3003|5432|27017|6379)'
```

## Diagnostic Commands

### Check All Required Ports

```bash
sudo ss -tulpn | grep -E ':(80|443|3000|3001|3002|3003|5432|27017|6379)'
```

### Check Specific Port

```bash
# Show everything listening on port 80
sudo ss -tulpn | grep ":80"

# Or with lsof
sudo lsof -i :80

# Or with netstat
sudo netstat -tulpn | grep ":80"
```

### Find Process Using Port

```bash
# Method 1: lsof
sudo lsof -i :<PORT>

# Method 2: ss
sudo ss -tulpn | grep ":<PORT>"

# Method 3: netstat
sudo netstat -tulpn | grep ":<PORT>"

# Method 4: fuser
sudo fuser <PORT>/tcp
```

### List All Listening Ports

```bash
sudo ss -tulpn
```

### Check Docker Status

```bash
# Show running containers
sudo docker ps

# Show all containers (including stopped)
sudo docker ps -a

# Show containers with port bindings
sudo docker ps --format "table {{.Names}}\t{{.Ports}}"
```

## Prevention Tips

1. **Always clean before installation:**
   ```bash
   sudo systemctl stop docker 2>/dev/null || true
   sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true
   sudo docker system prune -af
   ```

2. **Check ports before installation:**
   ```bash
   bash debug-ports.sh
   ```

3. **Use the automatic installer:**
   ```bash
   bash install-taxi-system.sh --fresh
   ```
   It includes automatic port management.

4. **Monitor port usage:**
   ```bash
   watch -n 2 'sudo ss -tulpn | grep -E ":(80|443|3000|3001|3002|3003|5432|27017|6379)"'
   ```

## Port Reference

| Port  | Service                | Process         | Kill Command                    |
|-------|------------------------|-----------------|--------------------------------|
| 80    | Nginx HTTP             | nginx           | `sudo pkill -9 nginx`           |
| 443   | Nginx HTTPS/SSL        | nginx           | `sudo pkill -9 nginx`           |
| 5432  | PostgreSQL Database    | postgres        | `sudo pkill -9 postgres`        |
| 27017 | MongoDB Database       | mongod          | `sudo pkill -9 mongod`          |
| 6379  | Redis Cache            | redis-server    | `sudo pkill -9 redis`           |
| 3000  | API Gateway            | node            | `sudo fuser -k 3000/tcp`        |
| 3001  | Admin Dashboard        | node            | `sudo fuser -k 3001/tcp`        |
| 3002  | Driver Dashboard       | node            | `sudo fuser -k 3002/tcp`        |
| 3003  | Customer Dashboard     | node            | `sudo fuser -k 3003/tcp`        |

## Need More Help?

If issues persist:

1. **Run the debug tool:**
   ```bash
   sudo bash debug-ports.sh
   ```

2. **Check system logs:**
   ```bash
   sudo journalctl -xe | tail -50
   sudo dmesg | tail -50
   ```

3. **Monitor in real-time:**
   ```bash
   watch -n 1 'sudo ss -tulpn'
   ```

4. **Full system restart** (last resort):
   ```bash
   sudo reboot
   ```

5. **Check available disk space:**
   ```bash
   df -h
   free -h
   ```
