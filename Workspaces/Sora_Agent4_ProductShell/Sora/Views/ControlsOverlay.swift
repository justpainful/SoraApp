import SwiftUI

struct ControlsOverlay: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var coordinator: RecordingCoordinator
    let toggleRecording: () -> Void
    let openFilters: () -> Void
    let selectQualityMode: (SoraQualityMode) -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let message = appState.recordingState.failureMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(SoraTheme.textPrimary)
                    .padding(12)
                    .soraPanel()
                    .padding(.horizontal, 16)
            }

            VStack(spacing: 12) {
                QualityModeButton(onSelect: selectQualityMode)

                HStack(spacing: 12) {
                    Button("filter.open", action: openFilters)
                        .buttonStyle(.borderedProminent)
                        .tint(SoraTheme.accent)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(appState.recordingState.statusText)
                            .font(.headline)
                            .foregroundStyle(appState.recordingState.statusColor)

                        if let url = coordinator.recentRecordings.first {
                            Text(url.lastPathComponent)
                                .font(.caption2)
                                .foregroundStyle(SoraTheme.textSecondary)
                                .lineLimit(1)
                        } else {
                            Text("recording.empty_recent")
                                .font(.caption2)
                                .foregroundStyle(SoraTheme.textSecondary)
                        }
                    }
                }
            }
            .padding(16)
            .soraPanel()
            .padding(.horizontal, 16)

            HStack {
                Spacer()
                RecordButton(
                    isRecording: appState.isRecording,
                    isDisabled: appState.recordingState == .saving
                ) {
                    toggleRecording()
                }
                Spacer()
            }
        }
        .padding(.bottom, 20)
    }
}
