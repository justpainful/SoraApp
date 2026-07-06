import CoreImage
import MetalKit
import SwiftUI

struct MetalPreviewView: UIViewRepresentable {
    @Binding var image: CIImage?
    @Binding var errorMessage: String?

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.framebufferOnly = false
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = true
        mtkView.delegate = context.coordinator

        guard let device = MTLCreateSystemDefaultDevice() else {
            DispatchQueue.main.async {
                errorMessage = "Metal is not available on this device."
            }
            return mtkView
        }

        mtkView.device = device
        context.coordinator.configure(device: device)
        DispatchQueue.main.async {
            errorMessage = nil
        }

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.currentImage = image
        context.coordinator.errorDidChange = { message in
            DispatchQueue.main.async {
                errorMessage = message
            }
        }
        uiView.setNeedsDisplay()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, MTKViewDelegate {
        var ciContext: CIContext?
        var currentImage: CIImage?
        var errorDidChange: ((String?) -> Void)?

        private var commandQueue: MTLCommandQueue?

        func configure(device: MTLDevice) {
            commandQueue = device.makeCommandQueue()
            ciContext = CIContext(mtlDevice: device, options: [.cacheIntermediates: false, .allowLowPower: true])
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let image = currentImage else { return }
            guard let ciContext,
                  let drawable = view.currentDrawable,
                  let commandQueue,
                  let commandBuffer = commandQueue.makeCommandBuffer() else {
                errorDidChange?("Preview rendering could not start.")
                return
            }

            let drawableSize = view.drawableSize
            let imageSize = image.extent.size
            guard drawableSize.width > 0,
                  drawableSize.height > 0,
                  imageSize.width > 0,
                  imageSize.height > 0 else {
                errorDidChange?("Preview received an invalid frame size.")
                return
            }

            let scaleX = drawableSize.width / imageSize.width
            let scaleY = drawableSize.height / imageSize.height
            let scale = max(scaleX, scaleY)

            let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            let tx = (drawableSize.width - scaledImage.extent.width) / 2.0
            let ty = (drawableSize.height - scaledImage.extent.height) / 2.0
            let centeredImage = scaledImage.transformed(by: CGAffineTransform(translationX: tx, y: ty))

            let destination = CIRenderDestination(
                width: Int(drawableSize.width),
                height: Int(drawableSize.height),
                pixelFormat: view.colorPixelFormat,
                commandBuffer: commandBuffer
            ) {
                drawable.texture
            }

            do {
                try ciContext.startTask(toRender: centeredImage, to: destination)
                errorDidChange?(nil)
            } catch {
                errorDidChange?("Preview rendering failed: \(error.localizedDescription)")
            }

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
