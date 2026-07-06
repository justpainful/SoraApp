//
//  SoraSlider.swift
//  Sora
//

import SwiftUI
import UIKit

struct SoraSlider: View {
    let title: String
    @Binding var value: Float
    
    @State private var isDragging: Bool = false
    @State private var lastPercentageTick: Int = -1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .kerning(1.2)
                
                Spacer()
                
                Text("\(Int(round(value * 100.0)))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 4)
            
            GeometryReader { geometry in
                let width = geometry.size.width
                let height: CGFloat = 8
                let activeWidth = CGFloat(value) * width
                let thumbSize: CGFloat = isDragging ? 24 : 18
                
                ZStack(alignment: .leading) {
                    // Track Background
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: height)
                    
                    // Active Fill Track with Gradient
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.12, green: 0.45, blue: 0.95),
                                    Color(red: 0.35, green: 0.68, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(activeWidth, height), height: height)
                        .shadow(color: Color(red: 0.12, green: 0.45, blue: 0.95).opacity(0.35), radius: 5, x: 0, y: 0)
                    
                    // Thumb Handle
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: Color.black.opacity(0.35), radius: 5, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 0.12, green: 0.45, blue: 0.95).opacity(0.85), lineWidth: isDragging ? 2 : 1)
                        )
                        // Centered offset on the active track width
                        .offset(x: activeWidth - (thumbSize / 2))
                        .animation(.spring(response: 0.22, dampingFraction: 0.65, blendDuration: 0), value: isDragging)
                }
                .contentShape(Rectangle()) // Extends drag hit area to full slider block
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isDragging = true
                            let touchLocation = gesture.location.x
                            // Clamp value between 0.0 and 1.0
                            let newValue = max(0.0, min(1.0, Float(touchLocation / width)))
                            
                            // Trigger haptics only when percentage changes by an integer step
                            let currentPercent = Int(round(newValue * 100.0))
                            if currentPercent != lastPercentageTick {
                                triggerHapticTick()
                                lastPercentageTick = currentPercent
                            }
                            
                            value = newValue
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: 24)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) filter intensity")
        .accessibilityValue("\(Int(round(value * 100.0))) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(1.0, value + 0.05)
                triggerHapticTick()
            case .decrement:
                value = max(0.0, value - 0.05)
                triggerHapticTick()
            @unknown default:
                break
            }
        }
    }
    
    private func triggerHapticTick() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.5)
    }
}
