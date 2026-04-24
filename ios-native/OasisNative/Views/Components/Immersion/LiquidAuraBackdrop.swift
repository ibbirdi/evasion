import SwiftUI

/// Full-screen wrapper around `AnimatedLiquidAura` used as the backdrop of the home surface.
///
/// The accent glows scattered through the app (headers, preset rows, binaural panels) use
/// the same shader at small sizes. This wrapper is the only place where the shader covers
/// the full viewport — it's configured deliberately slow and diffuse so the motion reads as
/// *presence*, not *animation*. The palette comes from the currently audible mix so the room
/// takes its color from what the user is hearing.
struct LiquidAuraBackdrop: View {
    let palette: [Color]

    var body: some View {
        AnimatedLiquidAura(
            palette: normalized(palette),
            shape: Rectangle(),
            intensity: 1.5,
            blurRadius: 22,
            baseBlendOpacity: 0.08,
            speedMultiplier: 0.48,
            frameRate: 30,
            isAnimated: true,
            animationKey: paletteKey,
            coverage: 1.35,
            accentMixAmount: 0.22,
            colorSeparation: 1.35
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// A stable key that only changes when the tint composition actually shifts — prevents
    /// the animation from restarting on every channel-state mutation that doesn't affect
    /// the visible palette.
    private var paletteKey: String {
        palette.map { color in
            let ui = UIColor(color)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            ui.getRed(&r, green: &g, blue: &b, alpha: &a)
            return "\(Int(r * 100)).\(Int(g * 100)).\(Int(b * 100))"
        }.joined(separator: "|")
    }

    /// The shader expects a non-empty palette. Empty/very short palettes fall back to a quiet
    /// neutral blue so the backdrop never disappears or renders pure black.
    private func normalized(_ colors: [Color]) -> [Color] {
        guard !colors.isEmpty else {
            return [Color(red: 0.12, green: 0.16, blue: 0.25)]
        }
        return colors
    }
}
