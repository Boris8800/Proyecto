/**
 * Email Service Utility
 * Handles email sending via different providers
 */

const nodemailer = require('nodemailer');

class EmailService {
    constructor(config) {
        this.config = config;
        this.transporter = null;
        this.initializeTransporter();
    }

    initializeTransporter() {
        try {
            const emailConfig = this.config.email;

            if (emailConfig.provider === 'smtp') {
                this.transporter = nodemailer.createTransport({
                    host: emailConfig.smtp.host,
                    port: emailConfig.smtp.port,
                    secure: emailConfig.smtp.secure,
                    auth: {
                        user: emailConfig.smtp.auth.user,
                        pass: emailConfig.smtp.auth.pass
                    }
                });
                console.log('[EMAIL] SMTP transporter initialized');
            } else if (emailConfig.provider === 'sendgrid') {
                this.transporter = nodemailer.createTransport({
                    host: 'smtp.sendgrid.net',
                    port: 587,
                    auth: {
                        user: 'apikey',
                        pass: emailConfig.sendgrid.apiKey
                    }
                });
                console.log('[EMAIL] SendGrid transporter initialized');
            } else if (emailConfig.provider === 'mailgun') {
                this.transporter = nodemailer.createTransport({
                    host: 'smtp.mailgun.org',
                    port: 587,
                    auth: {
                        user: `postmaster@${emailConfig.mailgun.domain}`,
                        pass: emailConfig.mailgun.apiKey
                    }
                });
                console.log('[EMAIL] Mailgun transporter initialized');
            }
        } catch (err) {
            console.error('[ERR] Failed to initialize email transporter:', err.message);
        }
    }

    /**
     * Send email
     * @param {Object} options - Email options
     * @param {string} options.to - Recipient email
     * @param {string} options.subject - Email subject
     * @param {string} options.html - HTML content
     * @param {string} options.text - Plain text content
     * @returns {Promise} Email send result
     */
    async send(options) {
        if (!this.transporter) {
            throw new Error('Email transporter not initialized');
        }

        const emailConfig = this.config.email;
        const fromEmail = this.getFromEmail();

        const mailOptions = {
            from: options.from || fromEmail,
            to: options.to,
            subject: options.subject,
            html: options.html || options.text,
            text: options.text
        };

        try {
            const info = await this.transporter.sendMail(mailOptions);
            console.log(`[EMAIL] Email sent to ${options.to}: ${info.messageId}`);
            return {
                success: true,
                messageId: info.messageId,
                provider: emailConfig.provider
            };
        } catch (err) {
            console.error('[ERR] Failed to send email:', err.message);
            throw err;
        }
    }

    /**
     * Send welcome email
     */
    async sendWelcomeEmail(userEmail, userName) {
        const html = `
            <h1>Welcome to Swift Cab!</h1>
            <p>Hi ${userName},</p>
            <p>Thank you for joining Swift Cab. We're excited to have you onboard.</p>
            <p>You can now book rides, track your trips, and manage your account.</p>
            <br/>
            <p>Best regards,<br/>Swift Cab Team</p>
        `;

        return this.send({
            to: userEmail,
            subject: 'Welcome to Swift Cab',
            html: html
        });
    }

    /**
     * Send booking confirmation email
     */
    async sendBookingConfirmation(userEmail, bookingDetails) {
        const html = `
            <h2>Booking Confirmation</h2>
            <p>Your booking has been confirmed!</p>
            <p><strong>Booking ID:</strong> ${bookingDetails.bookingId}</p>
            <p><strong>Pickup:</strong> ${bookingDetails.pickupLocation}</p>
            <p><strong>Destination:</strong> ${bookingDetails.destination}</p>
            <p><strong>Estimated Fare:</strong> $${bookingDetails.estimatedFare}</p>
            <p><strong>Driver:</strong> ${bookingDetails.driverName}</p>
            <br/>
            <p>Track your ride in the Swift Cab app.</p>
        `;

        return this.send({
            to: userEmail,
            subject: `Booking Confirmed - ${bookingDetails.bookingId}`,
            html: html
        });
    }

    /**
     * Send password reset email
     */
    async sendPasswordReset(userEmail, resetLink, userName) {
        const html = `
            <h2>Password Reset Request</h2>
            <p>Hi ${userName},</p>
            <p>We received a request to reset your password. Click the link below to proceed:</p>
            <p><a href="${resetLink}" style="background: #2563eb; color: white; padding: 10px 20px; border-radius: 5px; text-decoration: none;">Reset Password</a></p>
            <p>If you didn't request this, please ignore this email.</p>
            <p>This link expires in 1 hour.</p>
        `;

        return this.send({
            to: userEmail,
            subject: 'Password Reset Request',
            html: html
        });
    }

    /**
     * Send OTP verification email
     */
    async sendOTPEmail(userEmail, otp, userName) {
        const html = `
            <h2>Verify Your Email</h2>
            <p>Hi ${userName},</p>
            <p>Your verification code is:</p>
            <h3 style="background: #f3f4f6; padding: 15px; border-radius: 5px; text-align: center; font-family: monospace;">${otp}</h3>
            <p>This code expires in 10 minutes.</p>
            <p>Never share this code with anyone.</p>
        `;

        return this.send({
            to: userEmail,
            subject: 'Email Verification Code',
            html: html
        });
    }

    /**
     * Send trip completed email
     */
    async sendTripCompletedEmail(userEmail, tripDetails) {
        const html = `
            <h2>Trip Completed</h2>
            <p>Your trip has been completed!</p>
            <p><strong>Trip ID:</strong> ${tripDetails.tripId}</p>
            <p><strong>Duration:</strong> ${tripDetails.duration}</p>
            <p><strong>Distance:</strong> ${tripDetails.distance}</p>
            <p><strong>Total Fare:</strong> $${tripDetails.totalFare}</p>
            <p><strong>Driver Rating:</strong> ${tripDetails.driverRating}/5</p>
            <br/>
            <p>Rate your experience and help us improve our service!</p>
        `;

        return this.send({
            to: userEmail,
            subject: 'Trip Completed - Thank You!',
            html: html
        });
    }

    /**
     * Send admin notification
     */
    async sendAdminNotification(adminEmail, subject, message) {
        const html = `
            <h2>${subject}</h2>
            <p>${message}</p>
            <p>Sent: ${new Date().toLocaleString()}</p>
        `;

        return this.send({
            to: adminEmail,
            subject: `[ADMIN] ${subject}`,
            html: html
        });
    }

    /**
     * Get from email based on provider
     */
    getFromEmail() {
        const emailConfig = this.config.email;
        
        if (emailConfig.provider === 'smtp') {
            return emailConfig.smtp.from;
        } else if (emailConfig.provider === 'sendgrid') {
            return emailConfig.sendgrid.fromEmail;
        } else if (emailConfig.provider === 'mailgun') {
            return emailConfig.mailgun.fromEmail;
        }
        
        return 'noreply@swiftcab.com';
    }

    /**
     * Verify email transporter
     */
    async verify() {
        if (!this.transporter) {
            return { success: false, message: 'Transporter not initialized' };
        }

        try {
            await this.transporter.verify();
            console.log('[OK] Email transporter verified');
            return { success: true, message: 'Email service ready' };
        } catch (err) {
            console.error('[ERR] Email transporter verification failed:', err.message);
            return { success: false, message: err.message };
        }
    }
}

module.exports = EmailService;
