// DO NOT EDIT: Shared Core Contract for Sora.
// Only the integrator may change this file.

import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var filterSettings = SoraFilterSettings()
    @Published var qualityMode: SoraQualityMode = .performance
    @Published var lensMode: SoraLensMode = .wide
    @Published var recordingState: SoraRecordingState = .idle

    @Published var isFilterStudioOpen = false
    @Published var isSettingsOpen = false

    @Published var toast: SoraToast?
    @Published var lastSavedVideoURL: URL?

    var isRecording: Bool {
        if case .recording = recordingState {
            return true
        }
        return false
    }

    func showToast(_ title: String, message: String? = nil) {
        toast = SoraToast(title: title, message: message)
    }

    func resetFilters() {
        filterSettings = SoraFilterSettings()
    }
}
