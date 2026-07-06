import SwiftUI

struct ControlsOverlay: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var coordinator: RecordingCoordinator
    @Binding var showOriginal: Bool

    let toggleRecording: () -> Void
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
                .soraGlassRounded(cornerRadius: 18, tint: .orange.opacity(0.12), fallbackStrokeOpacity: 0.08)
                .padding(.horizontal, 16)
            }

            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                        showOriginal.toggle()
                    }
                } label: {
                    compactControl(
                        title: showOriginal ? "Filtered" : "Original",
                        systemImage: showOriginal ? "eye.slash" : "eye",
                        isActive: showOriginal
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Compare original camera image")

                if !coordinator.recentRecordings.isEmpty {
                    compactControl(
                        title: "Recent",
                        systemImage: "photo.on.rectangle.angled",
                        isActive: false
                    )
                    .opacity(0.92)
                    .accessibilityHidden(true)
                }

                Spacer(minLength: 0)

                Button {
                    appState.resetFilters()
                } label: {
                    compactControl(
                        title: "Reset",
                        systemImage: "arrow.counterclockwise",
                        isActive: false
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)

            ZStack {
                HStack {
                    if let latestRecording = coordinator.recentRecordings.first {
                        ShareLink(item: latestRecording) {
                            actionButton(systemImage: "photo.on.rectangle.angled")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Share latest recording")
                    } else {
                        actionButton(systemImage: "photo.on.rectangle.angled")
                            .opacity(0.45)
                            .accessibilityHidden(true)
                    }

                    Spacer(minLength: 0)

                    Button(action: openFilters) {
                        actionButton(systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(.plain)
                }

                RecordButton(
                    isRecording: appState.isRecording,
                    isDisabled: appState.recordingState == .saving
                ) {
                    toggleRecording()
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 24)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: appState.recordingState.statusText)
    }

    private func compactControl(title: String, systemImage: String, isActive: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))

            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(isActive ? Color.black : Color.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Capsule().fill(isActive ? Color.white : Color.clear))
        .soraGlassCapsule(
            tint: isActive ? .white.opacity(0.18) : .white.opacity(0.06),
            interactive: true,
            fallbackStrokeOpacity: 0.08
        )
    }

    private func actionButton(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 19, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 52, height: 52)
            .soraGlassCircle(interactive: true, fallbackStrokeOpacity: 0.08)
    }
}
