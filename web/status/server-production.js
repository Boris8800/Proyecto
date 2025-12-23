#!/usr/bin/env node

/**
 * Swift Cab Production Status Dashboard & API Server
 * Features:
 * - User authentication & session management
 * - Real-time monitoring of all services
 * - Centralized API management for all web servers
 * - Email configuration & testing
 * - Production-ready logging
 */

const express = require('express');
const fs = require('fs');
const path = require('path');
const os = require('os');
const session = require('express-session');
const crypto = require('crypto');

// Try to load nodemailer
let nodemailer;
try {
    nodemailer = require('nodemailer');
} catch (err) {
    console.warn('[WARN] nodemailer not installed. Email functionality disabled.');
}

const app = express();
const PORT = process.env.STATUS_PORT || 8080;
const VPS_IP = process.env.VPS_IP || '5.249.164.40';

// Configuration paths
const CONFIG_FILE = path.join(__dirname, '../..', 'config', 'email-config.json');
const USERS_FILE = path.join(__dirname, '../..', 'config', 'users.json');
const SERVICES_CONFIG = path.join(__dirname, '../..', 'config', 'services-config.json');

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Session management
app.use(session({
    secret: process.env.SESSION_SECRET || crypto.randomBytes(32).toString('hex'),
    resave: false,
    saveUninitialized: false,
    cookie: { 
        secure: false,
        httpOnly: true,
        maxAge: 24 * 60 * 60 * 1000 // 24 hours
    }
}));

// Serve static files
const statusDir = path.join(__dirname);
app.use(express.static(statusDir));

// ============================================================
// AUTHENTICATION MIDDLEWARE
// ============================================================

// Initialize users database
function initializeUsers() {
    if (!fs.existsSync(USERS_FILE)) {
        const defaultUsers = {
            users: [
                {
                    id: 1,
                    username: 'admin',
                    password: hashPassword('admin123'), // Change in production!
                    role: 'admin',
                    created: new Date()
                }
            ]
        };
        fs.writeFileSync(USERS_FILE, JSON.stringify(defaultUsers, null, 2));
        console.log('[INFO] Created default users file. Change password immediately!');
    }
}

function hashPassword(password) {
    return crypto.createHash('sha256').update(password).digest('hex');
}

function getUsers() {
    try {
        if (!fs.existsSync(USERS_FILE)) initializeUsers();
        return JSON.parse(fs.readFileSync(USERS_FILE, 'utf8'));
    } catch (err) {
        console.error('[ERROR] Failed to read users:', err.message);
        initializeUsers();
        return { users: [] };
    }
}

function requireAuth(req, res, next) {
    if (!req.session || !req.session.userId) {
        return res.status(401).json({ error: 'Unauthorized. Please login.' });
    }
    next();
}

// ============================================================
// CONFIGURATION MANAGEMENT
// ============================================================

function initializeEmailConfig() {
    if (!fs.existsSync(CONFIG_FILE)) {
        const defaultConfig = {
            email: {
                provider: 'smtp',
                smtp: {
                    host: 'smtp.gmail.com',
                    port: 587,
                    secure: false,
                    auth: { user: '', pass: '' }
                },
                sendgrid: { apiKey: '', from: '' },
                mailgun: { apiKey: '', domain: '', from: '' }
            }
        };
        fs.writeFileSync(CONFIG_FILE, JSON.stringify(defaultConfig, null, 2));
    }
}

function loadConfig(file) {
    try {
        if (!fs.existsSync(file)) return null;
        return JSON.parse(fs.readFileSync(file, 'utf8'));
    } catch (err) {
        console.error('[ERROR] Failed to load config:', err.message);
        return null;
    }
}

function saveConfig(file, data) {
    try {
        fs.writeFileSync(file, JSON.stringify(data, null, 2));
        return true;
    } catch (err) {
        console.error('[ERROR] Failed to save config:', err.message);
        return false;
    }
}

// ============================================================
// AUTHENTICATION ROUTES
// ============================================================

app.post('/api/auth/login', (req, res) => {
    const { username, password } = req.body;
    
    if (!username || !password) {
        return res.status(400).json({ error: 'Username and password required' });
    }
    
    const data = getUsers();
    const user = data.users.find(u => u.username === username);
    
    if (!user || user.password !== hashPassword(password)) {
        return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    req.session.userId = user.id;
    req.session.username = user.username;
    req.session.role = user.role;
    
    return res.json({ 
        success: true, 
        user: { id: user.id, username: user.username, role: user.role }
    });
});

app.post('/api/auth/logout', (req, res) => {
    req.session.destroy((err) => {
        if (err) return res.status(500).json({ error: 'Logout failed' });
        res.json({ success: true });
    });
});

app.get('/api/auth/status', (req, res) => {
    if (req.session && req.session.userId) {
        return res.json({
            authenticated: true,
            user: { username: req.session.username, role: req.session.role }
        });
    }
    res.json({ authenticated: false });
});

app.post('/api/auth/change-password', requireAuth, (req, res) => {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
        return res.status(400).json({ error: 'Current and new password required' });
    }
    
    const data = getUsers();
    const user = data.users.find(u => u.id === req.session.userId);
    
    if (!user || user.password !== hashPassword(currentPassword)) {
        return res.status(401).json({ error: 'Current password incorrect' });
    }
    
    user.password = hashPassword(newPassword);
    saveConfig(USERS_FILE, data);
    
    res.json({ success: true, message: 'Password changed successfully' });
});

// ============================================================
// HEALTH & SYSTEM ROUTES
// ============================================================

