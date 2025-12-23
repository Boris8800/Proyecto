#!/usr/bin/env node

/**
 * Enhanced Status Dashboard Server with Custom Email Server
 * Features:
 * - System monitoring
 * - Custom email server (self-hosted)
 * - API forms for maps, services, etc.
 * - Configuration management
 */

const express = require('express');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Load custom email server
const CustomEmailServer = require('./custom-email-server');
let emailServer;

const app = express();
const PORT = process.env.STATUS_PORT || 8080;
const VPS_IP = process.env.VPS_IP || '5.249.164.40';

// Configuration file path
const CONFIG_FILE = path.join(__dirname, '../..', 'config', 'email-config.json');

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Serve static files
const statusDir = path.join(__dirname);
app.use(express.static(statusDir));

// Initialize custom email server
function initializeEmailServer() {
    try {
        const config = {
            serverName: 'Swift Cab Mail Server',
            domain: process.env.MAIL_DOMAIN || 'swiftcab.local',
            fromEmail: process.env.FROM_EMAIL || 'noreply@swiftcab.local',
            fromName: 'Swift Cab',
            enableQueue: true,
            enableLogging: true
        };
        
        emailServer = new CustomEmailServer(config);
        console.log('[OK] Custom Email Server initialized');
        console.log('[INFO] Domain:', config.domain);
        console.log('[INFO] From Email:', config.fromEmail);
        return emailServer;
    } catch (err) {
        console.error('[ERROR] Failed to initialize email server:', err.message);
        return null;
    }
}

// Initialize default email config
function initializeEmailConfig() {
    const defaultConfig = {
        email: {
            provider: 'custom',
            custom: {
                serverName: 'Swift Cab Mail Server',
                domain: 'swiftcab.local',
                fromEmail: 'noreply@swiftcab.local',
                fromName: 'Swift Cab',
                port: 25,
                enableTLS: false,
                status: 'running'
            }
                    pass: 'your-app-password'
                },
                from: 'noreply@yourcompany.com',
                replyTo: 'support@yourcompany.com'
            },
            sendgrid: {
                apiKey: 'your-sendgrid-api-key',
                fromEmail: 'noreply@yourcompany.com',
                fromName: 'Swift Cab'
            },
            mailgun: {
                apiKey: 'your-mailgun-api-key',
                domain: 'mg.yourcompany.com',
                fromEmail: 'noreply@yourcompany.com'
            }
        },
        services: {
            maps: {
                provider: 'google',
                apiKey: 'your-google-maps-api-key',
                enabled: false
            },
            payment: {
                provider: 'stripe',
                apiKey: 'your-stripe-api-key',
                enabled: false
            }
        }
    };

    const configDir = path.dirname(CONFIG_FILE);
    if (!fs.existsSync(configDir)) {
        fs.mkdirSync(configDir, { recursive: true });
    }

    if (!fs.existsSync(CONFIG_FILE)) {
        fs.writeFileSync(CONFIG_FILE, JSON.stringify(defaultConfig, null, 2));
    }

    return defaultConfig;
}

// Load configuration
function loadConfig() {
    try {
        if (fs.existsSync(CONFIG_FILE)) {
            return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
        }
    } catch (err) {
        console.error('[ERR] Error loading config:', err.message);
    }
    return initializeEmailConfig();
}

// Save configuration
function saveConfig(config) {
    try {
        const configDir = path.dirname(CONFIG_FILE);
        if (!fs.existsSync(configDir)) {
            fs.mkdirSync(configDir, { recursive: true });
        }
        fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
        return true;
    } catch (err) {
        console.error('[ERR] Error saving config:', err.message);
        return false;
    }
}

// Routes

