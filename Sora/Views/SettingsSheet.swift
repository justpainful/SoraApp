import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var coordinator: RecordingCoordinator
    @ObservedObject var cameraManager: SoraCameraManager
    let hasRenderedFrame: Bool
    let latestOutputSize: CGSize
    let renderErrorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Privacy") {
                    Text("Sora works on device and does not use networking.")
                        .font(.subheadline)
                }

                Section("Capture") {
                    Text("Current build uses stable 1080p30. Quality mode is coming in v0.2.")
                        .font(.subheadline)
                }

                Section("Recent clips") {
                    if coordinator.recentRecordings.isEmpty {
                        Text("No recent clips")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(coordinator.recentRecordings, id: \.self) { url in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(url.lastPathComponent)
                                Text(url.path)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }

                Section("Filters") {
                    Button("Reset filters") {
                        appState.resetFilters()
                    }
                }

                Section("Debug") {
                    LabeledContent("Authorization", value: String(describing: cameraManager.authorizationStatus))
                    LabeledContent("Running", value: cameraManager.isRunning ? "Yes" : "No")
                    LabeledContent("Lens", value: cameraManager.currentLens.rawValue)
                    LabeledContent("Lenses", value: cameraManager.availableLensModes.map(\.rawValue).joined(separator: ", "))
                    LabeledContent("Preview", value: hasRenderedFrame ? "Ready" : "Waiting")
                    LabeledContent("Output", value: "\(Int(latestOutputSize.width)) × \(Int(latestOutputSize.height))")
                    LabeledContent("State", value: appState.recordingState.statusText)
                    LabeledContent("Last", value: appState.lastSavedVideoURL?.lastPathComponent ?? "None")
                    LabeledContent("Cam error", value: cameraManager.sessionErrorMessage ?? "None")
                    LabeledContent("Render error", value: renderErrorMessage ?? "None")
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [SoraTheme.backgroundTop, SoraTheme.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        appState.isSettingsOpen = false
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
