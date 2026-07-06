import AVFoundation
import CoreImage
import SwiftUI

final class SoraCameraManager: NSObject, ObservableObject, SoraCameraFrameOutput {
    @Published private(set) var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published private(set) var currentLens: SoraLensMode = .wide
    @Published private(set) var qualityMode: SoraQualityMode = .performance
    @Published private(set) var isRunning = false

    var onFrame: ((SoraFrame) -> Void)?

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.sora.camera.session")
    private let videoOutputQueue = DispatchQueue(label: "com.sora.camera.frames")

    private var videoDeviceInput: AVCaptureDeviceInput?
    private var frameIndex: Int64 = 0
    private var isConfigured = false

    override init() {
        super.init()
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestAuthorization() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.authorizationStatus = granted ? .authorized : .denied
                if granted {
                    self?.startSession()
                }
            }
        }
    }

    func startSession() {
        switch authorizationStatus {
        case .authorized:
            configureSessionIfNeeded()
            sessionQueue.async {
                guard !self.captureSession.isRunning else { return }
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isRunning = true
                }
            }
        case .notDetermined:
            requestAuthorization()
        default:
            break
        }
    }

    func stopSession() {
        sessionQueue.async {
            guard self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }

    func switchLens(to lens: SoraLensMode) {
        sessionQueue.async {
            self.captureSession.beginConfiguration()
            self.installDeviceInput(for: lens)
            self.captureSession.commitConfiguration()
            DispatchQueue.main.async {
                self.currentLens = lens
            }
        }
    }

    func setQualityMode(_ mode: SoraQualityMode) {
        qualityMode = mode
        sessionQueue.async {
            self.videoOutput.alwaysDiscardsLateVideoFrames = mode == .performance
        }
    }

    private func configureSessionIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        sessionQueue.async {
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .hd1920x1080
            self.installDeviceInput(for: self.currentLens)

            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                ]
                self.videoOutput.alwaysDiscardsLateVideoFrames = self.qualityMode == .performance
                self.videoOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
            }

            if let connection = self.videoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = false
                }
            }

            self.captureSession.commitConfiguration()
        }
    }

    private func installDeviceInput(for lens: SoraLensMode) {
        if let videoDeviceInput {
            captureSession.removeInput(videoDeviceInput)
        }

        let deviceType: AVCaptureDevice.DeviceType
        switch lens {
        case .wide:
            deviceType = .builtInWideAngleCamera
        case .ultraWide:
            deviceType = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) == nil
                ? .builtInWideAngleCamera
                : .builtInUltraWideCamera
        }

        guard let device = AVCaptureDevice.default(deviceType, for: .video, position: .back) else {
            return
        }

        do {
            try device.lockForConfiguration()
            if let format = device.formats.first(where: { format in
                let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                return dimensions.width == 1920 && dimensions.height == 1080
                    && format.videoSupportedFrameRateRanges.contains { $0.minFrameRate <= 30 && $0.maxFrameRate >= 30 }
            }) {
                device.activeFormat = format
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
            }
            device.unlockForConfiguration()
        } catch {
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard captureSession.canAddInput(input) else { return }
            captureSession.addInput(input)
            videoDeviceInput = input
        } catch {
            return
        }
    }
}

extension SoraCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let image = CIImage(cvPixelBuffer: pixelBuffer)

        frameIndex += 1

        onFrame?(
            SoraFrame(
                pixelBuffer: pixelBuffer,
                ciImage: image,
                timestamp: timestamp,
                frameIndex: frameIndex
            )
        )
    }
}
