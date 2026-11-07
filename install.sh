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

# 2. Build native macOS app with native hotkey listener and retina icon
echo "==> Building native AI Screenshot.app..."
"$DIR/build_app.sh"

# 3. Clean up legacy Automator Quick Action if present (removes menu bar gear icon)
rm -rf "$HOME/Library/Services/AI Screenshot.workflow"
python3 -c "
import plistlib, os, subprocess
p = os.path.expanduser('~/Library/Preferences/pbs.plist')
if os.path.exists(p):
    try:
        d = plistlib.load(open(p, 'rb'))
        s = d.get('NSServicesStatus', {})
        changed = False
        for k in ['(null) - AI Screenshot - runWorkflowAsService', 'com.manojm321.AI-Screenshot - AI Screenshot - runWorkflowAsService', 'com.user.AI-Screenshot - AI Screenshot - runWorkflowAsService']:
            if k in s:
                s.pop(k)
                changed = True
        if changed:
            plistlib.dump(d, open(p, 'wb'))
            subprocess.run(['killall', 'cfprefsd'], check=False)
            subprocess.run(['/System/Library/CoreServices/pbs', '-flush'], check=False)
            subprocess.run(['/System/Library/CoreServices/pbs', '-update'], check=False)
    except Exception:
        pass
" 2>/dev/null || true

# 4. Install to /Applications or ~/Applications
APP_NAME="AI Screenshot.app"
INSTALL_DIR="/Applications"
if [ ! -w "/Applications" ]; then
    INSTALL_DIR="$HOME/Applications"
    mkdir -p "$INSTALL_DIR"
fi

echo "==> Installing $APP_NAME to $INSTALL_DIR..."
# Terminate any running instance before replacing binary
killall "AI Screenshot" 2>/dev/null || true
rm -rf "$INSTALL_DIR/$APP_NAME"
cp -R "$DIR/$APP_NAME" "$INSTALL_DIR/"

# Invalidate Finder and LaunchServices caches so the icon appears immediately
touch "$INSTALL_DIR/$APP_NAME"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R "$INSTALL_DIR/$APP_NAME" 2>/dev/null || true
killall Finder 2>/dev/null || true

# 5. Launch the app in background to activate native global hotkey (⌘⇧1)
echo "==> Starting AI Screenshot..."
open -a "$INSTALL_DIR/$APP_NAME"

# 6. Native macOS visual confirmation
osascript -e 'display notification "Running in background! Press ⌘⇧1 anywhere to take an AI screenshot." with title "AI Screenshot" subtitle "Native Hotkey Active" sound name "Glass"' 2>/dev/null || true

echo ""
echo "--------------------------------------------------------"
echo "🎉 Setup is 100% complete!"
echo "AI Screenshot is running in the background."
echo "Native global shortcut ⌘ + ⇧ + 1 (Cmd + Shift + 1) is ACTIVE (0ms latency, no gear icon)."
echo "You also have a camera icon in your top menu bar."
echo "--------------------------------------------------------"
