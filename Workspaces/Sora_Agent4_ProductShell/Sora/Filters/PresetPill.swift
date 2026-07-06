import SwiftUI

struct PresetPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? SoraTheme.backgroundTop : SoraTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? SoraTheme.accent : SoraTheme.panel)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(SoraTheme.panelStroke, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
