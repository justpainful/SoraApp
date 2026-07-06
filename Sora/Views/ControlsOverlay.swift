import SwiftUI

struct ControlsOverlay: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var coordinator: RecordingCoordinator
    @Binding var showOriginal: Bool

    let toggleRecording: () -> Void
    let selectQuality: (SoraQualityMode) -> Void
    let openFilters: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            if let message = appState.recordingState.failureMessage {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(SoraTheme.warning)

                    Text(message)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(SoraTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .soraGlassRounded(cornerRadius: 20, tint: .orange.opacity(0.12))
                .padding(.horizontal, 16)
            }

            HStack(spacing: 12) {
                statusCard

                if let latestRecording = coordinator.recentRecordings.first {
                    ShareLink(item: latestRecording) {
                        actionPill(
                            title: "Share",
                            systemImage: "photo.on.rectangle.angled",
                            isActive: true
                        )
                    }
                    .accessibilityLabel("Share latest recording")
                } else {
                    actionPill(
                        title: "Share",
                        systemImage: "photo.on.rectangle.angled",
                        isActive: false
                    )
                    .opacity(0.5)
                    .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)

            SoraGlassContainer(spacing: 12) {
                HStack(alignment: .center, spacing: 14) {
                    Menu {
                        ForEach(SoraQualityMode.allCases) { mode in
                            Button {
                                selectQuality(mode)
                            } label: {
                                Label(mode.rawValue, systemImage: mode == .performance ? "speedometer" : "sparkles")
                            }
                        }
                    } label: {
                        actionPill(
                            title: appState.qualityMode == .performance ? "Speed" : "Quality",
                            systemImage: appState.qualityMode == .performance ? "speedometer" : "sparkles",
                            isActive: true
                        )
                    }
                    .accessibilityLabel("Select quality mode")

                    Button(action: openFilters) {
                        actionPill(title: "Looks", systemImage: "slider.horizontal.3", isActive: appState.isFilterStudioOpen)
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)

                    RecordButton(
                        isRecording: appState.isRecording,
                        isDisabled: appState.recordingState == .saving
                    ) {
                        toggleRecording()
                    }

                    Spacer(minLength: 0)

                    Button {
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
                            showOriginal.toggle()
                        }
                    } label: {
                        actionPill(
                            title: showOriginal ? "Filtered" : "Original",
                            systemImage: showOriginal ? "eye.slash" : "eye",
                            isActive: showOriginal
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Compare original camera image")

                    Button {
                        appState.resetFilters()
                    } label: {
                        actionPill(title: "Reset", systemImage: "arrow.counterclockwise", isActive: false)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 20)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: appState.recordingState.statusText)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(appState.recordingState.statusText)
                .font(.headline.weight(.semibold))
                .foregroundStyle(appState.recordingState.statusColor)

            if let url = coordinator.recentRecordings.first {
                Text(url.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(SoraTheme.textSecondary)
                    .lineLimit(1)
            } else {
                Text("No recent clips")
                    .font(.caption)
                    .foregroundStyle(SoraTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .soraGlassRounded(cornerRadius: 22, tint: .white.opacity(0.06))
    }

    private func actionPill(title: String, systemImage: String, isActive: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))

            Text(title)
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(isActive ? Color.black : Color.white)
        .frame(width: 66, height: 66)
        .background(
            Circle()
                .fill(isActive ? Color.white : Color.clear)
        )
        .soraGlassCircle(
            tint: isActive ? .white.opacity(0.18) : .white.opacity(0.08),
            interactive: true
        )
    }
}
