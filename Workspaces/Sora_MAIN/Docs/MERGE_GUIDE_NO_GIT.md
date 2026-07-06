# No-Git Merge Guide for Sora

Use `Workspaces/Sora_MAIN` as the final merge folder.

Copy only these folders/files from each agent workspace:

## Agent 1 → Sora_MAIN
- `Sora/Camera/`
- `Sora/Rendering/`
- `Sora/Views/CameraPermissionView.swift`

## Agent 2 → Sora_MAIN
- `Sora/Filters/`
- `Sora/Views/FilterStudioSheet.swift`
- `Sora/Views/SoraSlider.swift`
- `Sora/Views/PresetPill.swift`
- `Sora/Views/BeforeAfterButton.swift`

## Agent 3 → Sora_MAIN
- `Sora/Recording/`
- `Sora/Views/RecordingHUD.swift`
- `Sora/Views/SaveResultSheet.swift`
- `Sora/Views/MiniGalleryStrip.swift`

## Agent 4 → Sora_MAIN
- `Sora/Views/CameraView.swift`
- `Sora/Views/ControlsOverlay.swift`
- `Sora/Views/SoraHeader.swift`
- `Sora/Views/RecordButton.swift`
- `Sora/Views/QualityModeButton.swift`
- `Sora/Views/SettingsSheet.swift`
- `Sora/Views/SoraToastView.swift`
- `Sora/Design/`
- `Sora/Assets.xcassets/`

Do not overwrite locked shared core files unless the integrator explicitly decides to change them.
