import AVFoundation
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Local-only processing")
                            .font(.headline)
                        Text("Sora processes camera frames on-device and does not use networking.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
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
                    LabeledContent("Authorization", value: cameraManager.authorizationStatus.debugText)
                    LabeledContent("Camera running", value: cameraManager.isRunning ? "Yes" : "No")
                    LabeledContent("Current lens", value: cameraManager.currentLens.rawValue)
                    LabeledContent("Available lenses", value: cameraManager.availableLensModes.map(\.rawValue).joined(separator: ", "))
                    LabeledContent("Preview frame", value: hasRenderedFrame ? "Ready" : "Waiting")
                    LabeledContent("Output size", value: "\(Int(latestOutputSize.width)) × \(Int(latestOutputSize.height))")
                    LabeledContent("State", value: appState.recordingState.statusText)
                    LabeledContent("Last saved", value: appState.lastSavedVideoURL?.lastPathComponent ?? "None")
                    LabeledContent("Camera error", value: cameraManager.sessionErrorMessage ?? "None")
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
            .onAppear {
                coordinator.cleanRecentRecordings()
            }
        }
    }
}

private extension AVAuthorizationStatus {
    var debugText: String {
        switch self {
        case .notDetermined: return "Not determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        @unknown default: return "Unknown"
        }
    }
}
