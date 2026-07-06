import SwiftUI

struct CameraPermissionView: View {
    let isDenied: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image("SoraLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            Text(isDenied ? "permission.denied.title" : "permission.request.title")
                .font(.title2.weight(.semibold))
                .foregroundStyle(SoraTheme.textPrimary)

            Text(isDenied ? "permission.denied.message" : "permission.request.message")
                .font(.body)
                .foregroundStyle(SoraTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button(isDenied ? "permission.open_settings" : "permission.allow_camera", action: action)
                .buttonStyle(.borderedProminent)
                .tint(SoraTheme.accent)
        }
        .padding(28)
        .soraPanel()
        .padding(24)
    }
}
