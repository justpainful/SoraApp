import SwiftUI

struct SoraHeader: View {
    @EnvironmentObject private var appState: AppState
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
                    Text("app.name")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(SoraTheme.textPrimary)

                    Text(appState.recordingState.statusText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(appState.recordingState.statusColor)
                }
            }

            Spacer()

            Picker("lens.label", selection: $appState.lensMode) {
                ForEach(SoraLensMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 140)
            .accessibilityLabel("lens.label")

            Button(action: openSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.headline)
                    .foregroundStyle(SoraTheme.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(SoraTheme.panel, in: Circle())
            }
            .accessibilityLabel("settings.title")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .soraPanel()
        .padding(.horizontal, 16)
    }
}
