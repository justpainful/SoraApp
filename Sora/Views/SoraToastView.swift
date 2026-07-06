import SwiftUI

struct SoraToastView: View {
    let toast: SoraToast
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 34, height: 34)
                .soraGlassCircle(tint: iconColor.opacity(0.14))

            VStack(alignment: .leading, spacing: 4) {
                Text(toast.title)
                    .font(.headline.weight(.semibold))
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
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(SoraTheme.textSecondary)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .soraGlassCircle(interactive: true)
            .accessibilityLabel("Dismiss")
        }
        .padding(16)
        .soraGlassRounded(cornerRadius: 24, tint: .white.opacity(0.06))
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
