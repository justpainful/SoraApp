import CoreImage
import SwiftUI

@MainActor
final class SoraPreviewRenderer: ObservableObject, SoraLiveRendering {
    @Published private(set) var image: CIImage?

    func render(_ image: CIImage) {
        self.image = image
    }
}
