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


# Your assignment: Agent 2 — Sora Look Studio

Build the complete visual filter engine and filter control UI.

Own these areas only:
- `Sora/Filters/`
- `Sora/Views/FilterStudioSheet.swift`
- `Sora/Views/SoraSlider.swift`
- `Sora/Views/PresetPill.swift`
- `Sora/Views/BeforeAfterButton.swift`

Required:
- Create `SoraFilterProcessor` that receives `SoraFrame + SoraFilterSettings` and returns processed `CIImage`.
- Use built-in Core Image filters only for MVP:
  - `CIExposureAdjust`
  - `CIHighlightShadowAdjust`
  - `CIColorControls`
  - `CIGaussianBlur`
  - blend/composite filters
- Create presets: Natural, Clean, Soft, Cinematic.
- Create premium SwiftUI `FilterStudioSheet`.
- Add Smooth, Glow, and Contrast sliders.
- Add reset and preset pills.
- Keep the look natural and stable in real-time video.
- Do not reshape bodies or alter anatomy.

Do not implement camera capture, Metal rendering, recording, or Photos saving.

Success definition:
- Processor returns a valid `CIImage`.
- Sliders update `AppState.filterSettings`.
- Presets work.
- Project builds.
