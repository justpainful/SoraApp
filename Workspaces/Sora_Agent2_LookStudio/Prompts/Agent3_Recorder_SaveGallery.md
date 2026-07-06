Before coding, read:
- Sora/App/SoraTypes.swift
- Sora/App/AppState.swift
- Sora/App/SoraPipelineContract.swift
- Docs/SHARED_CORE_LOCK.md
- Docs/AGENT_RULES.md

These files are locked. Do not modify them.

You must implement your feature using the existing shared contracts only.

If you need a shared change, do not edit shared core. Write an Integration Request instead.

The project must build after your changes.

Project context:
We are building Sora, a local-only iOS SwiftUI camera app for iPhone. The MVP must be finished before tomorrow.

Final app must have:
- Premium Sora UI using the blue cloud mascot/logo.
- Live camera preview.
- Natural Sora Look filter with Smooth, Glow, Contrast, and presets.
- Processed video recording.
- Save to Photos.
- Stable real-device build.

Tech:
- SwiftUI
- AVFoundation
- Core Image
- Metal / MTKView
- AVAssetWriter
- PhotoKit

Rules:
- Start with stable 1080p30.
- Do not build 4K60 now.
- Do not add networking.
- Keep everything on-device.
- Do not reshape bodies or alter anatomy.
- Do not touch files outside your assigned feature pod unless required for integration.


# Your assignment: Agent 3 — Sora Recorder

Build the complete processed-video recording and save system.

Own these areas only:
- `Sora/Recording/`
- `Sora/Views/RecordingHUD.swift`
- `Sora/Views/SaveResultSheet.swift`
- `Sora/Views/MiniGalleryStrip.swift`

Required:
- Use `AVAssetWriter`.
- Receive processed `CIImage` frames and `CMTime` timestamps.
- Render processed `CIImage` into `CVPixelBuffer`.
- Append frames using `AVAssetWriterInputPixelBufferAdaptor`.
- Save final `.mov` locally.
- Save the video to Photos using PhotoKit.
- Build `RecordingHUD` with timer and state.
- Build `SaveResultSheet` after saving.
- Build a simple `MiniGalleryStrip` for recent local recording URLs.
- Start video-only for reliability. Audio can be v0.2 and must not block MVP.

Do not implement camera capture, filters, or global app styling.

Success definition:
- Start recording works.
- Stop recording returns a local `.mov` URL.
- Save to Photos works.
- Two recordings in a row do not crash.
- Project builds.
