//
//  BeforeAfterButton.swift
//  Sora
//

import SwiftUI

struct BeforeAfterButton: View {
    @Binding var showOriginal: Bool

    var body: some View {
        Button {
            showOriginal.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: showOriginal ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 13, weight: .bold))

                Text(showOriginal ? "SHOW FILTERED" : "SHOW ORIGINAL")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .kerning(0.8)
            }
            .foregroundColor(showOriginal ? Color.orange : Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(showOriginal ? Color.black.opacity(0.8) : Color.white.opacity(0.06))
                    .overlay(
                        Capsule()
                            .stroke(showOriginal ? Color.orange.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Compare raw camera image")
        .accessibilityHint("Toggle between the original camera feed and the filtered preview")
    }
}
