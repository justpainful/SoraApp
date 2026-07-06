import SwiftUI

struct SoraHeader: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var cameraManager: SoraCameraManager

    let selectLens: (SoraLensMode) -> Void
    let openSettings: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image("SoraLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Sora")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(SoraTheme.textPrimary)

                    Text(appState.recordingState.statusText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(appState.recordingState.statusColor)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                ForEach(cameraManager.availableLensModes) { mode in
                    Button {
                        selectLens(mode)
                    } label: {
                        Text(mode.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(cameraManager.currentLens == mode ? Color.black : SoraTheme.textPrimary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule()
                                    .fill(cameraManager.currentLens == mode ? Color.white : SoraTheme.panel)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(mode == .wide ? "1x lens" : "0.5x lens")
                }
            }

            Button(action: openSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.headline)
                    .foregroundStyle(SoraTheme.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(SoraTheme.panel, in: Circle())
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .soraPanel()
        .padding(.horizontal, 16)
    }
}
