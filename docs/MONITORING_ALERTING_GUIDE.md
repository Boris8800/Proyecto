# Comprehensive Monitoring & Alerting System Guide

## Overview

The Swift Cab monitoring and alerting system provides real-time visibility into system health, service availability, and performance metrics. It includes automated alerting, dashboard visualization, and comprehensive logging.

## Components

### 1. Monitoring Script (`scripts/monitoring.sh`)
Real-time monitoring with configurable thresholds and instant alerts.

**Features:**
- Web service health checks (3001, 3002, 3003)
- Backend service monitoring (API, Status Dashboard)
- Database connectivity checks (PostgreSQL, MongoDB, Redis)
- System resource monitoring (CPU, Memory, Disk)
- SSL certificate expiration tracking
- Nginx reverse proxy status
- Error rate analysis
- Response time measurement

**Usage:**
```bash
# Start monitoring dashboard (real-time)
bash /root/Proyecto/scripts/monitoring.sh start

# Check current status
bash /root/Proyecto/scripts/monitoring.sh status

# View monitoring logs
bash /root/Proyecto/scripts/monitoring.sh logs

# View recent alerts
bash /root/Proyecto/scripts/monitoring.sh alerts

# Quick health check
bash /root/Proyecto/scripts/monitoring.sh health

# Show configuration
bash /root/Proyecto/scripts/monitoring.sh config
```

### 2. Configuration File (`config/monitoring.conf`)
Centralized configuration for thresholds, services, and alerting channels.

**Key Settings:**
- CPU threshold: 80% warning, 95% critical
- Memory threshold: 85% warning, 95% critical
- Disk threshold: 85% warning, 95% critical
- Response time: 500ms warning, 1000ms critical
- Error rate: 3% warning, 5% critical

### 3. PM2 Configuration (`ecosystem.config.json`)
Process management with automatic restarts and resource limits.

**Features:**
- Cluster mode (utilizes all CPU cores)
- Automatic restart on crash
- Memory limit: 500MB per process
- Max 10 restart attempts
- Detailed logging to `/root/Proyecto/logs/`

**Commands:**
```bash
# Install PM2 globally
npm install -g pm2

# Start all services with PM2
pm2 start ecosystem.config.json

# Monitor processes
pm2 monit

# View logs
pm2 logs

# Restart all services
pm2 restart all

# Save PM2 configuration
pm2 save

# Set up auto-start on system boot
pm2 startup
```

## Monitoring Metrics

### Service Availability
- **Metric**: HTTP response on health check endpoints
- **Threshold**: Must return 200 status within 1 second
- **Alert Level**: CRITICAL if down for >2 minutes
- **Ports Monitored**: 3001 (Admin), 3002 (Driver), 3003 (Customer)

### Response Time
- **Metric**: Time to receive response from health endpoint
- **Warning**: > 500ms
- **Critical**: > 1000ms
- **Measurement**: HTTP HEAD request round-trip time

### CPU Usage
- **Metric**: System-wide CPU utilization percentage
- **Warning**: > 80%
- **Critical**: > 95%
- **Measurement**: `top` command output

### Memory Usage
- **Metric**: System RAM utilization percentage
- **Warning**: > 85%
- **Critical**: > 95%
- **Measurement**: `free` command output
- **Per-Process Limit**: 500MB (enforced by PM2)

### Disk Usage
- **Metric**: Disk space used on `/root/Proyecto`
- **Warning**: > 85%
- **Critical**: > 95%
- **Measurement**: `df` command output

### Error Rates
- **Metric**: Percentage of requests with 4xx/5xx status codes
- **Window**: Last 24 hours
- **Warning**: > 3%
- **Critical**: > 5%
- **Source**: Access logs analysis

### Database Connectivity
- **Services Checked**:
  - PostgreSQL (port 5432)
  - MongoDB (port 27017)
  - Redis (port 6379)
- **Alert**: CRITICAL if unreachable

### SSL Certificate Expiration
- **Paths Monitored**:
  - `/etc/letsencrypt/live/yourdomain.com/fullchain.pem`
  - Main domain and subdomains
- **Warning**: 14 days before expiration
- **Critical**: 7 days before expiration
- **Command**: `openssl x509 -enddate`

## Alert Severity Levels

### CRITICAL (Immediate Action Required)
- Service down or unreachable
- Response time > 1000ms
- Memory usage > 95%
- Disk usage > 95%
- CPU usage > 95%
- Database connectivity lost
- SSL certificate expiring in < 7 days

