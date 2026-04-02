//
//  Models.swift
//  Tally Matrix Clock
//

import SwiftUI

// StationCategory, BillboardDecade, MusicStationOption, StationSearchType, and SleepTimerOption
// are now provided by CryoKit

enum GlyphRainSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var fontSizeRange: ClosedRange<CGFloat> {
        switch self {
        case .small: return 22...36
        case .medium: return 36...52
        case .large: return 52...72
        }
    }

    var columnSpacing: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 44
        case .large: return 60
        }
    }
}

enum ColorSchemeOption: String, CaseIterable {
    case randomRGB = "Random RGB (Each Square)"
    case matrixColors = "Matrix Colors (Per Matrix)"
    case singleColor = "Single Color (All Matrices)"
    case phosphorGreen = "Phosphor Green (Glow)"
    case phosphorAmber = "Amber Phosphor (Glow)"
    case cgaPhosphor = "CGA Phosphor (Glow)"
    case phosphorBlue = "Blue Phosphor (Glow)"
    case crimson = "Crimson (Sleep)"
}

struct TextTarget: Equatable {
    let text: String
    let frame: CGRect
    let fontSize: CGFloat
    let isMonospaced: Bool

    func characterAt(x: CGFloat) -> Character? {
        guard frame.contains(CGPoint(x: x, y: frame.midY)) else { return nil }
        let charWidth = isMonospaced ? fontSize * 0.6 : frame.width / CGFloat(max(text.count, 1))
        let relativeX = x - frame.minX
        let charIndex = Int(relativeX / charWidth)
        guard charIndex >= 0 && charIndex < text.count else { return nil }
        return text[text.index(text.startIndex, offsetBy: charIndex)]
    }
}

struct TextTargetKey: PreferenceKey {
    static var defaultValue: [TextTarget] = []
    static func reduce(value: inout [TextTarget], nextValue: () -> [TextTarget]) {
        value.append(contentsOf: nextValue())
    }
}
