import CoreImage
import SwiftUI

@MainActor
final class SoraPreviewRenderer: ObservableObject, SoraLiveRendering {
    @Published private(set) var image: CIImage?

    nonisolated func render(_ image: CIImage) {
        Task { @MainActor in
            self.image = image
        }
    }
}
