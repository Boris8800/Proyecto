#!/usr/bin/env node

/**
 * Magic Links Authentication Server
 * Passwordless authentication using time-limited tokens (1-5 days)
 * Endpoints: POST /api/magic-links/generate, GET /api/magic-links/validate
 */

const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const crypto = require('crypto');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const cookieParser = require('cookie-parser');

const app = express();
const PORT = process.env.MAGIC_LINKS_PORT || 3333;
const DB_PATH = process.env.MAGIC_LINKS_DB || '/root/magic_links.db';
const TOKEN_LENGTH = 32;
const DEFAULT_EXPIRY_DAYS = 3; // 1-5 configurable

// Middleware
app.use(express.json());
app.use(cors());
app.use(cookieParser());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 requests per window
  message: 'Too many attempts, please try again later'
});

// Database initialization
const db = new sqlite3.Database(DB_PATH, (err) => {
  if (err) {
    console.error('[ERROR] Failed to connect to database:', err);
    process.exit(1);
  }
  console.log('[OK] Connected to Magic Links database');
  initializeDatabase();
});

// Database initialization
function initializeDatabase() {
  db.serialize(() => {
    db.run(`
      CREATE TABLE IF NOT EXISTS magic_links (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        token TEXT UNIQUE NOT NULL,
        role TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        expires_at DATETIME NOT NULL,
        used_at DATETIME,
        used BOOLEAN DEFAULT 0,
        ip_address TEXT,
        user_agent TEXT
      )
    `, (err) => {
      if (err) console.error('[ERROR] Failed to create magic_links table:', err);
      else console.log('[OK] magic_links table initialized');
    });

    db.run(`
      CREATE INDEX IF NOT EXISTS idx_token ON magic_links(token)
    `);

    db.run(`
      CREATE INDEX IF NOT EXISTS idx_email ON magic_links(email)
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS magic_links_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        session_token TEXT UNIQUE NOT NULL,
        role TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        expires_at DATETIME NOT NULL,
        last_activity DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `, (err) => {
      if (err) console.error('[ERROR] Failed to create sessions table:', err);
      else console.log('[OK] magic_links_sessions table initialized');
    });

    db.run(`
      CREATE INDEX IF NOT EXISTS idx_session_token ON magic_links_sessions(session_token)
    `);
  });
}

/**
 * POST /api/magic-links/generate
 * Generate a magic link for authentication
 */
app.post('/api/magic-links/generate', limiter, (req, res) => {
  const { email, role = 'user', days = DEFAULT_EXPIRY_DAYS } = req.body;

  // Validate input
  if (!email || !isValidEmail(email)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid email format'
    });
  }

  if (!['admin', 'driver', 'customer'].includes(role)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid role'
    });
  }

  if (![1, 2, 3, 4, 5].includes(parseInt(days))) {
    return res.status(400).json({
      success: false,
      error: 'Invalid expiry days (must be 1-5)'
    });
  }

  // Generate secure token
  const token = crypto.randomBytes(TOKEN_LENGTH / 2).toString('hex');
  const expiresAt = new Date(Date.now() + parseInt(days) * 24 * 60 * 60 * 1000);
  const ipAddress = req.ip || req.connection.remoteAddress;
  const userAgent = req.get('user-agent');

  // Save to database
  db.run(
    `INSERT OR REPLACE INTO magic_links 
     (email, token, role, expires_at, ip_address, user_agent) 
     VALUES (?, ?, ?, ?, ?, ?)`,
    [email, token, role, expiresAt.toISOString(), ipAddress, userAgent],
    function(err) {
      if (err) {
        console.error('[ERROR] Failed to generate magic link:', err);
        return res.status(500).json({
          success: false,
          error: 'Failed to generate magic link'
        });
      }

      const magicLink = `${getBaseUrl(req)}/auth/verify?token=${token}`;

      console.log(`[INFO] Magic link generated for ${email} (expires: ${days} days)`);

      res.json({
        success: true,
        message: 'Magic link generated',
        email,
        token,
        link: magicLink,
        expiresAt: expiresAt.toISOString(),
        expiresIn: `${days} days`,
        note: 'Share this link with the user or email it to them'
      });
    }
  );
});

/**
 * GET /api/magic-links/validate/:token
 * Validate a magic link token
 */
