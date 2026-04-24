import SwiftUI
import UIKit

/// GPU-rendered particle overlay backed by `CAEmitterLayer`. Replaces the SwiftUI Canvas
/// implementation that ran on the main thread and competed with `ScrollView` for frame
/// time (producing scroll jank). Core Animation's render server drives the emitter on its
/// own pipeline so main-thread work stays flat.
///
/// Each `ParticleStyle` maps to a curated `EmitterConfig` — cell properties tuned for that
/// atmosphere, a procedurally drawn texture (no asset files needed), and a render mode
/// chosen so luminous styles blend additively.
struct ParticleEmitterView: UIViewRepresentable {
    let style: ParticleStyle
    let tint: Color

    func makeUIView(context: Context) -> EmitterHostView {
        let view = EmitterHostView()
        view.backgroundColor = .clear
        view.configure(style: style, tintUIColor: resolvedTintColor)
        return view
    }

    func updateUIView(_ uiView: EmitterHostView, context: Context) {
        uiView.configure(style: style, tintUIColor: resolvedTintColor)
    }

    private var resolvedTintColor: UIColor {
        UIColor(tint)
    }
}

// MARK: - Host view

/// UIView whose backing layer is a CAEmitterLayer. Holds the current style so we can
/// tell if reconfiguration is actually needed and skip allocating new cells on every
/// SwiftUI update pass.
final class EmitterHostView: UIView {
    override class var layerClass: AnyClass {
        CAEmitterLayer.self
    }

    private var emitterLayer: CAEmitterLayer {
        layer as! CAEmitterLayer
    }

    private var currentStyle: ParticleStyle = .none
    private var currentTintHex: UInt32 = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyEmitterGeometry(for: currentStyle)
    }

    /// Configures the emitter for the given style. Idempotent — returns immediately if
    /// neither the style nor the tint has changed, avoiding the work of rebuilding cells
    /// on unrelated SwiftUI view updates.
    func configure(style: ParticleStyle, tintUIColor: UIColor) {
        let tintHex = tintUIColor.rgbaHex
        if style == currentStyle, tintHex == currentTintHex {
            return
        }
        currentStyle = style
        currentTintHex = tintHex

        guard style != .none else {
            emitterLayer.emitterCells = nil
            emitterLayer.birthRate = 0
            return
        }

        let config = EmitterConfig.config(for: style, tint: tintUIColor)
        emitterLayer.renderMode = config.renderMode
        emitterLayer.emitterCells = config.cells
        emitterLayer.birthRate = 1
        applyEmitterGeometry(for: style)
    }

    /// Positions and shapes the emitter based on the current style. Rain falls from a line
    /// across the top; embers rise from a line at the bottom; mist drifts from a vertical
    /// line at the left; motes from a vertical line at the right; fireflies from a central
    /// rectangle covering most of the screen.
    private func applyEmitterGeometry(for style: ParticleStyle) {
        let size = bounds.size
        guard size.width > 0, size.height > 0 else { return }

        switch style {
        case .rain:
            emitterLayer.emitterPosition = CGPoint(x: size.width / 2, y: -8)
            emitterLayer.emitterSize = CGSize(width: size.width * 1.1, height: 1)
            emitterLayer.emitterShape = .line
        case .embers:
            emitterLayer.emitterPosition = CGPoint(x: size.width / 2, y: size.height - 10)
            emitterLayer.emitterSize = CGSize(width: size.width * 0.9, height: 1)
            emitterLayer.emitterShape = .line
        case .fireflies:
            emitterLayer.emitterPosition = CGPoint(x: size.width / 2, y: size.height / 2)
            emitterLayer.emitterSize = CGSize(width: size.width * 0.8, height: size.height * 0.7)
            emitterLayer.emitterShape = .rectangle
        case .motes:
            emitterLayer.emitterPosition = CGPoint(x: size.width + 12, y: size.height / 2)
            emitterLayer.emitterSize = CGSize(width: 1, height: size.height)
            emitterLayer.emitterShape = .line
        case .mist:
            emitterLayer.emitterPosition = CGPoint(x: -80, y: size.height * 0.65)
            emitterLayer.emitterSize = CGSize(width: 1, height: size.height * 0.55)
            emitterLayer.emitterShape = .line
        case .none:
            break
        }
    }
}

// MARK: - Per-style emitter configuration

@MainActor
private struct EmitterConfig {
    let cells: [CAEmitterCell]
    let renderMode: CAEmitterLayerRenderMode

