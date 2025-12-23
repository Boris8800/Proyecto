#!/usr/bin/env node

/**
 * Job Magic Links Server
 * Generate and validate magic links for paid jobs
 * Send links to drivers with job details (pickup, dropoff, time, map)
 * Track driver location in real-time
 */

const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const crypto = require('crypto');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const cookieParser = require('cookie-parser');

const app = express();
const PORT = process.env.JOB_MAGIC_PORT || 3334;
const DB_PATH = process.env.JOB_DB || '/root/job_magic_links.db';
const TOKEN_LENGTH = 32;

// Middleware
app.use(express.json());
app.use(cors());
app.use(cookieParser());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 50, // Allow more requests for job creation
  message: 'Too many attempts, please try again later'
});

// Database initialization
const db = new sqlite3.Database(DB_PATH, (err) => {
  if (err) {
    console.error('[ERROR] Failed to connect to database:', err);
    process.exit(1);
  }
  console.log('[OK] Connected to Job Magic Links database');
  initializeDatabase();
});

// Database initialization
function initializeDatabase() {
  db.serialize(() => {
    // Jobs table
    db.run(`
      CREATE TABLE IF NOT EXISTS jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id TEXT UNIQUE NOT NULL,
        driver_email TEXT NOT NULL,
        driver_name TEXT,
        driver_phone TEXT,
        magic_token TEXT UNIQUE NOT NULL,
        pickup_address TEXT NOT NULL,
        pickup_lat REAL NOT NULL,
        pickup_lng REAL NOT NULL,
        dropoff_address TEXT NOT NULL,
        dropoff_lat REAL NOT NULL,
        dropoff_lng REAL NOT NULL,
        job_time DATETIME NOT NULL,
        fare DECIMAL(10, 2),
        payment_status TEXT DEFAULT 'pending',
        job_status TEXT DEFAULT 'pending',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        expires_at DATETIME NOT NULL,
        accepted_at DATETIME,
        completed_at DATETIME,
        ip_address TEXT,
        user_agent TEXT
      )
    `, (err) => {
      if (err) console.error('[ERROR] Failed to create jobs table:', err);
      else console.log('[OK] jobs table initialized');
    });

    // Job sessions table (for tracking driver interactions)
    db.run(`
      CREATE TABLE IF NOT EXISTS job_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id TEXT NOT NULL,
        driver_email TEXT NOT NULL,
        session_token TEXT UNIQUE NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        expires_at DATETIME NOT NULL,
        last_activity DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(job_id) REFERENCES jobs(job_id)
      )
    `, (err) => {
      if (err) console.error('[ERROR] Failed to create job_sessions table:', err);
      else console.log('[OK] job_sessions table initialized');
    });

    // Driver location tracking table
    db.run(`
      CREATE TABLE IF NOT EXISTS driver_locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id TEXT NOT NULL,
        driver_email TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        heading REAL,
        speed REAL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(job_id) REFERENCES jobs(job_id)
      )
    `, (err) => {
      if (err) console.error('[ERROR] Failed to create driver_locations table:', err);
      else console.log('[OK] driver_locations table initialized');
    });

    // Create indexes
    db.run(`CREATE INDEX IF NOT EXISTS idx_job_token ON jobs(magic_token)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_job_id ON jobs(job_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_driver_email ON jobs(driver_email)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_session_token ON job_sessions(session_token)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_driver_locations_job ON driver_locations(job_id)`);
  });
}

/**
 * POST /api/job-magic-links/create-for-job
 * Create a magic link for a paid job
 */
