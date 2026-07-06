import AVFoundation
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
    private var frameRate = 30
    private var lastTimestamp: CMTime = .zero
    private var didStartSession = false

    var isRecording: Bool {
        writerQueue.sync { assetWriter != nil }
    }

    func startRecording(outputSize: CGSize, frameRate: Int) throws {
        try writerQueue.sync {
            guard assetWriter == nil else { throw RecorderError.alreadyRecording }

            let outputURL = try Self.recordingsDirectory()
                .appendingPathComponent("sora-\(UUID().uuidString).mov")
            let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: Self.videoSettings(size: outputSize))
            input.expectsMediaDataInRealTime = true

            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                    kCVPixelBufferWidthKey as String: Int(outputSize.width),
                    kCVPixelBufferHeightKey as String: Int(outputSize.height),
                    kCVPixelBufferIOSurfacePropertiesKey as String: [:]
                ]
            )

            guard writer.canAdd(input) else { throw RecorderError.cannotAddWriterInput }
            writer.add(input)

            guard writer.startWriting() else {
                throw writer.error ?? RecorderError.failedToStartWriting
            }

            self.assetWriter = writer
            self.writerInput = input
            self.pixelBufferAdaptor = adaptor
            self.outputURL = outputURL
            self.outputSize = outputSize
            self.frameRate = max(1, frameRate)
            self.lastTimestamp = .zero
            self.didStartSession = false
        }
    }

    func appendFrame(image: CIImage, timestamp: CMTime) {
        writerQueue.async {
            guard
                let writer = self.assetWriter,
                let writerInput = self.writerInput,
                let adaptor = self.pixelBufferAdaptor,
                writer.status == .writing
            else {
                return
            }

            if !self.didStartSession {
                writer.startSession(atSourceTime: timestamp)
                self.didStartSession = true
            }

            guard writerInput.isReadyForMoreMediaData, let pool = adaptor.pixelBufferPool else { return }

            var pixelBuffer: CVPixelBuffer?
            guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer) == kCVReturnSuccess, let pixelBuffer else {
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

            let presentationTime = CMTimeCompare(timestamp, self.lastTimestamp) >= 0
                ? timestamp
                : CMTimeAdd(self.lastTimestamp, CMTime(value: 1, timescale: CMTimeScale(self.frameRate)))

            if adaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
                self.lastTimestamp = presentationTime
            }
        }
    }

    func stopRecording() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            writerQueue.async {
                guard let writer = self.assetWriter, let writerInput = self.writerInput, let outputURL = self.outputURL else {
                    continuation.resume(throwing: RecorderError.notRecording)
                    return
                }

                writerInput.markAsFinished()
                writer.finishWriting {
                    let result: Result<URL, Error>
                    if writer.status == .completed {
                        result = .success(outputURL)
                    } else {
                        result = .failure(writer.error ?? RecorderError.finishFailed)
                    }

                    self.reset()
                    continuation.resume(with: result)
                }
            }
        }
    }

    private func reset() {
        assetWriter = nil
        writerInput = nil
        pixelBufferAdaptor = nil
        outputURL = nil
        outputSize = .zero
        didStartSession = false
        lastTimestamp = .zero
    }

    private static func recordingsDirectory() throws -> URL {
        let directory = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sora", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func videoSettings(size: CGSize) -> [String: Any] {
        [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 10_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoExpectedSourceFrameRateKey: 30,
                AVVideoMaxKeyFrameIntervalKey: 30
            ]
        ]
    }

    private static func renderTransform(for extent: CGRect, outputSize: CGSize) -> CGAffineTransform {
        guard extent.width > 0, extent.height > 0 else { return .identity }
        let scale = max(outputSize.width / extent.width, outputSize.height / extent.height)
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

    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return SoraStrings.text("error.recording.already")
        case .notRecording:
            return SoraStrings.text("error.recording.none")
        case .cannotAddWriterInput:
            return SoraStrings.text("error.recording.writer_input")
        case .failedToStartWriting:
            return SoraStrings.text("error.recording.start")
        case .finishFailed:
            return SoraStrings.text("error.recording.finish")
        }
    }
}
