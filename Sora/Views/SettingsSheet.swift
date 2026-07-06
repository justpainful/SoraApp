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
                        Text("On-device processing")
                            .font(.headline)
                        Text("Sora refines frames locally on-device and saves results through the existing local Photos flow. No frame upload or remote processing is part of the current app path.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Capture") {
                    VStack(alignment: .leading, spacing: 12) {
                        QualityModeButton(onSelect: onSelectQuality)
                            .environmentObject(appState)

                        Text("Current build prioritizes stable real-time capture. Beauty refinement stays inside the local preview pipeline and quality mode remains constrained by the current recorder path.")
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
                    Text("Current controls cover skin refinement, soft glow, tonal definition, and preset looks. Body contouring is not part of the shipped filter stack.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

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
