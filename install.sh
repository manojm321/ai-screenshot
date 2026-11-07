#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Setting up AI Screenshot..."

# 1. Check for 'fm' CLI
if ! command -v fm &> /dev/null && [ ! -f "/usr/bin/fm" ]; then
    echo "⚠️  Warning: Apple Foundation Models CLI ('fm') not found."
    echo "   Ensure Apple Intelligence / Foundation Models are enabled on your Mac."
else
    echo "✅ Found 'fm' CLI at $(command -v fm || echo '/usr/bin/fm')"
fi

# 2. Build native macOS app
echo "==> Building native AI Screenshot.app..."
"$DIR/build_app.sh"

# 3. Install to /Applications or ~/Applications
APP_NAME="AI Screenshot.app"
INSTALL_DIR="/Applications"
if [ ! -w "/Applications" ]; then
    INSTALL_DIR="$HOME/Applications"
    mkdir -p "$INSTALL_DIR"
fi

echo "==> Installing $APP_NAME to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR/$APP_NAME"
cp -R "$DIR/$APP_NAME" "$INSTALL_DIR/"

# Register with LaunchServices
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$INSTALL_DIR/$APP_NAME" 2>/dev/null || true

# 4. Automatically install macOS Quick Action and bind Cmd+Shift+1
echo "==> Installing macOS Quick Action and binding ⌘⇧1 (Cmd+Shift+1)..."
python3 "$DIR/install_service.py"

echo ""
echo "--------------------------------------------------------"
echo "Setup is 100% complete!"
echo "AI Screenshot.app installed to: $INSTALL_DIR/$APP_NAME"
echo "Press ⌘ + ⇧ + 1 (Cmd + Shift + 1) anywhere to take an AI screenshot."
echo "--------------------------------------------------------"
