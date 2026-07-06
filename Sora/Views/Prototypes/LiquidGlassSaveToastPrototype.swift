import SwiftUI

struct LiquidGlassSaveToastPrototype: View {
    @Namespace private var glassNamespace
    @State private var showsFailure = false

    var body: some View {
        ZStack(alignment: .top) {
            SoraPrototypeBackdrop()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Spacer()

                    Button(showsFailure ? "Show success" : "Show failure") {
                        withAnimation(.snappy(duration: 0.24)) {
                            showsFailure.toggle()
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .soraPrototypeFallbackPanel(cornerRadius: 18)
                }

                #if compiler(>=6.2)
                if #available(iOS 26, *) {
                    nativeToast
                } else {
                    fallbackToast
                }
                #else
                fallbackToast
                #endif

                Spacer()
            }
            .padding(16)
        }
    }

    #if compiler(>=6.2)
    @available(iOS 26, *)
    private var nativeToast: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: showsFailure ? "exclamationmark.triangle.fill" : "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(showsFailure ? Color.orange : Color.green)
                    .frame(width: 34, height: 34)
                    .glassEffect(.regular.tint(.white.opacity(0.08)), in: .circle)
                    .glassEffectID("status-badge", in: glassNamespace)

                VStack(alignment: .leading, spacing: 3) {
                    Text(showsFailure ? "Save failed" : "Saved to Photos")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(showsFailure ? "Try exporting again after the current recording pass finishes." : "Your clip is available locally and in Photos.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.74))
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Button {} label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.glass)
                .glassEffectID("dismiss", in: glassNamespace)
                .accessibilityLabel("Dismiss")
            }
        }
        .padding(14)
    }
    #endif

    private var fallbackToast: some View {
        HStack(spacing: 12) {
            Image(systemName: showsFailure ? "exclamationmark.triangle.fill" : "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(showsFailure ? Color.orange : Color.green)
                .frame(width: 34, height: 34)
                .soraPrototypeFallbackPanel(cornerRadius: 17)

            VStack(alignment: .leading, spacing: 3) {
                Text(showsFailure ? "Save failed" : "Saved to Photos")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(showsFailure ? "Try exporting again after the current recording pass finishes." : "Your clip is available locally and in Photos.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.74))
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button {} label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .soraPrototypeFallbackPanel(cornerRadius: 17)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(14)
        .soraPrototypeFallbackPanel(cornerRadius: 26)
        .overlay(alignment: .bottomLeading) {
            SoraPrototypeFallbackBadge()
                .offset(y: 34)
        }
    }
}

#Preview {
    LiquidGlassSaveToastPrototype()
}
