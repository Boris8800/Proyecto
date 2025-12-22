#!/usr/bin/env node

const express = require('express');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = process.env.ADMIN_PORT || 3001;
const BASE_DIR = __dirname;

// Security Headers Middleware
app.use((req, res, next) => {
  // X-Content-Type-Options: Prevent MIME type sniffing
  res.setHeader('X-Content-Type-Options', 'nosniff');
  
  // X-Frame-Options: Prevent clickjacking
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  
  // X-XSS-Protection: Enable XSS filter
  res.setHeader('X-XSS-Protection', '1; mode=block');
  
  // Content-Security-Policy
  res.setHeader('Content-Security-Policy',
    "default-src 'self'; " +
    "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; " +
    "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; " +
    "img-src 'self' data: https:; " +
    "font-src 'self' https:; " +
    "connect-src 'self'; " +
    "frame-ancestors 'self'"
  );
  
  // Strict-Transport-Security (production only)
  if (process.env.NODE_ENV === 'production') {
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  }
  
  // Referrer-Policy
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  // Permissions-Policy
  res.setHeader('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
  
  next();
});

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:3001',
  credentials: true
}));
app.use(express.json());
app.use(express.static(path.join(BASE_DIR, 'admin')));

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok',
    service: 'admin-dashboard',
    timestamp: new Date().toISOString()
  });
});

// Serve index.html for all other routes (SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(BASE_DIR, 'admin', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`[OK] Admin Dashboard running on http://0.0.0.0:${PORT}`);
  console.log(`[INFO] Access at: http://5.249.164.40:${PORT}`);
});

// Error handling
process.on('uncaughtException', (err) => {
  console.error('[ERROR] Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('[ERROR] Unhandled Rejection at:', promise, 'reason:', reason);
});
