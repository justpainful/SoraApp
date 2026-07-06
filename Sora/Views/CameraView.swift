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
            recordingCoordinator.startRecording(outputSize: latestOutputSize, frameRate: 30)
        }
    }

    @MainActor
    private func receive(_ frame: SoraFrame) {
        guard let appState else { return }

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
    @EnvironmentObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var pipeline = CameraPipelineController()
    @State private var hasStartedSession = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                if pipeline.authorizationStatus == .authorized {
                    previewContent
                } else {
                    CameraPermissionView(
                        action: handlePermissionAction,
                        isDenied: pipeline.authorizationStatus == .denied || pipeline.authorizationStatus == .restricted
                    )
                }

                if pipeline.authorizationStatus == .authorized {
                    VStack(spacing: 0) {
                        SoraHeader(cameraManager: pipeline.cameraManager) { lens in
                            pipeline.selectLens(lens)
                        } selectQuality: { mode in
                            pipeline.selectQuality(mode)
                        } openSettings: {
                            appState.isSettingsOpen = true
                        }
                        .padding(.top, max(proxy.safeAreaInsets.top, 12))

                        Spacer(minLength: 0)

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
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom, 10))
                    }
                }

                if let toast = appState.toast {
                    VStack {
                        Spacer()
                        SoraToastView(toast: toast) {
                            if appState.toast?.id == toast.id {
                                appState.toast = nil
                            }
                        }
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom, 10))
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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
                pipeline.cameraManager.refreshAuthorizationStatus()
                appState.lensMode = pipeline.cameraManager.currentLens
                if pipeline.authorizationStatus == .authorized && !hasStartedSession {
                    hasStartedSession = true
                    pipeline.start()
                }
            }
        }
        .onDisappear {
            pipeline.stop()
            hasStartedSession = false
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                pipeline.cameraManager.refreshAuthorizationStatus()
            case .inactive, .background:
                pipeline.stop()
                hasStartedSession = false
            @unknown default:
                break
            }
        }
        .onReceive(pipeline.cameraManager.$authorizationStatus) { status in
            switch status {
            case .authorized:
                if !hasStartedSession {
                    hasStartedSession = true
                    pipeline.start()
                }
            case .denied, .restricted, .notDetermined:
                pipeline.stop()
                hasStartedSession = false
            @unknown default:
                break
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
            MetalPreviewView(
                image: Binding(
                    get: { pipeline.previewImage },
                    set: { _ in }
                ),
                errorMessage: $pipeline.renderErrorMessage
            )
            .ignoresSafeArea()

            if let cameraError = pipeline.cameraManager.sessionErrorMessage {
                errorCard(title: "Camera unavailable", message: cameraError)
            } else if let renderError = pipeline.renderErrorMessage {
                errorCard(title: "Preview unavailable", message: renderError)
            } else if !pipeline.hasRenderedFrame {
                ProgressView("Loading camera...")
                    .padding(20)
                    .soraGlassRounded(cornerRadius: 20, tint: .white.opacity(0.06), fallbackStrokeOpacity: 0.08)
            }
        }
    }

    private func handlePermissionAction() {
        if pipeline.authorizationStatus == .notDetermined {
            pipeline.requestPermission()
        } else if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
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
}