### WARNING (Attention Needed)
- Response time > 500ms
- CPU usage > 80%
- Memory usage > 85%
- Disk usage > 85%
- Error rate > 3%
- SSL certificate expiring in 7-14 days

### INFO (For Reference)
- Service restart
- Configuration change
- Routine health checks passed
- Backup completed

## Alert Delivery Channels

### Configured Channels
1. **Console Output**: Real-time dashboard display
2. **File Logging**: `/root/Proyecto/logs/alerts.log`
3. **Monitoring Log**: `/root/Proyecto/logs/monitoring.log`

### Optional Integrations (Disabled by Default)
```bash
# Enable in config/monitoring.conf

# Email Alerts
ENABLE_EMAIL_ALERTS=true
ALERT_EMAIL="admin@yourdomain.com"

# Slack Alerts
ENABLE_SLACK_ALERTS=true
SLACK_WEBHOOK_URL="https://hooks.slack.com/..."

# PagerDuty Integration
ENABLE_PAGERDUTY_ALERTS=true
PAGERDUTY_API_KEY="your-key"

# SMS Alerts (Twilio)
ENABLE_SMS_ALERTS=true
TWILIO_ACCOUNT_SID="your-sid"
```

## Dashboard Features

### Real-Time Display
```
╔════════════════════════════════════════════════════════════════╗
║          Swift Cab Monitoring Dashboard                        ║
║          Last Updated: 2025-12-22 15:30:45                    ║
╚════════════════════════════════════════════════════════════════╝

┌─ Web Services 
│ ✓ admin-dashboard (Port 3001): ONLINE - Response: 145ms
│ ✓ driver-portal (Port 3002): ONLINE - Response: 128ms
│ ✓ customer-app (Port 3003): ONLINE - Response: 156ms

┌─ Backend Services 
│ ✓ API Server (3000): ONLINE
│ ✓ Status Dashboard (8080): ONLINE

┌─ Databases 
│ postgresql: online
│ mongodb: online
│ redis: online

┌─ System Resources 
│ CPU Usage: 35%
│ Memory Usage: 62%
│ Disk Usage: 42%

┌─ SSL Certificates 
│ Certificate Expiration: 89 days remaining

┌─ Nginx Reverse Proxy 
│ Status: RUNNING

┌─ Error Rates (Last 24h) 
│ admin: 0.5%
│ driver: 0.3%
│ customer: 0.2%

┌─ Recent Alerts 
│ No recent alerts
```

### Auto-Refresh
- Updates every 30 seconds
- Configurable via `DASHBOARD_REFRESH_INTERVAL`
- Responsive to terminal resize

## Log Files

### Monitoring Logs
**Location**: `/root/Proyecto/logs/monitoring.log`
**Format**: `[YYYY-MM-DD HH:MM:SS] [LEVEL] [SERVICE] Message`
**Retention**: 30 days
**Size Limit**: 100MB (with rotation)

**Example**:
```
[2025-12-22 15:30:45] [INFO] [] Monitoring system started
[2025-12-22 15:30:47] [INFO] [] Health check completed
[2025-12-22 15:31:15] [WARNING] [admin-dashboard] Slow response time: 850ms
```

### Alert Logs
**Location**: `/root/Proyecto/logs/alerts.log`
**Format**: `[YYYY-MM-DD HH:MM:SS] [SEVERITY] [SERVICE] Message`
**Critical for**: Compliance, incident investigation, trend analysis

**Example**:
```
[2025-12-22 15:31:15] [WARNING] [admin-dashboard] Slow response time: 850ms
[2025-12-22 15:32:00] [CRITICAL] [customer-app] Service is offline (Port 3003)
[2025-12-22 15:32:05] [INFO] [customer-app] Service restored - recovered automatically
```

### Error Logs
**Locations**:
- `/root/Proyecto/logs/admin-error.log` - Admin Dashboard errors
- `/root/Proyecto/logs/driver-error.log` - Driver Portal errors
- `/root/Proyecto/logs/customer-error.log` - Customer App errors
- `/root/Proyecto/logs/nginx-error.log` - Nginx reverse proxy errors

## Automated Actions

### Service Restart
When a service becomes unresponsive:
1. Monitoring detects offline service
2. CRITICAL alert generated
3. PM2 automatically restarts service (if configured)
4. Service recovery logged
5. Alert escalation after 3 consecutive failures