// Main status dashboard
app.get('/', (req, res) => {
    const htmlPath = path.join(statusDir, 'index.html');
    fs.readFile(htmlPath, 'utf8', (err, data) => {
        if (err) {
            return res.status(500).send('Error loading dashboard');
        }
        res.set('Content-Type', 'text/html');
        res.send(data);
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

// ============================================================
// EMAIL CONFIGURATION ENDPOINTS
// ============================================================

// API: Get email configuration
app.get('/api/email/config', (req, res) => {
    if (!emailServer) {
        return res.json({ provider: 'custom', status: 'initializing' });
    }
    
    const stats = emailServer.getStats();
    res.json({
        provider: 'custom',
        custom: stats.config,
        status: stats.status,
        totalSent: stats.totalSent,
        totalFailed: stats.totalFailed
    });
});

// API: Update email configuration
app.post('/api/email/config', (req, res) => {
    try {
        // For custom server, settings are limited
        const config = loadConfig();
        
        if (req.body.custom) {
            config.email.custom = { ...config.email.custom, ...req.body.custom };
            config.email.provider = 'custom';
        }
        
        if (saveConfig(config)) {
            res.json({ success: true, message: 'Custom email server configuration updated' });
        } else {
            res.status(500).json({ success: false, message: 'Failed to save configuration' });
        }
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
});

// API: Test email with custom server
app.post('/api/email/test', async (req, res) => {
    try {
        if (!emailServer) {
            return res.status(503).json({ 
                success: false, 
                message: 'Custom email server not initialized' 
            });
        }

        const { to, subject, html, templateName, templateData } = req.body;

        if (!to) {
            return res.status(400).json({ 
                success: false, 
                message: 'Missing required field: to' 
            });
        }

        let result;

        // Send using template if provided
        if (templateName && templateData) {
            result = await emailServer.sendTemplate(templateName, {
                ...templateData,
                to: to
            });
        } else {
            // Send custom email
            result = await emailServer.send({
                to: to,
                subject: subject || 'Test Email',
                html: html || '<p>This is a test email from Swift Cab.</p>'
            });
        }

        if (result.success) {
            res.json({ 
                success: true, 
                message: 'Email sent successfully',
                emailId: result.emailId
            });
        } else {
            res.status(500).json({ 
                success: false, 
                message: result.error || 'Failed to send email'
            });
        }
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
});
                }
            });
        }

        const getFromEmail = () => {
            if (config.email.provider === 'smtp') return config.email.smtp.from;
            if (config.email.provider === 'sendgrid') return config.email.sendgrid.fromEmail;
            if (config.email.provider === 'mailgun') return config.email.mailgun.fromEmail;
            return 'noreply@example.com';
        };

        const mailOptions = {
            from: getFromEmail(),
            to: to,
            subject: subject,
            html: `<p>${message}</p><p><br/><small>Test email sent from Swift Cab Status Dashboard</small></p>`
        };

        const info = await transporter.sendMail(mailOptions);
        res.json({
            success: true,
            message: 'Test email sent successfully',
            messageId: info.messageId
        });
    } catch (err) {
        console.error('[ERR] Email error:', err);
        res.status(500).json({
            success: false,
            message: `Failed to send email: ${err.message}`
        });
    }
});

// ============================================================
// SERVICES CONFIGURATION ENDPOINTS
// ============================================================

// API: Get services configuration
app.get('/api/services/config', (req, res) => {
    const config = loadConfig();
    res.json(config.services);
});

// API: Update services configuration
app.post('/api/services/config', (req, res) => {
    try {
        const config = loadConfig();
        
        if (req.body.maps) {
            config.services.maps = { ...config.services.maps, ...req.body.maps };
        }
        
        if (req.body.payment) {
            config.services.payment = { ...config.services.payment, ...req.body.payment };
        }
        
        if (saveConfig(config)) {
            res.json({ success: true, message: 'Services configuration updated' });
        } else {
            res.status(500).json({ success: false, message: 'Failed to save configuration' });
        }
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
});

// API: Test maps service
app.post('/api/maps/test', async (req, res) => {
    try {
        const config = loadConfig();
        const { origin, destination } = req.body;

        if (!origin || !destination) {
            return res.status(400).json({ success: false, message: 'Missing required fields: origin, destination' });
        }

        if (!config.services.maps.enabled) {
            return res.status(400).json({ success: false, message: 'Maps service is not enabled' });
        }

        // Simulate route calculation (would be real API call in production)
        res.json({
            success: true,
            data: {
                origin: origin,
                destination: destination,
                distance: '5.2 km',
                duration: '12 mins',
                status: 'OK'
            },
            message: 'Route calculated successfully'
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// Initialize email server and start dashboard
const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`[OK] Status Dashboard running on http://0.0.0.0:${PORT}`);
    console.log(`[INFO] VPS IP: ${VPS_IP}`);
    console.log(`[INFO] Configuration file: ${CONFIG_FILE}`);
    console.log(`[INFO] Email Server: Custom (Self-Hosted)`);
    
    // Initialize custom email server
    emailServer = initializeEmailServer();
    if (emailServer) {
        console.log(`[INFO] API Endpoints: /api/email/config, /api/email/test, /api/services/config, /api/maps/test`);
    }
process.on('SIGINT', () => {
    console.log('\n[INFO] Status Dashboard shutting down...');
    server.close();
});
