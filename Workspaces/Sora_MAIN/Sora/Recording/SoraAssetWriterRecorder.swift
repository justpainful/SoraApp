import AVFoundation
import CoreGraphics
import CoreImage
import CoreMedia
import CoreVideo
import Foundation

final class SoraAssetWriterRecorder: SoraVideoRecording {
    private let writerQueue = DispatchQueue(label: "com.sora.recorder.writer")
    private let ciContext = CIContext(options: [.cacheIntermediates: false])

    private var assetWriter: AVAssetWriter?
    private var writerInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var outputURL: URL?
    private var outputSize: CGSize = .zero
    private var frameRate: Int = 30
    private var didStartSession = false
    private var lastTimestamp: CMTime = .zero
    private var sessionStartTimestamp: CMTime?
    private var writtenFrameCount = 0

    var isRecording: Bool {
        writerQueue.sync { assetWriter != nil }
    }

    func startRecording(outputSize: CGSize, frameRate: Int) throws {
        try writerQueue.sync {
            if assetWriter != nil {
                throw RecorderError.alreadyRecording
            }

            let normalizedSize = Self.normalizedOutputSize(outputSize)
            let recordingsDirectory = try Self.makeRecordingsDirectory()
            let fileURL = recordingsDirectory.appendingPathComponent("sora-\(UUID().uuidString).mov")

            let writer = try AVAssetWriter(outputURL: fileURL, fileType: .mov)
            let input = AVAssetWriterInput(
                mediaType: .video,
                outputSettings: Self.makeVideoSettings(size: normalizedSize)
            )
            input.expectsMediaDataInRealTime = true

            let attributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: Int(normalizedSize.width),
                kCVPixelBufferHeightKey as String: Int(normalizedSize.height),
                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ]

            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes: attributes
            )

            guard writer.canAdd(input) else {
                throw RecorderError.cannotAddWriterInput
            }

            writer.add(input)

            guard writer.startWriting() else {
                throw writer.error ?? RecorderError.failedToStartWriting
            }

            self.assetWriter = writer
            self.writerInput = input
            self.pixelBufferAdaptor = adaptor
            self.outputURL = fileURL
            self.outputSize = normalizedSize
            self.frameRate = max(frameRate, 1)
            self.didStartSession = false
            self.lastTimestamp = .zero
            self.sessionStartTimestamp = nil
            self.writtenFrameCount = 0
        }
    }

    func appendFrame(image: CIImage, timestamp: CMTime) {
        writerQueue.async {
            guard
                let writer = self.assetWriter,
                let input = self.writerInput,
                let adaptor = self.pixelBufferAdaptor,
                writer.status == .writing
            else {
                return
            }

            guard input.isReadyForMoreMediaData else {
                return
            }

            guard let pool = adaptor.pixelBufferPool else {
                return
            }

            var pixelBuffer: CVPixelBuffer?
            let createStatus = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
            guard createStatus == kCVReturnSuccess, let pixelBuffer else {
                return
            }

            CVPixelBufferLockBaseAddress(pixelBuffer, [])
            self.ciContext.render(
                image.transformed(by: Self.renderTransform(for: image.extent, outputSize: self.outputSize)),
                to: pixelBuffer,
                bounds: CGRect(origin: .zero, size: self.outputSize),
                colorSpace: CGColorSpaceCreateDeviceRGB()
            )
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

            let relativeTimestamp = self.relativeTimestamp(for: timestamp)
            let monotonicTimestamp = CMTimeCompare(relativeTimestamp, self.lastTimestamp) >= 0
                ? relativeTimestamp
                : CMTimeAdd(self.lastTimestamp, CMTime(value: 1, timescale: CMTimeScale(self.frameRate)))

            if !self.didStartSession {
                writer.startSession(atSourceTime: .zero)
                self.didStartSession = true
            }

            if adaptor.append(pixelBuffer, withPresentationTime: monotonicTimestamp) {
                self.lastTimestamp = monotonicTimestamp
                self.writtenFrameCount += 1
            }
        }
    }

    func stopRecording() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            writerQueue.async {
                guard let writer = self.assetWriter,
                      let input = self.writerInput,
                      let outputURL = self.outputURL else {
                    continuation.resume(throwing: RecorderError.notRecording)
                    return
                }

                guard self.writtenFrameCount > 0 else {
                    writer.cancelWriting()
                    self.resetWriterState()
                    continuation.resume(throwing: RecorderError.noFramesCaptured)
                    return
                }

                input.markAsFinished()
                writer.finishWriting {
                    let result: Result<URL, Error>
                    if writer.status == .completed {
                        result = .success(outputURL)
                    } else {
                        result = .failure(writer.error ?? RecorderError.finishFailed)
                    }

                    self.resetWriterState()
                    continuation.resume(with: result)
                }
            }
        }
    }

    private func relativeTimestamp(for timestamp: CMTime) -> CMTime {
        if let sessionStartTimestamp {
            return CMTimeSubtract(timestamp, sessionStartTimestamp)
        }

        sessionStartTimestamp = timestamp
        return .zero
    }

    private func resetWriterState() {
        assetWriter = nil
        writerInput = nil
        pixelBufferAdaptor = nil
        outputURL = nil
        outputSize = .zero
        didStartSession = false
        lastTimestamp = .zero
        sessionStartTimestamp = nil
        writtenFrameCount = 0
    }

    private static func makeRecordingsDirectory() throws -> URL {
        let directory = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sora", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return directory
    }

    private static func makeVideoSettings(size: CGSize) -> [String: Any] {
        let compression: [String: Any] = [
            AVVideoAverageBitRateKey: 10_000_000,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
            AVVideoExpectedSourceFrameRateKey: 30,
            AVVideoMaxKeyFrameIntervalKey: 30
        ]

        return [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: compression
        ]
    }

    private static func normalizedOutputSize(_ size: CGSize) -> CGSize {
        let fallback = CGSize(width: 1080, height: 1920)
        guard size.width > 0, size.height > 0 else { return fallback }

        func even(_ value: CGFloat) -> CGFloat {
            let rounded = max(2, Int(value.rounded()))
            return CGFloat(rounded.isMultiple(of: 2) ? rounded : rounded + 1)
        }

        return CGSize(width: even(size.width), height: even(size.height))
    }

    private static func renderTransform(for extent: CGRect, outputSize: CGSize) -> CGAffineTransform {
        guard extent.width > 0, extent.height > 0 else {
            return .identity
        }

        let scaleX = outputSize.width / extent.width
        let scaleY = outputSize.height / extent.height
        let scale = max(scaleX, scaleY)

        let scaledWidth = extent.width * scale
        let scaledHeight = extent.height * scale
        let x = (outputSize.width - scaledWidth) * 0.5
        let y = (outputSize.height - scaledHeight) * 0.5

        return CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: x / scale, y: y / scale)
    }
}

enum RecorderError: LocalizedError {
    case alreadyRecording
    case notRecording
    case cannotAddWriterInput
    case failedToStartWriting
    case finishFailed
    case noFramesCaptured

    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "A clip is already in progress."
        case .notRecording:
            return "No active clip was found."
        case .cannotAddWriterInput:
            return "The video writer input could not be configured."
        case .failedToStartWriting:
            return "The video writer could not start."
        case .finishFailed:
            return "The clip could not be finalized."
        case .noFramesCaptured:
            return "No camera frames were captured. Try again after the live preview appears."
        }
    }
}
