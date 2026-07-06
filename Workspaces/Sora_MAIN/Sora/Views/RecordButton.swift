import SwiftUI

struct RecordButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isRecording: Bool
    let isDisabled: Bool
    var disabledReason: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 88, height: 88)

                Circle()
                    .strokeBorder(Color.white.opacity(0.26), lineWidth: 2)
                    .frame(width: 76, height: 76)

                RoundedRectangle(cornerRadius: isRecording ? 14 : 32, style: .continuous)
                    .fill(isRecording ? SoraTheme.danger : Color.white)
                    .frame(width: isRecording ? 32 : 58, height: isRecording ? 32 : 58)
                    .scaleEffect(isRecording && !reduceMotion ? 0.92 : 1)
                    .animation(.easeInOut(duration: 0.18), value: isRecording)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        .accessibilityHint(disabledReason ?? "Double tap to toggle video recording")
    }
}
