//
//  FilterStudioSheet.swift
//  Sora
//

import SwiftUI
import UIKit

struct FilterStudioSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Binding var showOriginal: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            HStack {
                Button(action: {
                    triggerHapticNotification(style: .success)
                    appState.resetFilters()
                }) {
                    Text("RESET")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .kerning(1.0)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Capsule().fill(Color.white.opacity(0.04)))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("LOOK STUDIO")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .kerning(2.5)
                
                Spacer()
                
                Button(action: {
                    triggerHapticClick()
                    appState.isFilterStudioOpen = false
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SoraPreset.allCases) { preset in
                        PresetPill(
                            title: preset.rawValue.uppercased(),
                            isSelected: appState.filterSettings.preset == preset,
                            action: { selectPreset(preset) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 22)
            
            VStack(spacing: 20) {
                SoraSlider(
                    title: "Smooth",
                    value: Binding(get: { appState.filterSettings.smooth }, set: { appState.filterSettings.smooth = $0 })
                )
                
                SoraSlider(
                    title: "Glow",
                    value: Binding(get: { appState.filterSettings.glow }, set: { appState.filterSettings.glow = $0 })
                )
                
                SoraSlider(
                    title: "Contrast",
                    value: Binding(get: { appState.filterSettings.contrast }, set: { appState.filterSettings.contrast = $0 })
                )
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 14)

            Text("Compare affects the live preview only. Saved files use the Sora Look settings.")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
            
            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            
            BeforeAfterButton(showOriginal: $showOriginal)
                .padding(.bottom, 16)
        }
        .padding(.bottom, 10)
        .background(
            Color(red: 0.02, green: 0.04, blue: 0.08)
                .ignoresSafeArea()
        )
        .presentationDetents([.height(390), .medium])
        .presentationBackground(.ultraThinMaterial)
    }
    
    private func selectPreset(_ preset: SoraPreset) {
        appState.filterSettings.preset = preset
        
        switch preset {
        case .natural:
            appState.filterSettings.smooth = 0.35
            appState.filterSettings.glow = 0.20
            appState.filterSettings.contrast = 0.15
        case .clean:
            appState.filterSettings.smooth = 0.30
            appState.filterSettings.glow = 0.10
            appState.filterSettings.contrast = 0.25
        case .soft:
            appState.filterSettings.smooth = 0.60
            appState.filterSettings.glow = 0.40
            appState.filterSettings.contrast = 0.05
        case .cinematic:
            appState.filterSettings.smooth = 0.25
            appState.filterSettings.glow = 0.15
            appState.filterSettings.contrast = 0.30
        }
    }
    
    private func triggerHapticClick() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func triggerHapticNotification(style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(style)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        FilterStudioSheet(showOriginal: .constant(false))
            .environmentObject(AppState())
    }
}
