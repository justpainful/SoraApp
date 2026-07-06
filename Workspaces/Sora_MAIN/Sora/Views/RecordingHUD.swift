import SwiftUI

struct RecordingHUD: View {
    let state: SoraRecordingState
    var onRecordTapped: (() -> Void)?
    var onStopTapped: (() -> Void)?

    @State private var now = Date()

    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 10) {
                Circle()
                    .fill(state.accentColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: state.accentColor.opacity(0.6), radius: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.statusText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(timerText)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            Spacer(minLength: 0)

            Button(action: buttonAction) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 68, height: 68)

                    Circle()
                        .fill(buttonFill)
                        .frame(width: state.startedAt == nil ? 54 : 28, height: state.startedAt == nil ? 54 : 28)
                        .clipShape(RoundedRectangle(cornerRadius: state.startedAt == nil ? 27 : 8, style: .continuous))
                }
            }
            .buttonStyle(.plain)
            .disabled(isBusy)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .onReceive(timer) { now = $0 }
    }

    private var isBusy: Bool {
        if case .saving = state { return true }
        return false
    }

    private var buttonFill: Color {
        state.startedAt == nil ? .red : .red.opacity(0.92)
    }

    private var timerText: String {
        guard let startedAt = state.startedAt else {
            return state.statusText
        }

        let elapsed = max(0, Int(now.timeIntervalSince(startedAt)))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func buttonAction() {
        if state.startedAt == nil {
            onRecordTapped?()
        } else {
            onStopTapped?()
        }
    }
}
