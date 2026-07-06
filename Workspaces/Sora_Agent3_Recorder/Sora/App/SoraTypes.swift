// DO NOT EDIT: Shared Core Contract for Sora.
// Only the integrator may change this file.

import Foundation
import CoreImage
import CoreMedia
import CoreVideo
import SwiftUI

struct SoraFrame {
    let pixelBuffer: CVPixelBuffer
    let ciImage: CIImage
    let timestamp: CMTime
    let frameIndex: Int64
}

struct SoraFilterSettings: Equatable {
    var smooth: Float = 0.35
    var glow: Float = 0.20
    var contrast: Float = 0.15
    var preset: SoraPreset = .natural
}

enum SoraPreset: String, CaseIterable, Identifiable {
    case natural = "Natural"
    case clean = "Clean"
    case soft = "Soft"
    case cinematic = "Cinematic"

    var id: String { rawValue }
}

enum SoraQualityMode: String, CaseIterable, Identifiable {
    case performance = "Performance"
    case quality = "Quality"

    var id: String { rawValue }
}

enum SoraLensMode: String, CaseIterable, Identifiable {
    case wide = "1x"
    case ultraWide = "0.5x"

    var id: String { rawValue }
}

enum SoraRecordingState: Equatable {
    case idle
    case recording(startedAt: Date)
    case saving
    case saved(URL)
    case failed(String)
}

struct SoraToast: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String?
}
