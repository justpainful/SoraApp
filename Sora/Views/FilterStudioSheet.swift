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
                .fill(Color.white.opacity(0.24))
                .frame(width: 42, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 14)

            SoraGlassContainer(spacing: 12) {
                HStack {
                    Button(action: {
                        triggerHapticNotification(style: .success)
                        appState.resetFilters()
                    }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                    }
                    .buttonStyle(.plain)
                    .soraGlassCapsule(interactive: true)

                    Spacer()

                    Label("Look Studio", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Button(action: {
                        triggerHapticClick()
                        appState.isFilterStudioOpen = false
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    .soraGlassCircle(interactive: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SoraPreset.allCases) { preset in
                        PresetPill(
                            title: preset.rawValue,
                            isSelected: appState.filterSettings.preset == preset,
                            action: {
                                selectPreset(preset)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 22)

            VStack(spacing: 20) {
                SoraSlider(
                    title: "Refine",
                    value: Binding(
                        get: { appState.filterSettings.smooth },
                        set: { appState.filterSettings.smooth = $0 }
                    )
                )

                SoraSlider(
                    title: "Glow",
                    value: Binding(
                        get: { appState.filterSettings.glow },
                        set: { appState.filterSettings.glow = $0 }
                    )
                )

                SoraSlider(
                    title: "Definition",
                    value: Binding(
                        get: { appState.filterSettings.contrast },
                        set: { appState.filterSettings.contrast = $0 }
                    )
                )
            }
            .padding(.horizontal, 22)

            Text("Refine keeps edges and highlights intact while softening harsh texture.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.66))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
            .padding(.bottom, 22)

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            BeforeAfterButton(showOriginal: $showOriginal)
                .padding(.bottom, 16)
        }
        .padding(.bottom, 14)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.07, blue: 0.11),
                    Color(red: 0.06, green: 0.10, blue: 0.17)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .presentationDetents([.height(355), .medium])
        .presentationBackground(.ultraThinMaterial)
    }

    private func selectPreset(_ preset: SoraPreset) {
        appState.filterSettings.preset = preset

        switch preset {
        case .natural:
            appState.filterSettings.smooth = 0.22
            appState.filterSettings.glow = 0.08
            appState.filterSettings.contrast = 0.15
        case .clean:
            appState.filterSettings.smooth = 0.38
            appState.filterSettings.glow = 0.12
            appState.filterSettings.contrast = 0.28
        case .soft:
            appState.filterSettings.smooth = 0.60
            appState.filterSettings.glow = 0.24
            appState.filterSettings.contrast = 0.12
        case .cinematic:
            appState.filterSettings.smooth = 0.34
            appState.filterSettings.glow = 0.28
            appState.filterSettings.contrast = 0.38
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
