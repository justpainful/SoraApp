import SwiftUI

struct RecordButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isRecording: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 96, height: 96)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
                    )
                    .soraGlassCircle(tint: .white.opacity(0.08), interactive: !isDisabled, fallbackStrokeOpacity: 0.12)

                RoundedRectangle(cornerRadius: isRecording ? 14 : 32, style: .continuous)
                    .fill(isRecording ? SoraTheme.danger : Color.white)
                    .frame(width: isRecording ? 32 : 58, height: isRecording ? 32 : 58)
                    .scaleEffect(isRecording && !reduceMotion ? 0.90 : 1)
                    .shadow(color: (isRecording ? SoraTheme.danger : Color.white).opacity(0.32), radius: 14, x: 0, y: 8)
                    .animation(.spring(response: 0.22, dampingFraction: 0.74), value: isRecording)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        .accessibilityHint("Double tap to toggle video recording")
    }
}
