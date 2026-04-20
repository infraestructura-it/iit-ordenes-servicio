# ════════════════════════════════════════════════════════════════
#  IIT — Setup Sistema de Órdenes de Servicio v1.0
#  Ejecutar desde PowerShell en:
#  C:\Users\User01\OneDrive\2026-proyectos\
# ════════════════════════════════════════════════════════════════

# ── PASO 1: Crear directorio local ───────────────────────────────
$proyectos = "C:\Users\User01\OneDrive\2026-proyectos"
$proyecto  = "iit-ordenes-servicio"
$ruta      = Join-Path $proyectos $proyecto

Write-Host ""
Write-Host "══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  IIT — Órdenes de Servicio v1.0" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if (Test-Path $ruta) {
    Write-Host "⚠  Directorio ya existe: $ruta" -ForegroundColor Yellow
} else {
    New-Item -ItemType Directory -Path $ruta | Out-Null
    Write-Host "✓  Directorio creado: $ruta" -ForegroundColor Green
}

Set-Location $ruta
Write-Host "✓  Ubicación actual: $(Get-Location)" -ForegroundColor Green

# ── PASO 2: Descargar archivos desde GitHub Pages / Claude ───────
Write-Host ""
Write-Host "── Descargando archivos del proyecto..." -ForegroundColor Cyan

# URL base — CAMBIAR si publicas en otro repo primero
# Por ahora descargamos desde las URLs de descarga de Claude
# (Ajusta estas URLs a donde tengas los archivos disponibles)

$archivos = @(
    "index.html",
    "orden.html",
    "dashboard.html",
    "relay-endpoints.js",
    "chip_sin_fondo.png",
    "README.md"
)

# Si tienes los archivos en una carpeta local (ej: Descargas), cópialos:
$origen = "$env:USERPROFILE\Downloads\iit-ordenes-servicio"

if (Test-Path $origen) {
    Write-Host "  Copiando desde $origen..." -ForegroundColor Gray
    foreach ($archivo in $archivos) {
        $src = Join-Path $origen $archivo
        if (Test-Path $src) {
            Copy-Item $src $ruta -Force
            Write-Host "  ✓ $archivo" -ForegroundColor Green
        } else {
            Write-Host "  ✗ No encontrado: $archivo" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  ⚠  Carpeta de origen no encontrada." -ForegroundColor Yellow
    Write-Host "  → Copia manualmente los archivos descargados de Claude a:" -ForegroundColor Yellow
    Write-Host "     $ruta" -ForegroundColor White
    Write-Host ""
    Write-Host "  Presiona ENTER cuando los archivos estén en la carpeta..." -ForegroundColor Cyan
    Read-Host
}

# Verificar que los archivos estén
Write-Host ""
Write-Host "── Archivos en el directorio:" -ForegroundColor Cyan
Get-ChildItem $ruta | Format-Table Name, Length, LastWriteTime -AutoSize

# ── PASO 3: Inicializar Git ──────────────────────────────────────
Write-Host ""
Write-Host "── Inicializando repositorio Git..." -ForegroundColor Cyan

git init
git checkout -b main 2>$null
if ($LASTEXITCODE -ne 0) { git checkout -b main }

# .gitignore
@"
node_modules/
.env
*.log
orders.json
.DS_Store
Thumbs.db
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8

git add .
git commit -m "feat: IIT Sistema de Ordenes de Servicio v1.0

- index.html: sandbox captura datos basicos + envio QR
- orden.html: formulario completo 7 secciones + firma tactil
- dashboard.html: interface web gestion de ordenes
- relay-endpoints.js: endpoints para relay.js VPS
- Logo chip IIT integrado en los 3 HTML
- Modo demo con localStorage (sin backend requerido)"

Write-Host "✓  Commit inicial creado" -ForegroundColor Green

# ── PASO 4: Crear repo en GitHub ─────────────────────────────────
Write-Host ""
Write-Host "── Creando repositorio en GitHub..." -ForegroundColor Cyan

gh repo create infraestructura-it/iit-ordenes-servicio `
    --public `
    --description "IIT Sistema de Tickets - Ordenes de Servicio v1.0 con QR y dashboard" `
    --source . `
    --remote origin `
    --push

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓  Repo creado y archivos subidos" -ForegroundColor Green
} else {
    Write-Host "⚠  Intentando método alternativo..." -ForegroundColor Yellow
    gh repo create infraestructura-it/iit-ordenes-servicio --public --description "IIT Sistema de Tickets v1.0"
    git remote add origin "https://github.com/infraestructura-it/iit-ordenes-servicio.git"
    git push -u origin main
}

# ── PASO 5: Activar GitHub Pages ─────────────────────────────────
Write-Host ""
Write-Host "── Activando GitHub Pages..." -ForegroundColor Cyan

Start-Sleep -Seconds 3   # Esperar a que el repo quede disponible en la API

gh api repos/infraestructura-it/iit-ordenes-servicio/pages `
    -X POST `
    -f "source[branch]=main" `
    -f "source[path]=/" `
    2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓  GitHub Pages activado" -ForegroundColor Green
} else {
    Write-Host "⚠  Activando Pages manualmente (puede que ya esté activo)..." -ForegroundColor Yellow
    gh api repos/infraestructura-it/iit-ordenes-servicio/pages `
        -X POST `
        --input - << '{"source":{"branch":"main","path":"/"}}'
}

# ── PASO 6: Resumen final ────────────────────────────────────────
Write-Host ""
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✓  SETUP COMPLETO" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Directorio local:" -ForegroundColor White
Write-Host "  $ruta" -ForegroundColor Gray
Write-Host ""
Write-Host "  Repositorio GitHub:" -ForegroundColor White
Write-Host "  https://github.com/infraestructura-it/iit-ordenes-servicio" -ForegroundColor Cyan
Write-Host ""
Write-Host "  GitHub Pages (activo en ~2 minutos):" -ForegroundColor White
Write-Host "  https://infraestructura-it.github.io/iit-ordenes-servicio/" -ForegroundColor Cyan
Write-Host ""
Write-Host "  SIGUIENTE PASO: Editar CONFIG.relayUrl en los 3 HTML" -ForegroundColor Yellow
Write-Host "  Busca: 'https://tu-relay.iit.co'" -ForegroundColor Gray
Write-Host "  Reemplaza con tu URL real del VPS" -ForegroundColor Gray
Write-Host ""
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Cyan
