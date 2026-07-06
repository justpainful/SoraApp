import SwiftUI

enum SoraTheme {
    static let backgroundTop = Color(red: 0.02, green: 0.02, blue: 0.03)
    static let backgroundBottom = Color(red: 0.05, green: 0.05, blue: 0.06)
    static let accent = Color(red: 0.96, green: 0.81, blue: 0.22)
    static let accentMuted = Color(red: 0.52, green: 0.44, blue: 0.18)
    static let panel = Color.white.opacity(0.08)
    static let panelStroke = Color.white.opacity(0.12)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.66)
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
