import Foundation

struct SoraIconReplacement: Identifiable, Hashable {
    let id: String
    let currentLabel: String
    let replacementSymbol: String
    let usageNote: String
}

enum SoraIconMap {
    static let replacements: [SoraIconReplacement] = [
        .init(
            id: "settings",
            currentLabel: "Settings",
            replacementSymbol: "gearshape",
            usageNote: "Top bar trailing action"
        ),
        .init(
            id: "look-studio",
            currentLabel: "LOOK STUDIO",
            replacementSymbol: "sparkles",
            usageNote: "Filter sheet entry point and sheet identity"
        ),
        .init(
            id: "gallery",
            currentLabel: "Recent recordings",
            replacementSymbol: "photo.on.rectangle.angled",
            usageNote: "Bottom dock gallery access"
        ),
        .init(
            id: "compare-original",
            currentLabel: "SHOW ORIGINAL",
            replacementSymbol: "eye",
            usageNote: "Compare toggle active state"
        ),
        .init(
            id: "compare-filtered",
            currentLabel: "SHOW FILTERED",
            replacementSymbol: "eye.slash",
            usageNote: "Compare toggle return state"
        ),
        .init(
            id: "save-success",
            currentLabel: "Saved",
            replacementSymbol: "checkmark",
            usageNote: "Compact save confirmation"
        ),
        .init(
            id: "save-failure",
            currentLabel: "Couldn't Save",
            replacementSymbol: "exclamationmark.triangle",
            usageNote: "Compact save failure toast"
        ),
        .init(
            id: "dismiss",
            currentLabel: "Done / Close",
            replacementSymbol: "xmark",
            usageNote: "Dismiss affordances"
        )
    ]
}
