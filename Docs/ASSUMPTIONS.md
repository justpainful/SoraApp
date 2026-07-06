# Assumptions

- The prior restriction against editing production UI files has been lifted by the user for this turn.
- Camera, recording, and filter processing behavior should remain unchanged unless UI wiring requires a thin pass-through callback.
- Native iOS 26 Liquid Glass APIs may not be available in the active SDK, so all production UI changes include a system-material fallback.
- Since no local Apple toolchain is available on this Windows machine, build and simulator verification must happen later on macOS/Xcode.
