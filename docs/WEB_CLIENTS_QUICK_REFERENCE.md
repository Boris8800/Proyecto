# Swift Cab - Production Web Clients Quick Reference

## 🚀 Quick Start

### Access the Applications
```
Admin Dashboard:  http://5.249.164.40:3001
Driver Portal:    http://5.249.164.40:3002
Customer App:     http://5.249.164.40:3003
API Server:       http://5.249.164.40:3000
Status Dashboard: http://5.249.164.40:8080
```

### Start Services
```bash
cd /root/Proyecto/web
npm start
```

### Test All Services
```bash
./scripts/test-webs.sh
```

---

## 📱 Customer Booking App Features

### Core Features
- ✅ Interactive map-based location selection
- ✅ Real-time pricing calculator
- ✅ Three vehicle types (Economy/Comfort/Premium)
- ✅ Form validation with error messages
- ✅ Booking confirmation system

### Security
- ✅ Content Security Policy headers
- ✅ Input validation & sanitization
- ✅ Secure cookies (HttpOnly, Secure, SameSite)
- ✅ Rate limiting (10 req/60s)
- ✅ CSRF protection ready

### Design
- ✅ GetTransfer-like modern UI
- ✅ Responsive (mobile/tablet/desktop)
- ✅ Accessibility features
- ✅ Professional animations
- ✅ Dark gradient background

---

## 🔒 Security Features Implemented

### All Servers Have:
```
✓ X-Content-Type-Options: nosniff
✓ X-Frame-Options: DENY/SAMEORIGIN
✓ X-XSS-Protection: 1; mode=block
✓ Content-Security-Policy
✓ Strict-Transport-Security
✓ Referrer-Policy
✓ Permissions-Policy
```

### Cookies:
```
✓ session_id (24 hours) - Necessary
✓ user_preferences (1 year) - Preferences
✓ analytics_id (1 year) - Analytics
```

---

## 📂 Important Files

### Customer App
```
web/customer/index.html          # Modern HTML structure
web/customer/css/production.css  # 1,100+ lines of production CSS
web/customer/js/main.js          # Complete booking logic
web/server-customer.js           # Express server with security headers
```

### Security & Infrastructure
```
web/server-admin.js              # Admin server with security headers
web/server-driver.js             # Driver server with security headers
config/docker-compose.yml        # Docker services configuration
```

### Documentation
```
docs/PRODUCTION_READY_WEB_CLIENTS.md    # Complete feature guide
docs/WEB_CLIENTS_COMPLETION.md          # Project summary
scripts/test-webs.sh                    # Automated testing script
```

---

## 🔧 Configuration

### Environment Variables
```bash
NODE_ENV=production
CUSTOMER_PORT=3003
ADMIN_PORT=3001
DRIVER_PORT=3002
CORS_ORIGIN=http://localhost:3003
```

### For HTTPS (Production)
```bash
export SSL_CERT=/path/to/cert.pem
export SSL_KEY=/path/to/key.pem
npm start
```

---

## ✅ Testing Checklist

### Automated Tests
```bash
./scripts/test-webs.sh
```

Checks:
- Port availability (3001, 3002, 3003, 3000, 8080)
- HTTP endpoints returning 200
- Security headers present
- Health checks working

### Manual Testing (Browser)

**Form Validation**
- [ ] Invalid email rejected
- [ ] Phone < 10 digits rejected
- [ ] Name with numbers rejected
- [ ] Required fields enforced
- [ ] Error messages displayed

**Map Features**
- [ ] Click to select pickup (green marker)
- [ ] Click to select dropoff (red marker)
- [ ] Route line connects both points
- [ ] Zoom in/out buttons work
- [ ] Center map button works
- [ ] Geolocation works
- [ ] Distance updates pricing

**Cookies**
- [ ] Banner appears on first visit
- [ ] Accept all creates 3 cookies
- [ ] Reject all creates 1 cookie
- [ ] Cookie attributes set correctly
  - Secure flag ✓
  - HttpOnly flag ✓
  - SameSite=Strict ✓

