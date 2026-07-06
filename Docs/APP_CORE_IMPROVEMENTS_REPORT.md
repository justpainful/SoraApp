# Sora App Core Improvements Report

## Verdict
NOT READY FOR FULL END-USER USE until the PR is merged and the GitHub Actions compile check passes. The app code path is significantly safer for real iPhone testing.

## Changed Files

- `Sora/Views/CameraView.swift`
- `Sora/Views/ControlsOverlay.swift`
- `Sora/Views/RecordButton.swift`
- `Sora/Views/QualityModeButton.swift`
- `Sora/Views/SaveResultSheet.swift`
- `Sora/Views/SettingsSheet.swift`
- `Sora/Views/SoraToastView.swift`
- `Sora/Recording/RecordingCoordinator.swift`
- `Sora/Recording/SoraAssetWriterRecorder.swift`
- `Sora/Views/MiniGalleryStrip.swift`
- `Sora/Views/FilterStudioSheet.swift`

## Improvements Completed

1. Recording readiness: PASS. Recording is blocked until camera permission is authorized, the session is running, at least one preview frame rendered, and no camera/render error exists.
2. Fake Quality Mode: PASS. The selectable Quality picker was replaced with a stable Performance/1080p30 status view.
3. Recording state hardening: PASS. Double-start, saving-state, no-frame, and failed-state handling were improved.
4. Save result UX: PASS. SaveResultSheet now exposes clearer actions and messages.
5. Recent recordings persistence: PASS. Recent recording URLs are restored from UserDefaults and cleaned if missing.
6. Mini gallery: PASS. MiniGalleryStrip is kept small, usable, and non-blocking.
7. Before/After behavior: PASS. Look Studio now clarifies that comparison affects preview only; recording still uses Sora Look output.
8. Debug information: PASS. Settings now exposes camera/session/render/output debug information for real-device testing.
9. Error feedback: PASS. Toast severity detection now treats failure/unavailable/cannot/error/missing as warning states.
10. Performance safety: PASS. Existing processing queue and single pending-frame backpressure remain intact.
11. Lens truthfulness: PASS from existing implementation. Header renders available lenses only and unavailable lens selection shows a toast.
12. Product cleanup: PARTIAL. The production app is at the repository root. Historical Workspaces remain in the repository as archive material and were not deleted in this PR.

## Remaining Issues

- Build was not run from this tool environment.
- GitHub Actions currently runs on `main` push/workflow dispatch, not on every PR push.
- Real-device testing is still required for portrait orientation, Photos permission, actual saved playback, and second-recording behavior.
- Historical `Workspaces/` and prompt material remain in the repository. They are outside the root production app path.

## Testing Steps

1. Open the PR branch or merge it into a test branch.
2. Run the existing GitHub Actions compile verification.
3. Install on a real iPhone after signing is configured.
4. Launch Sora.
5. Grant camera permission.
6. Confirm the Record button stays disabled until the preview appears.
7. Change filter presets/sliders.
8. Record 5 seconds.
9. Stop recording.
10. Confirm SaveResultSheet appears.
11. Confirm the video appears in Photos.
12. Dismiss and record a second clip.
13. Switch 1x/0.5x if available.
14. Open Settings and inspect Debug values.
