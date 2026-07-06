import Foundation
import Photos

struct SoraPhotoLibrarySaver: SoraPhotoSaving {
    func saveVideoToPhotos(url: URL) async throws {
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
                    continuation.resume()
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

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return SoraStrings.text("error.photos.permission")
        case .saveFailed:
            return SoraStrings.text("error.photos.save")
        }
    }
}
