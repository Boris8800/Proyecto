# 🚀 Quick Reference - Magic Links

Guía rápida para usar la autenticación con magic links.

## 📱 Para Usuarios

### Driver Portal
1. Abre: `http://YOUR_IP:3002`
2. Ingresa tu email
3. Click "Send Magic Link"
4. Revisa tu email
5. Click en el enlace
6. ¡Acceso instantáneo!

### Customer App
1. Abre: `http://YOUR_IP:3003`
2. Ingresa tu email
3. Click "Send Magic Link"
4. Revisa tu email
5. Click en el enlace
6. ¡Listo para reservar!

## 🧪 Para Testing (Demo Mode)

### Sin Backend
Los dashboards funcionan en modo demo:

```bash
# Driver
http://localhost:3002
# Ingresa cualquier email → Ver confirmación

# Customer  
http://localhost:3003
# Ingresa cualquier email → Ver confirmación

# Simular magic link (sin email real)
http://localhost:3002?token=demo123
http://localhost:3003?token=demo123
```

## 🔧 Para Desarrolladores

### API Endpoints Necesarios

#### 1. Enviar Magic Link
```http
POST /api/auth/magic-link
Content-Type: application/json

{
  "email": "user@example.com",
  "type": "driver" | "customer"
}

Response: 200 OK
{
  "success": true,
  "message": "Magic link sent",
  "expiresIn": 900
}
```

#### 2. Verificar Magic Link
```http
POST /api/auth/verify-magic-link
Content-Type: application/json

{
  "token": "abc123xyz..."
}

Response: 200 OK
{
  "valid": true,
  "sessionToken": "jwt_token_here",
  "user": {
    "id": "123",
    "email": "user@example.com",
    "type": "driver"
  }
}
```

### Código Frontend (Ya implementado)

```javascript
// Enviar magic link
async function sendMagicLink() {
    const email = document.getElementById('driverEmail').value;
    
    const response = await fetch('/api/auth/magic-link', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, type: 'driver' })
    });
    
    // Mostrar confirmación
    showEmailSent(email);
}

// Verificar token
async function verifyMagicLink(token) {
    const response = await fetch('/api/auth/verify-magic-link', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token })
    });
    
    const data = await response.json();
    
    if (data.valid) {
        localStorage.setItem('authToken', data.sessionToken);
        showDashboard();
    }
}
```

### Backend Example (Node.js + Express)

```javascript
const express = require('express');
const crypto = require('crypto');
const nodemailer = require('nodemailer');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());

// 1. Enviar magic link
app.post('/api/auth/magic-link', async (req, res) => {
    const { email, type } = req.body;
    
    // Generar token
    const token = crypto.randomBytes(32).toString('hex');
    
    // Guardar en DB
    await db.magicTokens.create({
        email,
        token,
        type,
        expiresAt: new Date(Date.now() + 15 * 60 * 1000),
        used: false
    });
    
    // Enviar email
    const magicLink = `${process.env.FRONTEND_URL}/${type}?token=${token}`;
    await sendEmail(email, magicLink);
    
    res.json({ success: true, message: 'Magic link sent', expiresIn: 900 });
});

// 2. Verificar magic link
app.post('/api/auth/verify-magic-link', async (req, res) => {
    const { token } = req.body;
    
    // Buscar token
    const magicToken = await db.magicTokens.findOne({
        token,
        used: false,
        expiresAt: { $gt: new Date() }
    });
    
    if (!magicToken) {
        return res.status(401).json({ valid: false, error: 'Invalid token' });
    }
    
    // Marcar como usado
    await db.magicTokens.updateOne({ token }, { used: true });
    
    // Crear o encontrar usuario
    let user = await db.users.findOne({ email: magicToken.email });
    if (!user) {
        user = await db.users.create({
            email: magicToken.email,
            type: magicToken.type
        });
    }
    
    // Generar JWT
    const sessionToken = jwt.sign(
        { userId: user.id, email: user.email },
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

app.listen(3000);
```

## 📧 Email Template

