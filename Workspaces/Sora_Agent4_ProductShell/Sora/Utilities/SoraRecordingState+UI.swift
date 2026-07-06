import Foundation
import SwiftUI

extension SoraRecordingState {
    var statusText: String {
        switch self {
        case .idle:
            return SoraStrings.text("recording.status.ready")
        case .recording:
            return SoraStrings.text("recording.status.recording")
        case .saving:
            return SoraStrings.text("recording.status.saving")
        case .saved:
            return SoraStrings.text("recording.status.saved")
        case .failed:
            return SoraStrings.text("recording.status.failed")
        }
    }

    var statusColor: Color {
        switch self {
        case .idle:
            return Color.white.opacity(0.76)
        case .recording:
            return SoraTheme.danger
        case .saving:
            return SoraTheme.warning
        case .saved:
            return SoraTheme.success
        case .failed:
            return Color.orange
        }
    }

    var failureMessage: String? {
        guard case .failed(let message) = self else { return nil }
        return message
    }
}
