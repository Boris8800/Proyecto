# Web Dashboards - Taxi System

Professional web interfaces for the Taxi Management System.

## 📁 Directory Structure

```
web/
├── admin/           # Administrator Dashboard
│   ├── index.html   # Main admin interface
│   ├── css/
│   │   └── style.css
│   ├── js/
│   │   └── main.js
│   └── assets/      # Images, icons, etc.
│
├── driver/          # Driver Portal
│   ├── index.html   # Driver interface
│   ├── css/
│   │   └── style.css
│   ├── js/
│   │   └── main.js
│   └── assets/
│
└── customer/        # Customer App
    ├── index.html   # Customer booking interface
    ├── css/
    │   └── style.css
    ├── js/
    │   └── main.js
    └── assets/
```

## 🎨 Features

### 🔐 Magic Links Authentication

**Driver Portal** and **Customer App** use passwordless authentication:
- No passwords to remember
- One-click email verification
- More secure (unique tokens with expiration)
- Better UX on mobile devices
- Automatic signup for new users

See [MAGIC_LINKS_AUTH.md](../MAGIC_LINKS_AUTH.md) for complete implementation details.

### Admin Dashboard
- **Real-time Stats**: Active drivers, customers, rides, revenue
- **Recent Rides Table**: Status tracking, driver/customer info
- **Top Drivers Leaderboard**: Performance metrics
- **System Status Monitor**: API, Database, Redis, Payment Gateway
- **Responsive Design**: Works on desktop and mobile

### Driver Portal
- **Online/Offline Toggle**: Control availability
- **Ride Requests**: Accept/decline with customer ratings
- **Earnings Breakdown**: Base fare, tips, bonuses
- **Recent Rides**: Track completed trips
- **Performance Stats**: Today's rides, ratings, online time

### Customer App
- **Ride Booking Form**: Pickup/destination with autocomplete
- **Ride Type Selection**: Standard, Premium, XL
- **Trip Calculator**: Distance and time estimates
- **Ride History**: Past trips with ratings
- **Favorite Locations**: Quick access to home/work
- **Travel Stats**: Total rides, distance, money saved

## 🎯 Design System

### Color Palette
```css
--primary: #4facfe     /* Blue gradient start */
--secondary: #00f2fe   /* Blue gradient end */
--success: #00d084     /* Green for positive actions */
--warning: #ffa726     /* Orange for warnings */
--danger: #ff5252      /* Red for errors */
--purple: #9c27b0      /* Purple for special features */
--dark: #1a1a2e        /* Dark backgrounds */
--light: #f8f9fa       /* Light backgrounds */
--gray: #6c757d        /* Text gray */
```

### Typography
- **Font Family**: Segoe UI, Tahoma, Geneva, Verdana, sans-serif
- **Headers**: 2rem - 1.2rem
- **Body**: 1rem (16px base)
- **Small Text**: 0.85rem - 0.9rem

### Components
- **Cards**: White background, 15px border-radius, shadow
- **Buttons**: Gradient on primary, solid colors for secondary
- **Inputs**: 8px border-radius, 2px border, focus states
- **Status Badges**: Color-coded with rounded corners
- **Icons**: Font Awesome 6.0 CDN

## 🚀 Usage in Installation Script

The `install-taxi-system.sh` script automatically deploys these dashboards:

```bash
# The script copies web/ directory to /home/taxi/app/
create_all_dashboards() {
    cp -r web/admin/* /home/taxi/app/admin/
    cp -r web/driver/* /home/taxi/app/driver/
    cp -r web/customer/* /home/taxi/app/customer/
}
```

### Deployment Locations
- Admin Dashboard: `/home/taxi/app/admin/` → Port 3001
- Driver Portal: `/home/taxi/app/driver/` → Port 3002
- Customer App: `/home/taxi/app/customer/` → Port 3003

## 🔧 Customization

### Modify Colors
Edit the `:root` section in each `css/style.css`:
```css
:root {
    --primary: #YOUR_COLOR;
    --secondary: #YOUR_COLOR;
    /* ... */
}
```

### Update Content
- **HTML**: Edit `index.html` files directly
- **Styles**: Modify `css/style.css` for each dashboard
- **Functionality**: Add logic in `js/main.js` files

### Add New Pages
1. Create new HTML file in the dashboard folder
2. Link from `index.html`: `<a href="new-page.html">New Page</a>`
3. Ensure consistent styling by importing the same CSS

## 📡 API Integration

Each dashboard is ready for API integration. Current placeholders:

### Admin Dashboard
```javascript
fetch('/api/status')
    .then(response => response.json())
    .then(data => {
        // Update dashboard with real data
    });
```

### Driver Portal
```javascript
// Accept ride
fetch('/api/rides/accept', {
    method: 'POST',
    body: JSON.stringify({ rideId: '123' })
});

// Toggle online status
fetch('/api/driver/status', {
    method: 'PATCH',
    body: JSON.stringify({ online: true })
});
```

### Customer App
```javascript
// Book ride
fetch('/api/rides/book', {
    method: 'POST',
    body: JSON.stringify({
        pickup: 'Current Location',
        destination: 'Airport',
        rideType: 'standard'
    })
});
```

## 🎭 Demo Mode

All dashboards work standalone with demo data:
- **No API required** for initial viewing
- **Sample data** included in HTML
- **Mock interactions** in JavaScript
- **Graceful fallbacks** when API unavailable

## 📱 Responsive Design

### Breakpoints
- **Desktop**: > 1200px (full sidebar + grid)
- **Tablet**: 768px - 1200px (collapsed sidebar)
- **Mobile**: < 768px (icon-only sidebar)

### Mobile Optimizations
- Collapsible navigation
- Stack cards vertically
- Touch-friendly buttons (min 44x44px)
- Responsive typography
- Hamburger menu ready

## 🔐 Security Notes

- **No sensitive data** in client-side code
- **API authentication** should be implemented server-side
- **HTTPS recommended** for production
- **Input validation** needed on form submissions
- **CORS configuration** required for API calls

## 🧪 Testing

### Browser Compatibility
- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Mobile browsers

### Test Checklist
- [ ] All navigation links work
- [ ] Forms submit correctly
- [ ] Responsive design on all screen sizes
- [ ] Icons load from CDN
- [ ] No console errors
- [ ] Accessibility (keyboard navigation, screen readers)

## 📝 Future Enhancements

1. **Real-time Updates**: WebSocket integration for live data
2. **Maps Integration**: Google Maps/Leaflet for route visualization
3. **Chart.js**: Add analytics graphs and charts
4. **Push Notifications**: Browser notifications for new rides/alerts
5. **PWA Support**: Make installable as mobile app
6. **Dark Mode**: Toggle between light/dark themes
7. **Multi-language**: i18n support for international use
8. **Print Styles**: Optimized printing for reports

## 🤝 Contributing

To modify these dashboards:

1. Edit files in the `web/` directory
2. Test locally by opening HTML files in browser
3. Run the installer to deploy changes
4. Check all three dashboards after deployment

## 📄 License

Part of the Taxi Management System project.

---

**Note**: These dashboards are designed to be deployed by the `install-taxi-system.sh` script. Make sure the `web/` folder is in the same directory as the installation script.
