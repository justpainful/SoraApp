import SwiftUI

struct BeforeAfterButton: View {
    @Binding var showOriginal: Bool

    var body: some View {
        Button(showOriginal ? "filter.show_processed" : "filter.show_original") {
            showOriginal.toggle()
        }
        .buttonStyle(.borderedProminent)
        .tint(SoraTheme.accent)
        .accessibilityHint("filter.before_after_hint")
    }
}
