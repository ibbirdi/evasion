import SwiftUI
import UIKit

enum LiquidActivityPalette {
    static let preset = [
        Color(red: 0.48, green: 0.80, blue: 1.00).opacity(0.82),
        Color(red: 0.96, green: 0.58, blue: 0.92).opacity(0.68),
        Color(red: 1.00, green: 0.79, blue: 0.56).opacity(0.52)
    ]

    static func binaural(for tint: Color) -> [Color] {
        [
            tint.opacity(0.96),
            tint.opacity(0.72),
            tint.opacity(0.42)
        ]
    }

    static func channel(for tint: Color) -> [Color] {
        [
            tint,
            tint.opacity(0.78),
            Color.white.opacity(0.68)
        ]
    }

    static let playback = [
        Color(red: 0.74, green: 0.96, blue: 0.28),
        Color(red: 0.99, green: 0.82, blue: 0.25),
        Color(red: 0.97, green: 0.60, blue: 0.18)
    ]

    static func playback(from colors: [Color]) -> [Color] {
        let source = (colors.isEmpty ? playback : colors).map {
            $0.boostedSaturation(by: 1.55, brightness: 1.10)
        }

        if source.count <= 8 {
            return source
        }

        return (0..<8).map { index in
            let progress = Double(index) / 7.0
            let sourceIndex = Int(round(progress * Double(source.count - 1)))
            return source[sourceIndex]
        }
    }
}

private extension Color {
    func boostedSaturation(by factor: CGFloat, brightness: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var bright: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getHue(&hue, saturation: &saturation, brightness: &bright, alpha: &alpha) else {
            return self
        }

        return Color(
            hue: Double(hue),
            saturation: Double(min(1, saturation * factor)),
            brightness: Double(min(1, bright * brightness)),
            opacity: Double(alpha)
        )
    }
}
