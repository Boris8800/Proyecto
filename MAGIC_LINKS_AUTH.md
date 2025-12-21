# 🔐 Magic Links Authentication

Autenticación sin contraseña para Driver y Customer dashboards.

## 🎯 ¿Qué son los Magic Links?

Los **Magic Links** (Enlaces Mágicos) son un método de autenticación **passwordless** (sin contraseña) donde:

1. El usuario ingresa su email
2. Se envía un enlace único por correo
3. El usuario hace clic en el enlace
4. Acceso instantáneo sin contraseña

### ✅ Ventajas
- **Sin contraseñas**: No hay que recordar passwords
- **Más seguro**: Tokens de un solo uso con expiración
- **Mejor UX**: Un solo clic para acceder
- **Menos soporte**: No hay "olvidé mi contraseña"
- **Mobile-friendly**: Funciona perfecto en móviles

---

## 📱 Implementación

### Driver Portal (web/driver/)

#### Pantalla de Login
```html
<div class="magic-link-container" id="loginScreen">
    <div class="magic-link-card">
        <div class="magic-link-header">
            <i class="fas fa-taxi"></i>
            <h1>Driver Portal</h1>
            <p>Sign in with magic link</p>
        </div>
        
        <form id="magicLinkForm">
            <input type="email" id="driverEmail" required>
            <button type="submit">
                <i class="fas fa-paper-plane"></i>
                Send Magic Link
            </button>
        </form>
        
        <div id="emailSent" style="display: none;">
            <i class="fas fa-check-circle"></i>
            <h3>Check your email!</h3>
            <p>We've sent a magic link to <strong id="sentEmailAddress"></strong></p>
        </div>
    </div>
</div>
```

#### Flujo de Autenticación
```javascript
// 1. Enviar magic link
function sendMagicLink() {
    const email = document.getElementById('driverEmail').value;
    
    // Llamada API
    fetch('/api/auth/magic-link', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
            email: email,
            type: 'driver',
            redirectUrl: window.location.origin + '/driver'
        })
    });
}

// 2. Verificar token del enlace
function verifyMagicLink(token) {
    fetch('/api/auth/verify-magic-link', {
        method: 'POST',
        body: JSON.stringify({ token })
    })
    .then(response => response.json())
    .then(data => {
        if (data.valid) {
            // Guardar token de sesión
            localStorage.setItem('driverAuthToken', data.sessionToken);
            // Mostrar dashboard
            showDashboard();
        }
    });
}
```

---

### Customer App (web/customer/)

#### Pantalla de Login
```html
<div class="magic-link-container" id="loginScreen">
    <div class="magic-link-card">
        <div class="magic-link-header">
            <i class="fas fa-taxi"></i>
            <h1>QuickRide</h1>
            <p>Sign in with magic link</p>
        </div>
        
        <form id="magicLinkForm">
            <input type="email" id="customerEmail" required>
            <button type="submit">
                <i class="fas fa-paper-plane"></i>
                Send Magic Link
            </button>
            
            <!-- Beneficios visibles -->
            <div class="magic-link-benefits">
                <p><i class="fas fa-lock"></i> No password required</p>
                <p><i class="fas fa-bolt"></i> Instant access</p>
                <p><i class="fas fa-shield-alt"></i> More secure</p>
            </div>
        </form>
        
        <div class="magic-link-footer">
            <p><i class="fas fa-info-circle"></i> New here? Magic links work for signup too!</p>
        </div>
    </div>
</div>
```

---

## 🔧 Backend API Endpoints

### 1. Generar Magic Link

**Endpoint**: `POST /api/auth/magic-link`

**Request**:
```json
{
    "email": "user@example.com",
    "type": "driver" | "customer",
    "redirectUrl": "https://taxi.com/driver"
}
```

**Response**:
```json
{
    "success": true,
    "message": "Magic link sent to user@example.com",
    "expiresIn": 900
}
```

**Lógica Backend** (Node.js ejemplo):
```javascript
const crypto = require('crypto');
const nodemailer = require('nodemailer');

app.post('/api/auth/magic-link', async (req, res) => {
    const { email, type, redirectUrl } = req.body;
    
    // 1. Generar token único
    const token = crypto.randomBytes(32).toString('hex');
    
    // 2. Guardar en base de datos con expiración (15 min)
    await db.magicTokens.create({
        email,
        token,
        type,
        expiresAt: new Date(Date.now() + 15 * 60 * 1000),
        used: false
    });
    
    // 3. Crear enlace
    const magicLink = `${redirectUrl}?token=${token}`;
    
    // 4. Enviar email
    await sendEmail({
        to: email,
        subject: 'Your Magic Link to Sign In',
        html: `
            <h2>Click to sign in</h2>
            <p>Click the button below to sign in to your account:</p>
            <a href="${magicLink}" style="...">Sign In Now</a>
            <p>This link expires in 15 minutes.</p>
        `
    });
    
    res.json({ success: true, message: 'Magic link sent' });
});
```

