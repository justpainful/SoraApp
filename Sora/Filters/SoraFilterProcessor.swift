//
//  SoraFilterProcessor.swift
//  Sora
//
//  Created for Sora MVP.
//

import Foundation
import CoreImage

final class SoraFilterProcessor: SoraImageProcessing {
    /// Processes a single camera frame with the provided filter settings and returns the filtered output image.
    /// - Parameters:
    ///   - frame: The input camera frame containing the pixel buffer and CIImage.
    ///   - settings: The user-defined filter settings containing slider values and the active preset.
    /// - Returns: A processed, hardware-accelerated CIImage.
    func process(frame: SoraFrame, settings: SoraFilterSettings) -> CIImage {
        var image = frame.ciImage
        
        // 1. Apply Preset Look Color Grading
        image = applyPresetGrading(image: image, preset: settings.preset)
        
        // 2. Apply skin/detail smoothing (bilateral-like filter)
        if settings.smooth > 0 {
            image = applySkinSmoothing(image: image, intensity: settings.smooth)
        }
        
        // 3. Apply Glow / Bloom effect
        if settings.glow > 0 {
            image = applyGlow(image: image, intensity: settings.glow)
        }
        
        // 4. Apply Contrast adjustments
        image = applyContrast(image: image, intensity: settings.contrast)
        
        return image
    }
    
    // MARK: - Filter Operations
    
    /// Applies skin/detail smoothing using an edge-preserving filter graph.
    /// High-contrast edges (eyes, hair, borders) are masked out so that only flat areas (skin) are blurred.
    private func applySkinSmoothing(image: CIImage, intensity: Float) -> CIImage {
        guard intensity > 0 else { return image }

        let refinementMask = makeRefinementMask(image: image, intensity: intensity)
        let blurRadius = CGFloat(1.8 + intensity * 5.4)
        let lowFrequencyImage = gaussianBlur(image: image, radius: blurRadius)
        let toneEvenedImage = blend(source: lowFrequencyImage, background: image, mask: refinementMask)

        let detailRecovery = sharpen(
            image: toneEvenedImage,
            radius: 0.45 + Double(intensity) * 0.9,
            intensity: 0.18 + Double(intensity) * 0.24
        )

        let softenedRefinementMask = scaledMask(refinementMask, contrast: 1.2, brightness: -0.08)
        return blend(source: detailRecovery, background: image, mask: softenedRefinementMask)
    }

    /// Applies a beautiful, soft glow (bloom) effect by screen-blending a blurred layer with scaled alpha.
    private func applyGlow(image: CIImage, intensity: Float) -> CIImage {
        guard intensity > 0 else { return image }

        let glowRadius = CGFloat(4.0 + intensity * 18.0)
        let blurredImage = gaussianBlur(image: image, radius: glowRadius)
        let glowLayer = applyAlpha(to: blurredImage, alpha: CGFloat(0.08 + intensity * 0.22))
        let glowMask = makeHighlightMask(image: image, intensity: intensity)

        guard let screenFilter = CIFilter(name: "CIScreenBlendMode") else { return image }
        screenFilter.setValue(glowLayer, forKey: kCIInputImageKey)
        screenFilter.setValue(image, forKey: kCIInputBackgroundImageKey)

        guard let screenedImage = screenFilter.outputImage else { return image }
        return blend(source: screenedImage, background: image, mask: glowMask)
    }

    /// Adjusts contrast relative to the baseline of 0.15.
    private func applyContrast(image: CIImage, intensity: Float) -> CIImage {
        guard let contrastFilter = CIFilter(name: "CIColorControls") else { return image }
        contrastFilter.setValue(image, forKey: kCIInputImageKey)

        // Keep tonal separation controlled after refinement so midtones stay open.
        let contrastValue = 0.92 + intensity * 0.48
        contrastFilter.setValue(contrastValue, forKey: kCIInputContrastKey)

        return contrastFilter.outputImage ?? image
    }

