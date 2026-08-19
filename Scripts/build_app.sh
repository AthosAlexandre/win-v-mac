#!/bin/bash
#
# build_app.sh - Compila o MacClip em release e monta um bundle .app instalavel.
#
# Uso:
#   ./Scripts/build_app.sh            # gera build/MacClip.app
#   ./Scripts/build_app.sh --install  # gera e copia para /Applications
#
# Nao precisa do Xcode completo - so das Command Line Tools (Swift 6+).
# Ver docs/SETUP.md (secao "Gerar o .app instalavel").

set -euo pipefail

APP_NAME="MacClip"
BUNDLE_ID="com.athosalexandre.macclip"
VERSION="1.0.0"
MIN_MACOS="14.0"

# Raiz do projeto (um nivel acima de Scripts/)
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

BUILD_DIR=".build/release"
OUT_DIR="build"
APP_DIR="$OUT_DIR/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"

echo "==> Compilando em release..."
swift build -c release

echo "==> Montando $APP_DIR ..."
rm -rf "$APP_DIR"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

cp "$BUILD_DIR/$APP_NAME" "$CONTENTS/MacOS/$APP_NAME"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_MACOS</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> Assinando localmente (ad-hoc)..."
codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || \
    echo "   (aviso: codesign falhou; o app ainda roda localmente)"

echo "==> Pronto: $APP_DIR"

if [[ "${1:-}" == "--install" ]]; then
    echo "==> Instalando em /Applications..."
    rm -rf "/Applications/$APP_NAME.app"
    cp -R "$APP_DIR" "/Applications/$APP_NAME.app"
    echo "==> Instalado: /Applications/$APP_NAME.app"
    echo "    Abra pelo Launchpad ou rode: open -a $APP_NAME"
fi
