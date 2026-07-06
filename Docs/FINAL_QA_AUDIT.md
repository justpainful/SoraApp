# Sora Final QA Audit

## Verdict
B) NOT READY — BUILD BLOCKED. Project generation and build were not verifiable here because `xcodegen` and `xcodebuild` are unavailable, `Sora.xcodeproj` does not exist yet, and code inspection still found unresolved fake or unwired feature paths.

## Build Verification
- Tools available: `bash.exe` exists at `C:\Windows\system32\bash.exe`, but it fails because `/bin/bash` is missing; `xcodegen` unavailable; `xcodebuild` unavailable.
- Commands run:
  - `cd Workspaces/Sora_MAIN`
  - `bash ./Scripts/bootstrap_project.sh`
  - `xcodegen generate`
  - `xcodebuild -list`
- Result:
  - `bash ./Scripts/bootstrap_project.sh` failed with `execvpe(/bin/bash) failed: No such file or directory`
  - `xcodegen generate` failed with `xcodegen` not recognized
  - `xcodebuild -list` failed with `xcodebuild` not recognized
  - `Sora.xcodeproj` is missing
- Build log summary:
  - `project.yml` exists
  - `Scripts/bootstrap_project.sh` exists and does require XcodeGen
  - The project cannot be generated or built in this Windows environment with the currently installed tools
- If not run, why:
  - Full Apple build verification was not possible in this environment.
  - Build verification was not possible in this environment.

## Blockers
- `Sora.xcodeproj` does not exist. `project.yml` is present, so XcodeGen is required before any Xcode build can even start. Evidence: `project.yml`, missing generated project, `Scripts/bootstrap_project.sh:8-21`.
- `xcodegen` is not installed here, so project generation is blocked before compile verification. Evidence: command failure `xcodegen generate`.
- `xcodebuild` is not installed here, so no scheme listing, compile, or launch verification was possible. Evidence: command failure `xcodebuild -list`.
- The bootstrap script cannot run in this environment because `bash.exe` routes to WSL but `/bin/bash` is unavailable. Evidence: `Scripts/bootstrap_project.sh:1-21`, runtime error from `bash ./Scripts/bootstrap_project.sh`.
- There is a likely Swift concurrency compile risk in `SoraCameraManager.captureOutput`: the class is `@MainActor`, `captureOutput` is `nonisolated`, and it still touches actor-isolated state via `onFrame?(soraFrame)`. This was not build-verified, so it remains a real compile-risk blocker. Evidence: `Sora/Camera/SoraCameraManager.swift:6-7`, `15`, `200-224`.

## Critical Issues
- `RecordingHUD`, `SaveResultSheet`, and `MiniGalleryStrip` exist in the tree but are not wired into the active `CameraView` UI flow. The live screen only mounts `ControlsOverlay`, header, preview, filter sheet, settings sheet, and toast. This directly matches the known unresolved merge issue and means required save-result and mini-gallery UX is still dead code. Evidence: `Sora/Views/CameraView.swift:117-152`; component files exist at `Sora/Views/RecordingHUD.swift`, `Sora/Views/SaveResultSheet.swift`, `Sora/Views/MiniGalleryStrip.swift`; merge note in `Docs/MERGE_GUIDE_NO_GIT.md:19-34`.
- Quality mode is fake. The UI changes `AppState.qualityMode` and calls `cameraManager.setQualityMode`, but the implementation is a stub that only prints and explicitly says it is not implemented. This is a disconnected required feature, not a real mode switch. Evidence: `Sora/Views/QualityModeButton.swift:8-17`, `Sora/Views/CameraView.swift:80-82`, `Sora/Camera/SoraCameraManager.swift:193-197`.
- Save-result UI is not presented after recording finishes. `RecordingCoordinator` sets `saveResult`, but `CameraView` never observes or presents `SaveResultSheet`. A successful save only changes state and toast; the required result surface is absent from the app flow. Evidence: `Sora/Recording/RecordingCoordinator.swift:58-64`, `Sora/Views/CameraView.swift:145-159`.
- Mini gallery / recent recordings is not exposed as the requested strip. `RecordingCoordinator` stores `recentRecordings`, but `CameraView` only shows the latest filename as text and the full list only appears inside `SettingsSheet`; `MiniGalleryStrip` is unused. Evidence: `Sora/Recording/RecordingCoordinator.swift:8`, `69-75`; `Sora/Views/ControlsOverlay.swift:31-45`; `Sora/Views/SettingsSheet.swift:26-40`; `Sora/Views/MiniGalleryStrip.swift:3-63`.