---

### 2. Verificar Magic Link

**Endpoint**: `POST /api/auth/verify-magic-link`

**Request**:
```json
{
    "token": "abc123..."
}
```

**Response**:
```json
{
    "valid": true,
    "sessionToken": "xyz789...",
    "user": {
        "id": "123",
        "email": "user@example.com",
        "type": "driver"
    }
}
```

**Lógica Backend**:
```javascript
app.post('/api/auth/verify-magic-link', async (req, res) => {
    const { token } = req.body;
    
    // 1. Buscar token
    const magicToken = await db.magicTokens.findOne({ 
        token,
        used: false,
        expiresAt: { $gt: new Date() }
    });
    
    if (!magicToken) {
        return res.status(401).json({ 
            valid: false, 
            error: 'Invalid or expired token' 
        });
    }
    
    // 2. Marcar como usado
    await db.magicTokens.update({ token }, { used: true });
    
    // 3. Buscar o crear usuario
    let user = await db.users.findOne({ email: magicToken.email });
    if (!user) {
        user = await db.users.create({
            email: magicToken.email,
            type: magicToken.type,
            createdAt: new Date()
        });
    }
    
    // 4. Generar sesión JWT
    const sessionToken = jwt.sign(
        { userId: user.id, email: user.email, type: user.type },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
    );
    
    res.json({ 
        valid: true, 
        sessionToken,
        user: {
            id: user.id,
            email: user.email,
            type: user.type
        }
    });
});
```

---

## 📧 Email Template

