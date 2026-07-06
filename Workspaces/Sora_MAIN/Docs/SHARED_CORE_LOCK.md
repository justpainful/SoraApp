# Sora Shared Core Lock

Locked files:
- `Sora/App/SoraTypes.swift`
- `Sora/App/AppState.swift`
- `Sora/App/SoraPipelineContract.swift`

Rules:
1. Do not modify these files.
2. Do not rename shared types.
3. Do not change protocol method names.
4. Do not move shared files.
5. Only the integrator may modify shared core.
6. Do not add networking.
7. Do not add 4K60 for v0.1.
8. Do not reshape bodies or alter anatomy.

Every feature must communicate through:
- `SoraFrame`
- `SoraFilterSettings`
- `AppState`
- `SoraCameraFrameOutput`
- `SoraImageProcessing`
- `SoraLiveRendering`
- `SoraVideoRecording`
- `SoraPhotoSaving`
