import SwiftUI

struct CameraPermissionView: View {
    let action: () -> Void
    let isDenied: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.015, green: 0.055, blue: 0.13),
                    Color(red: 0.015, green: 0.13, blue: 0.28),
                    Color(red: 0.02, green: 0.22, blue: 0.44)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
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
                    
                    Text(isDenied ? 
                         "Sora needs camera access to capture video. Please enable it in Settings." : 
                         "Sora needs camera access to capture video.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 32)
                }
                
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
    }
}

#Preview {
    CameraPermissionView(action: {}, isDenied: false)
}