    static func config(for style: ParticleStyle, tint: UIColor) -> EmitterConfig {
        switch style {
        case .rain: return rainConfig()
        case .embers: return embersConfig()
        case .fireflies: return firefliesConfig()
        case .motes: return motesConfig(tint: tint)
        case .mist: return mistConfig()
        case .none: return EmitterConfig(cells: [], renderMode: .unordered)
        }
    }

    /// Two overlapping cell populations (close + distant) build parallax depth so the rain
    /// reads as volumetric rather than a flat plane of streaks.
    private static func rainConfig() -> EmitterConfig {
        let texture = ParticleTextureFactory.rainStreak()

        let near = CAEmitterCell()
        near.contents = texture
        near.birthRate = 140
        near.lifetime = 1.4
        near.lifetimeRange = 0.4
        near.velocity = 620
        near.velocityRange = 120
        near.yAcceleration = 340
        near.emissionLongitude = .pi / 2
        near.emissionRange = 0.08
        near.scale = 0.55
        near.scaleRange = 0.18
        near.alphaSpeed = -0.35
        near.alphaRange = 0.15
        near.color = UIColor(white: 1, alpha: 0.62).cgColor

        let far = CAEmitterCell()
        far.contents = texture
        far.birthRate = 80
        far.lifetime = 1.9
        far.lifetimeRange = 0.5
        far.velocity = 380
        far.velocityRange = 80
        far.yAcceleration = 260
        far.emissionLongitude = .pi / 2
        far.emissionRange = 0.1
        far.scale = 0.32
        far.scaleRange = 0.1
        far.alphaSpeed = -0.25
        far.alphaRange = 0.12
        far.color = UIColor(white: 1, alpha: 0.42).cgColor

        return EmitterConfig(cells: [far, near], renderMode: .unordered)
    }

    /// Warm glowing specks that rise from the bottom. Additive blending turns overlaps into
    /// highlights the way real embers read against a dark scene.
    private static func embersConfig() -> EmitterConfig {
        let texture = ParticleTextureFactory.softGlow(diameter: 42)

        let cell = CAEmitterCell()
        cell.contents = texture
        cell.birthRate = 22
        cell.lifetime = 4.2
        cell.lifetimeRange = 1.2
        cell.velocity = 110
        cell.velocityRange = 40
        cell.yAcceleration = -40
        cell.emissionLongitude = -.pi / 2
        cell.emissionRange = .pi / 5
        cell.scale = 0.42
        cell.scaleRange = 0.18
        cell.scaleSpeed = -0.04
        cell.alphaSpeed = -0.22
        cell.alphaRange = 0.2
        cell.spin = 0.4
        cell.spinRange = 2.8
        cell.color = UIColor(red: 1.0, green: 0.55, blue: 0.18, alpha: 0.95).cgColor
        // Slight hue variance per particle so the ember field looks like a natural fire
        // rather than a bank of identical dots.
        cell.redRange = 0.12
        cell.greenRange = 0.22
        cell.blueRange = 0.04

        return EmitterConfig(cells: [cell], renderMode: .additive)
    }

    /// Fireflies wander slowly at all depths; two populations at different scale + alpha
    /// give a sense of depth without needing a full 3D emitter.
    private static func firefliesConfig() -> EmitterConfig {
        let texture = ParticleTextureFactory.softGlow(diameter: 44)

        let close = CAEmitterCell()
        close.contents = texture
        close.birthRate = 6
        close.lifetime = 6.5
        close.lifetimeRange = 1.8
        close.velocity = 26
        close.velocityRange = 14
        close.emissionRange = .pi * 2
        close.scale = 0.36
        close.scaleRange = 0.12
        close.scaleSpeed = 0.02
        close.alphaSpeed = -0.18
        close.alphaRange = 0.3
        close.color = UIColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 0.95).cgColor
        close.redRange = 0.05
        close.greenRange = 0.12

        let far = CAEmitterCell()
        far.contents = texture
        far.birthRate = 10
        far.lifetime = 8.0
        far.lifetimeRange = 2.0
        far.velocity = 14
        far.velocityRange = 8
        far.emissionRange = .pi * 2
        far.scale = 0.18
        far.scaleRange = 0.08
        far.alphaSpeed = -0.12
        far.alphaRange = 0.2
        far.color = UIColor(red: 1.0, green: 0.95, blue: 0.62, alpha: 0.55).cgColor