**Responsive Design**
- [ ] Mobile (< 480px): Single column
- [ ] Tablet (480-768px): Stacked layout
- [ ] Desktop (768px+): Two columns
- [ ] Touch targets 44px minimum
- [ ] Fonts readable on all sizes

---

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Kill process on port
lsof -i :3003
kill -9 <PID>

# Or use different port
CUSTOMER_PORT=3030 npm start
```

### Map Not Loading
```javascript
// Check CSP headers allow Leaflet
// Check browser console for errors
// Verify CDN is accessible
```

### Cookies Not Working
```javascript
// Requires HTTPS for Secure flag
// Check browser privacy settings
// Verify SameSite policy compatibility
```

### Rate Limiting Issues
```javascript
// Clear localStorage
localStorage.clear()

// Wait 60 seconds for reset
// Or restart the browser
```

---

## 🌐 Browser Support

### Tested & Supported
- ✓ Chrome 90+
- ✓ Firefox 88+
- ✓ Safari 14+
- ✓ Edge 90+
- ✓ Mobile browsers (iOS Safari, Chrome Mobile)

### Requirements
- JavaScript enabled
- Geolocation permission (optional)
- Cookies enabled
- ES6 support

---

## 📊 Performance

### Optimized For
- Fast initial load
- Smooth interactions
- Responsive to user input
- Efficient map rendering
- Minimal network requests

### Recommendations for Production
- Enable gzip compression
- Use CDN for static assets
- Cache static files
- Implement service workers
- Monitor performance metrics

---

## 🔐 Security Best Practices

### For Production Deployment
1. **Use HTTPS** - Install SSL certificate
2. **Update Dependencies** - `npm audit` regularly
3. **Monitor Logs** - Check for suspicious activity
4. **Rate Limit on Server** - Use express-rate-limit
5. **Database Encryption** - Encrypt sensitive data
6. **Regular Backups** - Backup data daily
7. **Security Audits** - Annual penetration testing
8. **Update Frameworks** - Keep Node.js updated
9. **Monitor Performance** - Use APM tools
10. **Incident Response** - Have a plan

---

## 🆘 Getting Help

### Documentation Files
```
docs/PRODUCTION_READY_WEB_CLIENTS.md     - Feature guide & API specs
docs/WEB_CLIENTS_COMPLETION.md           - Project summary & checklist
docs/VPS_DEPLOYMENT_GUIDE.md             - VPS setup instructions
scripts/test-webs.sh                     - Testing & validation guide
```

### Useful Commands
```bash
# View logs
tail -f /root/Proyecto/logs/customer.log

# Check running processes
pgrep -f "server-customer"

# Test endpoint
curl http://localhost:3003/api/health

# Monitor ports
netstat -tlnp | grep 300
```

---

## 📈 Recent Updates (Dec 22, 2024)

- ✨ Added GetTransfer-like booking interface
- 🗺️ Integrated Leaflet.js map
- 🔐 Implemented security headers on all servers
- 🍪 Added GDPR-compliant cookie system
- ♿ Added accessibility features
- 📱 Enhanced responsive design
- ✅ Added comprehensive validation
- 📚 Created complete documentation
- 🧪 Added testing script
- 🚀 Production-ready deployment

---

## 📞 Support Contacts

- **API Issues**: Check `/api/health` endpoint
- **Database Issues**: Check Docker containers
- **Deployment Issues**: See VPS_DEPLOYMENT_GUIDE.md
- **Security Issues**: Review security headers
- **Performance Issues**: Check logs and monitor

---

## ⚡ Quick Tips

1. **Reset Cookies**: Open DevTools → Application → Storage → Clear All
2. **View Headers**: Use browser DevTools → Network tab
3. **Debug Map**: Open console, check `window.bookingMap`
4. **Test Form**: Use DevTools → Console to test validators
5. **Monitor Performance**: Use Lighthouse in Chrome DevTools

---

**Version**: 1.0.0 (Production Ready)  
**Last Updated**: December 22, 2024  
**Status**: ✅ Ready for VPS Deployment  
**VPS IP**: 5.249.164.40
