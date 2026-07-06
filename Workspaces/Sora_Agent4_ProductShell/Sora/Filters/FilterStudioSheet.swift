import SwiftUI

struct FilterStudioSheet: View {
    @EnvironmentObject private var appState: AppState
    @Binding var showOriginal: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("filter.title")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(SoraTheme.textPrimary)

                        Text("filter.subtitle")
                            .font(.subheadline)
                            .foregroundStyle(SoraTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("filter.presets")
                            .font(.headline)
                            .foregroundStyle(SoraTheme.textPrimary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(SoraPreset.allCases) { preset in
                                    PresetPill(
                                        title: preset.rawValue,
                                        isSelected: appState.filterSettings.preset == preset
                                    ) {
                                        appState.filterSettings = .preset(preset)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    VStack(spacing: 16) {
                        SoraSlider(
                            title: SoraStrings.text("filter.smooth"),
                            value: Binding(
                                get: { Double(appState.filterSettings.smooth) },
                                set: { appState.filterSettings.smooth = Float($0) }
                            )
                        )

                        SoraSlider(
                            title: SoraStrings.text("filter.glow"),
                            value: Binding(
                                get: { Double(appState.filterSettings.glow) },
                                set: { appState.filterSettings.glow = Float($0) }
                            )
                        )

                        SoraSlider(
                            title: SoraStrings.text("filter.contrast"),
                            value: Binding(
                                get: { Double(appState.filterSettings.contrast) },
                                set: { appState.filterSettings.contrast = Float($0) }
                            )
                        )
                    }

                    HStack(spacing: 12) {
                        BeforeAfterButton(showOriginal: $showOriginal)

                        Button("filter.reset") {
                            appState.resetFilters()
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
                }
                .padding(20)
            }
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
                        appState.isFilterStudioOpen = false
                    }
                    .foregroundStyle(SoraTheme.textPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
