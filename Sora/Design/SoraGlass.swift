import SwiftUI

struct SoraGlassContainer<Content: View>: View {
    private let spacing: CGFloat?
    private let content: Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

private struct SoraGlassFallbackRounded: ViewModifier {
    let cornerRadius: CGFloat
    let strokeOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(strokeOpacity), lineWidth: 1)
            )
    }
}

private struct SoraGlassFallbackCapsule: ViewModifier {
    let strokeOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(strokeOpacity), lineWidth: 1)
            )
    }
}

private struct SoraGlassFallbackCircle: ViewModifier {
    let strokeOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(strokeOpacity), lineWidth: 1)
            )
    }
}

extension View {
    @ViewBuilder
    func soraGlassRounded(
        cornerRadius: CGFloat = 24,
        tint: Color = .white.opacity(0.08),
        interactive: Bool = false,
        fallbackStrokeOpacity: Double = 0.16
    ) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            if interactive {
                self.glassEffect(.regular.tint(tint).interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                self.glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            self.modifier(SoraGlassFallbackRounded(cornerRadius: cornerRadius, strokeOpacity: fallbackStrokeOpacity))
        }
        #else
        self.modifier(SoraGlassFallbackRounded(cornerRadius: cornerRadius, strokeOpacity: fallbackStrokeOpacity))
        #endif
    }

    @ViewBuilder
    func soraGlassCapsule(
        tint: Color = .white.opacity(0.08),
        interactive: Bool = false,
        fallbackStrokeOpacity: Double = 0.16
    ) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            if interactive {
                self.glassEffect(.regular.tint(tint).interactive(), in: .capsule)
            } else {
                self.glassEffect(.regular.tint(tint), in: .capsule)
            }
        } else {
            self.modifier(SoraGlassFallbackCapsule(strokeOpacity: fallbackStrokeOpacity))
        }
        #else
        self.modifier(SoraGlassFallbackCapsule(strokeOpacity: fallbackStrokeOpacity))
        #endif
    }

    @ViewBuilder
    func soraGlassCircle(
        tint: Color = .white.opacity(0.08),
        interactive: Bool = false,
        fallbackStrokeOpacity: Double = 0.16
    ) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            if interactive {
                self.glassEffect(.regular.tint(tint).interactive(), in: .circle)
            } else {
                self.glassEffect(.regular.tint(tint), in: .circle)
            }
        } else {
            self.modifier(SoraGlassFallbackCircle(strokeOpacity: fallbackStrokeOpacity))
        }
        #else
        self.modifier(SoraGlassFallbackCircle(strokeOpacity: fallbackStrokeOpacity))
        #endif
    }
}
