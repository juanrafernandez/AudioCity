# FASE 0: SEGURIDAD Y LIMPIEZA - CHECKLIST EJECUTIVO
## ⚠️ TAREAS CRÍTICAS - EJECUTAR INMEDIATAMENTE

**Deadline:** 3 días máximo
**Responsable:** Lead Developer
**Prioridad:** CRÍTICA 🔴

---

## 🔐 1. SEGURIDAD DE CREDENCIALES

### 1.1 Eliminar GoogleService-Info.plist del repositorio

```bash
# En tu terminal, desde la raíz del proyecto:
cd /Users/juanrafernandez/Documents/GitHub/AudioCity

# Eliminar del índice de git (pero mantener el archivo local)
git rm --cached AudioCityPOC/GoogleService-Info.plist

# Hacer backup del archivo antes de cualquier operación
cp AudioCityPOC/GoogleService-Info.plist ~/Desktop/GoogleService-Info.plist.backup

# Commit del cambio
git commit -m "security: Remove GoogleService-Info.plist from repository"
```

### 1.2 Crear archivo .gitignore

```bash
# Crear/actualizar .gitignore en la raíz
cat > .gitignore << 'EOF'
# Firebase Credentials
**/GoogleService-Info.plist
firebase-credentials.json
firebase-adminsdk-*.json

# Environment Variables
.env
.env.local
.env.*.local
Secrets.plist
secrets.xcconfig

# Build folders
DerivedData/
build/
*.xcarchive

# Xcode User State
*.xcuserstate
*.xcuserdatad
xcuserdata/
*.xcworkspace/xcuserdata/

# Snapshots and Screenshots
snapshots/
screenshots/
*.png
*.jpg
*.jpeg
# Exception: keep assets
!Assets.xcassets/**/*.png
!Assets.xcassets/**/*.jpg

# macOS
.DS_Store
.AppleDouble
.LSOverride

# Thumbnails
._*

# Files that might appear on external disk
.Spotlight-V100
.Trashes

# Pods (if using CocoaPods)
Pods/
*.xcworkspace

# Carthage
Carthage/Build/

# Swift Package Manager
.swiftpm/
.build/

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Code coverage
*.gcda
*.gcno
*.profdata

# Backup files
*.backup
*.bak
*~
EOF

# Commit del .gitignore
git add .gitignore
git commit -m "chore: Add comprehensive .gitignore"
```

### 1.3 Crear plantilla de GoogleService-Info.plist

```bash
# Crear archivo plantilla
cat > AudioCityPOC/GoogleService-Info.plist.template << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CLIENT_ID</key>
	<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
	<key>REVERSED_CLIENT_ID</key>
	<string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
	<key>API_KEY</key>
	<string>YOUR_API_KEY</string>
	<key>GCM_SENDER_ID</key>
	<string>YOUR_SENDER_ID</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>com.audiocity.poc</string>
	<key>PROJECT_ID</key>
	<string>your-project-id</string>
	<key>STORAGE_BUCKET</key>
	<string>your-project-id.appspot.com</string>
	<key>IS_ADS_ENABLED</key>
	<false/>
	<key>IS_ANALYTICS_ENABLED</key>
	<false/>
	<key>IS_APPINVITE_ENABLED</key>
	<true/>
	<key>IS_GCM_ENABLED</key>
	<true/>
	<key>IS_SIGNIN_ENABLED</key>
	<true/>
	<key>GOOGLE_APP_ID</key>
	<string>1:YOUR_APP_ID:ios:YOUR_IOS_ID</string>
</dict>
</plist>
EOF

# Commit de la plantilla
git add AudioCityPOC/GoogleService-Info.plist.template
git commit -m "docs: Add GoogleService-Info.plist template"
```

### 1.4 Actualizar README con instrucciones

```bash
cat >> README.md << 'EOF'

## 🔧 Setup de Desarrollo

### Prerequisitos
- Xcode 15.0+
- iOS 16.0+ deployment target
- Firebase account

### Configuración Inicial

1. **Firebase Credentials:**
   ```bash
   # Copiar la plantilla
   cp AudioCityPOC/GoogleService-Info.plist.template AudioCityPOC/GoogleService-Info.plist

   # Editar con tus credenciales de Firebase
   # Obtener desde: https://console.firebase.google.com/
   ```

2. **Instalación:**
   ```bash
   # Abrir el proyecto
   open AudioCityPOC/AudioCityPOC.xcodeproj

   # Build el proyecto (⌘+B)
   ```

3. **Verificar:**
   - El archivo `GoogleService-Info.plist` NO debe aparecer en git
   - Verificar con: `git status` (no debe listarse)

### ⚠️ NUNCA COMMITEAR:
- `GoogleService-Info.plist`
- `firebase-credentials.json`
- Archivos en `/snapshots/`
EOF

git add README.md
git commit -m "docs: Add setup instructions for Firebase credentials"
```