```html
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; background: #f5f5f5; padding: 20px;">
    <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 10px; overflow: hidden;">
        <!-- Header -->
        <div style="background: linear-gradient(135deg, #4facfe, #00f2fe); padding: 40px; text-align: center;">
            <h1 style="color: white; margin: 0;">🚕 Your Magic Link</h1>
        </div>
        
        <!-- Content -->
        <div style="padding: 40px;">
            <h2>Sign in to TaxiSystem</h2>
            <p>Click the button below to sign in instantly. No password needed!</p>
            
            <div style="text-align: center; margin: 30px 0;">
                <a href="{{MAGIC_LINK}}" 
                   style="display: inline-block; 
                          padding: 15px 30px; 
                          background: #4facfe; 
                          color: white; 
                          text-decoration: none; 
                          border-radius: 8px; 
                          font-weight: bold;">
                    Sign In Now
                </a>
            </div>
            
            <p style="color: #666; font-size: 14px;">
                This link expires in 15 minutes and can only be used once.
            </p>
        </div>
        
        <!-- Footer -->
        <div style="padding: 20px; text-align: center; color: #666; font-size: 14px; border-top: 1px solid #eee;">
            <p>© 2025 TaxiSystem. Secure passwordless authentication.</p>
        </div>
    </div>
</body>
</html>
```

## 🗄️ Base de Datos

### MongoDB Schema

```javascript
// Collection: magic_tokens
{
    _id: ObjectId,
    email: String,          // "user@example.com"
    token: String,          // "abc123..." (unique, indexed)
    type: String,           // "driver" | "customer"
    expiresAt: Date,        // 15 min desde creación
    used: Boolean,          // false inicialmente
    usedAt: Date,           // cuando se usa
    createdAt: Date,
    ipAddress: String,
    userAgent: String
}

// Indexes
db.magic_tokens.createIndex({ token: 1 }, { unique: true });
db.magic_tokens.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
```

## ⚙️ Variables de Entorno

```bash
# .env
JWT_SECRET=your-super-secret-key-minimum-32-chars
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-specific-password
FRONTEND_URL=https://yourdomain.com
MAGIC_LINK_EXPIRY=900  # 15 minutos
```

## 🔐 Seguridad Checklist

- [ ] Tokens con crypto.randomBytes (32 bytes)
- [ ] Expiración de 15 minutos
- [ ] Un solo uso por token
- [ ] Rate limiting (3 intentos / 15 min)
- [ ] HTTPS en producción
- [ ] Validación de email
- [ ] JWT con expiración (7 días)
- [ ] Logging de intentos
- [ ] IP tracking opcional

## 📊 Estados HTTP

```
200 OK        - Magic link enviado / Token válido
400 Bad Request - Email inválido
401 Unauthorized - Token inválido o expirado
429 Too Many Requests - Rate limit excedido
500 Server Error - Error del servidor
```

## 🧪 Comandos de Testing

```bash
# Test envío de magic link (curl)
curl -X POST http://localhost:3000/api/auth/magic-link \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","type":"driver"}'

# Test verificación de token
curl -X POST http://localhost:3000/api/auth/verify-magic-link \
  -H "Content-Type: application/json" \
  -d '{"token":"abc123xyz"}'
```

## 📱 URLs de Acceso

```bash
# Producción
https://taxi.com/driver
https://taxi.com/customer

# Desarrollo
http://localhost:3002  # Driver
http://localhost:3003  # Customer

# Con token (desde email)
https://taxi.com/driver?token=abc123...
https://taxi.com/customer?token=abc123...
```

## 🔄 Flujo Completo

```
1. Usuario → email → Click "Send"
2. Frontend → POST /api/auth/magic-link
3. Backend → Genera token → Guarda en DB → Envía email
4. Usuario → Recibe email → Click enlace
5. Browser → Abre URL?token=...
6. Frontend → Detecta token → POST /api/auth/verify-magic-link
7. Backend → Verifica → Marca usado → Retorna JWT
8. Frontend → Guarda JWT → Muestra dashboard
9. ✅ ACCESO CONCEDIDO
```

## 📚 Documentación Completa

- **MAGIC_LINKS_AUTH.md** - Guía completa (15KB)
- **MAGIC_LINKS_IMPLEMENTATION.md** - Resumen de implementación
- **web/README.md** - Documentación de dashboards

---

**Última actualización**: Diciembre 2025  
**Status**: ✅ Frontend completo | ⏳ Backend pendiente  
**Versión**: 2.1.0