        return EmitterConfig(cells: [far, close], renderMode: .additive)
    }

    /// Very slow horizontal drift, tinted by the dominant channel. Two density bands with
    /// different scales and opacities so the air feels layered.
    private static func motesConfig(tint: UIColor) -> EmitterConfig {
        let texture = ParticleTextureFactory.softGlow(diameter: 38)

        let near = CAEmitterCell()
        near.contents = texture
        near.birthRate = 14
        near.lifetime = 16.0
        near.lifetimeRange = 4.0
        near.velocity = 24
        near.velocityRange = 10
        near.emissionLongitude = .pi // leftward
        near.emissionRange = 0.6
        near.scale = 0.26
        near.scaleRange = 0.12
        near.alphaSpeed = -0.05
        near.alphaRange = 0.2
        near.color = tint.withAlphaComponent(0.85).cgColor

        let far = CAEmitterCell()
        far.contents = texture
        far.birthRate = 22
        far.lifetime = 22.0
        far.lifetimeRange = 6.0
        far.velocity = 12
        far.velocityRange = 6
        far.emissionLongitude = .pi
        far.emissionRange = 0.5
        far.scale = 0.14
        far.scaleRange = 0.06
        far.alphaSpeed = -0.03
        far.alphaRange = 0.15
        far.color = tint.withAlphaComponent(0.45).cgColor

        return EmitterConfig(cells: [far, near], renderMode: .unordered)
    }

    /// Large diffuse wisps drifting right. Uses a very soft, very wide texture so each
    /// particle reads as volumetric fog rather than a shape.
    private static func mistConfig() -> EmitterConfig {
        let texture = ParticleTextureFactory.softGlow(diameter: 96)

        let cell = CAEmitterCell()
        cell.contents = texture
        cell.birthRate = 5
        cell.lifetime = 28.0
        cell.lifetimeRange = 6.0
        cell.velocity = 30
        cell.velocityRange = 10
        cell.emissionLongitude = 0 // rightward
        cell.emissionRange = 0.3
        cell.scale = 1.1
        cell.scaleRange = 0.5
        cell.scaleSpeed = 0.03
        cell.alphaSpeed = -0.025
        cell.alphaRange = 0.15
        cell.color = UIColor(white: 1, alpha: 0.22).cgColor

        return EmitterConfig(cells: [cell], renderMode: .unordered)
    }
}

// MARK: - Procedural texture factory

/// Generates the small CGImages used as particle content. Textures are cached by key so
/// repeated style changes don't reallocate. Generation uses CoreGraphics radial fills with
/// alpha falloff — no asset catalog entries needed. All calls are funnelled through the
/// main actor since `configure` is already main-actor-bound via UIView — no locking needed.
@MainActor
private enum ParticleTextureFactory {
    private static var cache: [String: CGImage] = [:]

    static func softGlow(diameter: CGFloat) -> CGImage? {
        let key = "softGlow-\(Int(diameter))"
        if let cached = cache[key] { return cached }

        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let center = CGPoint(x: diameter / 2, y: diameter / 2)
            let colors = [
                UIColor(white: 1, alpha: 1).cgColor,
                UIColor(white: 1, alpha: 0.35).cgColor,
                UIColor(white: 1, alpha: 0).cgColor
            ]
            let locations: [CGFloat] = [0, 0.5, 1]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: locations
            ) else { return }
            cg.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: diameter / 2,
                options: []
            )
        }
        let cg = image.cgImage
        if let cg {
            cache[key] = cg
        }
        return cg
    }

    static func rainStreak() -> CGImage? {
        let key = "rainStreak"
        if let cached = cache[key] { return cached }

        // Thin vertical streak with alpha falloff at both ends — reads as a fast-falling
        // drop with motion blur when scaled and rotated slightly.
        let size = CGSize(width: 4, height: 36)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let colors = [
                UIColor(white: 1, alpha: 0).cgColor,
                UIColor(white: 1, alpha: 0.88).cgColor,
                UIColor(white: 1, alpha: 0).cgColor
            ]
            let locations: [CGFloat] = [0, 0.6, 1]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: locations
            ) else { return }
            cg.drawLinearGradient(
                gradient,
                start: CGPoint(x: size.width / 2, y: 0),
                end: CGPoint(x: size.width / 2, y: size.height),
                options: []
            )
        }
        let cg = image.cgImage
        if let cg {
            cache[key] = cg
        }
        return cg
    }
}

// MARK: - Small helpers

private extension UIColor {
    /// 32-bit RGBA signature used to detect whether the tint changed enough to warrant a
    /// reconfiguration. Avoids comparing two UIColor instances, which doesn't have a sane
    /// equality in all cases (different color spaces can compare unequal for identical
    /// display colors).
    var rgbaHex: UInt32 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = UInt32(max(0, min(255, Int(r * 255))))
        let gi = UInt32(max(0, min(255, Int(g * 255))))
        let bi = UInt32(max(0, min(255, Int(b * 255))))
        let ai = UInt32(max(0, min(255, Int(a * 255))))
        return (ri << 24) | (gi << 16) | (bi << 8) | ai
    }
}
