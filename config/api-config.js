/**
 * ============================================
 * COMPLETE API CONFIGURATION SYSTEM
 * ============================================
 * Centralized management for all external APIs
 * Supports: Google, Email, SMS, Payments, Push, Analytics
 * 
 * Usage:
 *   const apiConfig = require('./config/api-config');
 *   
 *   // Send email
 *   await apiConfig.email.sendEmail({ ... });
 *   
 *   // Send SMS
 *   await apiConfig.sms.sendSMS({ ... });
 *   
 *   // Use Google Maps
 *   await apiConfig.google.geocodeAddress({ ... });
 */

require('dotenv').config();

// ============================================
// 1. GOOGLE APIS CONFIGURATION
// ============================================
const googleConfig = {
  mapsApiKey: process.env.GOOGLE_MAPS_API_KEY || null,
  geocodingApiKey: process.env.GOOGLE_GEOCODING_API_KEY || null,
  directionsApiKey: process.env.GOOGLE_DIRECTIONS_API_KEY || null,
  placesApiKey: process.env.GOOGLE_PLACES_API_KEY || null,

  // Methods
  methods: {
    geocodeAddress: async (address) => {
      if (!googleConfig.geocodingApiKey) {
        throw new Error('Google Geocoding API key not configured');
      }
      const axios = require('axios');
      try {
        const response = await axios.get(
          'https://maps.googleapis.com/maps/api/geocode/json',
          {
            params: {
              address: address,
              key: googleConfig.geocodingApiKey
            }
          }
        );
        return response.data.results[0];
      } catch (error) {
        throw new Error(`Geocoding failed: ${error.message}`);
      }
    },

    reverseGeocode: async (lat, lng) => {
      if (!googleConfig.geocodingApiKey) {
        throw new Error('Google Geocoding API key not configured');
      }
      const axios = require('axios');
      try {
        const response = await axios.get(
          'https://maps.googleapis.com/maps/api/geocode/json',
          {
            params: {
              latlng: `${lat},${lng}`,
              key: googleConfig.geocodingApiKey
            }
          }
        );
        return response.data.results[0];
      } catch (error) {
        throw new Error(`Reverse geocoding failed: ${error.message}`);
      }
    },

    getDirections: async (origin, destination, mode = 'driving') => {
      if (!googleConfig.directionsApiKey) {
        throw new Error('Google Directions API key not configured');
      }
      const axios = require('axios');
      try {
        const response = await axios.get(
          'https://maps.googleapis.com/maps/api/directions/json',
          {
            params: {
              origin: origin,
              destination: destination,
              mode: mode,
              key: googleConfig.directionsApiKey
            }
          }
        );
        return response.data.routes[0];
      } catch (error) {
        throw new Error(`Directions failed: ${error.message}`);
      }
    },

    getPlacePredictions: async (input, sessionToken = null) => {
      if (!googleConfig.placesApiKey) {
        throw new Error('Google Places API key not configured');
      }
      const axios = require('axios');
      try {
        const response = await axios.post(
          'https://places.googleapis.com/v1/places:autocomplete',
          {
            input: input,
            sessionToken: sessionToken
          },
          {
            headers: {
              'X-Goog-Api-Key': googleConfig.placesApiKey
            }
          }
        );
        return response.data.suggestions;
      } catch (error) {
        throw new Error(`Places autocomplete failed: ${error.message}`);
      }
    }
  }
};

