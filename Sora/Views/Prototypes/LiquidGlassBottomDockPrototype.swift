import SwiftUI

struct LiquidGlassBottomDockPrototype: View {
    @Namespace private var glassNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            SoraPrototypeBackdrop()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Text("Bottom dock proposal only")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))

                #if compiler(>=6.2)
                if #available(iOS 26, *) {
                    nativeDock
                } else {
                    fallbackDock
                }
                #else
                fallbackDock
                #endif
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)
        }
    }

    #if compiler(>=6.2)
    @available(iOS 26, *)
    private var nativeDock: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                prototypeAction(symbol: "photo.on.rectangle.angled", id: "gallery", label: "Recent captures")
                prototypeAction(symbol: "sparkles", id: "filters", label: "Filters")

                Button {} label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.96))
                            .frame(width: 78, height: 78)

                        Circle()
                            .fill(.red)
                            .frame(width: 58, height: 58)
                    }
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(.white.opacity(0.10)).interactive(), in: .circle)
                .glassEffectID("record-shell", in: glassNamespace)
                .accessibilityLabel("Capture")

                prototypeAction(symbol: "eye", id: "compare", label: "Compare original")
                prototypeAction(symbol: "gearshape", id: "settings", label: "Settings")
            }
        }
    }

    @available(iOS 26, *)
    private func prototypeAction(symbol: String, id: String, label: String) -> some View {
        Button {} label: {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 54, height: 54)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .glassEffectID(id, in: glassNamespace)
        .accessibilityLabel(label)
    }
    #endif

    private var fallbackDock: some View {
        HStack(alignment: .center, spacing: 16) {
            fallbackAction(symbol: "photo.on.rectangle.angled", label: "Recent captures")
            fallbackAction(symbol: "sparkles", label: "Filters")

            Button {} label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 78, height: 78)

                    Circle()
                        .fill(.red)
                        .frame(width: 58, height: 58)
                }
                .soraPrototypeFallbackPanel(cornerRadius: 39)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Capture")

            fallbackAction(symbol: "eye", label: "Compare original")
            fallbackAction(symbol: "gearshape", label: "Settings")
        }
        .overlay(alignment: .top) {
            SoraPrototypeFallbackBadge()
                .offset(y: -28)
        }
    }

    private func fallbackAction(symbol: String, label: String) -> some View {
        Button {} label: {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .soraPrototypeFallbackPanel(cornerRadius: 27)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview {
    LiquidGlassBottomDockPrototype()
}
