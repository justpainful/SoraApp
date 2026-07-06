import SwiftUI

enum SoraLiquidGlassNotes {
    static let requiredNativeAPIs = [
        "glassEffect(_:in:)",
        "GlassEffectContainer",
        "glassEffectID(_:in:)",
        ".buttonStyle(.glass)",
        ".buttonStyle(.glassProminent)"
    ]

    static let fallbackLabel = "Fallback Material"

    static let integrationTargets = [
        "SoraHeader",
        "ControlsOverlay",
        "FilterStudioSheet",
        "SoraToastView",
        "SaveResultSheet"
    ]
}

struct SoraPrototypeBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.05, blue: 0.09),
                Color(red: 0.06, green: 0.11, blue: 0.18),
                Color(red: 0.10, green: 0.15, blue: 0.24)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 220, height: 220)
                .blur(radius: 60)
                .offset(x: 50, y: -40)
                .accessibilityHidden(true)
        }
    }
}

struct SoraPrototypeFallbackBadge: View {
    var body: some View {
        Text(SoraLiquidGlassNotes.fallbackLabel)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.78))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.35), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .accessibilityLabel("Fallback material presentation")
    }
}

struct SoraPrototypeFallbackPanelModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
    }
}

extension View {
    func soraPrototypeFallbackPanel(cornerRadius: CGFloat = 24) -> some View {
        modifier(SoraPrototypeFallbackPanelModifier(cornerRadius: cornerRadius))
    }
}
