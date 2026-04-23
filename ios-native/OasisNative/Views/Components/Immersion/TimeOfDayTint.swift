import SwiftUI

/// Subtle gradient overlay that tints the immersion backdrop with a color temperature pulled
/// from the current time of day. Kept deliberately quiet — it shapes the feeling of the
/// room without competing with the channel palette below.
///
/// The tint sits on top of `LiquidAuraBackdrop` and below the darkening vignette. Opacity
/// is low enough that the tint reads as ambient light rather than a color wash.
struct TimeOfDayTint: View {
    let timeOfDay: TimeOfDay

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
        .blendMode(.plusLighter)
        .opacity(overlayOpacity)
        .allowsHitTesting(false)
        .animation(.smooth(duration: 1.2), value: timeOfDay)
    }

    /// Two stops per time of day. The top stop sets the sky character, the bottom stop the
    /// ground/atmosphere. Kept within a warm-cool range calibrated against the app's dark
    /// theme so the result never over-saturates.
    private var gradientColors: [Color] {
        switch timeOfDay {
        case .dawn:
            // Pre-sunrise: cool violet above warming into rose.
            return [
                Color(red: 0.26, green: 0.22, blue: 0.44),
                Color(red: 0.74, green: 0.42, blue: 0.48)
            ]
        case .morning:
            // Clear early sky: faint cyan over pale gold.
            return [
                Color(red: 0.42, green: 0.60, blue: 0.76),
                Color(red: 0.82, green: 0.76, blue: 0.62)
            ]
        case .noon:
            // Bright daylight, quiet: pale teal over cream.
            return [
                Color(red: 0.54, green: 0.70, blue: 0.76),
                Color(red: 0.86, green: 0.84, blue: 0.78)
            ]
        case .afternoon:
            // Light leaning gold: warmed teal above soft amber.
            return [
                Color(red: 0.56, green: 0.64, blue: 0.70),
                Color(red: 0.86, green: 0.70, blue: 0.56)
            ]
        case .dusk:
            // Magic hour: deep orange fading into magenta.
            return [
                Color(red: 0.86, green: 0.50, blue: 0.34),
                Color(red: 0.52, green: 0.28, blue: 0.44)
            ]
        case .evening:
            // Settling light: dusty indigo over burgundy.
            return [
                Color(red: 0.32, green: 0.28, blue: 0.48),
                Color(red: 0.44, green: 0.22, blue: 0.30)
            ]
        case .night:
            // Deep night: navy over quiet violet.
            return [
                Color(red: 0.10, green: 0.14, blue: 0.28),
                Color(red: 0.22, green: 0.16, blue: 0.34)
            ]
        }
    }

    private var overlayOpacity: Double {
        switch timeOfDay {
        case .noon, .afternoon: return 0.12
        case .morning: return 0.14
        case .dawn, .dusk: return 0.22
        case .evening, .night: return 0.18
        }
    }
}
