import CoreImage
import CoreMedia
import Foundation
import SwiftUI

@MainActor
final class RecordingCoordinator: ObservableObject {
    @Published private(set) var recentRecordings: [URL] = []
    @Published var saveResult: SaveResult?

    private let recorder: SoraVideoRecording
    private let photoSaver: SoraPhotoSaving
    private weak var appState: AppState?

    init(
        appState: AppState? = nil,
        recorder: SoraVideoRecording = SoraAssetWriterRecorder(),
        photoSaver: SoraPhotoSaving = SoraPhotoLibrarySaver()
    ) {
        self.appState = appState
        self.recorder = recorder
        self.photoSaver = photoSaver
    }

    func bind(appState: AppState) {
        self.appState = appState
    }

    func startRecording(outputSize: CGSize, frameRate: Int = 30) {
        saveResult = nil

        do {
            try recorder.startRecording(outputSize: outputSize, frameRate: frameRate)
            appState?.recordingState = .recording(startedAt: Date())
            appState?.showToast("Recording started")
        } catch {
            appState?.recordingState = .failed(error.localizedDescription)
            appState?.showToast("Recording failed", message: error.localizedDescription)
            saveResult = .failure(message: error.localizedDescription)
        }
    }

    func appendFrame(image: CIImage, timestamp: CMTime) {
        recorder.appendFrame(image: image, timestamp: timestamp)
    }

    func stopRecording(saveToPhotos: Bool = true) {
        guard recorder.isRecording else { return }
        appState?.recordingState = .saving

        Task {
            do {
                let url = try await recorder.stopRecording()
                appState?.lastSavedVideoURL = url
                insertRecent(url)

                if saveToPhotos {
                    try await photoSaver.saveVideoToPhotos(url: url)
                }

                appState?.recordingState = .saved(url)
                appState?.showToast("Video saved")
                saveResult = .success(localURL: url)
            } catch {
                appState?.recordingState = .failed(error.localizedDescription)
                appState?.showToast("Save failed", message: error.localizedDescription)
                saveResult = .failure(message: error.localizedDescription)
            }
        }
    }

    func dismissSaveResult() {
        saveResult = nil
        if case .saved = appState?.recordingState {
            appState?.recordingState = .idle
        }
    }

    private func insertRecent(_ url: URL) {
        recentRecordings.removeAll { $0 == url }
        recentRecordings.insert(url, at: 0)
        if recentRecordings.count > 12 {
            recentRecordings = Array(recentRecordings.prefix(12))
        }
    }
}
