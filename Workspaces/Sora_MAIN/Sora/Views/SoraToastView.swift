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

    private var normalizedTitle: String {
        toast.title.lowercased()
    }

    private var iconName: String {
        if normalizedTitle.contains("fail") || normalizedTitle.contains("denied") || normalizedTitle.contains("unavailable") {
            return "exclamationmark.triangle.fill"
        }
        return "checkmark.circle.fill"
    }

    private var iconColor: Color {
        iconName == "checkmark.circle.fill" ? SoraTheme.success : SoraTheme.warning
    }
}
