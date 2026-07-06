import CoreImage
import XCTest
@testable import Sora

final class SoraFilterProcessorTests: XCTestCase {
    func testProcessReturnsImageWithExtent() {
        let pixelBuffer = makePixelBuffer(width: 1080, height: 1920)
        let frame = SoraFrame(
            pixelBuffer: pixelBuffer,
            ciImage: CIImage(cvPixelBuffer: pixelBuffer),
            timestamp: .zero,
            frameIndex: 1
        )

        let processor = SoraFilterProcessor()
        let image = processor.process(frame: frame, settings: .preset(.natural))

        XCTAssertGreaterThan(image.extent.width, 0)
        XCTAssertGreaterThan(image.extent.height, 0)
    }

    func testPresetFactoryPreservesPresetIdentity() {
        for preset in SoraPreset.allCases {
            XCTAssertEqual(SoraFilterSettings.preset(preset).preset, preset)
        }
    }

    private func makePixelBuffer(width: Int, height: Int) -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            nil,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            [kCVPixelBufferIOSurfacePropertiesKey as String: [:]] as CFDictionary,
            &pixelBuffer
        )
        return pixelBuffer!
    }
}
