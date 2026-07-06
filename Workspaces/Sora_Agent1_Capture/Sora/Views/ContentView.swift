import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var cameraManager = SoraCameraManager()
    @State private var currentImage: CIImage?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if cameraManager.authorizationStatus == .authorized {
                MetalPreviewView(image: $currentImage)
                    .ignoresSafeArea()
                    .onAppear {
                        cameraManager.onFrame = { frame in
                            DispatchQueue.main.async {
                                self.currentImage = frame.ciImage
                            }
                        }
                        cameraManager.startSession()
                    }
                    .onDisappear {
                        cameraManager.stopSession()
                    }
                
                // Lens switcher UI for testing
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            let newLens: SoraLensMode = cameraManager.currentLens == .wide ? .ultraWide : .wide
                            cameraManager.switchLens(to: newLens)
                        }) {
                            Text(cameraManager.currentLens.rawValue)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(24)
                    }
                }
            } else {
                CameraPermissionView(
                    action: {
                        if cameraManager.authorizationStatus == .notDetermined {
                            cameraManager.requestAuthorization()
                        } else {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    },
                    isDenied: cameraManager.authorizationStatus == .denied
                )
            }
        }
        .onAppear {
            if cameraManager.authorizationStatus == .authorized {
                cameraManager.startSession()
            }
        }
    }
}
