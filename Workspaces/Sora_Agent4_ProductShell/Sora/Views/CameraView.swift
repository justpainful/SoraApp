import AVFoundation
import CoreImage
import SwiftUI
import UIKit

@MainActor
final class CameraPipelineController: ObservableObject {
    @Published var showOriginal = false
    @Published private(set) var hasRenderedFrame = false

    let cameraManager: SoraCameraManager
    let renderer: SoraPreviewRenderer
    let recordingCoordinator: RecordingCoordinator

    private let processor: SoraImageProcessing
    private weak var appState: AppState?

    init(
        cameraManager: SoraCameraManager = SoraCameraManager(),
        processor: SoraImageProcessing = SoraFilterProcessor(),
        renderer: SoraPreviewRenderer = SoraPreviewRenderer(),
        recordingCoordinator: RecordingCoordinator = RecordingCoordinator()
    ) {
        self.cameraManager = cameraManager
        self.processor = processor
        self.renderer = renderer
        self.recordingCoordinator = recordingCoordinator
    }

    func bind(appState: AppState) {
        self.appState = appState
        recordingCoordinator.bind(appState: appState)

        cameraManager.onFrame = { [weak self] frame in
            Task { @MainActor [weak self] in
                guard let self, let appState = self.appState else { return }

                let processed = self.processor.process(frame: frame, settings: appState.filterSettings)
                self.renderer.render(self.showOriginal ? frame.ciImage.oriented(.right) : processed)
                self.hasRenderedFrame = true

                if self.recordingCoordinatorIsActive {
                    self.recordingCoordinator.appendFrame(image: processed, timestamp: frame.timestamp)
                }
            }
        }
    }

    var authorizationStatus: AVAuthorizationStatus {
        cameraManager.authorizationStatus
    }

    var previewImage: CIImage? {
        renderer.image
    }

    private var recordingCoordinatorIsActive: Bool {
        if case .recording = appState?.recordingState {
            return true
        }
        return false
    }

    func start() {
        cameraManager.startSession()
    }

    func stop() {
        cameraManager.stopSession()
    }

    func requestPermission() {
        cameraManager.requestAuthorization()
    }

    func updateLens(_ lens: SoraLensMode) {
        cameraManager.switchLens(to: lens)
    }

    func updateQuality(_ mode: SoraQualityMode) {
        cameraManager.setQualityMode(mode)
    }

    func toggleRecording() {
        guard let appState else { return }

        if appState.isRecording {
            recordingCoordinator.stopRecording()
        } else {
            recordingCoordinator.startRecording()
        }
    }
}

struct CameraView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var pipeline = CameraPipelineController()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SoraTheme.backgroundTop, SoraTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if pipeline.authorizationStatus == .authorized {
                previewContent
            } else {
                CameraPermissionView(
                    isDenied: pipeline.authorizationStatus == .denied || pipeline.authorizationStatus == .restricted,
                    action: handlePermissionAction
                )
            }

            VStack {
                SoraHeader {
                    appState.isSettingsOpen = true
                }
                .padding(.top, 8)

                Spacer()

                ControlsOverlay(
                    coordinator: pipeline.recordingCoordinator,
                    toggleRecording: pipeline.toggleRecording,
                    openFilters: { appState.isFilterStudioOpen = true },
                    selectQualityMode: pipeline.updateQuality
                )
            }

            if let toast = appState.toast {
                VStack {
                    Spacer()
                    SoraToastView(toast: toast) {
                        if appState.toast?.id == toast.id {
                            appState.toast = nil
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $appState.isFilterStudioOpen) {
            FilterStudioSheet(showOriginal: $pipeline.showOriginal)
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.isSettingsOpen) {
            SettingsSheet(coordinator: pipeline.recordingCoordinator)
                .environmentObject(appState)
        }
        .onAppear {
            pipeline.bind(appState: appState)
            pipeline.start()
        }
        .onDisappear {
            pipeline.stop()
        }
        .onChange(of: appState.lensMode) { _, value in
            pipeline.updateLens(value)
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        ZStack {
            MetalPreviewView(
                image: Binding(
                    get: { pipeline.previewImage },
                    set: { _ in }
                )
            )
            .ignoresSafeArea()

            if !pipeline.hasRenderedFrame {
                ProgressView("camera.loading")
                    .padding(20)
                    .soraPanel()
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
}
