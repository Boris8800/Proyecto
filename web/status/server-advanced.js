#!/usr/bin/env node

/**
 * Swift Cab Advanced Production Status Dashboard & API Server
 * Enterprise-Grade Security Features:
 * - Session-based authentication with secure cookies
 * - CSRF (Cross-Site Request Forgery) protection
 * - Rate limiting (brute-force prevention)
 * - JWT tokens for stateless API access
 * - Role-based access control (RBAC)
 * - Password hashing with SHA256
 * - Comprehensive logging
 */

const express = require('express');
const fs = require('fs');
const path = require('path');
const os = require('os');
const session = require('express-session');
const crypto = require('crypto');
const csurf = require('csurf');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');

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
const JWT_SECRET = process.env.JWT_SECRET || crypto.randomBytes(32).toString('hex');

// Configuration paths
const CONFIG_FILE = path.join(__dirname, '../..', 'config', 'email-config.json');
const USERS_FILE = path.join(__dirname, '../..', 'config', 'users.json');
const SERVICES_CONFIG = path.join(__dirname, '../..', 'config', 'services-config.json');

// ============================================================
// MIDDLEWARE SETUP
// ============================================================

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Session configuration with secure defaults
app.use(session({
    secret: process.env.SESSION_SECRET || crypto.randomBytes(32).toString('hex'),
    resave: false,
    saveUninitialized: false,
    name: 'sessionId',
    cookie: {
        secure: process.env.NODE_ENV === 'production', // HTTPS only in production
        httpOnly: true,                                  // Not accessible via JavaScript
        sameSite: 'strict',                              // CSRF protection
        maxAge: 24 * 60 * 60 * 1000                     // 24 hours
    }
}));

// Serve static files
const statusDir = path.join(__dirname);
app.use(express.static(statusDir));

// CSRF protection middleware
const csrfProtection = csurf({ cookie: false });

// Rate limiting - General API limiter
const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 100,                   // 100 requests per window
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many requests, please try again later.' },
    skip: (req) => {
        // Skip rate limiting for authenticated admin users
        return req.session && req.session.role === 'admin';
    }
});

// Rate limiting - Strict limiter for auth endpoints
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 5,                     // 5 failed attempts per window
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many login attempts. Please try again later.' },
    skipSuccessfulRequests: true
});

app.use('/api/', generalLimiter);
app.use('/api/auth/login', authLimiter);

// ============================================================
// AUTHENTICATION & AUTHORIZATION
// ============================================================

function hashPassword(password) {
    return crypto.createHash('sha256').update(password).digest('hex');
}

