import CoreImage
import MetalKit
import SwiftUI

struct MetalPreviewView: UIViewRepresentable {
    @Binding var image: CIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.framebufferOnly = false
        view.isPaused = true
        view.enableSetNeedsDisplay = true
        view.delegate = context.coordinator

        if let device = view.device {
            context.coordinator.ciContext = CIContext(mtlDevice: device, options: [.cacheIntermediates: false])
        }

        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.currentImage = image
        uiView.setNeedsDisplay()
    }

    final class Coordinator: NSObject, MTKViewDelegate {
        var ciContext: CIContext?
        var currentImage: CIImage?

        private let commandQueue: MTLCommandQueue?

        override init() {
            commandQueue = MTLCreateSystemDefaultDevice()?.makeCommandQueue()
            super.init()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard
                let currentImage,
                let ciContext,
                let drawable = view.currentDrawable,
                let commandBuffer = commandQueue?.makeCommandBuffer()
            else {
                return
            }

            let targetRect = CGRect(origin: .zero, size: view.drawableSize)
            let scaledImage = currentImage.transformed(by: renderTransform(for: currentImage.extent, outputRect: targetRect))

            let destination = CIRenderDestination(
                width: Int(targetRect.width),
                height: Int(targetRect.height),
                pixelFormat: view.colorPixelFormat,
                commandBuffer: commandBuffer,
                mtlTextureProvider: { drawable.texture }
            )

            do {
                try ciContext.startTask(toRender: scaledImage, to: destination)
            } catch {
                return
            }

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        private func renderTransform(for extent: CGRect, outputRect: CGRect) -> CGAffineTransform {
            guard extent.width > 0, extent.height > 0 else { return .identity }

            let scale = max(outputRect.width / extent.width, outputRect.height / extent.height)
            let scaledSize = CGSize(width: extent.width * scale, height: extent.height * scale)
            let x = (outputRect.width - scaledSize.width) * 0.5
            let y = (outputRect.height - scaledSize.height) * 0.5

            return CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y)
                .scaledBy(x: scale, y: scale)
                .translatedBy(x: x / scale, y: y / scale)
        }
    }
}
