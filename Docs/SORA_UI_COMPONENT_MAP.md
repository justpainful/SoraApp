# Sora UI Component Map

| Current component | Proposed replacement | Files needing later integration | Risk |
| --- | --- | --- | --- |
| `SoraHeader` | `LiquidGlassTopBarPrototype` | `Sora/Views/SoraHeader.swift`, `Sora/Views/ControlsOverlay.swift` | Medium |
| Lens mode text pills inside `SoraHeader` | Icon-first glass lens chips with spoken accessibility labels | `Sora/Views/SoraHeader.swift` | Low |
| Settings button inside `SoraHeader` | Circular glass settings action | `Sora/Views/SoraHeader.swift` | Low |
| Bottom action area inside `ControlsOverlay` | `LiquidGlassBottomDockPrototype` | `Sora/Views/ControlsOverlay.swift`, `Sora/Views/RecordButton.swift`, `Sora/Views/MiniGalleryStrip.swift` | High |
| `FilterStudioSheet` header chrome | `LiquidGlassFilterSheetPrototype` header treatment | `Sora/Views/FilterStudioSheet.swift` | Medium |
| Preset pills in `FilterStudioSheet` | Glass chips grouped in a shared container | `Sora/Views/FilterStudioSheet.swift`, `Sora/Views/PresetPill.swift` | Medium |
| `BeforeAfterButton` text-heavy compare toggle | Icon-led compare chip in sheet footer | `Sora/Views/FilterStudioSheet.swift`, `Sora/Views/BeforeAfterButton.swift` | Medium |
| `SoraToastView` | `LiquidGlassSaveToastPrototype` | `Sora/Views/SoraToastView.swift` | Low |
| `SaveResultSheet` | Optional compact toast-first save acknowledgment | `Sora/Views/SaveResultSheet.swift`, `Sora/Views/SoraToastView.swift` | Medium |
| `SettingsSheet` | Keep mostly plain; optionally adopt system glass button styles only in toolbar actions | `Sora/Views/SettingsSheet.swift` | Low |
| `RecordingHUD` | Keep plain timing/status content; do not glass the timer body unless readability passes on live footage | `Sora/Views/RecordingHUD.swift` | Low |
| `MiniGalleryStrip` | Keep thumbnail-forward strip; avoid all-glass cards | `Sora/Views/MiniGalleryStrip.swift` | Low |

## Merge-Safe Notes
- This proposal does not modify any listed integration file.
- The prototypes are intentionally isolated in `Sora/Views/Prototypes`.
- Integration should happen only after the current recording/workflow PR is merged.