## Major Issues
- Filter work is being dispatched onto the main actor for every frame. `CameraPipelineController.bind` wraps frame handling in `Task { @MainActor ... }`, then runs `processor.process(frame:settings:)` there. That is exactly the wrong place for per-frame blur and blend work and creates a high risk of jank, dropped frames, and thermal pressure. Evidence: `Sora/Views/CameraView.swift:34-45`.
- `frameIndex` is not implemented correctly. The shared type requires it, but every emitted `SoraFrame` is hardcoded to `0`. This breaks frame progression semantics and is explicitly left as an MVP simplification in comments. Evidence: `Sora/App/SoraTypes.swift:10-15`, `Sora/Camera/SoraCameraManager.swift:207-220`.
- Authorization flow double-configures the capture session on first grant. `requestAuthorization()` calls both `configureSession()` and `startSession()`, and `startSession()` can call `configureSession()` again when inputs are still empty. That is sloppy session lifecycle code and can lead to duplicate configuration attempts and confusing failures. Evidence: `Sora/Camera/SoraCameraManager.swift:37-45`, `153-169`.
- Lens selection can lie on unsupported devices. If ultra-wide is unavailable, `setupDeviceInput` silently falls back to wide, but `switchLens` still sets `currentLens = lens`, so the UI can claim `0.5x` while using the wide camera. Evidence: `Sora/Camera/SoraCameraManager.swift:95-105`, `182-189`.
- Metal preview has no user-facing fallback or error state when Metal is unavailable. `MetalPreviewView` sets `device = MTLCreateSystemDefaultDevice()`, but if that returns `nil`, no `CIContext` is created and draw just returns. The user sees a stuck loading state with no recovery path. Evidence: `Sora/Rendering/MetalPreviewView.swift:8-21`, `33-56`; spinner path in `Sora/Views/CameraView.swift:176-180`.
- Recording output size is hardcoded to `1080x1920` instead of being derived from actual rendered frame geometry or active capture dimensions. That increases the risk of scaling, cropping, or orientation mismatch between preview and recording. Evidence: `Sora/Recording/RecordingCoordinator.swift:29-31`, `Sora/Recording/SoraAssetWriterRecorder.swift:107-110`, `224-241`.
- Photos save path does not verify that the file URL exists before calling `PHAssetChangeRequest.creationRequestForAssetFromVideo`. If recorder output fails silently or the file is missing, the save layer has no preflight check. Evidence: `Sora/Recording\SoraPhotoLibrarySaver.swift:5-23`.
- `NSMicrophoneUsageDescription` is present even though the app does not configure audio capture or write audio tracks. That is unnecessary permission surface and contradicts the stated local-only camera scope for this build. Evidence: `Sora/Supporting/Info.plist:27-28`; no audio capture path in `Sora/Camera/SoraCameraManager.swift` or `Sora/Recording/SoraAssetWriterRecorder.swift`.
- There are no tests at all. No unit tests, no UI tests, no build tests. Evidence: missing `Tests` directory and no test targets or test files found.

