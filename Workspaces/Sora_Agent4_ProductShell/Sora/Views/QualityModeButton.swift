import SwiftUI

struct QualityModeButton: View {
    @EnvironmentObject private var appState: AppState
    let onSelect: (SoraQualityMode) -> Void

    var body: some View {
        Picker("quality.label", selection: $appState.qualityMode) {
            ForEach(SoraQualityMode.allCases) { mode in
                Text(mode == .performance ? "quality.performance" : "quality.quality")
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: appState.qualityMode) { _, value in
            onSelect(value)
        }
        .accessibilityLabel("quality.label")
    }
}