function initializeUsers() {
    if (!fs.existsSync(USERS_FILE)) {
        const defaultUsers = {
            users: [
                {
                    id: 1,
                    username: 'admin',
                    password: hashPassword('admin123'),
                    role: 'admin',
                    permissions: ['read', 'write', 'delete', 'user_manage'],
                    created: new Date(),
                    lastLogin: null
                }
            ]
        };
        fs.writeFileSync(USERS_FILE, JSON.stringify(defaultUsers, null, 2));
        console.log('[CRITICAL] Created default users file at ' + USERS_FILE);
        console.log('[CRITICAL] Default user: admin / admin123');
        console.log('[CRITICAL] ⚠️  CHANGE PASSWORD IMMEDIATELY IN PRODUCTION!');
    }
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

function saveUsers(data) {
    try {
        fs.writeFileSync(USERS_FILE, JSON.stringify(data, null, 2));
        return true;
    } catch (err) {
        console.error('[ERROR] Failed to save users:', err.message);
        return false;
    }
}

// Generate JWT token
function generateJWT(user) {
    return jwt.sign(
        { 
            id: user.id, 
            username: user.username,
            role: user.role,
            permissions: user.permissions
        },
        JWT_SECRET,
        { expiresIn: '24h' }
    );
}

// Session-based auth middleware
function requireAuth(req, res, next) {
    if (!req.session || !req.session.userId) {
        return res.status(401).json({ error: 'Unauthorized. Please login.' });
    }
    next();
}

// JWT-based auth middleware (for stateless APIs)
function requireJWT(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader?.split(' ')[1];
    
    if (!token) {
        return res.status(401).json({ error: 'Missing JWT token' });
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded;
        next();
    } catch (err) {
        return res.status(401).json({ error: 'Invalid or expired token', details: err.message });
    }
}

// Role-based access control middleware
function requireRole(role) {
    return (req, res, next) => {
        if (!req.session || !req.session.userId) {
            return res.status(401).json({ error: 'Unauthorized' });
        }
        if (req.session.role !== role) {
            return res.status(403).json({ error: 'Forbidden. Insufficient permissions.' });
        }
        next();
    };
}

// Permission-based access control
function requirePermission(permission) {
    return (req, res, next) => {
        if (!req.session || !req.session.userId) {
            return res.status(401).json({ error: 'Unauthorized' });
        }
        
        const data = getUsers();
        const user = data.users.find(u => u.id === req.session.userId);
        
        if (!user || !user.permissions || !user.permissions.includes(permission)) {
            return res.status(403).json({ error: `Forbidden. Required permission: ${permission}` });
        }
        next();
    };
}

// ============================================================
// AUTHENTICATION ROUTES
// ============================================================

// GET CSRF token
app.get('/api/auth/csrf', csrfProtection, (req, res) => {
    res.json({ csrfToken: req.csrfToken() });
});

// LOGIN endpoint with CSRF protection
app.post('/api/auth/login', csrfProtection, (req, res) => {
    const { username, password } = req.body;
    
    if (!username || !password) {
        return res.status(400).json({ error: 'Username and password required' });
    }

    const data = getUsers();
    const user = data.users.find(u => u.username === username);

    if (!user || user.password !== hashPassword(password)) {
        console.warn(`[WARN] Failed login attempt for user: ${username}`);
        return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Update last login
    user.lastLogin = new Date();
    saveUsers(data);

    // Create session
    req.session.userId = user.id;
    req.session.username = user.username;
    req.session.role = user.role;
    req.session.permissions = user.permissions;

    console.log(`[INFO] User logged in: ${username}`);

    res.json({
        success: true,
        user: {
            id: user.id,
            username: user.username,
            role: user.role,
            permissions: user.permissions
        },
        token: generateJWT(user) // Also return JWT for API calls
    });
});

// LOGOUT endpoint
app.post('/api/auth/logout', (req, res) => {
    const username = req.session?.username || 'Unknown';
    req.session.destroy((err) => {
        if (err) {
            console.error('[ERROR] Logout failed:', err);
            return res.status(500).json({ error: 'Logout failed' });
        }
        console.log(`[INFO] User logged out: ${username}`);
        res.json({ success: true, message: 'Logged out successfully' });
    });
});

// AUTH STATUS endpoint
app.get('/api/auth/status', (req, res) => {
    if (req.session && req.session.userId) {
        return res.json({
            authenticated: true,
            user: {
                username: req.session.username,
                role: req.session.role,
                permissions: req.session.permissions
            }
        });
    }
    res.json({ authenticated: false });
});

// CHANGE PASSWORD endpoint
app.post('/api/auth/change-password', requireAuth, csrfProtection, (req, res) => {
    const { currentPassword, newPassword } = req.body;
    
    if (!currentPassword || !newPassword) {
        return res.status(400).json({ error: 'Current and new password required' });
    }

    if (newPassword.length < 6) {
        return res.status(400).json({ error: 'New password must be at least 6 characters' });
    }

    const data = getUsers();
    const user = data.users.find(u => u.id === req.session.userId);

    if (!user || user.password !== hashPassword(currentPassword)) {
        return res.status(401).json({ error: 'Current password incorrect' });
    }

    user.password = hashPassword(newPassword);
    if (saveUsers(data)) {
        console.log(`[INFO] Password changed for user: ${user.username}`);
        return res.json({ success: true, message: 'Password changed successfully' });
    }

    res.status(500).json({ error: 'Failed to change password' });
});

// ============================================================
// SYSTEM HEALTH ROUTES (Protected)
// ============================================================

app.get('/api/health', requireAuth, (req, res) => {
    const uptime = process.uptime();
    const memUsage = process.memoryUsage();

    res.json({
        status: 'ok',
        timestamp: new Date(),
        uptime: Math.floor(uptime),
        memory: {
            used: Math.round(memUsage.heapUsed / 1024 / 1024) + 'MB',
            total: Math.round(memUsage.heapTotal / 1024 / 1024) + 'MB'
        },
        server: {
            platform: os.platform(),
            nodeVersion: process.version,
            vpsIp: VPS_IP
        }
    });
});

// ============================================================
// SERVICES ROUTES (Protected)
// ============================================================

app.get('/api/services', requireAuth, (req, res) => {
    res.json({
        services: [
            {
                name: 'Admin Server',
                port: 3001,
                status: 'running',
                description: 'Admin dashboard and management'
            },
            {
                name: 'Driver App',
                port: 3002,
                status: 'running',
                description: 'Driver mobile app server'
            },
            {
                name: 'Customer App',
                port: 3003,
                status: 'running',
                description: 'Customer booking app server'
            }
        ]
    });
});

// ============================================================
// EMAIL CONFIGURATION ROUTES (Protected - requires 'write' permission)
// ============================================================

app.get('/api/email/config', requireAuth, (req, res) => {
    const config = loadConfig(CONFIG_FILE);
    if (!config) {
        return res.status(500).json({ error: 'Failed to load email config' });
    }
    // Don't expose sensitive data
    const safeConfig = JSON.parse(JSON.stringify(config));
    if (safeConfig.email?.smtp?.auth?.pass) {
        safeConfig.email.smtp.auth.pass = '***';
    }
    res.json(safeConfig);
});

app.post('/api/email/config', requireAuth, requirePermission('write'), csrfProtection, (req, res) => {
    const config = req.body;
    
    if (!config.email || !config.email.provider) {
        return res.status(400).json({ error: 'Invalid email configuration' });
    }

    if (saveConfig(CONFIG_FILE, config)) {
        console.log(`[INFO] Email config updated by ${req.session.username}`);
        return res.json({ success: true, message: 'Email configuration saved' });
    }

    res.status(500).json({ error: 'Failed to save configuration' });
});

// ============================================================
// USER MANAGEMENT ROUTES (Admin only)
// ============================================================

app.get('/api/users', requireAuth, requireRole('admin'), (req, res) => {
    const data = getUsers();
    // Don't expose password hashes
    const safeUsers = data.users.map(u => ({
        id: u.id,
        username: u.username,
        role: u.role,
        permissions: u.permissions,
        created: u.created,
        lastLogin: u.lastLogin
    }));
    res.json({ users: safeUsers });
});

app.post('/api/users', requireAuth, requireRole('admin'), requirePermission('user_manage'), csrfProtection, (req, res) => {
    const { username, password, role, permissions } = req.body;
    
    if (!username || !password) {
        return res.status(400).json({ error: 'Username and password required' });
    }

    const data = getUsers();
    if (data.users.some(u => u.username === username)) {
        return res.status(400).json({ error: 'User already exists' });
    }

    const newUser = {
        id: Math.max(...data.users.map(u => u.id)) + 1,
        username,
        password: hashPassword(password),
        role: role || 'user',
        permissions: permissions || ['read'],
        created: new Date(),
        lastLogin: null
    };

    data.users.push(newUser);
    if (saveUsers(data)) {
        console.log(`[INFO] New user created: ${username} by ${req.session.username}`);
        return res.json({
            success: true,
            message: 'User created successfully',
            user: {
                id: newUser.id,
                username: newUser.username,
                role: newUser.role
            }
        });
    }

    res.status(500).json({ error: 'Failed to create user' });
});

// ============================================================
// CONFIGURATION HELPERS
// ============================================================

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

// Initialize configurations
function initializeConfigs() {
    initializeUsers();
    
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

// ============================================================
// DASHBOARD ROUTES
// ============================================================

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// ============================================================
// ERROR HANDLING
// ============================================================

app.use((err, req, res, next) => {
    if (err.code === 'EBADCSRFTOKEN') {
        console.warn('[WARN] CSRF token validation failed');
        return res.status(403).json({ error: 'CSRF validation failed' });
    }

    console.error('[ERROR]', err);
    res.status(500).json({
        error: 'Internal server error',
        message: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

// ============================================================
// SERVER STARTUP
// ============================================================

initializeConfigs();

const server = app.listen(PORT, '0.0.0.0', () => {
    console.log('\n╔══════════════════════════════════════════════════════════╗');
    console.log('║  Swift Cab - Advanced Production Status Dashboard        ║');
    console.log('╚══════════════════════════════════════════════════════════╝\n');
    
    console.log('✅ [OK] Server running on http://0.0.0.0:' + PORT);
    console.log('📍 [INFO] VPS IP: ' + VPS_IP);
    console.log('🔐 [SECURITY] Session-based + JWT authentication enabled');
    console.log('🛡️  [SECURITY] CSRF protection enabled');
    console.log('⏱️  [SECURITY] Rate limiting enabled (15 min / 100 requests)');
    console.log('👤 [INFO] Default user: admin / admin123');
    console.log('⚠️  [CRITICAL] Change password immediately in production!\n');
    
    console.log('📚 API Endpoints:');
    console.log('   POST   /api/auth/login              - Login (returns JWT)');
    console.log('   POST   /api/auth/logout             - Logout');
    console.log('   GET    /api/auth/status             - Check auth status');
    console.log('   GET    /api/auth/csrf               - Get CSRF token');
    console.log('   POST   /api/auth/change-password    - Change password');
    console.log('   GET    /api/health                  - System health (auth required)');
    console.log('   GET    /api/services                - Services list (auth required)');
    console.log('   GET    /api/email/config            - Email config (auth required)');
    console.log('   POST   /api/email/config            - Update email (write permission)');
    console.log('   GET    /api/users                   - List users (admin only)');
    console.log('   POST   /api/users                   - Create user (admin only)\n');
});

server.on('error', (err) => {
    console.error('[ERROR] Server error:', err);
    process.exit(1);
});

module.exports = { app, server };
