# Sora Liquid Glass UI Plan

## Goal
Prepare a native iOS 26 Liquid Glass direction for Sora without changing camera, recording, filter, or save behavior. This document only proposes isolated UI integration targets and safe fallback behavior.

## Native API Baseline
- Real Liquid Glass must use native SwiftUI iOS 26 APIs:
  - `glassEffect(_:in:)`
  - `GlassEffectContainer`
  - `glassEffectID(_:in:)`
  - `.buttonStyle(.glass)`
  - `.buttonStyle(.glassProminent)`
- If the build target or active SDK does not expose those APIs, use a clearly labeled fallback based on standard system materials. That fallback is not Liquid Glass.

## What Should Become Liquid Glass
- Top bar action cluster
  - App mark container
  - Lens switcher chips
  - Settings button
- Bottom dock action cluster
  - Record-adjacent utility actions
  - Gallery shortcut
  - Filter entry point
  - Primary capture action shell only, not recording logic
- Filter sheet chrome
  - Grabber-adjacent header controls
  - Preset chips
  - Compare toggle shell
- Save feedback surface
  - Compact confirmation toast
  - Save success and failure icon badge

## What Should Stay Plain
- Live camera preview
- Recording timer readout content
- Filter sliders and their value logic
- Dense settings list rows
- File path readouts and technical metadata
- Any text-heavy explanation blocks
- Error details that need maximum contrast and stable readability

## Text To Remove Or Reduce
- Remove persistent status prose from the top bar when an icon/state treatment is sufficient.
- Replace visible lens text emphasis with compact icon-first chips while keeping accessibility labels.
- Reduce uppercase utility labels in overlay controls where the user already recognizes the action.
- Compress save confirmation copy from sheet-sized messaging to a short toast-sized acknowledgment when used as an overlay.

## Icons That Replace Text
- Settings: `gearshape`
- Wide lens: `camera.macro.circle` fallback, keep spoken label "1x lens"
- Ultra-wide lens: `camera.aperture` fallback, keep spoken label "0.5x lens"
- Filters / Look Studio: `sparkles`
- Gallery / recent captures: `photo.on.rectangle.angled`
- Compare original: `eye`
- Compare filtered: `eye.slash`
- Save success: `checkmark`
- Save failure: `exclamationmark.triangle`
- Close / dismiss: `xmark`

## Components That Should Integrate Later
- `SoraHeader`
  - Replace the current panel with a Liquid Glass top cluster.
- `ControlsOverlay`
  - Host a Liquid Glass bottom dock around existing actions.
- `RecordButton`
  - Re-skin only after workflow fixes are merged.
- `FilterStudioSheet`
  - Adopt Liquid Glass header/preset treatment without changing slider behavior.
- `SoraToastView`
  - Convert to a compact glass confirmation surface.
- `SaveResultSheet`
  - Decide whether the final product still needs a full sheet after toast integration.

## Components That Should Not Be Glass-Heavy
- `SettingsSheet`
  - Use native navigation chrome, plain grouped list content, and minimal glass accents only if needed.
- `MiniGalleryStrip`
  - Keep content-forward thumbnails; avoid wrapping every item in glass.
- `RecordingHUD`
  - Keep timer and status plain/high-contrast; glass can frame surrounding actions but should not obscure time visibility.

## Integration Strategy After Current PR Merges
1. Land the recording/workflow fixes first.
2. Validate the active Xcode SDK exposes the iOS 26 SwiftUI Liquid Glass APIs.
3. Swap one production area at a time:
   - top bar
   - bottom dock
   - filter sheet header/chips
   - save toast
4. Re-run visual checks for contrast, camera readability, and hit targets on bright and dark footage.
5. Keep fallback branches behind availability checks for non-iOS-26 builds.

## Risks
- Glass overuse can reduce camera readability.
- Morphing transitions require stable `glassEffectID` values and deliberate animation structure.
- If the team is not yet on an iOS 26 SDK, the prototypes remain design-only and must render with fallback materials.

## Non-Goals
- No integration into `CameraView`
- No recording logic changes
- No camera pipeline changes
- No filter processing changes
- No save pipeline changes
