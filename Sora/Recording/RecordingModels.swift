import Foundation
import SwiftUI

enum SaveResult: Identifiable, Equatable {
    case success(localURL: URL, message: String)
    case failure(message: String)

    var id: String {
        switch self {
        case .success(let localURL, let message):
            return "success-\(localURL.absoluteString)-\(message)"
        case .failure(let message):
            return "failure-\(message)"
        }
    }
}

extension SoraRecordingState {
    var statusText: String {
        switch self {
        case .idle:
            return "Ready"
        case .recording:
            return "Recording"
        case .saving:
            return "Saving"
        case .saved:
            return "Saved"
        case .failed:
            return "Failed"
        }
    }

    var accentColor: Color {
        switch self {
        case .idle:
            return .white.opacity(0.72)
        case .recording:
            return .red
        case .saving:
            return .yellow
        case .saved:
            return .green
        case .failed:
            return .orange
        }
    }

    var statusColor: Color {
        accentColor
    }

    var failureMessage: String? {
        guard case .failed(let message) = self else {
            return nil
        }
        return message
    }

    var startedAt: Date? {
        guard case .recording(let startedAt) = self else {
            return nil
        }
        return startedAt
    }
}