## Minor Issues
- UI strings contain mojibake / encoding corruption. `Loading cameraâ€¦` and `Couldnâ€™t Save` are visibly broken strings. Evidence: `Sora/Views/CameraView.swift:177`, `Sora/Views/SaveResultSheet.swift:88`.
- `SoraToastView` always uses a success checkmark icon even for failure toasts, which miscommunicates errors. Evidence: `Sora/Views/SoraToastView.swift:8-10`, failure toasts set in `Sora/Recording/RecordingCoordinator.swift:63-64`.
- `SettingsSheet` claims quality mode exists while also admitting it is reserved for future tuning. That text exposes the fake feature rather than hiding it, but it still confirms the implementation gap. Evidence: `Sora/Views/SettingsSheet.swift:21-24`.
- `VideoRenderer.swift` and `RecorderFrameRenderer.swift` are absent. They do not currently cause a compile failure because nothing references them, but their absence makes the rendering/recording architecture thinner than the audit request expected. Evidence: repo search found no such files.
- User-facing strings are hardcoded English throughout the UI. There are no localization resources. This was not part of the stated product scope, but it is still not production-ready polish for a premium app.

## Feature Checklist

| Feature | Status | Evidence | Issue |
|---|---|---|---|
| App opens CameraView | PASS | `Sora/Views/ContentView.swift:3-6`, `Sora/App/SoraApp.swift:7-11` | `ContentView` directly returns `CameraView` and `AppState` is injected at app entry |
| Camera permission | PASS | `Sora/Camera/SoraCameraManager.swift:32-47`, `Sora/Views/CameraView.swift:108-115`, `184-189`, `Sora/Views/CameraPermissionView.swift:3-60` | Real request/denied-settings flow exists in code; runtime not verified |
| Live preview | UNKNOWN | `Sora/Views/CameraView.swift:34-45`, `166-181`, `Sora/Rendering/MetalPreviewView.swift:5-93` | Code path exists, but build and runtime preview were not verifiable here |
| Filter pipeline | PASS | `Sora/Views/CameraView.swift:38-43`, `Sora/Filters/SoraFilterProcessor.swift:18-38` | Camera frame goes through processor before preview and recording unless original-preview toggle is active |
| Smooth slider | PASS | `Sora/Views/FilterStudioSheet.swift:83-89` | Binding writes directly into `appState.filterSettings.smooth` |
| Glow slider | PASS | `Sora/Views/FilterStudioSheet.swift:91-97` | Binding writes directly into `appState.filterSettings.glow` |
| Contrast slider | PASS | `Sora/Views/FilterStudioSheet.swift:99-105` | Binding writes directly into `appState.filterSettings.contrast` |
| Presets | PASS | `Sora/Views/FilterStudioSheet.swift:67-75`, `131-152` | Preset pills update preset plus slider defaults |
| Before/After | PASS | `Sora/Views/BeforeAfterButton.swift:12-37`, `Sora/Views/CameraView.swift:39`, `146` | Preview toggles between processed output and `frame.ciImage.oriented(.right)` |
| Record start | PASS | `Sora/Views/CameraView.swift:84-92`, `Sora/Recording/RecordingCoordinator.swift:29-38` | Record button calls real start path |
| Processed frame recording | PASS | `Sora/Views/CameraView.swift:42-44`, `Sora/Recording/RecordingCoordinator.swift:40-42`, `Sora/Recording/SoraAssetWriterRecorder.swift:75-122` | Processed CIImage is appended while recording state is active |
| Record stop | PASS | `Sora/Views/CameraView.swift:87-89`, `Sora/Recording/RecordingCoordinator.swift:44-67` | Stop path reaches real recorder stop and optional Photos save |
| Save to Photos | PASS | `Sora/Recording/RecordingCoordinator.swift:54-60`, `Sora/Recording/SoraPhotoLibrarySaver.swift:5-23`, `Sora/Supporting/Info.plist:29-30` | Real save call exists; lacks file-existence precheck and runtime verification |
| Save result UI | FAIL | `Sora/Recording/RecordingCoordinator.swift:60,64`, `Sora/Views/SaveResultSheet.swift:3-100`, `Sora/Views/CameraView.swift:145-159` | Result state is set but no sheet is ever presented |
| Mini gallery | FAIL | `Sora/Views/MiniGalleryStrip.swift:3-63`, `Sora/Views/ControlsOverlay.swift:36-45`, `Sora/Views/CameraView.swift:117-131` | Gallery strip exists but is unused in active camera UI |
| Quality mode | FAIL | `Sora/Views/QualityModeButton.swift:8-17`, `Sora/Camera/SoraCameraManager.swift:193-197` | UI changes state, backend does nothing |
| Lens mode | FAIL | `Sora/Views/SoraHeader.swift:29-36`, `Sora/Views/CameraView.swift:160-162`, `Sora/Camera/SoraCameraManager.swift:95-105`, `182-189` | Switching calls real logic, but unsupported ultra-wide falls back silently while UI still claims `0.5x` |
| Toasts/errors | PASS | `Sora/App/AppState.swift:27-29`, `Sora/Views/CameraView.swift:133-143`, `Sora/Views/SoraToastView.swift:3-39` | Toast surface is actually mounted and appState-driven |
| No networking | PASS | Repo search over `Sora/` found no `URLSession`, Alamofire, analytics, uploads, or remote endpoints | No network code found in inspected app sources |
| Shared core unchanged | PASS | `fc.exe` comparison against `Workspaces/Sora_BASE/Sora/App/*.swift` showed no differences | Locked shared-core files match base copies exactly |

