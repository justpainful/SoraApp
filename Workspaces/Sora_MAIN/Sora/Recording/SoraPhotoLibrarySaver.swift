import Foundation
import Photos

struct SoraPhotoLibrarySaver: SoraPhotoSaving {
    func saveVideoToPhotos(url: URL) async throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PhotoSavingError.fileMissing
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw PhotoSavingError.permissionDenied
        }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: PhotoSavingError.saveFailed)
                }
            }
        }
    }
}

enum PhotoSavingError: LocalizedError {
    case permissionDenied
    case saveFailed
    case fileMissing

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Photo Library permission was denied."
        case .saveFailed:
            return "The video could not be saved to Photos."
        case .fileMissing:
            return "The recorded video file could not be found before saving to Photos."
        }
    }
}
