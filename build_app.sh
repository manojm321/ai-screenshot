#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="AI Screenshot"
APP_BUNDLE="$DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Building $APP_NAME.app..."

# 1. Clean previous build
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

# 2. Always generate fresh pixel-perfect icon
echo "==> Generating AppIcon.icns..."
swift "$DIR/generate_icon.swift"
cp "$DIR/AppIcon.icns" "$RESOURCES/AppIcon.icns"

# 3. Compile native binary
echo "==> Compiling native Swift binary..."
swiftc -O -o "$MACOS/$APP_NAME" "$DIR/main.swift"
chmod +x "$MACOS/$APP_NAME"

# 4. Generate Info.plist
cat <<EOF > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>AI Screenshot</string>
    <key>CFBundleExecutable</key>
    <string>AI Screenshot</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.manojm321.ai-screenshot</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>AI Screenshot</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSScreenCaptureUsageDescription</key>
    <string>AI Screenshot requires screen capture access to take screenshots and name them using on-device Apple Foundation Models.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 5. Generate PkgInfo
echo -n "APPL????" > "$CONTENTS/PkgInfo"

# 6. Ad-hoc codesign so macOS Gatekeeper / TCC treats it as a first-class app
codesign --force --deep --sign - "$APP_BUNDLE"

# 7. Touch bundle to ensure Finder invalidates any cached icon
touch "$APP_BUNDLE"

echo "✅ Successfully built: $APP_BUNDLE"
