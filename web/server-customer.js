#!/usr/bin/env node

const express = require('express');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = process.env.CUSTOMER_PORT || 3003;
const BASE_DIR = __dirname;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(BASE_DIR, 'customer')));

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok',
    service: 'customer-app',
    timestamp: new Date().toISOString()
  });
});

// Serve index.html for all other routes (SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(BASE_DIR, 'customer', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`[OK] Customer App running on http://0.0.0.0:${PORT}`);
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