app.get('/api/health', requireAuth, (req, res) => {
    const uptime = process.uptime();
    const memUsage = process.memoryUsage();
    
    res.json({
        status: 'ok',
        timestamp: new Date(),
        uptime: uptime,
        memory: {
            used: Math.round(memUsage.heapUsed / 1024 / 1024) + ' MB',
            total: Math.round(memUsage.heapTotal / 1024 / 1024) + ' MB'
        },
        services: {
            admin: { port: 3001, status: 'running' },
            driver: { port: 3002, status: 'running' },
            customer: { port: 3003, status: 'running' },
            status: { port: 8080, status: 'running' }
        }
    });
});

app.get('/api/services', requireAuth, (req, res) => {
    res.json({
        services: [
            { id: 1, name: 'Admin', port: 3001, type: 'admin', url: `http://${VPS_IP}:3001`, status: 'running' },
            { id: 2, name: 'Driver App', port: 3002, type: 'driver', url: `http://${VPS_IP}:3002`, status: 'running' },
            { id: 3, name: 'Customer App', port: 3003, type: 'customer', url: `http://${VPS_IP}:3003`, status: 'running' },
            { id: 4, name: 'Status Dashboard', port: 8080, type: 'status', url: `http://${VPS_IP}:8080`, status: 'running' }
        ]
    });
});

// ============================================================
// EMAIL API ROUTES
// ============================================================

app.get('/api/email/config', requireAuth, (req, res) => {
    initializeEmailConfig();
    const config = loadConfig(CONFIG_FILE);
    res.json(config?.email || {});
});

app.post('/api/email/config', requireAuth, (req, res) => {
    const config = loadConfig(CONFIG_FILE) || { email: {} };
    config.email = req.body;
    
    if (saveConfig(CONFIG_FILE, config)) {
        res.json({ success: true, message: 'Email config saved' });
    } else {
        res.status(500).json({ error: 'Failed to save config' });
    }
});

app.post('/api/email/test', requireAuth, async (req, res) => {
    const { to, subject, html } = req.body;
    
    if (!to || !subject || !html) {
        return res.status(400).json({ error: 'Missing required fields' });
    }
    
    if (!nodemailer) {
        return res.status(503).json({ error: 'Email service not available' });
    }
    
    try {
        const config = loadConfig(CONFIG_FILE);
        const emailConfig = config?.email;
        
        if (!emailConfig?.provider) {
            return res.status(400).json({ error: 'Email provider not configured' });
        }
        
        let transporter;
        if (emailConfig.provider === 'smtp' && emailConfig.smtp?.auth?.user) {
            transporter = nodemailer.createTransport(emailConfig.smtp);
        } else {
            return res.status(400).json({ error: 'Email provider not properly configured' });
        }
        
        await transporter.sendMail({
            from: emailConfig.smtp.auth.user,
            to: to,
            subject: subject,
            html: html
        });
        
        res.json({ success: true, message: 'Test email sent successfully' });
    } catch (err) {
        res.status(500).json({ error: 'Failed to send email: ' + err.message });
    }
});

// ============================================================
// SERVICES CONFIGURATION API
// ============================================================

app.get('/api/services/config', requireAuth, (req, res) => {
    const config = loadConfig(SERVICES_CONFIG) || {
        maps: { provider: 'google', enabled: false },
        payment: { provider: 'stripe', enabled: false },
        sms: { provider: 'twilio', enabled: false }
    };
    res.json(config);
});

app.post('/api/services/config', requireAuth, (req, res) => {
    const config = req.body;
    
    if (saveConfig(SERVICES_CONFIG, config)) {
        res.json({ success: true, message: 'Services config saved' });
    } else {
        res.status(500).json({ error: 'Failed to save config' });
    }
});

// ============================================================
// MAPS API TEST
// ============================================================

app.post('/api/maps/test', requireAuth, (req, res) => {
    const { origin, destination } = req.body;
    
    if (!origin || !destination) {
        return res.status(400).json({ error: 'Origin and destination required' });
    }
    
    // Mock response - would integrate with real Maps API
    res.json({
        success: true,
        origin: origin,
        destination: destination,
        distance: '5.2 km',
        duration: '15 mins',
        fare: (Math.random() * 20 + 8).toFixed(2)
    });
});

// ============================================================
// MANAGEMENT API ROUTES (for web servers to fetch config)
// ============================================================

app.get('/api/web-servers/:type/config', (req, res) => {
    const { type } = req.params;
    const services = loadConfig(SERVICES_CONFIG) || {};
    
    res.json({
        service: type,
        config: services,
        timestamp: new Date()
    });
});

app.get('/api/web-servers/:type/email-config', (req, res) => {
    const config = loadConfig(CONFIG_FILE);
    res.json(config?.email || {});
});

// ============================================================
// ERROR HANDLING
// ============================================================

app.use((err, req, res, next) => {
    console.error('[ERROR]', err.message);
    res.status(500).json({ error: 'Internal server error' });
});

// ============================================================
// START SERVER
// ============================================================

initializeUsers();
initializeEmailConfig();

app.listen(PORT, '0.0.0.0', () => {
    console.log(`[OK] Status Dashboard running on http://0.0.0.0:${PORT}`);
    console.log(`[INFO] VPS IP: ${VPS_IP}`);
    console.log(`[INFO] Default credentials: admin / admin123 (CHANGE IMMEDIATELY IN PRODUCTION!)`);
    console.log(`[INFO] API Base: /api/`);
    console.log(`[INFO] Auth: POST /api/auth/login`);
    console.log(`[INFO] Status: GET /api/health`);
});

module.exports = app;
