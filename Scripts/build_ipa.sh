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

echo "Build mode: $([[ "$SIGNED_BUILD" == true ]] && echo signed || echo verification-only)"

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
    -configuration Debug \
    -sdk iphonesimulator \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$DERIVED_DATA" \
    BUNDLE_IDENTIFIER="$BUNDLE_IDENTIFIER" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_IDENTIFIER" \
    CODE_SIGNING_ALLOWED=NO \
    clean build | tee "$LOG_DIR/compile-verification.log"

  cat > "$ARTIFACT_DIR/README_UNSIGNED.txt" <<EOF
This run verified project generation and compilation only.
No installable IPA was exported because Apple signing secrets were missing.
Provide APPLE_CERTIFICATE_BASE64, P12_PASSWORD, PROVISIONING_PROFILE_BASE64,
KEYCHAIN_PASSWORD, DEVELOPMENT_TEAM, BUNDLE_IDENTIFIER, and EXPORT_METHOD
to produce an installable signed IPA artifact.
EOF
fi
