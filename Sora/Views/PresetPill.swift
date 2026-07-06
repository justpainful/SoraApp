//
//  PresetPill.swift
//  Sora
//

import SwiftUI
import UIKit

struct PresetPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            triggerSelectionHaptic()
            action()
        }) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .black : .white.opacity(0.82))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(isSelected ? Color.white : Color.clear))
                .soraGlassCapsule(
                    tint: isSelected ? .white.opacity(0.20) : .white.opacity(0.08),
                    interactive: true
                )
                .scaleEffect(isSelected ? 1.04 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.7, blendDuration: 0), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) Preset")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }
    
    private func triggerSelectionHaptic() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
