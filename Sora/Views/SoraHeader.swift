import SwiftUI

struct SoraHeader: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var cameraManager: SoraCameraManager

    let selectLens: (SoraLensMode) -> Void
    let selectQuality: (SoraQualityMode) -> Void
    let openSettings: () -> Void

    var body: some View {
        SoraGlassContainer(spacing: 12) {
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image("SoraLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42, height: 42)
                        .padding(4)
                        .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sora")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(SoraTheme.textPrimary)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(appState.recordingState.statusColor)
                                .frame(width: 8, height: 8)

                            Text(appState.recordingState.statusText)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(appState.recordingState.statusColor)
                        }
                    }
                }

                Spacer()

                Menu {
                    ForEach(SoraQualityMode.allCases) { mode in
                        Button {
                            selectQuality(mode)
                        } label: {
                            Label(mode == .performance ? "Performance" : "Quality", systemImage: mode == .performance ? "speedometer" : "sparkles")
                        }
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: appState.qualityMode == .performance ? "speedometer" : "sparkles")
                            .font(.system(size: 16, weight: .semibold))

                        Text(appState.qualityMode == .performance ? "SPD" : "HQ")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                }
                .soraGlassCircle(interactive: true)
                .accessibilityLabel("Quality mode")

                HStack(spacing: 8) {
                    ForEach(cameraManager.availableLensModes) { mode in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                selectLens(mode)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: mode == .wide ? "camera.macro.circle" : "camera.aperture")
                                    .font(.system(size: 13, weight: .semibold))

                                Text(mode.rawValue)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(cameraManager.currentLens == mode ? Color.black : SoraTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(cameraManager.currentLens == mode ? Color.white : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                        .soraGlassCapsule(
                            tint: cameraManager.currentLens == mode ? .white.opacity(0.18) : .white.opacity(0.08),
                            interactive: true
                        )
                        .accessibilityLabel(mode == .wide ? "1x lens" : "0.5x lens")
                        .accessibilityAddTraits(cameraManager.currentLens == mode ? [.isSelected] : [])
                    }
                }

                Button(action: openSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SoraTheme.textPrimary)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                .soraGlassCircle(interactive: true)
                .accessibilityLabel("Settings")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .soraGlassRounded(cornerRadius: 28, tint: .white.opacity(0.06))
        .padding(.horizontal, 16)
    }
}