// ============================================
// 2. EMAIL CONFIGURATION
// ============================================
const emailConfig = {
  service: process.env.EMAIL_SERVICE || 'gmail',
  user: process.env.EMAIL_USER || null,
  password: process.env.EMAIL_PASSWORD || null,
  sendgridKey: process.env.SENDGRID_API_KEY || null,
  mailgunKey: process.env.MAILGUN_API_KEY || null,
  mailgunDomain: process.env.MAILGUN_DOMAIN || null,
  awsAccessKey: process.env.AWS_SES_ACCESS_KEY_ID || null,
  awsSecretKey: process.env.AWS_SES_SECRET_ACCESS_KEY || null,

  methods: {
    sendEmail: async (options) => {
      const { to, subject, text, html, from } = options;

      if (!to || !subject) {
        throw new Error('Missing required email fields: to, subject');
      }

      try {
        if (emailConfig.service === 'sendgrid' && emailConfig.sendgridKey) {
          return await emailConfig.methods._sendViasendGrid({
            to, subject, text, html, from
          });
        } else if (emailConfig.service === 'mailgun' && emailConfig.mailgunKey) {
          return await emailConfig.methods._sendViaMailgun({
            to, subject, text, html, from
          });
        } else if (emailConfig.service === 'aws-ses' && emailConfig.awsAccessKey) {
          return await emailConfig.methods._sendViaAWSSES({
            to, subject, text, html, from
          });
        } else if (emailConfig.service === 'gmail' || emailConfig.service === 'smtp') {
          return await emailConfig.methods._sendViaNodemailer({
            to, subject, text, html, from
          });
        } else {
          throw new Error('Email service not configured');
        }
      } catch (error) {
        throw new Error(`Email send failed: ${error.message}`);
      }
    },

    _sendViaNodemailer: async (options) => {
      const nodemailer = require('nodemailer');
      const transporter = nodemailer.createTransport({
        service: emailConfig.service,
        auth: {
          user: emailConfig.user,
          pass: emailConfig.password
        }
      });

      return new Promise((resolve, reject) => {
        transporter.sendMail(
          {
            from: options.from || emailConfig.user,
            to: options.to,
            subject: options.subject,
            text: options.text,
            html: options.html
          },
          (error, info) => {
            if (error) reject(error);
            else resolve(info);
          }
        );
      });
    },

    _sendViaMailgun: async (options) => {
      const axios = require('axios');
      const FormData = require('form-data');
      const form = new FormData();

      form.append('from', options.from || `noreply@${emailConfig.mailgunDomain}`);
      form.append('to', options.to);
      form.append('subject', options.subject);
      if (options.html) form.append('html', options.html);
      if (options.text) form.append('text', options.text);

      try {
        const response = await axios.post(
          `https://api.mailgun.net/v3/${emailConfig.mailgunDomain}/messages`,
          form,
          {
            auth: {
              username: 'api',
              password: emailConfig.mailgunKey
            }
          }
        );
        return response.data;
      } catch (error) {
        throw new Error(`Mailgun error: ${error.message}`);
      }
    },

    _sendViaAWSSES: async (options) => {
      const AWS = require('aws-sdk');
      const ses = new AWS.SES({
        accessKeyId: emailConfig.awsAccessKey,
        secretAccessKey: emailConfig.awsSecretKey,
        region: process.env.AWS_SES_REGION || 'us-east-1'
      });

      const params = {
        Source: options.from || process.env.AWS_SES_FROM_EMAIL,
        Destination: { ToAddresses: [options.to] },
        Message: {
          Subject: { Data: options.subject },
          Body: {
            Html: { Data: options.html || options.text },
            Text: { Data: options.text }
          }
        }
      };

      return new Promise((resolve, reject) => {
        ses.sendEmail(params, (error, data) => {
          if (error) reject(error);
          else resolve(data);
        });
      });
    },

    _sendViasendGrid: async (options) => {
      const sgMail = require('@sendgrid/mail');
      sgMail.setApiKey(emailConfig.sendgridKey);

      const msg = {
        to: options.to,
        from: options.from || process.env.SENDGRID_FROM_EMAIL,
        subject: options.subject,
        text: options.text,
        html: options.html
      };

      return await sgMail.send(msg);
    }
  }
};

// ============================================
// 3. SMS CONFIGURATION
// ============================================
const smsConfig = {
  service: process.env.SMS_SERVICE || 'twilio',
  twilioAccountSid: process.env.TWILIO_ACCOUNT_SID || null,
  twilioAuthToken: process.env.TWILIO_AUTH_TOKEN || null,
  twilioPhoneNumber: process.env.TWILIO_PHONE_NUMBER || null,
  vonageApiKey: process.env.VONAGE_API_KEY || null,
  vonageApiSecret: process.env.VONAGE_API_SECRET || null,
  vonageFromNumber: process.env.VONAGE_FROM_NUMBER || null,
  awsSnsAccessKey: process.env.AWS_SNS_ACCESS_KEY_ID || null,
  awsSnsSecretKey: process.env.AWS_SNS_SECRET_ACCESS_KEY || null,

  methods: {
    sendSMS: async (options) => {
      const { to, message } = options;

      if (!to || !message) {
        throw new Error('Missing required SMS fields: to, message');
      }

      try {
        if (smsConfig.service === 'twilio' && smsConfig.twilioAccountSid) {
          return await smsConfig.methods._sendViaTwilio({ to, message });
        } else if (smsConfig.service === 'vonage' && smsConfig.vonageApiKey) {
          return await smsConfig.methods._sendViaVonage({ to, message });
        } else if (smsConfig.service === 'aws-sns' && smsConfig.awsSnsAccessKey) {
          return await smsConfig.methods._sendViaAWSSNS({ to, message });
        } else {
          throw new Error('SMS service not configured');
        }
      } catch (error) {
        throw new Error(`SMS send failed: ${error.message}`);
      }
    },

    _sendViaTwilio: async (options) => {
      const twilio = require('twilio');
      const client = twilio(smsConfig.twilioAccountSid, smsConfig.twilioAuthToken);

      return await client.messages.create({
        body: options.message,
        from: smsConfig.twilioPhoneNumber,
        to: options.to
      });
    },

    _sendViaVonage: async (options) => {
      const vonage = require('@vonage/server-sdk');
      const client = new vonage.Sms({
        apiKey: smsConfig.vonageApiKey,
        apiSecret: smsConfig.vonageApiSecret
      });

      return new Promise((resolve, reject) => {
        client.submitSm(
          {
            to: options.to,
            from: smsConfig.vonageFromNumber,
            text: options.message
          },
          (err, responseData) => {
            if (err) reject(err);
            else {
              if (responseData.messages[0]['status'] === '0') {
                resolve(responseData);
              } else {
                reject(new Error(`Message failed with error: ${responseData.messages[0]['error-text']}`));
              }
            }
          }
        );
      });
    },

    _sendViaAWSSNS: async (options) => {
      const AWS = require('aws-sdk');
      const sns = new AWS.SNS({
        accessKeyId: smsConfig.awsSnsAccessKey,
        secretAccessKey: smsConfig.awsSnsSecretKey,
        region: process.env.AWS_SNS_REGION || 'us-east-1'
      });

      return new Promise((resolve, reject) => {
        sns.publish({
          Message: options.message,
          PhoneNumber: options.to
        }, (error, data) => {
          if (error) reject(error);
          else resolve(data);
        });
      });
    }
  }
};

