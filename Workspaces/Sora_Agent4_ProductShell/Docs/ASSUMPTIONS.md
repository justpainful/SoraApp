# Assumptions

- The referenced integration workspace is responsible for creating missing filter, rendering, recording, and Photos-saving modules locally because the other pods were not merged into this workspace yet.
- `SoraQualityMode` changes preview/throughput behavior only for v0.1 and does not introduce 4K, 60fps, or remote processing.
- Processed recording should always use the active Sora Look even when the user temporarily toggles the before/after preview comparison.
- The project remains iPhone portrait-only and targets iOS 17.0, so no iOS 26 Liquid Glass API is used in this workspace.
- This environment cannot execute a real iOS/Xcode build, simulator launch, or on-device camera/photo permission flow verification.
