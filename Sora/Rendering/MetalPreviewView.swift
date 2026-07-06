import CoreImage
import SwiftUI
import UIKit

struct MetalPreviewView: UIViewRepresentable {
    @Binding var image: CIImage?
    @Binding var errorMessage: String?

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .black
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        context.coordinator.render(
            image: image,
            targetSize: uiView.bounds.size
        ) { renderedImage, message in
            errorMessage = message
            if let renderedImage {
                uiView.image = renderedImage
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private let ciContext = CIContext(options: [.cacheIntermediates: false])
        private let renderQueue = DispatchQueue(label: "com.sora.preview.render", qos: .userInteractive)
        private var renderID: Int = 0

        func render(
            image: CIImage?,
            targetSize: CGSize,
            completion: @escaping (UIImage?, String?) -> Void
        ) {
            guard let image else { return }

            renderID += 1
            let currentRenderID = renderID

            renderQueue.async { [ciContext] in
                let extent = image.extent.integral
                guard extent.width > 0, extent.height > 0 else {
                    DispatchQueue.main.async {
                        completion(nil, "Preview received an invalid frame size.")
                    }
                    return
                }

                let outputImage: CIImage
                if targetSize.width > 0, targetSize.height > 0 {
                    let scaleX = targetSize.width / extent.width
                    let scaleY = targetSize.height / extent.height
                    let scale = max(scaleX, scaleY)
                    let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                    let tx = (targetSize.width - scaledImage.extent.width) / 2.0
                    let ty = (targetSize.height - scaledImage.extent.height) / 2.0
                    outputImage = scaledImage.transformed(by: CGAffineTransform(translationX: tx, y: ty))
                } else {
                    outputImage = image
                }

                guard let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent.integral) else {
                    DispatchQueue.main.async {
                        completion(nil, "Preview rendering failed.")
                    }
                    return
                }

                let renderedImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    guard currentRenderID == self.renderID else { return }
                    completion(renderedImage, nil)
                }
            }
        }
    }
}
