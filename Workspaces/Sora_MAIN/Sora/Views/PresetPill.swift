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
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.12, green: 0.45, blue: 0.95),
                                            Color(red: 0.35, green: 0.68, blue: 1.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color(red: 0.12, green: 0.45, blue: 0.95).opacity(0.4), radius: 6, x: 0, y: 3)
                        } else {
                            Capsule()
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                    }
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
