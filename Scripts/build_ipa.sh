#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCHEME="Sora"
PROJECT="Sora.xcodeproj"
CONFIGURATION="Release"
DERIVED_DATA="$ROOT_DIR/build/DerivedData"
ARCHIVE_PATH="$ROOT_DIR/build/Sora.xcarchive"
EXPORT_DIR="$ROOT_DIR/build/export"
ARTIFACT_DIR="$ROOT_DIR/build-output"
LOG_DIR="$ARTIFACT_DIR/logs"
EXPORT_OPTIONS_PLIST="$ROOT_DIR/build/ExportOptions.plist"
UNSIGNED_APP_DIR="$DERIVED_DATA/Build/Products/$CONFIGURATION-iphoneos"
UNSIGNED_APP_PATH="$UNSIGNED_APP_DIR/Sora.app"
UNSIGNED_PAYLOAD_DIR="$ROOT_DIR/build/unsigned-payload"
UNSIGNED_IPA_PATH="$ARTIFACT_DIR/Sora-unsigned.ipa"

mkdir -p "$DERIVED_DATA" "$EXPORT_DIR" "$ARTIFACT_DIR" "$LOG_DIR" "$ROOT_DIR/build"

: "${BUNDLE_IDENTIFIER:=com.local.sora}"
: "${KEYCHAIN_PASSWORD:=temporary-build-keychain-password}"
: "${EXPORT_METHOD:=development}"

SIGNED_BUILD=true
for required_var in APPLE_CERTIFICATE_BASE64 P12_PASSWORD PROVISIONING_PROFILE_BASE64 DEVELOPMENT_TEAM; do
  if [[ -z "${!required_var:-}" ]]; then
    SIGNED_BUILD=false
  fi
done

echo "Build mode: $([[ "$SIGNED_BUILD" == true ]] && echo signed || echo unsigned-device-ipa)"

if [[ ! -d "$PROJECT" ]]; then
  echo "Missing $PROJECT. Run Scripts/bootstrap_project.sh first." >&2
  exit 1
fi

if [[ "$SIGNED_BUILD" == true ]]; then
  KEYCHAIN_PATH="$RUNNER_TEMP/sora-build.keychain-db"
  CERT_PATH="$RUNNER_TEMP/sora_certificate.p12"
  PROFILE_PATH="$RUNNER_TEMP/sora.mobileprovision"
  PROFILE_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"

  mkdir -p "$PROFILE_DIR"

  echo "$APPLE_CERTIFICATE_BASE64" | base64 --decode > "$CERT_PATH"
  echo "$PROVISIONING_PROFILE_BASE64" | base64 --decode > "$PROFILE_PATH"

  security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
  security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
  security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
  security import "$CERT_PATH" -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
  security list-keychains -d user -s "$KEYCHAIN_PATH" login.keychain-db
  cp "$PROFILE_PATH" "$PROFILE_DIR/"

  cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${EXPORT_METHOD}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>${DEVELOPMENT_TEAM}</string>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -derivedDataPath "$DERIVED_DATA" \
    -destination "generic/platform=iOS" \
    BUNDLE_IDENTIFIER="$BUNDLE_IDENTIFIER" \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_IDENTIFIER" \
    clean archive | tee "$LOG_DIR/archive.log"

  xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" | tee "$LOG_DIR/export.log"

  find "$EXPORT_DIR" -maxdepth 1 \( -name "*.ipa" -o -name "*.app" \) -exec cp -R {} "$ARTIFACT_DIR/" \;
else
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk iphoneos \
    -destination "generic/platform=iOS" \
    -derivedDataPath "$DERIVED_DATA" \
    BUNDLE_IDENTIFIER="$BUNDLE_IDENTIFIER" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_IDENTIFIER" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_IDENTITY="" \
    clean build | tee "$LOG_DIR/unsigned-device-build.log"

  if [[ ! -d "$UNSIGNED_APP_PATH" ]]; then
    echo "Unsigned device app was not produced at $UNSIGNED_APP_PATH" >&2
    exit 1
  fi

  rm -rf "$UNSIGNED_PAYLOAD_DIR"
  mkdir -p "$UNSIGNED_PAYLOAD_DIR/Payload"
  cp -R "$UNSIGNED_APP_PATH" "$UNSIGNED_PAYLOAD_DIR/Payload/"

  (
    cd "$UNSIGNED_PAYLOAD_DIR"
    /usr/bin/zip -qry "$UNSIGNED_IPA_PATH" Payload
  )

  if [[ ! -f "$UNSIGNED_IPA_PATH" ]]; then
    echo "Unsigned IPA packaging failed." >&2
    exit 1
  fi

  APP_INFO_PLIST="$UNSIGNED_APP_PATH/Info.plist"
  if [[ -f "$APP_INFO_PLIST" ]]; then
    /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_INFO_PLIST" > "$ARTIFACT_DIR/bundle-identifier.txt"
  fi

  cp -R "$UNSIGNED_APP_PATH" "$ARTIFACT_DIR/"

  cat > "$ARTIFACT_DIR/README_UNSIGNED.txt" <<EOF
This run produced an unsigned device IPA for sideload-style tooling.
Bundle identifier: $BUNDLE_IDENTIFIER
Artifact: $(basename "$UNSIGNED_IPA_PATH")

This IPA is not signed by Apple and is not directly installable through standard iOS install flows.
Use your preferred sideload/signing tool if you need to place it on a device.

To produce a signed installable IPA instead, provide:
APPLE_CERTIFICATE_BASE64, P12_PASSWORD, PROVISIONING_PROFILE_BASE64,
KEYCHAIN_PASSWORD, DEVELOPMENT_TEAM, BUNDLE_IDENTIFIER, and EXPORT_METHOD.
EOF
fi
