import SwiftUI

struct SaveResultSheet: View {
    let result: SaveResult
    var onDismiss: (() -> Void)?
    var onRecordAgain: (() -> Void)?

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
                        .lineLimit(2)

                    ShareLink(item: localURL) {
                        Label("Share clip", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.top, 4)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            HStack(spacing: 12) {
                Button("Dismiss") {
                    onDismiss?()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button("Record Again") {
                    onRecordAgain?()
                }
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
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
            return "Could not save"
        }
    }

    private var message: String {
        switch result {
        case .success:
            return "Your clip was saved locally and sent to Photos. You can record another clip now."
        case .failure(let message):
            return message
        }
    }
}
