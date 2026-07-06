import SwiftUI

struct SaveResultSheet: View {
    let result: SaveResult
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(.white.opacity(0.18))
                .frame(width: 42, height: 5)
                .padding(.top, 8)

            Image(systemName: iconName)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(message)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.76))
                .multilineTextAlignment(.center)

            if case .success(let localURL) = result {
                VStack(spacing: 8) {
                    Text("Local file")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))

                    Text(localURL.lastPathComponent)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button("Done") {
                onDismiss?()
            }
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.08, blue: 0.16),
                    Color(red: 0.04, green: 0.14, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var iconName: String {
        switch result {
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch result {
        case .success:
            return .green
        case .failure:
            return .orange
        }
    }

    private var title: String {
        switch result {
        case .success:
            return "Saved"
        case .failure:
            return "Couldn’t Save"
        }
    }

    private var message: String {
        switch result {
        case .success:
            return "Your video is ready locally and has been sent to Photos."
        case .failure(let message):
            return message
        }
    }
}
