import SwiftUI

/// Full-screen particle layer rendered above the static `AnimatedBackdrop`. Each `ParticleStyle` has
/// its own spawn pattern, motion, and color rule. The field is deliberately modest: small
/// counts, short lifetimes, low opacity. It suggests weather or place — it should never feel
/// like effects piled onto the UI.
///
/// Rendering uses `TimelineView(.animation)` + `Canvas` so the whole system runs in a single
/// draw call on the main thread. `drawingGroup()` is intentionally not applied here: the
/// total particle count is small enough that CPU rasterization stays cheap, and forcing an
/// offscreen Metal layer would compete with the backdrop shader for GPU bandwidth.
struct ParticleField: View {
    let style: ParticleStyle
    let tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [Particle] = []
    @State private var lastTick: TimeInterval = 0
    @State private var seededForSize: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            if style == .none || reduceMotion {
                Color.clear
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                    Canvas { gc, size in
                        let now = context.date.timeIntervalSinceReferenceDate
                        render(gc: gc, size: size, now: now)
                    }
                }
                .onAppear {
                    seed(in: proxy.size)
                }
                .onChange(of: proxy.size) { _, newSize in
                    seed(in: newSize)
                }
                .onChange(of: style) { _, _ in
                    seed(in: proxy.size)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    // MARK: - Particle state

    private struct Particle: Equatable {
        var position: CGPoint
        var velocity: CGVector
        var size: CGFloat
        var opacity: Double
        /// Seconds since spawn, used to derive age-based opacity envelopes.
        var age: Double
        /// Lifetime before respawn, in seconds.
        var lifetime: Double
        /// 0…1 jitter seed held per particle so flicker/twinkle stays deterministic.
        var seed: Double
    }

    // MARK: - Config per style

    private var config: StyleConfig {
        StyleConfig.forStyle(style)
    }

    // MARK: - Seeding

    private func seed(in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        guard style != .none else {
            particles = []
            return
        }

        seededForSize = size
        let count = config.particleCount

        particles = (0..<count).map { _ in
            makeParticle(in: size, initialAge: Double.random(in: 0...config.lifetime))
        }
        lastTick = 0
    }

    private func makeParticle(in size: CGSize, initialAge: Double = 0) -> Particle {
        let x = CGFloat.random(in: 0...size.width)
        let startPoint: CGPoint
        let velocity: CGVector

        switch style {
        case .rain:
            // Start above the visible area so the first frame isn't a burst at the top edge.
            startPoint = CGPoint(x: x, y: CGFloat.random(in: -size.height * 0.2...size.height))
            velocity = CGVector(
                dx: CGFloat.random(in: -6...6),
                dy: CGFloat.random(in: 260...380)
            )
        case .embers:
            // Rise from the bottom quarter.
            startPoint = CGPoint(x: x, y: CGFloat.random(in: size.height * 0.72...size.height * 1.1))
            velocity = CGVector(
                dx: CGFloat.random(in: -18...18),
                dy: CGFloat.random(in: -130 ... -70)
            )
        case .fireflies:
            startPoint = CGPoint(
                x: x,
                y: CGFloat.random(in: size.height * 0.2...size.height * 0.85)
            )
            velocity = CGVector(
                dx: CGFloat.random(in: -14...14),
                dy: CGFloat.random(in: -10...10)
            )
        case .motes:
            startPoint = CGPoint(x: x, y: CGFloat.random(in: 0...size.height))
            velocity = CGVector(
                dx: CGFloat.random(in: -18 ... -4),
                dy: CGFloat.random(in: -4...4)
            )
        case .mist:
            startPoint = CGPoint(
                x: CGFloat.random(in: -size.width * 0.2...size.width),
                y: CGFloat.random(in: size.height * 0.42...size.height * 0.92)
            )
            velocity = CGVector(
                dx: CGFloat.random(in: 14...42),
                dy: CGFloat.random(in: -2...2)
            )
        case .none:
            startPoint = .zero
            velocity = .zero
        }

        return Particle(
            position: startPoint,
            velocity: velocity,
            size: CGFloat.random(in: config.sizeRange),
            opacity: Double.random(in: config.opacityRange),
            age: initialAge,
            lifetime: config.lifetime * Double.random(in: 0.72...1.18),
            seed: Double.random(in: 0...1)
        )
    }

    // MARK: - Rendering

    private func render(gc: GraphicsContext, size: CGSize, now: TimeInterval) {
        // First frame after seed — initialize the tick clock without advancing particles.
        if lastTick == 0 {
            lastTick = now
            return
        }

        // Guard against huge deltas when the app returns from background. dt is capped so
        // particles don't jump across the screen on resume.
        let rawDt = now - lastTick
        let dt = min(max(rawDt, 0), 0.1)
        lastTick = now

        for index in particles.indices {
            var particle = particles[index]
            particle.age += dt
            particle.position.x += particle.velocity.dx * CGFloat(dt)
            particle.position.y += particle.velocity.dy * CGFloat(dt)

            // Lifetime or offscreen respawn.
            if particle.age > particle.lifetime || !isOnscreen(particle.position, size: size) {
                particle = makeParticle(in: size)
            }

            particles[index] = particle
            draw(particle, in: gc, size: size, now: now)
        }
    }

    private func isOnscreen(_ point: CGPoint, size: CGSize) -> Bool {
        // Allow generous margins so particles drifting just outside the frame don't respawn
        // mid-arc when they're about to re-enter (useful for mist).
        let margin: CGFloat = 80
        return point.x >= -margin
            && point.x <= size.width + margin
            && point.y >= -margin
            && point.y <= size.height + margin
    }

    private func draw(_ particle: Particle, in gc: GraphicsContext, size: CGSize, now: TimeInterval) {
        let envelope = ageEnvelope(particle: particle, now: now)
        let finalOpacity = particle.opacity * envelope
        guard finalOpacity > 0.01 else { return }

        let drawColor = color(for: particle).opacity(finalOpacity)

        switch style {
        case .rain:
            // Thin vertical streak — approximates motion blur.
            var path = Path()
            path.move(to: particle.position)
            path.addLine(to: CGPoint(
                x: particle.position.x - particle.velocity.dx * 0.012,
                y: particle.position.y - particle.velocity.dy * 0.012
            ))
            gc.stroke(path, with: .color(drawColor), lineWidth: particle.size)
        case .embers:
            // Halo at 3× radius so embers read as glowing coals rather than flat dots.
            drawHalo(at: particle.position, radius: particle.size * 3, color: drawColor, gc: gc)
            let radius = particle.size
            let rect = CGRect(
                x: particle.position.x - radius,
                y: particle.position.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            gc.fill(Path(ellipseIn: rect), with: .color(drawColor))
        case .fireflies:
            // Slight twinkle via time-based opacity wobble.
            let twinkle = 0.65 + 0.35 * sin(now * 2.4 + particle.seed * 6.28)
            let effective = drawColor.opacity(finalOpacity * twinkle)
            drawHalo(at: particle.position, radius: particle.size * 3.5, color: effective, gc: gc)
            let radius = particle.size
            let rect = CGRect(
                x: particle.position.x - radius,
                y: particle.position.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            gc.fill(Path(ellipseIn: rect), with: .color(effective))
        case .motes:
            let radius = particle.size * 0.5
            let rect = CGRect(
                x: particle.position.x - radius,
                y: particle.position.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            gc.fill(Path(ellipseIn: rect), with: .color(drawColor))
        case .mist:
            // Stretched horizontal ellipse; long and thin.
            let w = particle.size * 8
            let h = particle.size * 1.6
            let rect = CGRect(
                x: particle.position.x - w / 2,
                y: particle.position.y - h / 2,
                width: w,
                height: h
            )
            gc.fill(Path(ellipseIn: rect), with: .color(drawColor))
        case .none:
            return
        }
    }

    /// Draws a soft glow centered on a point. Used by embers and fireflies so they read as
    /// luminous rather than flat — a single radial fill at ~20% of the particle's opacity.
    private func drawHalo(at center: CGPoint, radius: CGFloat, color: Color, gc: GraphicsContext) {
        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        gc.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.22)))
    }

    private func ageEnvelope(particle: Particle, now: TimeInterval) -> Double {
        // Fade in over the first 12% of lifetime, hold, fade out over the last 18%.
        let progress = particle.age / particle.lifetime
        if progress < 0.12 {
            return progress / 0.12
        }
        if progress > 0.82 {
            return max(0, (1 - progress) / 0.18)
        }
        return 1
    }

    private func color(for particle: Particle) -> Color {
        switch style {
        case .embers:
            // Warm red→orange→gold; particle seed selects within the range.
            let hue = 0.02 + particle.seed * 0.08
            return Color(hue: hue, saturation: 0.85, brightness: 0.98)
        case .fireflies:
            // Warm yellow-green leaning gold.
            return Color(hue: 0.14, saturation: 0.7, brightness: 0.98)
        case .motes:
            // Neutral warm; picks up channel tint subtly.
            return tint
        case .mist:
            return Color.white
        case .rain:
            return Color.white
        case .none:
            return Color.clear
        }
    }
}

// MARK: - Per-style tuning

private struct StyleConfig {
    let particleCount: Int
    let sizeRange: ClosedRange<CGFloat>
    let opacityRange: ClosedRange<Double>
    let lifetime: Double

    static func forStyle(_ style: ParticleStyle) -> StyleConfig {
        switch style {
        case .rain:
            return StyleConfig(
                particleCount: 55,
                sizeRange: 1.0...1.9,
                opacityRange: 0.32...0.58,
                lifetime: 2.2
            )
        case .embers:
            return StyleConfig(
                particleCount: 28,
                sizeRange: 1.0...2.1,
                opacityRange: 0.38...0.72,
                lifetime: 3.6
            )
        case .fireflies:
            return StyleConfig(
                particleCount: 22,
                sizeRange: 1.4...2.6,
                opacityRange: 0.48...0.78,
                lifetime: 8.0
            )
        case .motes:
            return StyleConfig(
                particleCount: 32,
                sizeRange: 1.8...3.2,
                opacityRange: 0.18...0.34,
                lifetime: 14.0
            )
        case .mist:
            return StyleConfig(
                particleCount: 12,
                sizeRange: 4.4...7.0,
                opacityRange: 0.16...0.28,
                lifetime: 22.0
            )
        case .none:
            return StyleConfig(
                particleCount: 0,
                sizeRange: 0...0,
                opacityRange: 0...0,
                lifetime: 0
            )
        }
    }
}
