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


# Your assignment: Agent 4 — Product Shell + Final Integration

Build the premium app shell and integrate all feature pods.

Own these areas primarily:
- `Sora/Views/CameraView.swift`
- `Sora/Views/ControlsOverlay.swift`
- `Sora/Views/SoraHeader.swift`
- `Sora/Views/RecordButton.swift`
- `Sora/Views/QualityModeButton.swift`
- `Sora/Views/SettingsSheet.swift`
- `Sora/Views/SoraToastView.swift`
- `Sora/Design/`
- `Sora/Assets.xcassets/`

Required:
- Build main `CameraView`.
- Build `ControlsOverlay`.
- Use the Sora blue cloud mascot/logo from assets.
- Premium dark/blue visual identity.
- Animated record button.
- Quality mode selector.
- Settings sheet with local-only privacy note.
- Toasts for success/errors.
- Integrate CameraManager, SoraFilterProcessor, VideoRenderer, and VideoRecorder through `AppState` and shared protocols.
- Do not rewrite feature modules unless required to fix integration.

Final QA:
- Build errors.
- Permission flow.
- Preview.
- Filter sliders.
- Recording.
- Save to Photos.
- Second recording.

Success definition:
- App feels like one polished product.
- No fake buttons.
- No broken screens.
- Project builds on a real iPhone target.
