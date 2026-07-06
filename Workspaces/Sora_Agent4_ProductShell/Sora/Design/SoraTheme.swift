import SwiftUI

enum SoraTheme {
    static let backgroundTop = Color(red: 0.02, green: 0.05, blue: 0.12)
    static let backgroundBottom = Color(red: 0.03, green: 0.17, blue: 0.34)
    static let accent = Color(red: 0.27, green: 0.67, blue: 1.0)
    static let accentMuted = Color(red: 0.16, green: 0.39, blue: 0.74)
    static let panel = Color.white.opacity(0.12)
    static let panelStroke = Color.white.opacity(0.18)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let danger = Color(red: 1.0, green: 0.32, blue: 0.39)
    static let success = Color(red: 0.36, green: 0.87, blue: 0.58)
    static let warning = Color(red: 1.0, green: 0.77, blue: 0.35)
}

struct SoraPanelBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(SoraTheme.panelStroke, lineWidth: 1)
            )
    }
}

extension View {
    func soraPanel() -> some View {
        modifier(SoraPanelBackground())
    }
}
