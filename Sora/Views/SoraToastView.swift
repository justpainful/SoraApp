import SwiftUI

struct SoraToastView: View {
    let toast: SoraToast
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(toast.title)
                    .font(.headline)
                    .foregroundStyle(SoraTheme.textPrimary)

                if let message = toast.message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(SoraTheme.textSecondary)
                }
            }

            Spacer(minLength: 8)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .foregroundStyle(SoraTheme.textSecondary)
            }
            .accessibilityLabel("Dismiss")
        }
        .padding(16)
        .soraPanel()
        .padding(.horizontal, 16)
        .task(id: toast.id) {
            try? await Task.sleep(for: .seconds(3))
            dismiss()
        }
    }

    private var normalizedText: String {
        ([toast.title, toast.message].compactMap { $0 }.joined(separator: " ")).lowercased()
    }

    private var iconName: String {
        if normalizedText.contains("fail")
            || normalizedText.contains("denied")
            || normalizedText.contains("unavailable")
            || normalizedText.contains("cannot")
            || normalizedText.contains("error")
            || normalizedText.contains("missing") {
            return "exclamationmark.triangle.fill"
        }
        return "checkmark.circle.fill"
    }

    private var iconColor: Color {
        iconName == "checkmark.circle.fill" ? SoraTheme.success : SoraTheme.warning
    }
}
