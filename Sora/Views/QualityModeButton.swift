import SwiftUI

struct QualityModeButton: View {
    @EnvironmentObject private var appState: AppState
    let onSelect: (SoraQualityMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Performance")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SoraTheme.textPrimary)
            Text("Quality mode is coming in v0.2. Current build uses stable 1080p30.")
                .font(.caption)
                .foregroundStyle(SoraTheme.textSecondary)
        }
        .padding(12)
        .background(SoraTheme.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            appState.qualityMode = .performance
            onSelect(.performance)
        }
        .accessibilityLabel("Performance mode")
    }
}
