// DO NOT EDIT: Shared Core Contract for Sora.
// Only the integrator may change this file.

import Foundation
import CoreImage
import CoreMedia
import CoreVideo
import CoreGraphics

protocol SoraCameraFrameOutput: AnyObject {
    var onFrame: ((SoraFrame) -> Void)? { get set }

    func startSession()
    func stopSession()
    func switchLens(to lens: SoraLensMode)
    func setQualityMode(_ mode: SoraQualityMode)
}

protocol SoraImageProcessing {
    func process(
        frame: SoraFrame,
        settings: SoraFilterSettings
    ) -> CIImage
}

protocol SoraLiveRendering: AnyObject {
    func render(_ image: CIImage)
}

protocol SoraVideoRecording: AnyObject {
    var isRecording: Bool { get }

    func startRecording(
        outputSize: CGSize,
        frameRate: Int
    ) throws

    func appendFrame(
        image: CIImage,
        timestamp: CMTime
    )

    func stopRecording() async throws -> URL
}

protocol SoraPhotoSaving {
    func saveVideoToPhotos(url: URL) async throws
}
