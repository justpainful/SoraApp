import AVFoundation
import CoreImage
import SwiftUI
import UIKit

final class CameraPipelineController: ObservableObject {
    @Published var showOriginal = false
    @Published private(set) var hasRenderedFrame = false
    @Published private(set) var previewImage: CIImage?
    @Published var renderErrorMessage: String?

    let cameraManager: SoraCameraManager
    let renderer: SoraPreviewRenderer
    let recordingCoordinator: RecordingCoordinator

    private let processor: SoraImageProcessing
    private let processingQueue = DispatchQueue(label: "com.sora.pipeline.processing", qos: .userInteractive)

    private weak var appState: AppState?
    @MainActor private var isProcessingFrame = false
    @MainActor private var pendingFrame: SoraFrame?
    @MainActor private var pendingSettings = SoraFilterSettings()
    @MainActor private var pendingShowOriginal = false
    @MainActor private var latestOutputSize = CGSize(width: 1080, height: 1920)
    @MainActor private var isFrameProcessingEnabled = false

    @MainActor
    init(
        cameraManager: SoraCameraManager = SoraCameraManager(),
        processor: SoraImageProcessing = SoraFilterProcessor()
    ) {
        self.cameraManager = cameraManager
        self.processor = processor
        self.renderer = SoraPreviewRenderer()
        self.recordingCoordinator = RecordingCoordinator()
    }

    @MainActor
    func bind(appState: AppState) {
        guard self.appState == nil else { return }

        self.appState = appState
        recordingCoordinator.bind(appState: appState)

        cameraManager.onFrame = { [weak self] frame in
            Task { @MainActor [weak self] in
                self?.receive(frame)
            }
        }
    }

    var authorizationStatus: AVAuthorizationStatus {
        cameraManager.authorizationStatus
    }

    @MainActor
    func start() {
        guard cameraManager.authorizationStatus == .authorized else { return }
        cameraManager.startSession()
    }

    func stop() {
        cameraManager.stopSession()
    }

    func requestPermission() {
        cameraManager.requestAuthorization()
    }

    @MainActor
    func selectLens(_ lens: SoraLensMode) {
        guard cameraManager.canUseLens(lens) else {
            appState?.showToast("Lens unavailable", message: "0.5x lens is not available on this device.")
            return
        }

        appState?.lensMode = lens
        cameraManager.switchLens(to: lens)
    }

    @MainActor
    func selectQuality(_ mode: SoraQualityMode) {
        appState?.qualityMode = mode
        cameraManager.setQualityMode(mode)
    }

    @MainActor
    func toggleRecording() {
        guard let appState else { return }

        if appState.isRecording {
            recordingCoordinator.stopRecording()
        } else {
            isFrameProcessingEnabled = true
            recordingCoordinator.startRecording(outputSize: latestOutputSize, frameRate: 30)
        }
    }

    @MainActor
    func setFrameProcessingEnabled(_ enabled: Bool) {
        isFrameProcessingEnabled = enabled
    }

    @MainActor
    private func receive(_ frame: SoraFrame) {
        guard let appState else { return }

        latestOutputSize = Self.normalizedOutputSize(for: frame.ciImage.extent)

        guard isFrameProcessingEnabled else {
            if showOriginal {
                previewImage = frame.ciImage
                renderer.render(frame.ciImage)
            }
            return
        }

        let settings = appState.filterSettings
        let showOriginal = self.showOriginal

        if isProcessingFrame {
            pendingFrame = frame
            pendingSettings = settings
            pendingShowOriginal = showOriginal
            return
        }

        isProcessingFrame = true
        process(frame: frame, settings: settings, showOriginal: showOriginal)
    }

    @MainActor
    private func process(frame: SoraFrame, settings: SoraFilterSettings, showOriginal: Bool) {
        processingQueue.async { [weak self] in
            guard let self else { return }

            let processedImage = self.processor.process(frame: frame, settings: settings)
            let displayImage = showOriginal ? frame.ciImage : processedImage
            let outputSize = Self.normalizedOutputSize(for: processedImage.extent)

            Task { @MainActor [weak self] in
                guard let self else { return }

                self.latestOutputSize = outputSize
                self.previewImage = displayImage
                self.hasRenderedFrame = true
                self.renderer.render(displayImage)

                if case .recording = self.appState?.recordingState {
                    self.recordingCoordinator.appendFrame(image: processedImage, timestamp: frame.timestamp)
                }

                if let pendingFrame = self.pendingFrame {
                    let pendingSettings = self.pendingSettings
                    let pendingShowOriginal = self.pendingShowOriginal
                    self.pendingFrame = nil
                    self.process(frame: pendingFrame, settings: pendingSettings, showOriginal: pendingShowOriginal)
                } else {
                    self.isProcessingFrame = false
                }
            }
        }
    }

