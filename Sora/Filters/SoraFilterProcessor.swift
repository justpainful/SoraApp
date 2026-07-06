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
        
        // 1. Create a blurred version of the image.
        // We scale the blur radius from 0 to 12 based on intensity.
        let blurRadius = CGFloat(intensity * 12.0)
        let clampedImage = image.clampedToExtent()
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return image }
        blurFilter.setValue(clampedImage, forKey: kCIInputImageKey)
        blurFilter.setValue(blurRadius, forKey: kCIInputRadiusKey)
        guard let blurredImage = blurFilter.outputImage?.cropped(to: image.extent) else { return image }
        
        // 2. Generate an edge mask from the original image.
        // 2a. Convert the image to grayscale.
        guard let grayFilter = CIFilter(name: "CIColorControls") else { return image }
        grayFilter.setValue(image, forKey: kCIInputImageKey)
        grayFilter.setValue(0.0, forKey: kCIInputSaturationKey)
        guard let grayImage = grayFilter.outputImage else { return image }
        
        // 2b. Extract edges from the grayscale image.
        guard let edgeFilter = CIFilter(name: "CIEdges") else { return image }
        edgeFilter.setValue(grayImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(2.0, forKey: kCIInputIntensityKey)
        guard let edgeImage = edgeFilter.outputImage else { return image }
        
        // 2c. Invert the edge map (flat areas = 1.0, edges = 0.0).
        guard let invertFilter = CIFilter(name: "CIColorInvert") else { return image }
        invertFilter.setValue(edgeImage, forKey: kCIInputImageKey)
        guard let invertedEdges = invertFilter.outputImage else { return image }
        
        // 2d. Blur the inverted edge map to prevent harsh edges.
        guard let maskBlurFilter = CIFilter(name: "CIGaussianBlur") else { return image }
        maskBlurFilter.setValue(invertedEdges.clampedToExtent(), forKey: kCIInputImageKey)
        maskBlurFilter.setValue(3.0, forKey: kCIInputRadiusKey)
        guard let maskImage = maskBlurFilter.outputImage?.cropped(to: image.extent) else { return image }
        
        // 3. Composite original and blurred images using the mask.
        // inputImage (white/1.0 source) -> blurredImage (smoothed skin)
        // inputBackgroundImage (black/0.0 source) -> original image (sharp eyes, hair, clothes)
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return image }
        blendFilter.setValue(blurredImage, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        
        return blendFilter.outputImage ?? image
    }
    
    /// Applies a beautiful, soft glow (bloom) effect by screen-blending a blurred layer with scaled alpha.
    private func applyGlow(image: CIImage, intensity: Float) -> CIImage {
        guard intensity > 0 else { return image }
        
        // 1. Create a wide blur of the image.
        // We scale the blur radius from 0 to 28 based on intensity.
        let glowRadius = CGFloat(intensity * 28.0)
        let clampedImage = image.clampedToExtent()
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return image }
        blurFilter.setValue(clampedImage, forKey: kCIInputImageKey)
        blurFilter.setValue(glowRadius, forKey: kCIInputRadiusKey)
        guard let blurredImage = blurFilter.outputImage?.cropped(to: image.extent) else { return image }
        
        // 2. Adjust the opacity (alpha channel) of the blurred layer.
        guard let matrixFilter = CIFilter(name: "CIColorMatrix") else { return image }
        matrixFilter.setValue(blurredImage, forKey: kCIInputImageKey)
        matrixFilter.setValue(CIVector(x: 1.0, y: 0.0, z: 0.0, w: 0.0), forKey: "inputRVector")
        matrixFilter.setValue(CIVector(x: 0.0, y: 1.0, z: 0.0, w: 0.0), forKey: "inputGVector")
        matrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 1.0, w: 0.0), forKey: "inputBVector")
        // We scale the alpha so the glow effect is dreamily subtle (max 35% opacity)
        matrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: CGFloat(intensity * 0.35)), forKey: "inputAVector")
        matrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0), forKey: "inputBiasVector")
        guard let glowLayer = matrixFilter.outputImage else { return image }
        
        // 3. Screen blend the glow layer over the original image.
        guard let screenFilter = CIFilter(name: "CIScreenBlendMode") else { return image }
        screenFilter.setValue(glowLayer, forKey: kCIInputImageKey)
        screenFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        return screenFilter.outputImage ?? image
    }
    
    /// Adjusts contrast relative to the baseline of 0.15.
    private func applyContrast(image: CIImage, intensity: Float) -> CIImage {
        guard let contrastFilter = CIFilter(name: "CIColorControls") else { return image }
        contrastFilter.setValue(image, forKey: kCIInputImageKey)
        
        // Baseline setting is 0.15 which maps to neutral contrast (1.0).
        // Slider value ranges from 0.0 to 1.0.
        // We map this to contrast values between 0.7 (low contrast) and 1.5 (high contrast).
        let contrastValue = 1.0 + (intensity - 0.15) * 0.6
        contrastFilter.setValue(contrastValue, forKey: kCIInputContrastKey)
        
        return contrastFilter.outputImage ?? image
    }
    
    /// Applies color grading profiles corresponding to each preset look.
    private func applyPresetGrading(image: CIImage, preset: SoraPreset) -> CIImage {
        var processed = image
        
        switch preset {
        case .natural:
            // Natural preset leaves color values as-is (true to life camera input).
            break
            
        case .clean:
            // Clean look: brighten slightly and overlay a subtle cool blue tint.
            guard let controlsFilter = CIFilter(name: "CIColorControls") else { break }
            controlsFilter.setValue(processed, forKey: kCIInputImageKey)
            controlsFilter.setValue(0.04, forKey: kCIInputBrightnessKey)
            if let output = controlsFilter.outputImage {
                processed = output
            }
            
            // Soft cool tint (#E6F2FF -> RGB: 0.90, 0.95, 1.00) at 10% opacity
            let coolColor = CIColor(red: 0.90, green: 0.95, blue: 1.00)
            processed = applyColorOverlay(image: processed, color: coolColor, opacity: 0.10)
            
        case .soft:
            // Soft look: lower contrast slightly, increase brightness, and overlay a warm rose/lavender tint.
            guard let controlsFilter = CIFilter(name: "CIColorControls") else { break }
            controlsFilter.setValue(processed, forKey: kCIInputImageKey)
            controlsFilter.setValue(0.03, forKey: kCIInputBrightnessKey)
            controlsFilter.setValue(0.95, forKey: kCIInputContrastKey)
            if let output = controlsFilter.outputImage {
                processed = output
            }
            
            // Warm rose tint (#FFF0F5 -> RGB: 1.00, 0.94, 0.96) at 14% opacity
            let roseColor = CIColor(red: 1.00, green: 0.94, blue: 0.96)
            processed = applyColorOverlay(image: processed, color: roseColor, opacity: 0.14)
            
        case .cinematic:
            // Cinematic look: lower saturation, boost contrast, and overlay a warm gold highlight grade.
            guard let controlsFilter = CIFilter(name: "CIColorControls") else { break }
            controlsFilter.setValue(processed, forKey: kCIInputImageKey)
            controlsFilter.setValue(0.90, forKey: kCIInputSaturationKey)
            controlsFilter.setValue(1.08, forKey: kCIInputContrastKey)
            if let output = controlsFilter.outputImage {
                processed = output
            }
            
            // Warm filmic gold tint (#FFB870 -> RGB: 1.00, 0.72, 0.44) at 12% opacity
            let goldColor = CIColor(red: 1.00, green: 0.72, blue: 0.44)
            processed = applyColorOverlay(image: processed, color: goldColor, opacity: 0.12)
        }
        
        return processed
    }
    
    /// Utility function that overlays a solid color over the source image using Soft Light blending.
    private func applyColorOverlay(image: CIImage, color: CIColor, opacity: Float) -> CIImage {
        // 1. Generate a solid color image.
        guard let colorFilter = CIFilter(name: "CIConstantColorGenerator") else { return image }
        colorFilter.setValue(color, forKey: kCIInputColorKey)
        guard let colorImage = colorFilter.outputImage?.cropped(to: image.extent) else { return image }
        
        // 2. Scale the opacity of the color layer using CIColorMatrix.
        guard let matrixFilter = CIFilter(name: "CIColorMatrix") else { return image }
        matrixFilter.setValue(colorImage, forKey: kCIInputImageKey)
        matrixFilter.setValue(CIVector(x: 1.0, y: 0.0, z: 0.0, w: 0.0), forKey: "inputRVector")
        matrixFilter.setValue(CIVector(x: 0.0, y: 1.0, z: 0.0, w: 0.0), forKey: "inputGVector")
        matrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 1.0, w: 0.0), forKey: "inputBVector")
        matrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: CGFloat(opacity)), forKey: "inputAVector")
        matrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0), forKey: "inputBiasVector")
        guard let overlayWithOpacity = matrixFilter.outputImage else { return image }
        
        // 3. Blend the overlay with the original image using CISoftLightBlendMode.
        guard let blendFilter = CIFilter(name: "CISoftLightBlendMode") else { return image }
        blendFilter.setValue(overlayWithOpacity, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        return blendFilter.outputImage ?? image
    }
}
