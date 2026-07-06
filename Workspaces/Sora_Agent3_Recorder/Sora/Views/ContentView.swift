import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

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

            VStack(spacing: 18) {
                Image("SoraLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(radius: 18)

                Text("Sora")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Shared Core Ready")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.82))

                Text("Give each agent its assigned workspace and prompt.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.58))
                    .padding(.horizontal, 28)
            }
        }
    }
}
