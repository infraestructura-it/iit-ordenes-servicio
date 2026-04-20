// ════════════════════════════════════════════════════════════════
//  IIT ÓRDENES DE SERVICIO — Endpoints para relay.js
//  Agregar estas rutas al relay.js existente
// ════════════════════════════════════════════════════════════════

// Dependencias adicionales (ya deberías tener express y nodemailer)
// npm install nodemailer
// Agrega en el bloque de requires de tu relay.js:
//   const nodemailer = require('nodemailer');
//   const fs = require('fs');

// ── STORAGE (JSON file — sin DB externa) ──────────────────────
const ORDERS_FILE = './orders.json';

function readOrders() {
  try {
    if (!fs.existsSync(ORDERS_FILE)) return [];
    return JSON.parse(fs.readFileSync(ORDERS_FILE, 'utf8'));
  } catch { return []; }
}

function writeOrders(orders) {
  fs.writeFileSync(ORDERS_FILE, JSON.stringify(orders, null, 2));
}

// ── MAILER ────────────────────────────────────────────────────
// Configura con tu SMTP (Gmail, SendGrid, Brevo, etc.)
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: process.env.SMTP_USER,   // correo@iit.com.co
    pass: process.env.SMTP_PASS    // App Password o SMTP key
  }
});

// ════════════════════════════════════════════════════════════════
//  RUTAS — Pegar dentro del bloque de rutas de relay.js
// ════════════════════════════════════════════════════════════════

// GET /api/orders — Listar todas las órdenes
app.get('/api/orders', (req, res) => {
  const orders = readOrders();
  res.json(orders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));
});

// POST /api/orders — Crear nueva orden (desde sandbox index.html)
app.post('/api/orders', (req, res) => {
  const orders = readOrders();
  const order = {
    ...req.body,
    createdAt: req.body.createdAt || new Date().toISOString(),
    status: req.body.status || 'pendiente'
  };

  // Evitar duplicados por orderId
  const idx = orders.findIndex(o => o.orderId === order.orderId);
  if (idx >= 0) {
    orders[idx] = { ...orders[idx], ...order };
  } else {
    orders.push(order);
  }

  writeOrders(orders);
  console.log(`[OS] Nueva orden creada: ${order.orderId}`);
  res.json({ ok: true, orderId: order.orderId });
});

// PUT /api/orders/:id — Actualizar orden (desde orden.html y dashboard)
app.put('/api/orders/:id', (req, res) => {
  const orders = readOrders();
  const idx = orders.findIndex(o => o.orderId === req.params.id);

  if (idx < 0) {
    // Si no existe, crear
    orders.push({ ...req.body, orderId: req.params.id });
  } else {
    orders[idx] = { ...orders[idx], ...req.body };
  }

  writeOrders(orders);
  console.log(`[OS] Orden actualizada: ${req.params.id} → status: ${req.body.status}`);
  res.json({ ok: true });
});

// GET /api/orders/:id — Obtener una orden específica
app.get('/api/orders/:id', (req, res) => {
  const orders = readOrders();
  const order = orders.find(o => o.orderId === req.params.id);
  if (!order) return res.status(404).json({ error: 'Orden no encontrada' });
  res.json(order);
});

// DELETE /api/orders/:id — Eliminar orden
app.delete('/api/orders/:id', (req, res) => {
  const orders = readOrders();
  const filtered = orders.filter(o => o.orderId !== req.params.id);
  writeOrders(filtered);
  res.json({ ok: true });
});

// POST /api/email — Enviar correo con QR (desde index.html)
app.post('/api/email', async (req, res) => {
  const { to, subject, html, orderId, nombre } = req.body;

  try {
    await transporter.sendMail({
      from: `"IIT Infraestructura-IT" <${process.env.SMTP_USER}>`,
      to,
      subject,
      html
    });

    console.log(`[EMAIL] QR enviado a ${to} para orden ${orderId}`);
    res.json({ ok: true, message: 'Correo enviado' });
  } catch (err) {
    console.error('[EMAIL] Error:', err.message);
    res.status(500).json({ ok: false, error: err.message });
  }
});

// ════════════════════════════════════════════════════════════════
//  VARIABLES DE ENTORNO requeridas (.env en tu VPS)
// ════════════════════════════════════════════════════════════════
/*
  SMTP_HOST=smtp.gmail.com          # o smtp.brevo.com, etc.
  SMTP_USER=correo@iit.com.co
  SMTP_PASS=tu_app_password_aqui

  # Para Gmail: activar "Verificación en 2 pasos" y generar
  # "Contraseña de aplicación" en myaccount.google.com/apppasswords
*/

// ════════════════════════════════════════════════════════════════
//  CORS — Asegúrate de tener este middleware en relay.js
// ════════════════════════════════════════════════════════════════
/*
  app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type,Authorization');
    if (req.method === 'OPTIONS') return res.sendStatus(200);
    next();
  });
*/