app.post('/api/job-magic-links/create-for-job', limiter, (req, res) => {
  const {
    jobId,
    driverEmail,
    driverName,
    driverPhone,
    pickupAddress,
    pickupLat,
    pickupLng,
    dropoffAddress,
    dropoffLat,
    dropoffLng,
    jobTime,
    fare,
    expiryHours = 24
  } = req.body;

  // Validate required fields
  if (!jobId || !driverEmail || !pickupAddress || !dropoffAddress || !jobTime) {
    return res.status(400).json({
      success: false,
      error: 'Missing required fields'
    });
  }

  if (!isValidEmail(driverEmail)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid driver email'
    });
  }

  if (!isValidCoordinates(pickupLat, pickupLng) || !isValidCoordinates(dropoffLat, dropoffLng)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid coordinates'
    });
  }

  // Generate secure token
  const token = crypto.randomBytes(TOKEN_LENGTH / 2).toString('hex');
  const expiresAt = new Date(Date.now() + expiryHours * 60 * 60 * 1000);
  const ipAddress = req.ip || req.connection.remoteAddress;
  const userAgent = req.get('user-agent');

  // Save to database
  db.run(
    `INSERT INTO jobs 
     (job_id, driver_email, driver_name, driver_phone, magic_token, 
      pickup_address, pickup_lat, pickup_lng, 
      dropoff_address, dropoff_lat, dropoff_lng, 
      job_time, fare, expires_at, ip_address, user_agent) 
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [jobId, driverEmail, driverName, driverPhone, token,
     pickupAddress, pickupLat, pickupLng,
     dropoffAddress, dropoffLat, dropoffLng,
     jobTime, fare, expiresAt.toISOString(), ipAddress, userAgent],
    function(err) {
      if (err) {
        console.error('[ERROR] Failed to create job magic link:', err);
        return res.status(500).json({
          success: false,
          error: 'Failed to create magic link'
        });
      }

      const magicLink = `${getBaseUrl(req)}/driver/job?token=${token}`;

      console.log(`[INFO] Job magic link created: ${jobId} for ${driverEmail} (expires: ${expiryHours}h)`);

      res.json({
        success: true,
        message: 'Job magic link created',
        jobId,
        driverEmail,
        token,
        link: magicLink,
        expiresAt: expiresAt.toISOString(),
        expiresIn: `${expiryHours} hours`,
        jobDetails: {
          pickup: pickupAddress,
          dropoff: dropoffAddress,
          time: jobTime,
          fare: fare
        }
      });
    }
  );
});

/**
 * GET /api/job-magic-links/validate/:token
 * Validate job magic link and get job details
 */
app.get('/api/job-magic-links/validate/:token', (req, res) => {
  const { token } = req.params;

  if (!token || token.length !== TOKEN_LENGTH) {
    return res.status(400).json({
      success: false,
      error: 'Invalid token format'
    });
  }

  db.get(
    `SELECT * FROM jobs 
     WHERE magic_token = ? AND job_status != 'completed' AND expires_at > datetime('now')`,
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
          error: 'Invalid or expired job link'
        });
      }

      // Create session
      const sessionToken = crypto.randomBytes(TOKEN_LENGTH / 2).toString('hex');
      const sessionExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

      db.run(
        `INSERT INTO job_sessions 
         (job_id, driver_email, session_token, expires_at) 
         VALUES (?, ?, ?, ?)`,
        [row.job_id, row.driver_email, sessionToken, sessionExpiresAt.toISOString()],
        (err) => {
          if (err) {
            console.error('[ERROR] Failed to create session:', err);
            return res.status(500).json({
              success: false,
              error: 'Failed to create session'
            });
          }

          // Update job status to accepted
          db.run(
            `UPDATE jobs SET job_status = 'accepted', accepted_at = CURRENT_TIMESTAMP WHERE job_id = ?`,
            [row.job_id]
          );

          console.log(`[OK] Job accepted: ${row.job_id} by ${row.driver_email}`);

          // Set session cookie
          res.cookie('job_session_token', sessionToken, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'strict',
            maxAge: 24 * 60 * 60 * 1000
          });

          res.json({
            success: true,
            message: 'Job link validated',
            jobId: row.job_id,
            driverEmail: row.driver_email,
            driverName: row.driver_name,
            sessionToken,
            jobDetails: {
              jobId: row.job_id,
              pickup: {
                address: row.pickup_address,
                lat: row.pickup_lat,
                lng: row.pickup_lng
              },
              dropoff: {
                address: row.dropoff_address,
                lat: row.dropoff_lat,
                lng: row.dropoff_lng
              },
              time: row.job_time,
              fare: row.fare,
              status: row.job_status
            },
            expiresAt: sessionExpiresAt.toISOString()
          });
        }
      );
    }
  );
});

/**
 * POST /api/job-magic-links/update-location/:jobId
 * Update driver location for tracking
 */
app.post('/api/job-magic-links/update-location/:jobId', (req, res) => {
  const { jobId } = req.params;
  const { latitude, longitude, accuracy, heading, speed, sessionToken } = req.body;

  // Verify session token
  if (!sessionToken) {
    return res.status(401).json({
      success: false,
      error: 'No session token provided'
    });
  }

  db.get(
    `SELECT driver_email FROM job_sessions 
     WHERE session_token = ? AND job_id = ? AND expires_at > datetime('now')`,
    [sessionToken, jobId],
    (err, sessionRow) => {
      if (err || !sessionRow) {
        return res.status(401).json({
          success: false,
          error: 'Invalid or expired session'
        });
      }

      if (!isValidCoordinates(latitude, longitude)) {
        return res.status(400).json({
          success: false,
          error: 'Invalid coordinates'
        });
      }

      // Save location
      db.run(
        `INSERT INTO driver_locations 
         (job_id, driver_email, latitude, longitude, accuracy, heading, speed) 
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [jobId, sessionRow.driver_email, latitude, longitude, accuracy, heading, speed],
        (err) => {
          if (err) {
            console.error('[ERROR] Failed to save location:', err);
            return res.status(500).json({
              success: false,
              error: 'Failed to save location'
            });
          }

          // Update session activity
          db.run(
            `UPDATE job_sessions SET last_activity = CURRENT_TIMESTAMP 
             WHERE session_token = ?`,
            [sessionToken]
          );

          res.json({
            success: true,
            message: 'Location updated',
            jobId,
            location: { latitude, longitude }
          });
        }
      );
    }
  );
});

