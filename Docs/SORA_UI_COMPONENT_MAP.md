# Sora UI Component Map

| Current component | Proposed replacement | Files needing later integration | Risk |
| --- | --- | --- | --- |
| `SoraHeader` | Glass top bar integrated from the prototype direction | Device validation only | Medium |
| Lens mode text pills inside `SoraHeader` | Icon-first glass lens chips with spoken accessibility labels | `Sora/Views/SoraHeader.swift` | Low |
| Settings button inside `SoraHeader` | Circular glass settings action | Device validation only | Low |
| Bottom action area inside `ControlsOverlay` | Glass bottom dock integrated from the prototype direction | Device validation only | High |
| `FilterStudioSheet` header chrome | Glass header treatment integrated | Device validation only | Medium |
| Preset pills in `FilterStudioSheet` | Glass chips grouped in a shared container | Device validation only | Medium |
| `BeforeAfterButton` text-heavy compare toggle | Icon-led compare chip in sheet footer and bottom dock | Device validation only | Medium |
| `SoraToastView` | Compact glass confirmation surface integrated | Device validation only | Low |
| `SaveResultSheet` | Glass-styled result sheet retained for now | Product decision pending | Medium |
| `SettingsSheet` | Keep mostly plain; optionally adopt system glass button styles only in toolbar actions | `Sora/Views/SettingsSheet.swift` | Low |
| `RecordingHUD` | Keep plain timing/status content; do not glass the timer body unless readability passes on live footage | `Sora/Views/RecordingHUD.swift` | Low |
| `MiniGalleryStrip` | Keep thumbnail-forward strip; avoid all-glass cards | `Sora/Views/MiniGalleryStrip.swift` | Low |

## Merge-Safe Notes
- This proposal does not modify any listed integration file.
- The prototypes are intentionally isolated in `Sora/Views/Prototypes`.
- Integration should happen only after the current recording/workflow PR is merged.
