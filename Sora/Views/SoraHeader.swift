import SwiftUI

struct SoraHeader: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var cameraManager: SoraCameraManager

    let selectLens: (SoraLensMode) -> Void
    let selectQuality: (SoraQualityMode) -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                HStack {
                    Menu {
                        ForEach(SoraQualityMode.allCases) { mode in
                            Button {
                                selectQuality(mode)
                            } label: {
                                Label(mode == .performance ? "Performance" : "Quality", systemImage: mode == .performance ? "speedometer" : "sparkles")
                            }
                        }
                    } label: {
                        Image(systemName: appState.qualityMode == .performance ? "speedometer" : "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    .soraGlassCircle(interactive: true, fallbackStrokeOpacity: 0.08)
                    .accessibilityLabel("Quality mode")

                    Spacer(minLength: 0)

                    Button(action: openSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .soraGlassCircle(interactive: true, fallbackStrokeOpacity: 0.08)
                    .accessibilityLabel("Settings")
                }

                SoraGlassContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(cameraManager.availableLensModes) { mode in
                            Button {
                                withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                                    selectLens(mode)
                                }
                            } label: {
                                Text(mode.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(cameraManager.currentLens == mode ? .black : .white)
                                    .frame(minWidth: 56)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(cameraManager.currentLens == mode ? Color.white : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                            .soraGlassCapsule(
                                tint: cameraManager.currentLens == mode ? .white.opacity(0.18) : .white.opacity(0.06),
                                interactive: true,
                                fallbackStrokeOpacity: 0.08
                            )
                            .accessibilityLabel(mode == .wide ? "1x lens" : "0.5x lens")
                            .accessibilityAddTraits(cameraManager.currentLens == mode ? [.isSelected] : [])
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            if appState.recordingState != .idle {
                HStack(spacing: 8) {
                    Circle()
                        .fill(appState.recordingState.statusColor)
                        .frame(width: 8, height: 8)

                    Text(appState.recordingState.statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .soraGlassCapsule(tint: .white.opacity(0.06), fallbackStrokeOpacity: 0.08)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
