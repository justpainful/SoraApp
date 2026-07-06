import SwiftUI

struct ControlsOverlay: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var coordinator: RecordingCoordinator
    let toggleRecording: () -> Void
    let openFilters: () -> Void

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
                HStack(spacing: 12) {
                    Button("Filters", action: openFilters)
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
                            Text("No recent clips")
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
