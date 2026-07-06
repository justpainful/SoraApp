import SwiftUI

struct SoraSlider: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(SoraTheme.textPrimary)

                Spacer()

                Text(value, format: .percent.precision(.fractionLength(0)))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(SoraTheme.textSecondary)
            }

            Slider(value: $value, in: 0 ... 1)
                .tint(SoraTheme.accent)
        }
        .padding(16)
        .soraPanel()
    }
}