### 1.5 Limpiar historial de Git (OPCIONAL - CUIDADO)

⚠️ **ADVERTENCIA:** Esta operación reescribe el historial. Solo ejecutar si:
- El repositorio es privado
- Has coordinado con todo el equipo
- Tienes backup completo

```bash
# SOLO SI ES ABSOLUTAMENTE NECESARIO
# Usar BFG Repo-Cleaner (más seguro que filter-branch)

# Instalar BFG
brew install bfg

# Hacer backup completo
cd /Users/juanrafernandez/Documents/GitHub
tar -czf AudioCity-backup-$(date +%Y%m%d).tar.gz AudioCity/

# Ejecutar BFG para eliminar GoogleService-Info.plist del historial
cd AudioCity
bfg --delete-files GoogleService-Info.plist

# Limpiar refs
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (REQUIERE COORDINACIÓN CON EQUIPO)
# git push origin --force --all
```

**ALTERNATIVA RECOMENDADA:**
- Dejar el historial como está
- Rotar las credenciales de Firebase (siguiente paso)
- El archivo ya no se commitea en adelante

---

## 🔑 2. ROTAR CREDENCIALES DE FIREBASE

### 2.1 En Firebase Console

1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Seleccionar tu proyecto
3. **Settings** → **General**
4. Scroll a **Your apps** → iOS app
5. Click en **⚙️** → **Eliminar app** (si el proyecto es de prueba)

   **O si es producción:**

6. **Settings** → **Service accounts** → **Generate new private key**
7. Regenerar todas las API keys

### 2.2 Actualizar configuración local

```bash
# Descargar nuevo GoogleService-Info.plist
# Desde Firebase Console → Settings → Your apps → iOS → Download

# Reemplazar archivo local (NO COMMITEAR)
cp ~/Downloads/GoogleService-Info.plist AudioCityPOC/GoogleService-Info.plist

# Verificar que NO esté en git
git status  # No debe aparecer
```

---

## 🗑️ 3. LIMPIEZA DE ARCHIVOS INNECESARIOS

### 3.1 Eliminar carpeta snapshots/

```bash
cd /Users/juanrafernandez/Documents/GitHub/AudioCity/AudioCityPOC

# Verificar contenido antes de eliminar
ls -lh snapshots/

# Hacer backup si quieres conservar las imágenes
mkdir -p ~/Desktop/audiocity-snapshots-backup
cp -r snapshots/ ~/Desktop/audiocity-snapshots-backup/

# Eliminar del repositorio
git rm -r snapshots/

# Commit
git commit -m "chore: Remove snapshots folder (12.5 MB)"
```

### 3.2 Eliminar duplicación de RouteActivityAttributes.swift

```bash
# Verificar cuál archivo usar
# Mantener: AudioCityPOC/Models/RouteActivityAttributes.swift
# Eliminar: RouteActivityWidget/RouteActivityAttributes.swift

# Hacer backup
cp RouteActivityWidget/RouteActivityAttributes.swift ~/Desktop/RouteActivityAttributes.swift.backup

# Eliminar duplicado
git rm RouteActivityWidget/RouteActivityAttributes.swift

# Actualizar target membership en Xcode:
# 1. Abrir Xcode
# 2. Seleccionar AudioCityPOC/Models/RouteActivityAttributes.swift
# 3. File Inspector → Target Membership
# 4. ✅ AudioCityPOC
# 5. ✅ RouteActivityWidgetExtension

# Commit
git commit -m "refactor: Remove duplicate RouteActivityAttributes.swift"
```

### 3.3 Limpiar headers duplicados

Abrir en Xcode y limpiar manualmente:
- `Route.swift` - Eliminar header duplicado (líneas 1-7 duplicadas)
- `LocationService.swift` - Verificar header
- `AudioService.swift` - Verificar header

```bash
# Después de limpiar en Xcode:
git add AudioCityPOC/AudioCityPOC/Models/Route.swift
git add AudioCityPOC/AudioCityPOC/Services/LocationService.swift
git add AudioCityPOC/AudioCityPOC/Services/AudioService.swift
git commit -m "fix: Clean duplicate file headers"
```

---

## 📋 4. CREAR CONFIGURACIÓN POR ENTORNOS

### 4.1 Crear archivos de configuración

