import SwiftUI

struct AnimatedLiquidAura<ShapeType: Shape>: View {
    @Environment(\.scenePhase) private var scenePhase

    let palette: [Color]
    let shape: ShapeType
    let intensity: Double
    let blurRadius: CGFloat
    let baseBlendOpacity: Double
    let speedMultiplier: Double
    let frameRate: Double
    let isAnimated: Bool
    let animationKey: String
    let coverage: Double
    let accentMixAmount: Double
    let colorSeparation: Double

    @State private var animationStart = Date()
    @State private var timeOffset = Double.random(in: 0...180)
    @State private var seedA = Float.random(in: 0...1)
    @State private var seedB = Float.random(in: 0...1)

    init(
        palette: [Color],
        shape: ShapeType,
        intensity: Double,
        blurRadius: CGFloat = 5,
        baseBlendOpacity: Double = 0,
        speedMultiplier: Double = 1,
        frameRate: Double = 24,
        isAnimated: Bool = false,
        animationKey: String = "",
        coverage: Double = 1,
        accentMixAmount: Double = 0.18,
        colorSeparation: Double = 1
    ) {
        self.palette = palette
        self.shape = shape
        self.intensity = intensity
        self.blurRadius = blurRadius
        self.baseBlendOpacity = baseBlendOpacity
        self.speedMultiplier = speedMultiplier
        self.frameRate = frameRate
        self.isAnimated = isAnimated
        self.animationKey = animationKey
        self.coverage = coverage
        self.accentMixAmount = accentMixAmount
        self.colorSeparation = colorSeparation
    }

    var body: some View {
        GeometryReader { proxy in
            auraBody(size: proxy.size)
        }
        .allowsHitTesting(false)
        .onAppear {
            restartAnimation(randomizeSeeds: true)
        }
        .onChange(of: scenePhase) { previousPhase, newPhase in
            guard previousPhase != .active, newPhase == .active else { return }
            restartAnimation(randomizeSeeds: true)
        }
        .onChange(of: animationKey) { _, _ in
            restartAnimation(randomizeSeeds: true)
        }
    }

    @ViewBuilder
    private func auraBody(size: CGSize) -> some View {
        if isAnimated, scenePhase == .active {
            TimelineView(.periodic(from: .now, by: 1.0 / max(frameRate, 1))) { context in
                auraLayer(size: size, time: relativeTime(at: context.date))
            }
        } else {
            auraLayer(size: size, time: timeOffset)
        }
    }

    private func auraLayer(size: CGSize, time: Double) -> some View {
        ZStack {
            shape
                .fill(makeShader(size: size, time: time))

            shape
                .fill(primaryTint.opacity(baseBlendOpacity))
        }
        .compositingGroup()
    }

    private func makeShader(size: CGSize, time: Double) -> Shader {
        let shaderPalette = normalizedPalette
        let arguments: [Shader.Argument] = [
            .float2(CGSize(width: max(size.width, 1), height: max(size.height, 1))),
            .float(Float(time)),
            .float(seedA),
            .float(seedB),
            .color(shaderPalette[0]),
            .color(shaderPalette[1]),
            .color(shaderPalette[2]),
            .color(shaderPalette[3]),
            .color(shaderPalette[4]),
            .color(shaderPalette[5]),
            .color(shaderPalette[6]),
            .color(shaderPalette[7]),
            .float(Float(max(0, intensity))),
            .float(Float(softness)),
            .float(Float(max(0.15, speedMultiplier))),
            .float(Float(max(0.8, coverage))),
            .float(Float(max(0, min(1, accentMixAmount)))),
            .float(Float(max(1, colorSeparation)))
        ]

        var shader = Shader(
            function: ShaderFunction(library: .default, name: "liquidAuraFill"),
            arguments: arguments
        )
        shader.dithersColor = true
        return shader
    }

    private var softness: CGFloat {
        0.68 + (blurRadius * 0.12)
    }

    private var primaryTint: Color {
        palette.first ?? .white
    }

    private var secondaryTint: Color {
        palette.count > 1 ? palette[1] : primaryTint
    }

    private var tertiaryTint: Color {
        palette.count > 2 ? palette[2] : secondaryTint
    }

    private var normalizedPalette: [Color] {
        var colors = palette.isEmpty ? [Color.white] : palette

        if colors.count >= 8 {
            return (0..<8).map { index in
                let progress = Double(index) / 7.0
                let sourceIndex = Int(round(progress * Double(colors.count - 1)))
                return colors[sourceIndex]
            }
        }

        while colors.count < 8 {
            colors.append(colors[colors.count % max(palette.count, 1)])
        }

        return Array(colors.prefix(8))
    }

    private func relativeTime(at date: Date) -> Double {
        date.timeIntervalSince(animationStart) + timeOffset
    }

    private func restartAnimation(randomizeSeeds: Bool) {
        animationStart = Date()
        timeOffset = Double.random(in: 0...180)
        if randomizeSeeds {
            seedA = Float.random(in: 0...1)
            seedB = Float.random(in: 0...1)
        }
    }
}