## Exact Pipeline Trace
Camera:
- `SoraCameraManager.captureOutput(_:didOutput:from:)` receives `CMSampleBuffer`
- `CMSampleBufferGetImageBuffer(sampleBuffer)` extracts `CVPixelBuffer`
- `CIImage(cvPixelBuffer: pixelBuffer)` creates the frame image
- `SoraFrame(pixelBuffer:ciImage:timestamp:frameIndex:)` is built in `Sora/Camera/SoraCameraManager.swift:216-221`
- `onFrame?(soraFrame)` emits it in `Sora/Camera/SoraCameraManager.swift:223`

Filter:
- `CameraPipelineController.bind(appState:)` assigns `cameraManager.onFrame`
- In that closure, `self.processor.process(frame: frame, settings: appState.filterSettings)` runs in `Sora/Views/CameraView.swift:38`
- Concrete processor is `SoraFilterProcessor.process(frame:settings:)` in `Sora/Filters/SoraFilterProcessor.swift:18-38`

Preview:
- `self.renderer.render(self.showOriginal ? frame.ciImage.oriented(.right) : processed)` in `Sora/Views/CameraView.swift:39`
- `SoraPreviewRenderer.render(_:)` stores the latest image in `Sora/Rendering/SoraPreviewRenderer.swift:8-9`
- `MetalPreviewView` binds to `pipeline.previewImage` in `Sora/Views/CameraView.swift:168-173`
- `MetalPreviewView.updateUIView` copies the image into its coordinator and calls `setNeedsDisplay()` in `Sora/Rendering/MetalPreviewView.swift:24-27`
- `Coordinator.draw(in:)` renders the bound `CIImage` into the MTKView drawable in `Sora/Rendering/MetalPreviewView.swift:51-90`

Recorder:
- While recording state is active, `CameraPipelineController` calls `recordingCoordinator.appendFrame(image: processed, timestamp: frame.timestamp)` in `Sora/Views/CameraView.swift:42-43`
- `RecordingCoordinator.appendFrame` forwards to `recorder.appendFrame` in `Sora/Recording/RecordingCoordinator.swift:40-42`
- `SoraAssetWriterRecorder.appendFrame` renders the processed CIImage into a pixel buffer and appends it to `AVAssetWriterInputPixelBufferAdaptor` in `Sora/Recording/SoraAssetWriterRecorder.swift:75-122`

Photos:
- `RecordingCoordinator.stopRecording` awaits `recorder.stopRecording()` in `Sora/Recording/RecordingCoordinator.swift:49-55`
- If saving is enabled, it calls `photoSaver.saveVideoToPhotos(url: url)` in `Sora/Recording/RecordingCoordinator.swift:54-56`
- `SoraPhotoLibrarySaver.saveVideoToPhotos` requests `.addOnly` authorization and uses `PHPhotoLibrary.shared().performChanges` in `Sora/Recording/SoraPhotoLibrarySaver.swift:5-23`

