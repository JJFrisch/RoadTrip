#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ASC_API_KEY_ID=... ASC_API_ISSUER_ID=... ASC_API_PRIVATE_KEY_PATH=... \
# ./scripts/testflight_beta_upload.sh 1.0.0 12

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <marketing-version> <build-number>"
  exit 1
fi

MARKETING_VERSION="$1"
BUILD_NUMBER="$2"

: "${ASC_API_KEY_ID:?ASC_API_KEY_ID is required}"
: "${ASC_API_ISSUER_ID:?ASC_API_ISSUER_ID is required}"
: "${ASC_API_PRIVATE_KEY_PATH:?ASC_API_PRIVATE_KEY_PATH is required}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVE_PATH="$ROOT_DIR/build/RoadTrip.xcarchive"
EXPORT_PATH="$ROOT_DIR/build/export"

mkdir -p "$ROOT_DIR/build"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

echo "Setting version to $MARKETING_VERSION ($BUILD_NUMBER)..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $MARKETING_VERSION" "$ROOT_DIR/RoadTrip/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$ROOT_DIR/RoadTrip/Info.plist"

echo "Archiving RoadTrip..."
xcodebuild \
  -project "$ROOT_DIR/RoadTrip.xcodeproj" \
  -scheme "RoadTrip" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  archive

echo "Exporting IPA..."
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$ROOT_DIR/docs/release/ExportOptions-AppStore.plist"

IPA_PATH="$(find "$EXPORT_PATH" -name "*.ipa" | head -n 1)"
if [[ -z "${IPA_PATH:-}" ]]; then
  echo "No IPA found in $EXPORT_PATH"
  exit 1
fi

echo "Uploading IPA to App Store Connect..."
xcrun altool \
  --upload-app \
  --type ios \
  --file "$IPA_PATH" \
  --apiKey "$ASC_API_KEY_ID" \
  --apiIssuer "$ASC_API_ISSUER_ID" \
  --private-key "$ASC_API_PRIVATE_KEY_PATH"

echo "Upload submitted. Finalize the build in App Store Connect -> TestFlight."
