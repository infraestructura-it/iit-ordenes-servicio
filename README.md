# IIT — Sistema de Órdenes de Servicio v1.0

> **Infraestructura-IT · Bogotá, Colombia**  
> Sistema de tickets de Soporte & Mantenimiento con QR, relay.js y dashboard web.

---

## Arquitectura

```
index.html          →  Sandbox: captura 4 datos básicos → genera OS ID → envía QR por email
orden.html          →  Formulario completo (se abre escaneando el QR)
dashboard.html      →  Interface web de todas las órdenes
relay-endpoints.js  →  Endpoints para agregar al relay.js en VPS
chip_sin_fondo.png  →  Logo IIT
```

## Flujo de uso

```
Cliente abre index.html
  └─ llena nombre / teléfono / correo / empresa
  └─ POST /api/orders  → guarda orden "pendiente"
  └─ POST /api/email   → envía correo con QR

Cliente escanea QR con celular
  └─ abre orden.html?orden=IIT-...&nombre=...
  └─ llena 7 secciones completas + firma táctil
  └─ PUT /api/orders/:id → status "enviada"

IIT gestiona desde dashboard.html
  └─ visualiza todas las órdenes
  └─ cambia estado: pendiente → en-proceso → cerrada
```

## Configuración

En los 3 HTML, cambiar la constante `CONFIG.relayUrl`:

```javascript
const CONFIG = {
  relayUrl: 'https://tu-relay.iit.co',   // ← URL real de tu VPS
  ...
};
```

En el VPS, agregar al `.env`:

```env
SMTP_HOST=smtp.gmail.com
SMTP_USER=correo@iit.com.co
SMTP_PASS=app_password_aqui
```

## Deploy en GitHub Pages

```powershell
# Ya incluido en el script de setup
gh repo create infraestructura-it/iit-ordenes-servicio --public
gh api repos/infraestructura-it/iit-ordenes-servicio/pages -X POST -f source.branch=main -f source.path=/
```

URL resultante: `https://infraestructura-it.github.io/iit-ordenes-servicio/`

## Stack

- HTML/CSS/JS vanilla — sin frameworks
- QR generado via `api.qrserver.com`
- Backend: relay.js (Node.js + Express) en VPS
- Storage: `orders.json` en VPS (sin DB externa)
- Email: Nodemailer + SMTP
- Demo mode: funciona con localStorage sin backend

---

*Sistema de Tickets IIT · Versión 1.0 · Abril 2026*
