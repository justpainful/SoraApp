# Sora Fix Pass Final Report

## Verdict
NOT READY - SIGNING REQUIRED

## What Changed
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\.github\workflows\ios-ipa.yml`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\README_BUILD_IPA.md`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Scripts\bootstrap_project.sh`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Scripts\build_ipa.sh`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\project.yml`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Sora\Camera\SoraCameraManager.swift`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Sora\Recording\RecordingCoordinator.swift`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Sora\Recording\SoraAssetWriterRecorder.swift`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Sora\Recording\SoraPhotoLibrarySaver.swift`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Sora\Rendering\MetalPreviewView.swift`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Sora\Supporting\Info.plist`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Sora\Views\CameraView.swift`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Sora\Views\ControlsOverlay.swift`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Sora\Views\SaveResultSheet.swift`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Sora\Views\SettingsSheet.swift`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Sora\Views\SoraHeader.swift`
- `C:\Users\kuroi\Downloads\Sora_Agent_Starter\Sora_Agent_Starter\Workspaces\Sora_MAIN\Sora\Views\SoraToastView.swift`

## Build / CI Status
- GitHub Actions workflow added: yes
- project.yml verified: yes
- bootstrap script verified: no
- IPA workflow supports signed build: yes
- IPA workflow supports artifact upload: yes
- Local build run: no
- If no, why:
  - This Windows environment does not have Apple build tooling, so `xcodegen`, `xcodebuild`, archive, and export could not be executed locally.

## Fixed Audit Issues
- Added a macOS GitHub Actions workflow for project generation, build verification, archive, export, and artifact upload.
- Added a macOS-friendly bootstrap script and a build script for signed and unsigned CI modes.
- Removed the app's fake active quality-mode control from the live camera UI.
- Reworked `SoraCameraManager` to avoid MainActor delegate misuse, emit real `frameIndex` values, and prevent double session configuration/start.
- Added truthful lens availability handling so `0.5x` is only shown when available.
- Wired `RecordingHUD`, `SaveResultSheet`, and `MiniGalleryStrip` into the active `CameraView` flow.
- Kept recording on processed frames while `showOriginal` only changes preview output.
- Removed hardcoded recording-size start logic from the UI path and derive the recorder output size from processed frame extents.
- Added file-existence preflight before Photos saving.
- Removed `NSMicrophoneUsageDescription` from `Info.plist`.
- Added user-facing preview fallback messaging when Metal rendering cannot start.
- Fixed mojibake strings in `CameraView` and `SaveResultSheet`.
- Updated toast icon behavior so failure and warning toasts are not shown as success.

## Remaining Issues
- No Apple build or GitHub Actions run was executed in this environment, so compile success, archive success, export success, and installable IPA output remain unverified.
- `QualityModeButton.swift` still exists in the repo but is intentionally unused in v0.1 to avoid exposing a fake feature.
- `SoraPreviewRenderer` remains thin and mostly acts as a compatibility sink because the active preview path now publishes directly from `CameraPipelineController`.
- There are still no automated unit or UI tests.

