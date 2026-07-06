import CoreImage
import CoreMedia
import Foundation
import SwiftUI

@MainActor
final class RecordingCoordinator: ObservableObject {
    @Published private(set) var recentRecordings: [URL]
    @Published var saveResult: SaveResult?

    private let recorder: SoraVideoRecording
    private let photoSaver: SoraPhotoSaving
    private weak var appState: AppState?
    private var appendedFrameCount = 0

    private static let storageKey = "sora.recentRecordings.v1"
    private static let maxItems = 12

    init(
        appState: AppState? = nil,
        recorder: SoraVideoRecording = SoraAssetWriterRecorder(),
        photoSaver: SoraPhotoLibrarySaver = SoraPhotoLibrarySaver()
    ) {
        self.appState = appState
        self.recorder = recorder
        self.photoSaver = photoSaver
        self.recentRecordings = Self.loadRecentRecordings()
    }

    func bind(appState: AppState) {
        self.appState = appState
    }

    func startRecording(outputSize: CGSize, frameRate: Int = 30) {
        saveResult = nil
        guard !recorder.isRecording else {
            let message = "A recording is already active."
            appState?.recordingState = .failed(message)
            appState?.showToast("Cannot start", message: message)
            saveResult = .failure(message: message)
            return
        }

        if case .saving = appState?.recordingState {
            let message = "Wait for saving to finish."
            appState?.showToast("Please wait", message: message)
            return
        }

        do {
            appendedFrameCount = 0
            try recorder.startRecording(outputSize: outputSize, frameRate: frameRate)
            appState?.recordingState = .recording(startedAt: Date())
            appState?.showToast("Started")
        } catch {
            appState?.recordingState = .failed(error.localizedDescription)
            appState?.showToast("Start failed", message: error.localizedDescription)
            saveResult = .failure(message: error.localizedDescription)
        }
    }

    func appendFrame(image: CIImage, timestamp: CMTime) {
        guard recorder.isRecording else { return }
        appendedFrameCount += 1
        recorder.appendFrame(image: image, timestamp: timestamp)
    }

    func stopRecording(saveToPhotos: Bool = true) {
        guard recorder.isRecording else { return }
        appState?.recordingState = .saving

        Task {
            do {
                let url = try await recorder.stopRecording()
                guard appendedFrameCount > 0 else { throw RecorderError.noFramesCaptured }

                appState?.lastSavedVideoURL = url
                insertRecent(url)

                if saveToPhotos { try await photoSaver.saveVideoToPhotos(url: url) }

                appState?.recordingState = .saved(url)
                appState?.showToast("Saved")
                saveResult = .success(localURL: url)
            } catch {
                appState?.recordingState = .failed(error.localizedDescription)
                appState?.showToast("Save failed", message: error.localizedDescription)
                saveResult = .failure(message: error.localizedDescription)
            }
            appendedFrameCount = 0
        }
    }

    func dismissSaveResult() {
        saveResult = nil
        if case .saved = appState?.recordingState { appState?.recordingState = .idle }
        if case .failed = appState?.recordingState { appState?.recordingState = .idle }
    }

    func cleanRecentRecordings() {
        recentRecordings = Self.validURLs(from: recentRecordings)
        persistRecentRecordings()
    }

    private func insertRecent(_ url: URL) {
        recentRecordings.removeAll { $0 == url }
        recentRecordings.insert(url, at: 0)
        recentRecordings = Array(Self.validURLs(from: recentRecordings).prefix(Self.maxItems))
        persistRecentRecordings()
    }

    private func persistRecentRecordings() {
        let strings = recentRecordings.map { $0.absoluteString }
        UserDefaults.standard.set(strings, forKey: Self.storageKey)
    }

    private static func loadRecentRecordings() -> [URL] {
        let strings = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
        let urls = strings.compactMap { URL(string: $0) }
        return Array(validURLs(from: urls).prefix(maxItems))
    }

    private static func validURLs(from urls: [URL]) -> [URL] {
        urls.filter { FileManager.default.fileExists(atPath: $0.path) }
    }
}
