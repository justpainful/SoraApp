import SwiftUI
import MetalKit
import CoreImage

struct MetalPreviewView: UIViewRepresentable {
    @Binding var image: CIImage?
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.framebufferOnly = false
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = true
        mtkView.delegate = context.coordinator
        
        // Setup CIContext
        if let device = mtkView.device {
            context.coordinator.ciContext = CIContext(mtlDevice: device, options: [.cacheIntermediates: false, .allowLowPower: true])
        }
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.currentImage = image
        uiView.setNeedsDisplay()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var ciContext: CIContext?
        var currentImage: CIImage?
        private let commandQueue: MTLCommandQueue?
        
        override init() {
            if let device = MTLCreateSystemDefaultDevice() {
                self.commandQueue = device.makeCommandQueue()
            } else {
                self.commandQueue = nil
            }
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Not needed for simple preview
        }
        
        func draw(in view: MTKView) {
            guard let image = currentImage,
                  let ciContext = ciContext,
                  let drawable = view.currentDrawable,
                  let commandBuffer = commandQueue?.makeCommandBuffer() else {
                return
            }
            
            // Calculate aspect fill
            let drawableSize = view.drawableSize
            let imageSize = image.extent.size
            
            let scaleX = drawableSize.width / imageSize.width
            let scaleY = drawableSize.height / imageSize.height
            let scale = max(scaleX, scaleY)
            
            let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            
            let tx = (drawableSize.width - scaledImage.extent.width) / 2.0
            let ty = (drawableSize.height - scaledImage.extent.height) / 2.0
            
            let centeredImage = scaledImage.transformed(by: CGAffineTransform(translationX: tx, y: ty))
            
            // Render
            let destination = CIRenderDestination(width: Int(drawableSize.width),
                                                  height: Int(drawableSize.height),
                                                  pixelFormat: view.colorPixelFormat,
                                                  commandBuffer: commandBuffer,
                                                  mtlTextureProvider: { () -> MTLTexture in
                return drawable.texture
            })
            
            do {
                try ciContext.startTask(toRender: centeredImage, to: destination)
            } catch {
                print("MetalPreviewView: Render failed: \(error)")
            }
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
