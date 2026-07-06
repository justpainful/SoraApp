import Foundation

extension SoraFilterSettings {
    static func preset(_ preset: SoraPreset) -> SoraFilterSettings {
        switch preset {
        case .natural:
            return SoraFilterSettings(smooth: 0.35, glow: 0.20, contrast: 0.15, preset: .natural)
        case .clean:
            return SoraFilterSettings(smooth: 0.22, glow: 0.10, contrast: 0.18, preset: .clean)
        case .soft:
            return SoraFilterSettings(smooth: 0.48, glow: 0.32, contrast: 0.05, preset: .soft)
        case .cinematic:
            return SoraFilterSettings(smooth: 0.18, glow: 0.14, contrast: 0.28, preset: .cinematic)
        }
    }
}
