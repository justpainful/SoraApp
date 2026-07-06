import SwiftUI

struct LiquidGlassFilterSheetPrototype: View {
    @Namespace private var glassNamespace
    @State private var selectedPreset = "Natural"
    @State private var compareOriginal = false

    private let presets = ["Natural", "Clean", "Soft", "Cinema"]

    var body: some View {
        ZStack {
            SoraPrototypeBackdrop()
                .ignoresSafeArea()

            VStack {
                Spacer()

                #if compiler(>=6.2)
                if #available(iOS 26, *) {
                    nativeSheet
                } else {
                    fallbackSheet
                }
                #else
                fallbackSheet
                #endif
            }
        }
    }

    #if compiler(>=6.2)
    @available(iOS 26, *)
    private var nativeSheet: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(.white.opacity(0.75))
                .frame(width: 42, height: 5)

            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    Button("Reset") {}
                        .font(.callout.weight(.semibold))
                        .buttonStyle(.glass)
                        .glassEffectID("reset", in: glassNamespace)

                    Spacer()

                    Label("Look Studio", systemImage: "sparkles")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Button {} label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .buttonStyle(.glass)
                    .glassEffectID("close", in: glassNamespace)
                    .accessibilityLabel("Close")
                }
            }

            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(presets, id: \.self) { preset in
                        Group {
                            if selectedPreset == preset {
                                Button(preset) {
                                    withAnimation(.snappy(duration: 0.24)) {
                                        selectedPreset = preset
                                    }
                                }
                                .font(.footnote.weight(.semibold))
                                .buttonStyle(.glassProminent)
                                .glassEffectID("preset-\(preset)", in: glassNamespace)
                            } else {
                                Button(preset) {
                                    withAnimation(.snappy(duration: 0.24)) {
                                        selectedPreset = preset
                                    }
                                }
                                .font(.footnote.weight(.semibold))
                                .buttonStyle(.glass)
                                .glassEffectID("preset-\(preset)", in: glassNamespace)
                            }
                        }
                    }
                }
            }

            VStack(spacing: 18) {
                prototypeRow(title: "Smooth", value: "35")
                prototypeRow(title: "Glow", value: "20")
                prototypeRow(title: "Contrast", value: "15")
            }

            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        compareOriginal.toggle()
                    } label: {
                        Label(compareOriginal ? "Filtered" : "Original", systemImage: compareOriginal ? "eye.slash" : "eye")
                    }
                    .font(.callout.weight(.semibold))
                    .buttonStyle(.glass)
                    .glassEffectID("compare", in: glassNamespace)

                    Spacer()

                    Button("Apply") {}
                        .font(.callout.weight(.semibold))
                        .buttonStyle(.glassProminent)
                        .glassEffectID("apply", in: glassNamespace)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
    #endif

    private var fallbackSheet: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(.white.opacity(0.75))
                .frame(width: 42, height: 5)

            HStack {
                Button("Reset") {}
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .soraPrototypeFallbackPanel(cornerRadius: 20)

                Spacer()

                Label("Look Studio", systemImage: "sparkles")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {} label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .soraPrototypeFallbackPanel(cornerRadius: 19)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }

            HStack(spacing: 10) {
                ForEach(presets, id: \.self) { preset in
                    Button(preset) {
                        selectedPreset = preset
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .soraPrototypeFallbackPanel(cornerRadius: 18)
                }
            }

            VStack(spacing: 18) {
                prototypeRow(title: "Smooth", value: "35")
                prototypeRow(title: "Glow", value: "20")
                prototypeRow(title: "Contrast", value: "15")
            }

            HStack(spacing: 12) {
                Button {
                    compareOriginal.toggle()
                } label: {
                    Label(compareOriginal ? "Filtered" : "Original", systemImage: compareOriginal ? "eye.slash" : "eye")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .soraPrototypeFallbackPanel(cornerRadius: 20)
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Apply") {}
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.white, in: Capsule())
            }

            SoraPrototypeFallbackBadge()
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private func prototypeRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text(value)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white.opacity(0.76))
            }

            Capsule()
                .fill(.white.opacity(0.18))
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.86))
                        .frame(width: 110)
                }
        }
    }
}

#Preview {
    LiquidGlassFilterSheetPrototype()
}
