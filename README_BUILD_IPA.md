# Sora GitHub Actions IPA Build

## Required GitHub Secrets

Installable signed IPA output requires these repository secrets:

- `APPLE_CERTIFICATE_BASE64`
  - Base64-encoded `.p12` signing certificate.
- `P12_PASSWORD`
  - Password for the `.p12` certificate.
- `PROVISIONING_PROFILE_BASE64`
  - Base64-encoded `.mobileprovision` file for the app.
- `KEYCHAIN_PASSWORD`
  - Temporary macOS keychain password used during the workflow.
- `DEVELOPMENT_TEAM`
  - Apple Developer Team ID.
- `BUNDLE_IDENTIFIER`
  - Bundle identifier to use during the build, for example `com.yourteam.sora`.
- `EXPORT_METHOD`
  - Export method, for example `development`, `ad-hoc`, or `app-store`.

## How To Trigger The Workflow

1. Push this repo to GitHub.
2. Open the repository on GitHub.
3. Go to `Actions`.
4. Open the `iOS IPA Build` workflow.
5. Run `Run workflow`, or push to `main` / `master`.

## Where The Artifact Appears

- Open the finished workflow run.
- Download the `sora-build-output` artifact.
- For signed runs, the artifact contains the exported `.ipa`.
- For verification-only runs, the artifact contains build logs and an unsigned-build note instead of an installable IPA.

## Signed IPA vs Unsigned Build

### Signed IPA

- Requires all signing secrets above.
- Runs project generation, archive, export, and artifact upload.
- Produces an installable `.ipa` only if the certificate, provisioning profile, team ID, and bundle identifier all match.

### Unsigned Device IPA Build

- Runs automatically when signing secrets are missing.
- Generates `Sora.xcodeproj` and builds the app for `iphoneos` with signing disabled.
- Packages `Payload/Sora.app` into an unsigned `.ipa` artifact.
- This artifact is useful for sideload-style tooling, but it is not Apple-signed and is not directly installable through normal iOS distribution flows.

## Common Signing Failures

- `No profiles for ... were found`
  - The provisioning profile does not match `BUNDLE_IDENTIFIER` or `DEVELOPMENT_TEAM`.
- `No signing certificate ... found`
  - The `.p12` file is missing, corrupted, or the `P12_PASSWORD` is wrong.
- `exportArchive` fails
  - `EXPORT_METHOD` does not match the provisioning profile type, or the archive was not signed correctly.
- `archive` fails with code signing errors
  - The certificate, provisioning profile, and bundle identifier do not belong to the same Apple developer team.

## macOS CI Path

- `Scripts/bootstrap_project.sh` installs XcodeGen if needed and generates `Sora.xcodeproj`.
- `Scripts/build_ipa.sh` chooses signed export mode when all secrets are present.
- Without secrets, it falls back to project generation plus compile verification.
