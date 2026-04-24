import SwiftUI

/// Full-screen particle layer rendered above the static `AnimatedBackdrop`. Each
/// `ParticleStyle` has its own spawn pattern, motion, and color rule.
///
/// The field is modelled as **pure functions of time** rather than a mutable particle
/// pool: each particle is just a stable seed, and its position at any moment is derived
/// from `(seed, now, size, style)`. SwiftUI's Canvas closure runs inside view-body
/// evaluation, so writing back to `@State` from there is an anti-pattern that can miss
/// frames entirely (which is why the previous implementation looked static or invisible).
/// By never mutating during draw, we avoid the issue and get deterministic behaviour.
struct ParticleField: View {
    let style: ParticleStyle
    let tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            if style == .none || reduceMotion {
                Color.clear
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                    Canvas { gc, size in
                        let now = context.date.timeIntervalSinceReferenceDate
                        drawAll(gc: gc, size: size, now: now)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    // MARK: - Drawing

    private func drawAll(gc: GraphicsContext, size: CGSize, now: TimeInterval) {
        guard size.width > 0, size.height > 0 else { return }

        let config = StyleConfig.forStyle(style)
        // Deterministic seed set: one per particle slot. We derive everything from the seed
        // and current time — no per-slot state stored anywhere.
        for index in 0..<config.particleCount {
            let seed = Self.hashedSeed(for: index, style: style)
            draw(seed: seed, index: index, config: config, gc: gc, size: size, now: now)
        }
    }

    /// Stable 0…1 pseudo-random seed derived from the slot index and style. Same index +
    /// style always yields the same seed across frames, so particle identities are fixed.
    private static func hashedSeed(for index: Int, style: ParticleStyle) -> Double {
        // Combine index + style hash into a single deterministic value. The large primes
        // scramble the bits so adjacent indices don't produce near-identical seeds.
        var h = UInt64(index &+ 1) &* 2_654_435_761
        h ^= UInt64(bitPattern: Int64(style.hashValue)) &* 40_503
        h = (h ^ (h >> 16)) &* 0x7FEB_352D
        h = (h ^ (h >> 15)) &* 0x846C_A68B
        return Double(h & 0xFFFF_FFFF) / Double(UInt32.max)
    }

    private func draw(
        seed: Double,
        index: Int,
        config: StyleConfig,
        gc: GraphicsContext,
        size: CGSize,
        now: TimeInterval
    ) {
        // Age loops inside [0, lifetime). `seed * lifetime` staggers particles so they
        // don't all spawn on the same frame.
        let lifetime = config.lifetime * (0.72 + seed * 0.46)
        let age = (now - seed * lifetime).truncatingRemainder(dividingBy: lifetime)
        guard age >= 0 else { return }

        // Second independent seed for perpendicular dimensions. XOR with an odd salt.
        let secondSeed = fract(seed * 12.9898 + 78.233)
        let thirdSeed = fract(seed * 43.2164 + 13.017)

        let particleSize = lerp(config.sizeRange.lowerBound, config.sizeRange.upperBound, seed)
        let baseOpacity = lerp(config.opacityRange.lowerBound, config.opacityRange.upperBound, secondSeed)

        let position = positionFor(
            age: age,
            style: style,
            size: size,
            seed: seed,
            secondSeed: secondSeed,
            thirdSeed: thirdSeed,
            lifetime: lifetime
        )

        let envelope = ageEnvelope(age: age, lifetime: lifetime)
        let finalOpacity = baseOpacity * envelope
        guard finalOpacity > 0.01 else { return }

        let drawColor = color(for: style).opacity(finalOpacity)

        drawShape(
            style: style,
            position: position,
            particleSize: particleSize,
            drawColor: drawColor,
            finalOpacity: finalOpacity,
            seed: seed,
            now: now,
            gc: gc
        )
    }

    private func positionFor(
        age: Double,
        style: ParticleStyle,
        size: CGSize,
        seed: Double,
        secondSeed: Double,
        thirdSeed: Double,
        lifetime: Double
    ) -> CGPoint {
        let w = Double(size.width)
        let h = Double(size.height)
        let spawnX = secondSeed * w

        switch style {
        case .rain:
            // Start above screen, fall down. Velocity set so it crosses the screen in one
            // lifetime; jitter X slightly over age for wind effect.
            let vy = (h + h * 0.3) / lifetime
            let jitterX = sin(age * 1.4 + thirdSeed * 6.28) * 8
            return CGPoint(x: spawnX + jitterX, y: -h * 0.1 + vy * age)
        case .embers:
            // Rise from near bottom, drift sideways a little. Accelerating is overkill;
            // linear motion reads fine at this opacity.
            let vy = (h * 0.9) / lifetime
            let jitterX = sin(age * 2.1 + thirdSeed * 6.28) * 14
            return CGPoint(x: spawnX + jitterX, y: h * 0.95 - vy * age)
        case .fireflies:
            // Meander in a bounded region; uses a slow Lissajous so paths never repeat
            // exactly.
            let centerX = spawnX
            let centerY = h * 0.25 + thirdSeed * h * 0.55
            let rx = 40 + seed * 80
            let ry = 30 + thirdSeed * 50
            let phase = seed * 6.28
            return CGPoint(
                x: centerX + rx * sin(age * 0.6 + phase),
                y: centerY + ry * cos(age * 0.4 + phase * 1.3)
            )
        case .motes:
            // Slow leftward drift with vertical wobble. Wraps horizontally via modulo so the
            // particle re-enters from the right edge.
            let speed = 14 + seed * 20
            let travel = speed * age
            let rawX = spawnX - travel
            let wrappedX = ((rawX.truncatingRemainder(dividingBy: w + 60)) + w + 60)
                .truncatingRemainder(dividingBy: w + 60) - 30
            let yBase = thirdSeed * h
            let wobble = sin(age * 0.8 + seed * 6.28) * 6
            return CGPoint(x: wrappedX, y: yBase + wobble)
        case .mist:
            // Fast rightward drift, lower third of the screen. Also wraps.
            let speed = 28 + seed * 22
            let travel = speed * age
            let rawX = spawnX + travel
            let wrappedX = (rawX.truncatingRemainder(dividingBy: w + 120)) - 60
            let yBase = h * 0.42 + thirdSeed * h * 0.5
            return CGPoint(x: wrappedX, y: yBase + sin(age * 0.3 + seed * 6.28) * 4)
        case .none:
            return .zero
        }
    }

    private func drawShape(
        style: ParticleStyle,
        position: CGPoint,
        particleSize: CGFloat,
        drawColor: Color,
        finalOpacity: Double,
        seed: Double,
        now: TimeInterval,
        gc: GraphicsContext
    ) {
        switch style {
        case .rain:
            var path = Path()
            let streakLen = particleSize * 9
            path.move(to: position)
            path.addLine(to: CGPoint(x: position.x - 1, y: position.y - streakLen))
            gc.stroke(path, with: .color(drawColor), lineWidth: particleSize)
        case .embers:
            drawHalo(at: position, radius: particleSize * 3.4, color: drawColor, gc: gc)
            gc.fill(circlePath(at: position, radius: particleSize), with: .color(drawColor))
        case .fireflies:
            let twinkle = 0.6 + 0.4 * sin(now * 2.4 + seed * 6.28)
            let effective = drawColor.opacity(finalOpacity * twinkle)
            drawHalo(at: position, radius: particleSize * 3.8, color: effective, gc: gc)
            gc.fill(circlePath(at: position, radius: particleSize), with: .color(effective))
        case .motes:
            gc.fill(circlePath(at: position, radius: particleSize * 0.5), with: .color(drawColor))
        case .mist:
            let w = particleSize * 9
            let h = particleSize * 1.6
            let rect = CGRect(
                x: position.x - w / 2,
                y: position.y - h / 2,
                width: w,
                height: h
            )
            gc.fill(Path(ellipseIn: rect), with: .color(drawColor))
        case .none:
            return
        }
    }

    private func circlePath(at point: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
    }

    /// Soft glow at ~22% of the core color. Used by embers and fireflies.
    private func drawHalo(at center: CGPoint, radius: CGFloat, color: Color, gc: GraphicsContext) {
        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        gc.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.22)))
    }

    /// 0 at birth, 1 at midlife, 0 at death. Smooth fade on both ends so particles don't
    /// pop in or out. Attack is slightly shorter than release to make spawns feel alive.
    private func ageEnvelope(age: Double, lifetime: Double) -> Double {
        let progress = age / lifetime
        if progress < 0.14 {
            return progress / 0.14
        }
        if progress > 0.80 {
            return max(0, (1 - progress) / 0.20)
        }
        return 1
    }

    private func color(for style: ParticleStyle) -> Color {
        switch style {
        case .embers:
            return Color(hue: 0.05, saturation: 0.85, brightness: 0.98)
        case .fireflies:
            return Color(hue: 0.14, saturation: 0.7, brightness: 1.0)
        case .motes:
            return tint
        case .mist, .rain:
            return Color.white
        case .none:
            return Color.clear
        }
    }

    // MARK: - Math helpers

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat {
        a + CGFloat(t) * (b - a)
    }

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + t * (b - a)
    }

    private func fract(_ x: Double) -> Double {
        x - floor(x)
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
                particleCount: 60,
                sizeRange: 1.0...1.8,
                opacityRange: 0.32...0.58,
                lifetime: 2.0
            )
        case .embers:
            return StyleConfig(
                particleCount: 30,
                sizeRange: 1.1...2.2,
                opacityRange: 0.42...0.78,
                lifetime: 3.8
            )
        case .fireflies:
            return StyleConfig(
                particleCount: 22,
                sizeRange: 1.5...2.8,
                opacityRange: 0.52...0.82,
                lifetime: 8.5
            )
        case .motes:
            return StyleConfig(
                particleCount: 34,
                sizeRange: 2.0...3.4,
                opacityRange: 0.22...0.42,
                lifetime: 14.0
            )
        case .mist:
            return StyleConfig(
                particleCount: 14,
                sizeRange: 4.4...7.0,
                opacityRange: 0.18...0.32,
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
