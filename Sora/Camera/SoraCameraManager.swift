import AVFoundation
import CoreImage
import Foundation

final class SoraCameraManager: NSObject, ObservableObject, SoraCameraFrameOutput {
    @Published private(set) var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published private(set) var currentLens: SoraLensMode = .wide
    @Published private(set) var availableLensModes: [SoraLensMode] = [.wide]
    @Published private(set) var isRunning = false
    @Published private(set) var sessionErrorMessage: String?

    var onFrame: ((SoraFrame) -> Void)? {
        get { frameHandlerLock.withLock { frameHandler } }
        set { frameHandlerLock.withLock { frameHandler = newValue } }
    }

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.sora.camera.session", qos: .userInitiated)
    private let videoOutputQueue = DispatchQueue(label: "com.sora.camera.videoOutput", qos: .userInteractive)
    private let frameCounterLock = NSLock()
    private let frameHandlerLock = NSLock()

    private var frameHandler: ((SoraFrame) -> Void)?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var frameCounter: Int64 = 0
    private var isConfigured = false
    private var isConfiguring = false

    var previewSession: AVCaptureSession {
        captureSession
    }

    override init() {
        super.init()
        refreshAvailableLenses()
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func refreshAuthorizationStatus() {
        updateAuthorizationStatus(AVCaptureDevice.authorizationStatus(for: .video))
    }

    func requestAuthorization() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }
            self.updateAuthorizationStatus(granted ? .authorized : .denied)
            if granted {
                self.updateSessionError(nil)
            } else {
                self.updateSessionError("Camera permission was denied.")
            }
        }
    }

    func startSession() {
        switch authorizationStatus {
        case .authorized:
            break
        case .notDetermined:
            requestAuthorization()
            return
        case .denied, .restricted:
            updateSessionError("Camera access is unavailable. Enable camera access in Settings.")
            return
        @unknown default:
            updateSessionError("Camera authorization returned an unknown state.")
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.configureSessionIfNeeded() else { return }
            guard !self.captureSession.isRunning else {
                self.publishRunningState(true)
                return
            }

            self.captureSession.startRunning()
            self.publishRunningState(self.captureSession.isRunning)
            if self.captureSession.isRunning {
                self.updateSessionError(nil)
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            self.resetFrameCounter()
            self.publishRunningState(false)
        }
    }

    func switchLens(to lens: SoraLensMode) {
        guard canUseLens(lens) else {
            updateSessionError("0.5x lens is not available on this device.")
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.captureSession.beginConfiguration()
            let selectedLens = self.installVideoInput(for: lens)
            self.captureSession.commitConfiguration()

            guard let selectedLens else { return }
            self.publishCurrentLens(selectedLens)
            self.updateSessionError(nil)
        }
    }

    func setQualityMode(_ mode: SoraQualityMode) {
        if mode != .performance {
            updateSessionError("Quality mode is coming in v0.2. Current build uses stable 1080p30.")
        }
    }

    func canUseLens(_ lens: SoraLensMode) -> Bool {
        availableLensModes.contains(lens)
    }

    private func configureSessionIfNeeded() -> Bool {
        if isConfigured { return true }
        if isConfiguring { return false }

        isConfiguring = true
        defer { isConfiguring = false }

        refreshAvailableLenses()
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1920x1080

        guard installVideoInput(for: currentLens) != nil else {
            captureSession.commitConfiguration()
            isConfigured = false
            return false
        }

        if !captureSession.outputs.contains(where: { $0 === videoOutput }) {
            guard captureSession.canAddOutput(videoOutput) else {
                captureSession.commitConfiguration()
                updateSessionError("The camera output could not be configured.")
                isConfigured = false
                return false
            }

            captureSession.addOutput(videoOutput)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            ]
            videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        }

        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = false
            }
        }

        captureSession.commitConfiguration()
        isConfigured = true
        updateSessionError(nil)
        return true
    }

    private func installVideoInput(for desiredLens: SoraLensMode) -> SoraLensMode? {
        guard let device = cameraDevice(for: desiredLens) else {
            updateSessionError("No compatible back camera is available on this device.")
            return nil
        }

        if let currentInput = videoDeviceInput {
            captureSession.removeInput(currentInput)
            videoDeviceInput = nil
        }

        configureDevice(device)

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard captureSession.canAddInput(input) else {
                updateSessionError("The selected camera input could not be attached.")
                return nil
            }

            captureSession.addInput(input)
            videoDeviceInput = input

            let selectedLens: SoraLensMode = device.deviceType == .builtInUltraWideCamera ? .ultraWide : .wide
            publishCurrentLens(selectedLens)
            return selectedLens
        } catch {
            updateSessionError("The selected camera input could not be created: \(error.localizedDescription)")
            return nil
        }
    }

    private func cameraDevice(for lens: SoraLensMode) -> AVCaptureDevice? {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .back
        )

        switch lens {
        case .wide:
            return session.devices.first { $0.deviceType == .builtInWideAngleCamera }
        case .ultraWide:
            return session.devices.first { $0.deviceType == .builtInUltraWideCamera }
        }
    }

    private func configureDevice(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            if let format = bestFormat(for: device) {
                device.activeFormat = format
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
            }
        } catch {
            updateSessionError("The camera could not be configured: \(error.localizedDescription)")
        }
    }

    private func bestFormat(for device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        device.formats.first { format in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            guard dimensions.width == 1920, dimensions.height == 1080 else {
                return false
            }

            return format.videoSupportedFrameRateRanges.contains { range in
                range.minFrameRate <= 30 && range.maxFrameRate >= 30
            }
        }
    }

    private func refreshAvailableLenses() {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .back
        )

        var lenses: [SoraLensMode] = []
        if discovery.devices.contains(where: { $0.deviceType == .builtInWideAngleCamera }) {
            lenses.append(.wide)
        }
        if discovery.devices.contains(where: { $0.deviceType == .builtInUltraWideCamera }) {
            lenses.append(.ultraWide)
        }
        if lenses.isEmpty {
            lenses = [.wide]
        }

        DispatchQueue.main.async { [lenses] in
            self.availableLensModes = lenses
            if !lenses.contains(self.currentLens) {
                self.currentLens = .wide
            }
        }
    }

    private func nextFrameIndex() -> Int64 {
        frameCounterLock.withLock {
            let value = frameCounter
            frameCounter += 1
            return value
        }
    }

    private func resetFrameCounter() {
        frameCounterLock.withLock {
            frameCounter = 0
        }
    }

    private func updateAuthorizationStatus(_ status: AVAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
    }

    private func publishCurrentLens(_ lens: SoraLensMode) {
        DispatchQueue.main.async {
            self.currentLens = lens
        }
    }

    private func publishRunningState(_ running: Bool) {
        DispatchQueue.main.async {
            self.isRunning = running
        }
    }

    private func updateSessionError(_ message: String?) {
        DispatchQueue.main.async {
            self.sessionErrorMessage = message
        }
    }
}

extension SoraCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let image = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
        let frame = SoraFrame(
            pixelBuffer: pixelBuffer,
            ciImage: image,
            timestamp: timestamp,
            frameIndex: nextFrameIndex()
        )

        let handler = onFrame
        handler?(frame)
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