### Resource Management
When resource limits approached:
1. Memory limit: 500MB per process (enforced by PM2)
2. Process automatically restarted if exceeds limit
3. WARNING alert generated before restart
4. Restart logged with memory consumption

### SSL Certificate Renewal
Automated renewal via Let's Encrypt:
1. Check runs daily
2. 14 days before expiration: WARNING alert
3. 7 days before expiration: CRITICAL alert
4. Automatic renewal attempted at 7 days
5. Nginx reloaded with new certificate

## Setup Instructions

### 1. Install PM2
```bash
sudo npm install -g pm2

# Set up auto-start on boot
pm2 startup systemd -u root --hp /root
pm2 save
```

### 2. Start Monitoring
```bash
cd /root/Proyecto

# Start all services with PM2
pm2 start ecosystem.config.json

# Start monitoring dashboard in a screen/tmux session
screen -S monitoring
bash scripts/monitoring.sh start

# Or in background
nohup bash scripts/monitoring.sh start > logs/monitoring-daemon.log 2>&1 &
```

### 3. Configure Alerts
```bash
# Edit monitoring configuration
nano config/monitoring.conf

# Adjust thresholds as needed
# Enable desired alert channels (email, Slack, PagerDuty)
```

### 4. Set Up Cron Jobs
```bash
# Daily certificate check at 2 AM
0 2 * * * bash /root/Proyecto/scripts/renew-ssl.sh

# Hourly health check
0 * * * * bash /root/Proyecto/scripts/monitoring.sh health

# Log rotation (if using logrotate)
/root/Proyecto/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
}
```

## Performance Tips

### Optimize Monitoring
1. **Reduce Check Frequency**: Increase `HEALTH_CHECK_INTERVAL` for less critical services
2. **Batch Operations**: Group multiple checks together
3. **Cache Results**: Store recent health check results
4. **Parallel Checking**: Run checks concurrently

### System Resources
1. **PM2 Memory**: Monitor with `pm2 monit`
2. **Log Rotation**: Implement automatic log rotation
3. **Database Cleanup**: Archive old metrics regularly

### Scaling
For multi-server deployments:
1. Use centralized logging (ELK stack)
2. Implement distributed monitoring (Prometheus)
3. Use managed services (Datadog, New Relic)
4. Set up high-availability dashboard

## Troubleshooting

### High CPU Usage
```bash
# Check which process is consuming CPU
top -p $(pgrep -f "node.*server")

# Check for infinite loops in code
pm2 logs
```

### Memory Leaks
```bash
# Monitor memory over time
watch -n 5 'ps aux | grep node | grep -v grep'

# Get heap dump (Node.js)
kill -USR2 $(pgrep -f "node.*server")
```

### Service Constantly Restarting
```bash
# Check PM2 logs
pm2 logs

# Check server logs
tail -100 /root/Proyecto/logs/*-error.log

# Increase min_uptime in ecosystem.config.json
```

### Nginx Issues
```bash
# Test configuration
sudo nginx -t

# Check logs
sudo tail -50 /var/log/nginx/error.log

# Restart Nginx
sudo systemctl restart nginx
```

## Best Practices

1. **Regular Reviews**: Check alert logs weekly
2. **Threshold Tuning**: Adjust thresholds based on actual patterns
3. **Documentation**: Document any custom thresholds
4. **Escalation**: Set up proper alert escalation procedures
5. **Testing**: Regularly test alert delivery mechanisms
6. **Backup Monitoring**: Monitor database backups separately
7. **Capacity Planning**: Track metrics over time for growth trends
8. **On-Call Rotation**: Set up proper on-call procedures for CRITICAL alerts

## Maintenance Calendar

- **Daily**: Check alert logs for patterns
- **Weekly**: Review monitoring dashboard, adjust thresholds
- **Monthly**: Verify all alert channels working, test failover
- **Quarterly**: Capacity planning review, trend analysis
- **Annually**: Complete monitoring system audit, documentation update

## Support & Escalation

### Escalation Path
1. **Level 1**: Automated restart (handled by PM2)
2. **Level 2**: Alert notification to on-call engineer
3. **Level 3**: Escalation to senior engineer if unresolved in 30 minutes
4. **Level 4**: Escalation to manager/director if unresolved in 1 hour

### Contact Information
- **On-Call Email**: oncall@yourdomain.com
- **Slack Channel**: #alerts
- **Emergency Phone**: +1-XXX-XXX-XXXX

---

**Last Updated**: 2025-12-22
**Status**: ✅ Production Ready
**Next Review**: 2026-01-22
