//
//  BeforeAfterButton.swift
//  Sora
//

import SwiftUI

struct BeforeAfterButton: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var isPressed = false
    @State private var savedSettings: SoraFilterSettings? = nil
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: isPressed ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 13, weight: .bold))
                
                Text(isPressed ? "RAW PREVIEW" : "COMPARE RAW")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .kerning(0.8)
            }
            .foregroundColor(isPressed ? Color.orange : Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isPressed ? Color.black.opacity(0.8) : Color.white.opacity(0.06))
                    .overlay(
                        Capsule()
                            .stroke(isPressed ? Color.orange.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.75, blendDuration: 0), value: isPressed)
        }
        .buttonStyle(.plain)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        triggerHapticPress(style: .medium)
                        backupAndBypass()
                    }
                }
                .onEnded { _ in
                    if isPressed {
                        isPressed = false
                        triggerHapticPress(style: .light)
                        restoreSettings()
                    }
                }
        )
        .onDisappear {
            // Restore settings immediately if view disappears while user is holding down
            restoreSettings()
        }
        .accessibilityLabel("Compare raw camera image")
        .accessibilityHint("Hold down to see the camera stream without filters applied")
    }
    
    private func backupAndBypass() {
        // Save current filter settings
        savedSettings = appState.filterSettings
        
        // Temporarily apply bypass settings (0.15 is the neutral baseline for contrast)
        appState.filterSettings = SoraFilterSettings(
            smooth: 0.0,
            glow: 0.0,
            contrast: 0.15,
            preset: .natural
        )
    }
    
    private func restoreSettings() {
        if let saved = savedSettings {
            appState.filterSettings = saved
            savedSettings = nil
        }
    }
    
    private func triggerHapticPress(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
