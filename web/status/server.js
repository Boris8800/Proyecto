#!/usr/bin/env node

/**
 * Status Dashboard Server
 * Serves the VPS status monitoring dashboard on port 8080
 */

const express = require('express');
const fs = require('fs');
const path = require('path');
const os = require('os');

const app = express();
const PORT = process.env.STATUS_PORT || 8080;
const VPS_IP = process.env.VPS_IP || '5.249.164.40';

// Middleware
app.use(express.json());

// Serve static files
const statusDir = path.join(__dirname, '..');
app.use(express.static(statusDir));

// Routes

// Main status dashboard
app.get('/', (req, res) => {
    fs.readFile(path.join(statusDir, 'status', 'index.html'), 'utf8', (err, data) => {
        if (err) {
            return res.status(500).send('Error loading dashboard');
        }
        // Replace VPS_IP placeholder
        const html = data.replace(/const VPS_IP = '5\.249\.164\.40'/g, `const VPS_IP = '${VPS_IP}'`);
        res.send(html);
    });
});

// API: Get system health
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        platform: os.platform(),
        arch: os.arch(),
        cpus: os.cpus().length,
        hostname: os.hostname()
    });
});

// API: Get container status
app.get('/api/containers', async (req, res) => {
    const { exec } = require('child_process');
    
    exec('docker ps --format "{{.Names}}|{{.Status}}"', (error, stdout) => {
        if (error) {
            return res.json({ containers: [] });
        }
        
        const containers = stdout.trim().split('\n').map(line => {
            const [name, status] = line.split('|');
            return {
                name,
                status,
                running: status.includes('Up')
            };
        });
        
        res.json({ containers });
    });
});

// API: Get service status
app.get('/api/services', async (req, res) => {
    const services = {
        api: { port: 3000, name: 'API Server' },
        admin: { port: 3001, name: 'Admin Dashboard' },
        driver: { port: 3002, name: 'Driver Portal' },
        customer: { port: 3003, name: 'Customer App' },
        postgres: { port: 5432, name: 'PostgreSQL' },
        mongo: { port: 27017, name: 'MongoDB' },
        redis: { port: 6379, name: 'Redis' }
    };
    
    res.json({ services, vps_ip: VPS_IP });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`[OK] Status Dashboard running on http://0.0.0.0:${PORT}`);
    console.log(`[OK] VPS IP: ${VPS_IP}`);
});