    /// Applies color grading profiles corresponding to each preset look.
    private func applyPresetGrading(image: CIImage, preset: SoraPreset) -> CIImage {
        var processed = image

        switch preset {
        case .natural:
            // Minimal grading. Stay close to camera output.
            break

        case .clean:
            guard let controlsFilter = CIFilter(name: "CIColorControls") else { break }
            controlsFilter.setValue(processed, forKey: kCIInputImageKey)
            controlsFilter.setValue(0.015, forKey: kCIInputBrightnessKey)
            controlsFilter.setValue(1.02, forKey: kCIInputContrastKey)
            if let output = controlsFilter.outputImage {
                processed = output
            }

            let cleanColor = CIColor(red: 0.95, green: 0.97, blue: 1.0)
            processed = applyColorOverlay(image: processed, color: cleanColor, opacity: 0.07)

        case .soft:
            guard let controlsFilter = CIFilter(name: "CIColorControls") else { break }
            controlsFilter.setValue(processed, forKey: kCIInputImageKey)
            controlsFilter.setValue(0.03, forKey: kCIInputBrightnessKey)
            controlsFilter.setValue(0.96, forKey: kCIInputContrastKey)
            if let output = controlsFilter.outputImage {
                processed = output
            }

            let softColor = CIColor(red: 1.0, green: 0.95, blue: 0.97)
            processed = applyColorOverlay(image: processed, color: softColor, opacity: 0.12)

        case .cinematic:
            guard let controlsFilter = CIFilter(name: "CIColorControls") else { break }
            controlsFilter.setValue(processed, forKey: kCIInputImageKey)
            controlsFilter.setValue(0.96, forKey: kCIInputSaturationKey)
            controlsFilter.setValue(1.06, forKey: kCIInputContrastKey)
            controlsFilter.setValue(0.01, forKey: kCIInputBrightnessKey)
            if let output = controlsFilter.outputImage {
                processed = output
            }

            let studioColor = CIColor(red: 1.0, green: 0.86, blue: 0.70)
            processed = applyColorOverlay(image: processed, color: studioColor, opacity: 0.10)
        }

        return processed
    }

    /// Utility function that overlays a solid color over the source image using Soft Light blending.
    private func applyColorOverlay(image: CIImage, color: CIColor, opacity: Float) -> CIImage {
        guard let colorFilter = CIFilter(name: "CIConstantColorGenerator") else { return image }
        colorFilter.setValue(color, forKey: kCIInputColorKey)
        guard let colorImage = colorFilter.outputImage?.cropped(to: image.extent) else { return image }

        let overlayWithOpacity = applyAlpha(to: colorImage, alpha: CGFloat(opacity))
        guard let blendFilter = CIFilter(name: "CISoftLightBlendMode") else { return image }
        blendFilter.setValue(overlayWithOpacity, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)

        return blendFilter.outputImage ?? image
    }

    private func makeRefinementMask(image: CIImage, intensity: Float) -> CIImage {
        let grayscale = desaturate(image)
        let edgeImage = edges(grayscale, intensity: 1.6 + Double(intensity) * 1.2)
        let invertedEdges = invert(edgeImage)
        let blurredMask = gaussianBlur(image: invertedEdges, radius: 2.6 + CGFloat(intensity * 1.6))
        return scaledMask(blurredMask, contrast: 1.35 + Double(intensity) * 0.35, brightness: -0.10)
    }

    private func makeHighlightMask(image: CIImage, intensity: Float) -> CIImage {
        let grayscale = desaturate(image)
        let softened = gaussianBlur(image: grayscale, radius: 1.6)
        let shaped = scaledMask(
            softened,
            contrast: 2.2 + Double(intensity) * 1.1,
            brightness: -0.42 + Double(intensity) * 0.10
        )
        return gaussianBlur(image: shaped, radius: 2.2 + CGFloat(intensity * 2.0))
    }

    private func desaturate(_ image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)
        return filter.outputImage ?? image
    }

    private func edges(_ image: CIImage, intensity: Double) -> CIImage {
        guard let filter = CIFilter(name: "CIEdges") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(intensity, forKey: kCIInputIntensityKey)
        return filter.outputImage ?? image
    }

    private func invert(_ image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorInvert") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }

    private func gaussianBlur(image: CIImage, radius: CGFloat) -> CIImage {
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return image }
        filter.setValue(image.clampedToExtent(), forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        return filter.outputImage?.cropped(to: image.extent) ?? image
    }

    private func sharpen(image: CIImage, radius: Double, intensity: Double) -> CIImage {
        guard let filter = CIFilter(name: "CIUnsharpMask") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        filter.setValue(intensity, forKey: kCIInputIntensityKey)
        return filter.outputImage ?? image
    }

    private func scaledMask(_ image: CIImage, contrast: Double, brightness: Double) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        return filter.outputImage ?? image
    }

    private func applyAlpha(to image: CIImage, alpha: CGFloat) -> CIImage {
        guard let matrixFilter = CIFilter(name: "CIColorMatrix") else { return image }
        matrixFilter.setValue(image, forKey: kCIInputImageKey)
        matrixFilter.setValue(CIVector(x: 1.0, y: 0.0, z: 0.0, w: 0.0), forKey: "inputRVector")
        matrixFilter.setValue(CIVector(x: 0.0, y: 1.0, z: 0.0, w: 0.0), forKey: "inputGVector")
        matrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 1.0, w: 0.0), forKey: "inputBVector")
        matrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: alpha), forKey: "inputAVector")
        matrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0), forKey: "inputBiasVector")
        return matrixFilter.outputImage ?? image
    }

    private func blend(source: CIImage, background: CIImage, mask: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIBlendWithMask") else { return background }
        filter.setValue(source, forKey: kCIInputImageKey)
        filter.setValue(background, forKey: kCIInputBackgroundImageKey)
        filter.setValue(mask, forKey: kCIInputMaskImageKey)
        return filter.outputImage ?? background
    }
}
