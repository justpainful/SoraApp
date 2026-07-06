import CoreImage
import CoreMedia
import Foundation
import SwiftUI

enum SaveResult: Identifiable, Equatable {
    case success(localURL: URL)
    case failure(message: String)

    var id: String {
        switch self {
        case .success(let localURL):
            return localURL.absoluteString
        case .failure(let message):
            return message
        }
    }
}

@MainActor
final class RecordingCoordinator: ObservableObject {
    @Published private(set) var recentRecordings: [URL] = []
    @Published var saveResult: SaveResult?

    private weak var appState: AppState?
    private let recorder: SoraVideoRecording
    private let photoSaver: SoraPhotoSaving

    init(
        recorder: SoraVideoRecording = SoraAssetWriterRecorder(),
        photoSaver: SoraPhotoSaving = SoraPhotoLibrarySaver()
    ) {
        self.recorder = recorder
        self.photoSaver = photoSaver
    }

    func bind(appState: AppState) {
        self.appState = appState
    }

    func startRecording(outputSize: CGSize = CGSize(width: 1080, height: 1920), frameRate: Int = 30) {
        do {
            try recorder.startRecording(outputSize: outputSize, frameRate: frameRate)
            appState?.recordingState = .recording(startedAt: Date())
            appState?.showToast(SoraStrings.text("toast.recording.started"))
        } catch {
            appState?.recordingState = .failed(error.localizedDescription)
            appState?.showToast(SoraStrings.text("toast.recording.failed"), message: error.localizedDescription)
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
                recentRecordings.removeAll { $0 == url }
                recentRecordings.insert(url, at: 0)
                recentRecordings = Array(recentRecordings.prefix(12))

                if saveToPhotos {
                    try await photoSaver.saveVideoToPhotos(url: url)
                }

                appState?.recordingState = .saved(url)
                appState?.showToast(SoraStrings.text("toast.saved.title"), message: SoraStrings.text("toast.saved.message"))
                saveResult = .success(localURL: url)
            } catch {
                appState?.recordingState = .failed(error.localizedDescription)
                appState?.showToast(SoraStrings.text("toast.saved.failed"), message: error.localizedDescription)
                saveResult = .failure(message: error.localizedDescription)
            }
        }
    }
}
