//
//  BeforeAfterButton.swift
//  Sora
//

import SwiftUI

struct BeforeAfterButton: View {
    @Binding var showOriginal: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
                showOriginal.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: showOriginal ? "eye.slash" : "eye")
                    .font(.system(size: 14, weight: .bold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(showOriginal ? "Filtered" : "Original")
                        .font(.system(size: 12, weight: .bold, design: .rounded))

                    Text("Compare")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle((showOriginal ? SoraTheme.accent : Color.white).opacity(0.78))
                }
            }
            .foregroundColor(showOriginal ? SoraTheme.accent : Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Capsule().fill(showOriginal ? Color.white : Color.clear))
            .soraGlassCapsule(
                tint: showOriginal ? SoraTheme.accent.opacity(0.18) : .white.opacity(0.08),
                interactive: true
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Compare raw camera image")
        .accessibilityHint("Toggle between the original camera feed and the filtered preview")
    }
}