    private static func normalizedOutputSize(for extent: CGRect) -> CGSize {
        guard extent.width > 0, extent.height > 0 else {
            return CGSize(width: 1080, height: 1920)
        }

        func even(_ value: CGFloat) -> CGFloat {
            let rounded = max(2, Int(value.rounded()))
            return CGFloat(rounded.isMultiple(of: 2) ? rounded : rounded + 1)
        }

        return CGSize(width: even(extent.width), height: even(extent.height))
    }
}

struct CameraView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var isRequestingPermission = false
    @State private var isPresentingAuthorizedCamera = false
    @State private var authorizationPresentationTask: Task<Void, Never>?

    var body: some View {
        Group {
            if isPresentingAuthorizedCamera {
                AuthorizedCameraView()
            } else {
                CameraPermissionView(
                    action: handlePermissionAction,
                    isDenied: authorizationStatus == .denied || authorizationStatus == .restricted,
                    isLoading: authorizationStatus == .authorized
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            refreshAuthorizationStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshAuthorizationStatus()
            } else if phase == .inactive || phase == .background {
                authorizationPresentationTask?.cancel()
                authorizationPresentationTask = nil
                isPresentingAuthorizedCamera = false
            }
        }
    }

    private func handlePermissionAction() {
        if authorizationStatus == .notDetermined {
            guard !isRequestingPermission else { return }
            isRequestingPermission = true
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    isRequestingPermission = false
                    authorizationStatus = granted ? .authorized : .denied
                    updateAuthorizedPresentation()
                }
            }
        } else if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }

    private func refreshAuthorizationStatus() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        updateAuthorizedPresentation()
    }

    private func updateAuthorizedPresentation() {
        authorizationPresentationTask?.cancel()

        guard authorizationStatus == .authorized, scenePhase == .active else {
            isPresentingAuthorizedCamera = false
            authorizationPresentationTask = nil
            return
        }

        authorizationPresentationTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            guard authorizationStatus == .authorized, scenePhase == .active else { return }
            isPresentingAuthorizedCamera = true
            authorizationPresentationTask = nil
        }
    }
}

