import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

struct SoraFilterProcessor: SoraImageProcessing {
    func process(frame: SoraFrame, settings: SoraFilterSettings) -> CIImage {
        let presetSettings = resolvedSettings(for: settings)
        let baseImage = frame.ciImage.oriented(.right)

        let exposure = CIFilter.exposureAdjust()
        exposure.inputImage = baseImage
        exposure.ev = exposureValue(for: presetSettings)

        let highlightShadow = CIFilter.highlightShadowAdjust()
        highlightShadow.inputImage = exposure.outputImage
        highlightShadow.highlightAmount = -0.12 - presetSettings.contrast * 0.08
        highlightShadow.shadowAmount = 0.16 + presetSettings.smooth * 0.22

        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = highlightShadow.outputImage
        colorControls.saturation = saturationValue(for: presetSettings)
        colorControls.brightness = 0.01 + presetSettings.glow * 0.04
        colorControls.contrast = 1.0 + presetSettings.contrast * 0.42

        let glowBlur = CIFilter.gaussianBlur()
        glowBlur.inputImage = colorControls.outputImage
        glowBlur.radius = presetSettings.glow * 8.0

        let softGlow = glowBlur.outputImage?
            .cropped(to: baseImage.extent)
            .applyingFilter(
                "CIColorMatrix",
                parameters: [
                    "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
                    "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.16 + presetSettings.glow * 0.16)
                ]
            )

        let composited = softGlow?.applyingFilter(
            "CISourceOverCompositing",
            parameters: [kCIInputBackgroundImageKey: colorControls.outputImage as Any]
        ) ?? colorControls.outputImage ?? baseImage

        let finalImage = composited.applyingFilter(
            "CISharpenLuminance",
            parameters: ["inputSharpness": max(0.05, 0.22 - presetSettings.smooth * 0.18)]
        )

        return finalImage
    }

    private func resolvedSettings(for settings: SoraFilterSettings) -> SoraFilterSettings {
        var merged = SoraFilterSettings.preset(settings.preset)
        merged.smooth = settings.smooth
        merged.glow = settings.glow
        merged.contrast = settings.contrast
        return merged
    }

    private func exposureValue(for settings: SoraFilterSettings) -> Float {
        switch settings.preset {
        case .natural:
            return 0.02
        case .clean:
            return 0.06
        case .soft:
            return 0.04
        case .cinematic:
            return -0.08
        }
    }

    private func saturationValue(for settings: SoraFilterSettings) -> Float {
        switch settings.preset {
        case .natural:
            return 1.03
        case .clean:
            return 1.01
        case .soft:
            return 0.97
        case .cinematic:
            return 0.92
        }
    }
}