/**
 * GET /api/job-magic-links/driver-location/:jobId
 * Get latest driver location (for admin/customer tracking)
 */
app.get('/api/job-magic-links/driver-location/:jobId', (req, res) => {
  const { jobId } = req.params;

  db.get(
    `SELECT * FROM driver_locations 
     WHERE job_id = ? 
     ORDER BY created_at DESC LIMIT 1`,
    [jobId],
    (err, row) => {
      if (err) {
        return res.status(500).json({
          success: false,
          error: 'Failed to fetch location'
        });
      }

      if (!row) {
        return res.status(404).json({
          success: false,
          error: 'No location data available'
        });
      }

      res.json({
        success: true,
        location: {
          latitude: row.latitude,
          longitude: row.longitude,
          accuracy: row.accuracy,
          heading: row.heading,
          speed: row.speed,
          timestamp: row.created_at
        }
      });
    }
  );
});

/**
 * GET /api/job-magic-links/job/:jobId
 * Get job details
 */
app.get('/api/job-magic-links/job/:jobId', (req, res) => {
  const { jobId } = req.params;

  db.get(
    `SELECT * FROM jobs WHERE job_id = ?`,
    [jobId],
    (err, row) => {
      if (err) {
        return res.status(500).json({
          success: false,
          error: 'Failed to fetch job'
        });
      }

      if (!row) {
        return res.status(404).json({
          success: false,
          error: 'Job not found'
        });
      }

      res.json({
        success: true,
        job: {
          jobId: row.job_id,
          driverEmail: row.driver_email,
          driverName: row.driver_name,
          driverPhone: row.driver_phone,
          pickup: {
            address: row.pickup_address,
            lat: row.pickup_lat,
            lng: row.pickup_lng
          },
          dropoff: {
            address: row.dropoff_address,
            lat: row.dropoff_lat,
            lng: row.dropoff_lng
          },
          jobTime: row.job_time,
          fare: row.fare,
          status: row.job_status,
          paymentStatus: row.payment_status,
          createdAt: row.created_at,
          acceptedAt: row.accepted_at,
          completedAt: row.completed_at
        }
      });
    }
  );
});

/**
 * POST /api/job-magic-links/complete-job/:jobId
 * Mark job as completed
 */
app.post('/api/job-magic-links/complete-job/:jobId', (req, res) => {
  const { jobId } = req.params;
  const { sessionToken } = req.body;

  // Verify session
  db.get(
    `SELECT * FROM job_sessions 
     WHERE job_id = ? AND session_token = ? AND expires_at > datetime('now')`,
    [jobId, sessionToken],
    (err, sessionRow) => {
      if (err || !sessionRow) {
        return res.status(401).json({
          success: false,
          error: 'Invalid session'
        });
      }

      // Mark job as completed
      db.run(
        `UPDATE jobs SET job_status = 'completed', completed_at = CURRENT_TIMESTAMP 
         WHERE job_id = ?`,
        [jobId],
        (err) => {
          if (err) {
            return res.status(500).json({
              success: false,
              error: 'Failed to complete job'
            });
          }

          console.log(`[OK] Job completed: ${jobId}`);

          res.json({
            success: true,
            message: 'Job marked as completed',
            jobId
          });
        }
      );
    }
  );
});

/**
 * GET /api/job-magic-links/stats
 * Get statistics
 */
app.get('/api/job-magic-links/stats', (req, res) => {
  db.all(
    `SELECT 
      (SELECT COUNT(*) FROM jobs) as total_jobs,
      (SELECT COUNT(*) FROM jobs WHERE job_status = 'completed') as completed_jobs,
      (SELECT COUNT(*) FROM jobs WHERE job_status = 'accepted') as accepted_jobs,
      (SELECT COUNT(*) FROM jobs WHERE job_status = 'pending') as pending_jobs,
      (SELECT COUNT(*) FROM job_sessions WHERE expires_at > datetime('now')) as active_sessions,
      (SELECT COUNT(DISTINCT job_id) FROM driver_locations) as tracked_jobs`,
    [],
    (err, rows) => {
      if (err) {
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

function isValidCoordinates(lat, lng) {
  return typeof lat === 'number' && typeof lng === 'number' &&
         lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
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
    service: 'Job Magic Links Server'
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
  console.log(`║  📦 Job Magic Links Server Started    ║`);
  console.log(`╠════════════════════════════════════════╣`);
  console.log(`║  Port: ${PORT}`);
  console.log(`║  Database: ${DB_PATH}`);
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
