# 📱 Viáticos App — Flutter para Android

App de gestión de viáticos, tarjeta CITI, impuestos y gastos mensuales.

---

## 🚀 Cómo obtener el APK (sin instalar nada)

### Paso 1 — Crear repositorio en GitHub
1. Ir a [github.com](https://github.com) e iniciar sesión (o crear cuenta gratuita)
2. Hacer clic en **"New repository"** (botón verde)
3. Nombre: `viaticos-app`
4. Dejarlo en **Público** (necesario para Actions gratuitas)
5. Clic en **"Create repository"**

### Paso 2 — Subir el código
En la página del repositorio vacío, GitHub muestra comandos. Desde tu PC con Git instalado:

```bash
# Dentro de la carpeta viaticos_app
git init
git add .
git commit -m "Primer commit - App Viáticos"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/viaticos-app.git
git push -u origin main
```

> 💡 Si no tenés Git, podés subir los archivos directamente desde el botón **"uploading an existing file"** en GitHub.

### Paso 3 — Esperar la compilación automática
1. Ir a la pestaña **"Actions"** de tu repositorio
2. Vas a ver el workflow **"Build APK - Viáticos App"** ejecutándose
3. Esperar ~5 minutos hasta que aparezca ✅ verde

### Paso 4 — Descargar el APK
1. Hacer clic en el workflow completado
2. En la sección **"Artifacts"** (al final de la página)
3. Clic en **"viaticos-app-release"** para descargar el ZIP
4. Descomprimir → adentro está el **app-release.apk**

### Paso 5 — Instalar en Android
1. Pasar el APK al celular (por USB, WhatsApp, Google Drive, etc.)
2. En el celular ir a **Ajustes → Seguridad → Instalar apps desconocidas**
3. Habilitar la instalación desde el origen que uses (ej: "Mis archivos")
4. Abrir el APK y tocar **Instalar**

---

## 📲 También podés ejecutarlo manualmente

Si ya tenés el repositorio y querés recompilar:
1. Ir a **Actions** → **Build APK - Viáticos App**
2. Clic en **"Run workflow"** → **"Run workflow"**

---

## 🏗️ Estructura del proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── database/
│   └── database_helper.dart     # SQLite + datos iniciales del Excel
├── models/
│   └── models.dart              # Modelos de datos
└── screens/
    ├── home_screen.dart          # Navegación principal
    ├── dashboard_screen.dart     # Panel con saldos
    ├── citi_screen.dart          # Movimientos CITI (CRUD completo)
    ├── impuestos_screen.dart     # Impuestos Delia
    ├── gastos_screen.dart        # Gastos mensuales
    └── resumen_screen.dart       # Análisis y estadísticas
```
