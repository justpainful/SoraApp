import SwiftUI

struct LiquidGlassTopBarPrototype: View {
    @Namespace private var glassNamespace

    @State private var selectedLens = PrototypeLens.wide

    var body: some View {
        ZStack(alignment: .top) {
            SoraPrototypeBackdrop()
                .ignoresSafeArea()

            VStack(spacing: 18) {
                #if compiler(>=6.2)
                if #available(iOS 26, *) {
                    nativeTopBar
                } else {
                    fallbackTopBar
                }
                #else
                fallbackTopBar
                #endif

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
        }
    }

    #if compiler(>=6.2)
    @available(iOS 26, *)
    private var nativeTopBar: some View {
        GlassEffectContainer(spacing: 14) {
            HStack(spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles.tv")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.tint(.white.opacity(0.12)), in: .circle)
                        .glassEffectID("logo", in: glassNamespace)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sora")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)

                        Text("Ready")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    ForEach(PrototypeLens.allCases) { lens in
                        Button {
                            withAnimation(.snappy(duration: 0.28)) {
                                selectedLens = lens
                            }
                        } label: {
                            Image(systemName: lens.symbolName)
                                .font(.system(size: 15, weight: .semibold))
                                .frame(width: 42, height: 42)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(
                            selectedLens == lens
                                ? .regular.tint(.white.opacity(0.18)).interactive()
                                : .regular.tint(.white.opacity(0.08)).interactive(),
                            in: .circle
                        )
                        .glassEffectID(lens.id, in: glassNamespace)
                        .accessibilityLabel(lens.accessibilityLabel)
                    }
                }

                Button {} label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
                .glassEffectID("settings", in: glassNamespace)
                .accessibilityLabel("Settings")
            }
        }
    }
    #endif

    private var fallbackTopBar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles.tv")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .soraPrototypeFallbackPanel(cornerRadius: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sora")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("Ready")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                ForEach(PrototypeLens.allCases) { lens in
                    Button {
                        selectedLens = lens
                    } label: {
                        Image(systemName: lens.symbolName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .soraPrototypeFallbackPanel(cornerRadius: 21)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(lens.accessibilityLabel)
                }
            }

            Button {} label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .soraPrototypeFallbackPanel(cornerRadius: 22)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .overlay(alignment: .bottomLeading) {
            SoraPrototypeFallbackBadge()
                .offset(y: 38)
        }
    }
}

private enum PrototypeLens: String, CaseIterable, Identifiable {
    case ultraWide
    case wide

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .ultraWide: return "camera.aperture"
        case .wide: return "camera.macro.circle"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .ultraWide: return "0.5x lens"
        case .wide: return "1x lens"
        }
    }
}

#Preview {
    LiquidGlassTopBarPrototype()
}