## Feature Checklist
| Feature | Status | Evidence |
|---|---|---|
| GitHub Actions workflow | PASS | `.github/workflows/ios-ipa.yml` |
| Project generation | UNKNOWN | `Scripts/bootstrap_project.sh`, `project.yml` |
| IPA artifact upload | PASS | `.github/workflows/ios-ipa.yml`, `Scripts/build_ipa.sh` |
| Signing secrets documented | PASS | `README_BUILD_IPA.md` |
| App opens CameraView | PASS | `Sora/App/SoraApp.swift`, `Sora/Views/ContentView.swift` |
| Camera permission | PASS | `Sora/Camera/SoraCameraManager.swift`, `Sora/Views/CameraPermissionView.swift` |
| Live preview | UNKNOWN | `Sora/Views/CameraView.swift`, `Sora/Rendering/MetalPreviewView.swift` |
| Filter pipeline | PASS | `Sora/Views/CameraView.swift`, `Sora/Filters/SoraFilterProcessor.swift` |
| Smooth slider | PASS | `Sora/Views/FilterStudioSheet.swift` |
| Glow slider | PASS | `Sora/Views/FilterStudioSheet.swift` |
| Contrast slider | PASS | `Sora/Views/FilterStudioSheet.swift` |
| Presets | PASS | `Sora/Views/FilterStudioSheet.swift` |
| Before/After | PASS | `Sora/Views/CameraView.swift`, `Sora/Views/BeforeAfterButton.swift` |
| Record start | PASS | `Sora/Views/CameraView.swift`, `Sora/Recording/RecordingCoordinator.swift` |
| Processed frame recording | PASS | `Sora/Views/CameraView.swift`, `Sora/Recording/SoraAssetWriterRecorder.swift` |
| Record stop | PASS | `Sora/Views/CameraView.swift`, `Sora/Recording/RecordingCoordinator.swift` |
| Save to Photos | PASS | `Sora/Recording/SoraPhotoLibrarySaver.swift` |
| SaveResultSheet wired | PASS | `Sora/Views/CameraView.swift`, `Sora/Views/SaveResultSheet.swift` |
| MiniGalleryStrip wired | PASS | `Sora/Views/CameraView.swift`, `Sora/Views/MiniGalleryStrip.swift` |
| RecordingHUD wired | PASS | `Sora/Views/CameraView.swift`, `Sora/Views/RecordingHUD.swift` |
| Quality fake removed/fixed | PASS | `Sora/Views/ControlsOverlay.swift`, `Sora/Views/SettingsSheet.swift` |
| Lens fallback truthful | PASS | `Sora/Camera/SoraCameraManager.swift`, `Sora/Views/SoraHeader.swift` |
| frameIndex increments | PASS | `Sora/Camera/SoraCameraManager.swift` |
| Photos preflight | PASS | `Sora/Recording/SoraPhotoLibrarySaver.swift` |
| No networking | PASS | no network code added; existing app sources remain local-only |
| No body reshaping | PASS | `Sora/Filters/SoraFilterProcessor.swift` uses Core Image grading, blur, edge-mask, bloom, and contrast only |

## Exact Pipeline Trace
Camera -> `SoraCameraManager.captureOutput(_:didOutput:from:)`

Filter -> `CameraPipelineController.receive(_:)` -> `CameraPipelineController.process(frame:settings:showOriginal:)` -> `SoraFilterProcessor.process(frame:settings:)`

Preview -> `CameraPipelineController.process` publishes `previewImage` -> `MetalPreviewView.updateUIView` -> `MetalPreviewView.Coordinator.draw(in:)`

Recorder -> `CameraPipelineController.process` -> `RecordingCoordinator.appendFrame(image:timestamp:)` -> `SoraAssetWriterRecorder.appendFrame(image:timestamp:)`

Photos -> `RecordingCoordinator.stopRecording(saveToPhotos:)` -> `SoraAssetWriterRecorder.stopRecording()` -> `SoraPhotoLibrarySaver.saveVideoToPhotos(url:)`

## GitHub Actions Instructions
1. Required secrets:
   - `APPLE_CERTIFICATE_BASE64`
   - `P12_PASSWORD`
   - `PROVISIONING_PROFILE_BASE64`
   - `KEYCHAIN_PASSWORD`
   - `DEVELOPMENT_TEAM`
   - `BUNDLE_IDENTIFIER`
   - `EXPORT_METHOD`
2. How to push repo:
   - Commit the workspace and push it to a GitHub repository with Actions enabled.
3. How to run workflow:
   - Open `Actions` -> `iOS IPA Build` -> `Run workflow`, or push to `main` / `master`.
4. Where IPA artifact appears:
   - Download the `sora-build-output` artifact from the workflow run page.
5. What failure means if signing secrets are missing:
   - The workflow falls back to compile verification only. That does not produce an installable iPhone IPA.

## Recommended Next Version
- Audio
- Real 4K30
- Person mask
- Better performance
- Better presets
- App icon polish