```bash
cd AudioCityPOC

# Crear carpeta de configuración
mkdir -p Config

# Development config
cat > Config/Development.xcconfig << 'EOF'
// Development Configuration
PRODUCT_BUNDLE_IDENTIFIER = com.audiocity.poc.dev
PRODUCT_NAME = AudioCity Dev
FIREBASE_PLIST_NAME = GoogleService-Info-Dev
APP_ENVIRONMENT = Development
EOF

# Staging config
cat > Config/Staging.xcconfig << 'EOF'
// Staging Configuration
PRODUCT_BUNDLE_IDENTIFIER = com.audiocity.poc.staging
PRODUCT_NAME = AudioCity Staging
FIREBASE_PLIST_NAME = GoogleService-Info-Staging
APP_ENVIRONMENT = Staging
EOF

# Production config
cat > Config/Production.xcconfig << 'EOF'
// Production Configuration
PRODUCT_BUNDLE_IDENTIFIER = com.audiocity.poc
PRODUCT_NAME = AudioCity
FIREBASE_PLIST_NAME = GoogleService-Info
APP_ENVIRONMENT = Production
EOF

# Commit configs
git add Config/
git commit -m "feat: Add configuration files for environments"
```

### 4.2 Configurar en Xcode

1. Abrir proyecto en Xcode
2. Seleccionar proyecto (raíz)
3. **Info** tab
4. Expandir **Configurations**
5. Para cada configuración (Debug, Release):
   - Click en nombre
   - Seleccionar archivo .xcconfig correspondiente

---

## ✅ 5. VERIFICACIÓN FINAL

### Checklist de seguridad:

```bash
# 1. Verificar que GoogleService-Info.plist NO está en git
git ls-files | grep GoogleService-Info.plist
# Output esperado: (vacío)

# 2. Verificar que .gitignore contiene las exclusiones
cat .gitignore | grep -E "(GoogleService|snapshots|.env)"
# Output esperado: debe listar esas líneas

# 3. Verificar tamaño del repositorio (debe haber reducido)
du -sh .git
# Comparar con el tamaño anterior

# 4. Verificar que no hay archivos grandes
git ls-files | xargs ls -lh | sort -k5 -hr | head -20

# 5. Verificar que el proyecto compila
cd AudioCityPOC
xcodebuild -project AudioCityPOC.xcodeproj -scheme AudioCityPOC -destination 'platform=iOS Simulator,name=iPhone 17' clean build
```

### Tests de seguridad:

```bash
# Buscar posibles secretos expuestos
git grep -i "api[_-]key"
git grep -i "secret"
git grep -i "password"
git grep -i "token"

# Si encuentra algo sospechoso, investigar y eliminar
```

---

## 📤 6. PUSH DE CAMBIOS

### Solo cuando hayas completado TODO lo anterior:

```bash
# Verificar cambios
git status
git log --oneline -10

# Push a la rama actual
git push origin feature/design-system-v2

# O crear rama específica para seguridad
git checkout -b security/remove-credentials
git push origin security/remove-credentials

# Crear Pull Request en GitHub con título:
# "🔐 CRITICAL: Remove credentials and sensitive files from repository"
```

---

## 📝 DOCUMENTACIÓN ADICIONAL

### Crear SECURITY.md

```bash
cat > SECURITY.md << 'EOF'
# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in AudioCity, please email security@audiocity.app

**Please do NOT:**
- Open a public GitHub issue
- Post in discussions or forums

## Secure Development Practices

### Credentials
- Never commit `GoogleService-Info.plist` to the repository
- Use environment variables for sensitive data
- Rotate keys if accidentally exposed

### Code Review
- All code changes require review
- Security-sensitive changes require security team approval

### Dependencies
- Keep all dependencies up to date
- Monitor for security vulnerabilities
- Use Dependabot alerts

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |
EOF

git add SECURITY.md
git commit -m "docs: Add security policy"
```

---

## 🎯 RESULTADO ESPERADO

Al finalizar esta fase:

- ✅ `GoogleService-Info.plist` NO está en el repositorio
- ✅ `.gitignore` completo y funcionando
- ✅ Plantilla de configuración documentada
- ✅ README actualizado con instrucciones de setup
- ✅ Carpeta `snapshots/` eliminada (~12.5 MB liberados)
- ✅ Archivos duplicados eliminados
- ✅ Configuración por entornos creada
- ✅ El proyecto compila correctamente
- ✅ Credenciales de Firebase rotadas
- ✅ Políticas de seguridad documentadas

**Tiempo estimado:** 2-3 horas de trabajo concentrado

**Próximo paso:** Iniciar Fase 1 - Refactoring Técnico

---

**Última actualización:** Diciembre 2025
**Responsable:** Lead Developer
**Aprobado por:** CTO
