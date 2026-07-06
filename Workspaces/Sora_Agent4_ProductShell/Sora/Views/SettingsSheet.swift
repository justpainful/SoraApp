import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var coordinator: RecordingCoordinator

    var body: some View {
        NavigationStack {
            List {
                Section("privacy.title") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("privacy.local_only")
                            .font(.headline)
                        Text("privacy.local_only_note")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("quality.title") {
                    Text(appState.qualityMode == .performance ? "quality.performance_note" : "quality.quality_note")
                        .font(.subheadline)
                }

                Section("recording.recent") {
                    if coordinator.recentRecordings.isEmpty {
                        Text("recording.empty_recent")
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

                Section("filter.title") {
                    Button("filter.reset") {
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
                    Button("common.done") {
                        appState.isSettingsOpen = false
                    }
                }
            }
            .navigationTitle("settings.title")
        }
    }
}
