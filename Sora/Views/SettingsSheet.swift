import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var coordinator: RecordingCoordinator

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

                Section("Recent recordings") {
                    if coordinator.recentRecordings.isEmpty {
                        Text("No recent recordings")
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