app.get('/api/magic-links/validate/:token', (req, res) => {
  const { token } = req.params;

  if (!token || token.length !== TOKEN_LENGTH) {
    return res.status(400).json({
      success: false,
      error: 'Invalid token format'
    });
  }

  db.get(
    `SELECT email, role FROM magic_links 
     WHERE token = ? AND used = 0 AND expires_at > datetime('now')`,
    [token],
    (err, row) => {
      if (err) {
        console.error('[ERROR] Failed to validate token:', err);
        return res.status(500).json({
          success: false,
          error: 'Validation failed'
        });
      }

      if (!row) {
        return res.status(400).json({
          success: false,
          error: 'Invalid or expired magic link'
        });
      }

      // Mark token as used
      db.run(
        `UPDATE magic_links SET used = 1, used_at = CURRENT_TIMESTAMP WHERE token = ?`,
        [token],
        (err) => {
          if (err) {
            console.error('[ERROR] Failed to mark token as used:', err);
            return res.status(500).json({
              success: false,
              error: 'Failed to complete authentication'
            });
          }

          // Create session
          const sessionToken = crypto.randomBytes(TOKEN_LENGTH / 2).toString('hex');
          const sessionExpiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

          db.run(
            `INSERT INTO magic_links_sessions 
             (email, session_token, role, expires_at) 
             VALUES (?, ?, ?, ?)`,
            [row.email, sessionToken, row.role, sessionExpiresAt.toISOString()],
            (err) => {
              if (err) {
                console.error('[ERROR] Failed to create session:', err);
                return res.status(500).json({
                  success: false,
                  error: 'Failed to create session'
                });
              }

              console.log(`[OK] User authenticated: ${row.email} (${row.role})`);

              // Set session cookie
              res.cookie('session_token', sessionToken, {
                httpOnly: true,
                secure: process.env.NODE_ENV === 'production',
                sameSite: 'strict',
                maxAge: 7 * 24 * 60 * 60 * 1000
              });

              res.json({
                success: true,
                message: 'Magic link validated',
                email: row.email,
                role: row.role,
                sessionToken,
                expiresAt: sessionExpiresAt.toISOString()
              });
            }
          );
        }
      );
    }
  );
});

/**
 * GET /api/magic-links/verify-session
 * Verify session cookie
 */
app.get('/api/magic-links/verify-session', (req, res) => {
  const sessionToken = req.cookies.session_token;

  if (!sessionToken) {
    return res.status(401).json({
      success: false,
      error: 'No session found'
    });
  }

  db.get(
    `SELECT email, role FROM magic_links_sessions 
     WHERE session_token = ? AND expires_at > datetime('now')`,
    [sessionToken],
    (err, row) => {
      if (err) {
        console.error('[ERROR] Failed to verify session:', err);
        return res.status(500).json({
          success: false,
          error: 'Verification failed'
        });
      }

      if (!row) {
        return res.status(401).json({
          success: false,
          error: 'Session expired or invalid'
        });
      }

      // Update last activity
      db.run(
        `UPDATE magic_links_sessions SET last_activity = CURRENT_TIMESTAMP WHERE session_token = ?`,
        [sessionToken]
      );

      res.json({
        success: true,
        email: row.email,
        role: row.role
      });
    }
  );
});

/**
 * POST /api/magic-links/logout
 * Revoke session
 */
app.post('/api/magic-links/logout', (req, res) => {
  const sessionToken = req.cookies.session_token;

  if (!sessionToken) {
    return res.status(400).json({
      success: false,
      error: 'No session to revoke'
    });
  }

  db.run(
    `DELETE FROM magic_links_sessions WHERE session_token = ?`,
    [sessionToken],
    (err) => {
      if (err) {
        console.error('[ERROR] Failed to logout:', err);
        return res.status(500).json({
          success: false,
          error: 'Logout failed'
        });
      }

      res.clearCookie('session_token');

      console.log('[OK] User logged out');

      res.json({
        success: true,
        message: 'Logged out successfully'
      });
    }
  );
});

/**
 * GET /api/magic-links/stats
 * Get magic links statistics
 */
app.get('/api/magic-links/stats', (req, res) => {
  db.all(
    `SELECT 
      (SELECT COUNT(*) FROM magic_links) as total_generated,
      (SELECT COUNT(*) FROM magic_links WHERE used = 1) as total_used,
      (SELECT COUNT(*) FROM magic_links WHERE used = 0 AND expires_at > datetime('now')) as active_links,
      (SELECT COUNT(*) FROM magic_links_sessions WHERE expires_at > datetime('now')) as active_sessions`,
    [],
    (err, rows) => {
      if (err) {
        console.error('[ERROR] Failed to fetch stats:', err);
        return res.status(500).json({
          success: false,
          error: 'Failed to fetch statistics'
        });
      }

      res.json({
        success: true,
        stats: rows[0] || {}
      });
    }
  );
});

/**
 * Helper Functions
 */

function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

function getBaseUrl(req) {
  return `${req.protocol}://${req.get('host')}`;
}

/**
 * Health Check
 */
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Magic Links Authentication Server'
  });
});

/**
 * 404 Handler
 */
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  });
});

/**
 * Error Handler
 */
app.use((err, req, res, next) => {
  console.error('[ERROR]', err);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

/**
 * Server startup
 */
app.listen(PORT, () => {
  console.log(`\n╔════════════════════════════════════════╗`);
  console.log(`║  🔐 Magic Links Server Started        ║`);
  console.log(`╠════════════════════════════════════════╣`);
  console.log(`║  Port: ${PORT}`);
  console.log(`║  Database: ${DB_PATH}`);
  console.log(`║  Default Expiry: ${DEFAULT_EXPIRY_DAYS} days (1-5 configurable)`);
  console.log(`╚════════════════════════════════════════╝\n`);
});

// Handle shutdown gracefully
process.on('SIGINT', () => {
  console.log('\n[INFO] Shutting down server...');
  db.close((err) => {
    if (err) console.error('[ERROR]', err);
    else console.log('[OK] Database connection closed');
    process.exit(0);
  });
});
