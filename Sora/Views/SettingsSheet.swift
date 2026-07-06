import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var coordinator: RecordingCoordinator
    let onSelectQuality: (SoraQualityMode) -> Void

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
                    VStack(alignment: .leading, spacing: 12) {
                        QualityModeButton(onSelect: onSelectQuality)
                            .environmentObject(appState)

                        Text("Current build uses stable 1080p30. Quality mode is limited while the recorder remains on the stable path.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
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
                    Button(action: { appState.isSettingsOpen = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                    .soraGlassCircle(interactive: true)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