// ============================================
// 4. PAYMENT GATEWAYS CONFIGURATION
// ============================================
const paymentConfig = {
  stripe: {
    secretKey: process.env.STRIPE_SECRET_KEY || null,
    publishableKey: process.env.STRIPE_PUBLISHABLE_KEY || null,
    webhookSecret: process.env.STRIPE_WEBHOOK_SECRET || null
  },
  paypal: {
    clientId: process.env.PAYPAL_CLIENT_ID || null,
    clientSecret: process.env.PAYPAL_CLIENT_SECRET || null,
    mode: process.env.PAYPAL_MODE || 'sandbox'
  },
  square: {
    accessToken: process.env.SQUARE_ACCESS_TOKEN || null,
    locationId: process.env.SQUARE_LOCATION_ID || null
  }
};

// ============================================
// 5. PUSH NOTIFICATIONS CONFIGURATION
// ============================================
const pushConfig = {
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || null,
    privateKey: process.env.FIREBASE_PRIVATE_KEY || null,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL || null
  },
  onesignal: {
    appId: process.env.ONESIGNAL_APP_ID || null,
    apiKey: process.env.ONESIGNAL_API_KEY || null
  }
};

// ============================================
// 6. ANALYTICS CONFIGURATION
// ============================================
const analyticsConfig = {
  sentry: {
    dsn: process.env.SENTRY_DSN || null
  },
  logrocket: {
    appId: process.env.LOGROCKET_APP_ID || null
  }
};

// ============================================
// MAIN API CONFIG EXPORT
// ============================================
module.exports = {
  google: {
    ...googleConfig,
    geocodeAddress: googleConfig.methods.geocodeAddress,
    reverseGeocode: googleConfig.methods.reverseGeocode,
    getDirections: googleConfig.methods.getDirections,
    getPlacePredictions: googleConfig.methods.getPlacePredictions
  },

  email: {
    service: emailConfig.service,
    sendEmail: emailConfig.methods.sendEmail
  },

  sms: {
    service: smsConfig.service,
    sendSMS: smsConfig.methods.sendSMS
  },

  payment: paymentConfig,
  push: pushConfig,
  analytics: analyticsConfig,

  // Helper: Check configuration status
  checkStatus: () => {
    const status = {
      google: {
        maps: !!googleConfig.mapsApiKey,
        geocoding: !!googleConfig.geocodingApiKey,
        directions: !!googleConfig.directionsApiKey,
        places: !!googleConfig.placesApiKey
      },
      email: !!emailConfig.service,
      sms: !!smsConfig.service,
      payment: {
        stripe: !!paymentConfig.stripe.secretKey,
        paypal: !!paymentConfig.paypal.clientId,
        square: !!paymentConfig.square.accessToken
      },
      push: {
        firebase: !!pushConfig.firebase.projectId,
        onesignal: !!pushConfig.onesignal.appId
      },
      analytics: {
        sentry: !!analyticsConfig.sentry.dsn,
        logrocket: !!analyticsConfig.logrocket.appId
      }
    };
    return status;
  },

  // Helper: Print configuration status
  printStatus: () => {
    const status = module.exports.checkStatus();
    console.log('\n============================================');
    console.log('API CONFIGURATION STATUS');
    console.log('============================================');
    console.log(JSON.stringify(status, null, 2));
    console.log('============================================\n');
  }
};