Missing link:
- The pipeline ends at state update and toast. There is no active UI link from `RecordingCoordinator.saveResult` to `SaveResultSheet`, and no active UI link from `recentRecordings` to `MiniGalleryStrip`.

## Files Inspected
- `project.yml`
- `Scripts/bootstrap_project.sh`
- `Docs/MERGE_GUIDE_NO_GIT.md`
- `Docs/SHARED_CORE_LOCK.md`
- `Sora/Supporting/Info.plist`
- `Sora/App/SoraApp.swift`
- `Sora/App/AppState.swift`
- `Sora/App/SoraPipelineContract.swift`
- `Sora/App/SoraTypes.swift`
- `Sora/Camera/SoraCameraManager.swift`
- `Sora/Design/SoraTheme.swift`
- `Sora/Filters/SoraFilterProcessor.swift`
- `Sora/Rendering/MetalPreviewView.swift`
- `Sora/Rendering/SoraPreviewRenderer.swift`
- `Sora/Recording/RecordingCoordinator.swift`
- `Sora/Recording/RecordingModels.swift`
- `Sora/Recording/SoraAssetWriterRecorder.swift`
- `Sora/Recording/SoraPhotoLibrarySaver.swift`
- `Sora/Views/ContentView.swift`
- `Sora/Views/CameraView.swift`
- `Sora/Views/CameraPermissionView.swift`
- `Sora/Views/ControlsOverlay.swift`
- `Sora/Views/FilterStudioSheet.swift`
- `Sora/Views/SoraSlider.swift`
- `Sora/Views/PresetPill.swift`
- `Sora/Views/BeforeAfterButton.swift`
- `Sora/Views/RecordButton.swift`
- `Sora/Views/RecordingHUD.swift`
- `Sora/Views/SaveResultSheet.swift`
- `Sora/Views/MiniGalleryStrip.swift`
- `Sora/Views/SettingsSheet.swift`
- `Sora/Views/QualityModeButton.swift`
- `Sora/Views/SoraHeader.swift`
- `Sora/Views/SoraToastView.swift`

## Files With Highest Risk
- `Sora/Views/CameraView.swift`
  - Central wiring point for preview, filter, record start/stop, sheets, and toast; currently the place where required recording result/gallery UI is missing and where heavy per-frame work is pushed onto the main actor.
- `Sora/Camera/SoraCameraManager.swift`
  - Contains session lifecycle, permission flow, lens switching, frame emission, fake quality-mode backend, and the likely actor-isolation compile risk.
- `Sora/Recording/RecordingCoordinator.swift`
  - Owns recording state, Photos save flow, recent recordings, and `saveResult`, but the app does not surface much of what it manages.
- `Sora/Recording/SoraAssetWriterRecorder.swift`
  - Core processed-video path; hardcoded output size and runtime-only correctness make it a high-risk file until it is built and tested on device.
- `Sora/Rendering/MetalPreviewView.swift`
  - Entire live preview depends on it; no Metal failure UX and no runtime proof here.

## Recommended Fix Order
1. Restore buildability first: generate `Sora.xcodeproj` on a Mac with XcodeGen, run `xcodebuild -list`, then fix any actual compile errors starting with `SoraCameraManager` actor isolation.
2. Wire the dead recording UX into `CameraView`: present `RecordingHUD`, present `SaveResultSheet` from `recordingCoordinator.saveResult`, and mount `MiniGalleryStrip` from `recordingCoordinator.recentRecordings`.
3. Replace the fake quality mode with real camera configuration changes or remove the control until backend behavior exists.
4. Move per-frame filter processing off the main actor and re-check preview smoothness and thermal behavior.
5. Fix `frameIndex`, lens fallback truthfulness, file-existence precheck before Photos save, and broken mojibake strings.
