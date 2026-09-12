#!/bin/bash
set -euo pipefail

APP_NAME="MetaPeek"
APP_DIR="dist/${APP_NAME}.app"

echo "==> Building (release)..."
swift build -c release
BIN_PATH=$(swift build -c release --show-bin-path)

echo "==> Assembling ${APP_NAME}.app..."
rm -rf dist
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${BIN_PATH}/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
cp "AppResources/Info.plist" "${APP_DIR}/Contents/Info.plist"

for bundle in "${BIN_PATH}"/*.bundle; do
    [ -d "$bundle" ] && cp -R "$bundle" "${APP_DIR}/Contents/Resources/"
done

if [ -f "AppResources/AppIcon.icns" ]; then
    cp "AppResources/AppIcon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"
fi

echo "==> Ad-hoc code signing..."
codesign --force --deep --sign - "${APP_DIR}"

echo "==> Done: ${APP_DIR}"
echo "Run with: open \"${APP_DIR}\""
