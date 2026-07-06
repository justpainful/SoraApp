import SwiftUI

struct CameraPermissionView: View {
    let action: () -> Void
    let isDenied: Bool
    let isLoading: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .padding()
                    .background(
                        Circle().fill(.white.opacity(0.1))
                    )
                
                VStack(spacing: 8) {
                    Text("Camera Access")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    Text(
                        isDenied
                            ? "Sora needs camera access to capture video. Please enable it in Settings."
                            : isLoading
                                ? "Camera access was granted. Preparing the camera..."
                                : "Sora needs camera access to capture video."
                    )
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 32)
                }
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding(.top, 16)
                } else {
                    Button(action: action) {
                        Text(isDenied ? "Open Settings" : "Allow Camera")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 32)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 16)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    CameraPermissionView(action: {}, isDenied: false, isLoading: false)
}