### HTML Email Template

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; background: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; }
        .header { background: linear-gradient(135deg, #4facfe, #00f2fe); padding: 40px; text-align: center; }
        .header h1 { color: white; margin: 0; }
        .content { padding: 40px; }
        .button { display: inline-block; padding: 15px 30px; background: #4facfe; color: white; text-decoration: none; border-radius: 8px; font-weight: bold; }
        .footer { padding: 20px; text-align: center; color: #666; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚕 Your Magic Link</h1>
        </div>
        <div class="content">
            <h2>Sign in to TaxiSystem</h2>
            <p>Click the button below to sign in instantly. No password needed!</p>
            
            <p style="text-align: center; margin: 30px 0;">
                <a href="{{MAGIC_LINK}}" class="button">
                    Sign In Now
                </a>
            </p>
            
            <p style="color: #666; font-size: 14px;">
                This link will expire in 15 minutes and can only be used once.
            </p>
            
            <p style="color: #666; font-size: 14px;">
                If you didn't request this link, you can safely ignore this email.
            </p>
        </div>
        <div class="footer">
            <p>© 2025 TaxiSystem. Secure passwordless authentication.</p>
        </div>
    </div>
</body>
</html>
```

---

## 🔒 Seguridad

### Best Practices Implementadas

#### 1. **Tokens Únicos y Seguros**
```javascript
// Usar crypto para generar tokens aleatorios
const token = crypto.randomBytes(32).toString('hex');
// Resultado: "a1b2c3d4e5f6..." (64 caracteres)
```

#### 2. **Expiración Corta**
```javascript
// Token expira en 15 minutos
expiresAt: new Date(Date.now() + 15 * 60 * 1000)
```

#### 3. **Un Solo Uso**
```javascript
// Marcar token como usado después de verificar
await db.magicTokens.update({ token }, { used: true });
```

#### 4. **Rate Limiting**
```javascript
// Limitar solicitudes por IP
const rateLimit = require('express-rate-limit');

const magicLinkLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 3, // 3 intentos máximo
    message: 'Too many requests, please try again later'
});

app.post('/api/auth/magic-link', magicLinkLimiter, async (req, res) => {
    // ...
});
```

#### 5. **HTTPS Obligatorio**
```javascript
// Forzar HTTPS en producción
if (process.env.NODE_ENV === 'production' && req.protocol !== 'https') {
    return res.redirect('https://' + req.hostname + req.url);
}
```

#### 6. **Verificación de Email**
```javascript
// Validar formato de email
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
if (!emailRegex.test(email)) {
    return res.status(400).json({ error: 'Invalid email format' });
}
```

---

## 💾 Estructura de Base de Datos

### MongoDB Collection: magic_tokens

```javascript
{
    _id: ObjectId("..."),
    email: "user@example.com",
    token: "a1b2c3d4e5f6...",
    type: "driver", // or "customer"
    createdAt: ISODate("2025-12-21T00:00:00Z"),
    expiresAt: ISODate("2025-12-21T00:15:00Z"),
    used: false,
    usedAt: null,
    ipAddress: "192.168.1.1",
    userAgent: "Mozilla/5.0..."
}
```

### Index para Performance
```javascript
db.magic_tokens.createIndex({ token: 1 }, { unique: true });
db.magic_tokens.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // TTL index
db.magic_tokens.createIndex({ email: 1, createdAt: -1 });
```

---

## 🎨 Diseño UI/UX

### Colores
- **Primary**: `#4facfe` (Azul)
- **Success**: `#00d084` (Verde)
- **Background**: Gradient linear

### Animaciones
```css
@keyframes slideUp {
    from {
        opacity: 0;
        transform: translateY(30px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.magic-link-card {
    animation: slideUp 0.5s ease-out;
}
```

### Estados Visuales
1. **Form inicial**: Email input + botón "Send Magic Link"
2. **Enviando**: Spinner + "Sending..."
3. **Email enviado**: ✅ Check + mensaje de confirmación
4. **Verificando**: Spinner + "Verifying your magic link..."
5. **Acceso concedido**: Dashboard visible

---

## 🧪 Testing

### Demo Mode (Frontend)

Para testing sin backend, ambos dashboards incluyen simulación:

```javascript
// Simular envío de email (1.5s delay)
setTimeout(() => {
    document.querySelector('.magic-form').style.display = 'none';
    document.getElementById('emailSent').style.display = 'block';
}, 1500);

// Simular verificación de token (1.5s delay)
setTimeout(() => {
    document.getElementById('loginScreen').style.display = 'none';
    document.getElementById('mainDashboard').style.display = 'flex';
}, 1500);
```

### Testing con Token

Para probar el flujo completo:

1. **Driver**: Abrir `http://localhost:3002?token=test123`
2. **Customer**: Abrir `http://localhost:3003?token=test123`

El dashboard detectará el parámetro `token` y ejecutará la verificación automáticamente.

---

## 🚀 Deployment

### Variables de Entorno Necesarias

```bash
# .env
JWT_SECRET=your-super-secret-key-here
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_FROM=noreply@taxisystem.com
MAGIC_LINK_EXPIRY=900  # 15 minutos en segundos
FRONTEND_URL=https://taxisystem.com
```

### Configuración SMTP (Gmail)

```javascript
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT,
    secure: false, // true para 465, false para otros puertos
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
    }
});
```

---

## 📊 Métricas Recomendadas

### Tracking de Autenticación

```javascript
// Eventos a trackear:
analytics.track('magic_link_requested', {
    email: email,
    type: type,
    timestamp: new Date()
});

analytics.track('magic_link_sent', {
    email: email,
    deliveryStatus: 'sent'
});

analytics.track('magic_link_clicked', {
    email: email,
    timeFromSend: timeDiff
});

analytics.track('magic_link_verified', {
    email: email,
    success: true
});
```

### KPIs Importantes
- **Tasa de conversión**: Links enviados vs verificados
- **Tiempo promedio**: Desde envío hasta verificación
- **Tasa de expiración**: Links que expiran sin uso
- **Reenvíos**: Cuántos usuarios reenvían el link

---

## 🔄 Flujo Completo

```
1. Usuario → Ingresa email → Click "Send Magic Link"
                ↓
2. Frontend → POST /api/auth/magic-link
                ↓
3. Backend → Genera token → Guarda en DB → Envía email
                ↓
4. Usuario → Recibe email → Click en enlace
                ↓
5. Browser → Abre URL con ?token=... 
                ↓
6. Frontend → Detecta token → POST /api/auth/verify-magic-link
                ↓
7. Backend → Verifica token → Marca como usado → Genera JWT
                ↓
8. Frontend → Guarda JWT → Muestra dashboard
                ↓
9. Usuario → Acceso concedido ✅
```

---

## 📝 Checklist de Implementación

### Frontend ✅
- [x] Pantalla de login con email input
- [x] Mensaje "email enviado"
- [x] Detección de token en URL
- [x] Verificación de token
- [x] Transición a dashboard
- [x] Botón "Reenviar enlace"
- [x] Animaciones y estados de carga

### Backend (Pendiente)
- [ ] Endpoint POST /api/auth/magic-link
- [ ] Endpoint POST /api/auth/verify-magic-link
- [ ] Generación de tokens seguros
- [ ] Almacenamiento en MongoDB
- [ ] Configuración SMTP
- [ ] Template de email HTML
- [ ] Rate limiting
- [ ] Logging y analytics

### Seguridad
- [ ] HTTPS en producción
- [ ] Validación de email
- [ ] Expiración de tokens (15 min)
- [ ] Tokens de un solo uso
- [ ] Rate limiting (3 intentos/15 min)
- [ ] JWT para sesiones
- [ ] Sanitización de inputs

---

## 🎓 Recursos Adicionales

- [Auth0: Magic Links Guide](https://auth0.com/docs/connections/passwordless)
- [OWASP: Passwordless Authentication](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [Nodemailer Documentation](https://nodemailer.com/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)

---

**Implementado en**: Driver Portal + Customer App  
**Última actualización**: Diciembre 2025  
**Status**: ✅ Frontend completo, Backend pendiente