private struct AuthorizedCameraView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var pipeline = CameraPipelineController()
    @State private var hasStartedSession = false
    @State private var isChromeVisible = false
    @State private var pendingStartTask: Task<Void, Never>?
    @State private var pendingProcessingTask: Task<Void, Never>?
    @State private var pendingChromeTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            previewContent

            if isChromeVisible, let toast = appState.toast {
                VStack {
                    Spacer(minLength: 0)
                    SoraToastView(toast: toast) {
                        if appState.toast?.id == toast.id {
                            appState.toast = nil
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 108)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .top, spacing: 0) {
            if isChromeVisible {
                SoraHeader(cameraManager: pipeline.cameraManager) { lens in
                    pipeline.selectLens(lens)
                } selectQuality: { mode in
                    pipeline.selectQuality(mode)
                } openSettings: {
                    appState.isSettingsOpen = true
                }
                .padding(.top, 8)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isChromeVisible {
                VStack(spacing: 10) {
                    if appState.isRecording || appState.recordingState == .saving {
                        RecordingHUD(
                            state: appState.recordingState,
                            onRecordTapped: pipeline.toggleRecording,
                            onStopTapped: pipeline.toggleRecording
                        )
                        .padding(.horizontal, 16)
                    }

                    ControlsOverlay(
                        coordinator: pipeline.recordingCoordinator,
                        showOriginal: $pipeline.showOriginal,
                        toggleRecording: pipeline.toggleRecording,
                        openFilters: { appState.isFilterStudioOpen = true }
                    )
                }
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $appState.isFilterStudioOpen) {
            FilterStudioSheet(showOriginal: $pipeline.showOriginal)
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.isSettingsOpen) {
            SettingsSheet(
                coordinator: pipeline.recordingCoordinator,
                onSelectQuality: pipeline.selectQuality
            )
            .environmentObject(appState)
        }
        .sheet(
            item: Binding(
                get: { pipeline.recordingCoordinator.saveResult },
                set: { pipeline.recordingCoordinator.saveResult = $0 }
            )
        ) { result in
            SaveResultSheet(result: result) {
                pipeline.recordingCoordinator.dismissSaveResult()
            }
        }
        .onAppear {
            Task { @MainActor in
                pipeline.bind(appState: appState)
                appState.lensMode = pipeline.cameraManager.currentLens
                scheduleCameraStartIfReady()
            }
        }
        .onDisappear {
            pendingStartTask?.cancel()
            pendingStartTask = nil
            pendingProcessingTask?.cancel()
            pendingProcessingTask = nil
            pendingChromeTask?.cancel()
            pendingChromeTask = nil
            pipeline.setFrameProcessingEnabled(false)
            pipeline.stop()
            hasStartedSession = false
            isChromeVisible = false
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                scheduleCameraStartIfReady()
            case .inactive, .background:
                pendingStartTask?.cancel()
                pendingStartTask = nil
                pendingProcessingTask?.cancel()
                pendingProcessingTask = nil
                pendingChromeTask?.cancel()
                pendingChromeTask = nil
                pipeline.setFrameProcessingEnabled(false)
                pipeline.stop()
                hasStartedSession = false
                isChromeVisible = false
            @unknown default:
                break
            }
        }
        .onChange(of: pipeline.cameraManager.isRunning) { _, isRunning in
            if isRunning {
                scheduleChromeReveal()
            } else {
                pendingChromeTask?.cancel()
                pendingChromeTask = nil
                isChromeVisible = false
            }
        }
        .onReceive(pipeline.cameraManager.$currentLens) { lens in
            if appState.lensMode != lens {
                appState.lensMode = lens
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: appState.isRecording)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: appState.toast?.id)
    }

    @ViewBuilder
    private var previewContent: some View {
        ZStack {
            CameraSessionPreviewView(session: pipeline.cameraManager.previewSession)
                .ignoresSafeArea()

            if !pipeline.showOriginal, pipeline.previewImage != nil {
                MetalPreviewView(
                    image: Binding(
                        get: { pipeline.previewImage },
                        set: { _ in }
                    ),
                    errorMessage: $pipeline.renderErrorMessage
                )
                .ignoresSafeArea()
            }

            if let cameraError = pipeline.cameraManager.sessionErrorMessage {
                errorCard(title: "Camera unavailable", message: cameraError)
            } else if !pipeline.cameraManager.isRunning && !pipeline.hasRenderedFrame {
                ProgressView("Loading camera...")
                    .padding(20)
                    .soraGlassRounded(cornerRadius: 20, tint: .white.opacity(0.06), fallbackStrokeOpacity: 0.08)
            } else if let renderError = pipeline.renderErrorMessage, !pipeline.showOriginal {
                VStack {
                    Spacer()
                    Text(renderError)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .soraGlassCapsule(tint: .white.opacity(0.06), fallbackStrokeOpacity: 0.08)
                        .padding(.bottom, 120)
                }
            }
        }
    }

    private func errorCard(title: String, message: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .soraGlassRounded(cornerRadius: 20, tint: .white.opacity(0.06), fallbackStrokeOpacity: 0.08)
        .padding(.horizontal, 24)
    }

    private func scheduleCameraStartIfReady() {
        guard scenePhase == .active else { return }
        guard !hasStartedSession else { return }

        pendingStartTask?.cancel()
        isChromeVisible = false
        pendingStartTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            guard scenePhase == .active else { return }
            guard !hasStartedSession else { return }

            hasStartedSession = true
            pipeline.start()
            scheduleProcessingEnable()
        }
    }

    private func scheduleProcessingEnable() {
        pendingProcessingTask?.cancel()
        pipeline.setFrameProcessingEnabled(false)

        pendingProcessingTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            guard scenePhase == .active else { return }
            guard hasStartedSession else { return }

            pipeline.setFrameProcessingEnabled(true)
        }
    }

    private func scheduleChromeReveal() {
        guard scenePhase == .active else { return }
        guard hasStartedSession else { return }

        pendingChromeTask?.cancel()
        pendingChromeTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            guard scenePhase == .active else { return }
            guard hasStartedSession else { return }
            guard pipeline.cameraManager.isRunning else { return }

            withAnimation(.easeOut(duration: 0.2)) {
                isChromeVisible = true
            }
        }
    }
}
