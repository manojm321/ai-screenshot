#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="AI Screenshot"
APP_BUNDLE="${SCRIPT_DIR}/${APP_NAME}.app"
DMG_NAME="AI-Screenshot.dmg"
DMG_PATH="${SCRIPT_DIR}/${DMG_NAME}"
VOL_NAME="AI Screenshot"

echo "==> Preparing DMG build..."

# Ensure the app bundle is built
if [[ ! -d "${APP_BUNDLE}" ]]; then
    echo "==> Building ${APP_BUNDLE} first..."
    "${SCRIPT_DIR}/build_app.sh"
fi

# Clean up any existing dmg
rm -f "${DMG_PATH}" "${DMG_PATH}.sha256"

# Create staging directory
STAGING_DIR="$(mktemp -d /tmp/dmg-staging.XXXXXX)"
trap 'rm -rf "${STAGING_DIR}"' EXIT

echo "==> Staging files..."
cp -R "${APP_BUNDLE}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

# Set custom volume icon if AppIcon.icns exists
if [[ -f "${SCRIPT_DIR}/AppIcon.icns" ]]; then
    cp "${SCRIPT_DIR}/AppIcon.icns" "${STAGING_DIR}/.VolumeIcon.icns"
    if command -v SetFile &>/dev/null; then
        SetFile -c icnC "${STAGING_DIR}/.VolumeIcon.icns" 2>/dev/null || true
        SetFile -a C "${STAGING_DIR}" 2>/dev/null || true
    fi
fi

echo "==> Creating compressed disk image (${DMG_NAME})..."
hdiutil create \
    -volname "${VOL_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

# Generate checksum
echo "==> Computing SHA256 checksum..."
(cd "${SCRIPT_DIR}" && shasum -a 256 "${DMG_NAME}" > "${DMG_NAME}.sha256")

echo "✅ DMG created successfully: ${DMG_PATH}"
cat "${DMG_PATH}.sha256"
