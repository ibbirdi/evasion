// Oasis — App Store screenshot composer
//
// Content (slide catalogue + localized copy + bezel image path) lives in
// `scripts/screenshot_content.json`. Edit that file to add a language, tweak
// headlines, swap images, or change per-slide layouts and accent colors —
// no Swift changes needed.
//
// Canvas: 1320 × 2868 (full) + 880 × 1912 preview alongside (for review
// without hitting the 2000px image-inline limit).
//
// Usage:
//   swift scripts/generate_store_screenshot_comps.swift
//   swift scripts/generate_store_screenshot_comps.swift --only 01_hero
//   swift scripts/generate_store_screenshot_comps.swift --only 01_hero --lang fr-FR

import AppKit
import CoreImage
import Foundation

// ──────────────────────────────────────────────────────────────────────────
// MARK: Data model
// ──────────────────────────────────────────────────────────────────────────

enum LayoutMode: String, Codable {
    case poster       // Large editorial hook, oversized device cropped at bottom
    case top          // Text at top, device fully visible below
    case bottom       // Device fully visible at top, text below
    case bleed        // Oversized device, compact caption at bottom
    case peekBottom   // Text at top, device oversized and bleeding off bottom
}

enum BackgroundStyle: String, Codable {
    case warmGradient      // 3-stop sunset gradient (hero, paywall)
    case creamRadial       // cream base with centered accent radial glow
    case duskGradient      // deep teal/indigo gradient for focus/calm slides
    case studioGradient    // premium dark green/teal with warm acoustic glow
    case sageMist          // soft editorial mist with restrained color
    case spatialGradient   // deep blue/teal/violet for spatial audio
    case midnightCopper    // dark premium copper for purchase/value slides
}

/// Decoded directly from screenshot_content.json.
struct SlideConfig: Codable {
    let slug: String
    let source: String
    let layout: LayoutMode
    let background: BackgroundStyle
    let accent: String        // hex string "#RRGGBB"
    let iconSymbol: String
    let darkText: Bool
}

struct CopyEntry: Codable {
    let eyebrow: String?
    let headline: String
    let subhead: String
}

struct ContentFile: Codable {
    let bezelImage: String
    let capturesDir: String
    let capturePrefix: String
    let slides: [SlideConfig]
    let copy: [String: [String: CopyEntry]]
}

/// Runtime slide model (with resolved NSColor).
struct Slide {
    let slug: String
    let source: String
    let layout: LayoutMode
    let background: BackgroundStyle
    let accent: NSColor
    let iconSymbol: String
    let darkText: Bool
}

struct Copy {
    let eyebrow: String?
    let headline: String
    let subhead: String
}

extension Slide {
    init(_ cfg: SlideConfig) {
        self.slug = cfg.slug
        self.source = cfg.source
        self.layout = cfg.layout
        self.background = cfg.background
        self.accent = hex(cfg.accent)
        self.iconSymbol = cfg.iconSymbol
        self.darkText = cfg.darkText
    }
}

extension Copy {
    init(_ e: CopyEntry) {
        self.eyebrow = e.eyebrow
        self.headline = e.headline
        self.subhead = e.subhead
    }
}

// ──────────────────────────────────────────────────────────────────────────
// MARK: Content loader — slides + copy + bezel path live in
// scripts/screenshot_content.json. Edit that file to retune copy, swap images,
// add locales, or change layouts without touching the Swift compositor.
// ──────────────────────────────────────────────────────────────────────────

func loadContent() -> ContentFile {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let url = root.appendingPathComponent("scripts/screenshot_content.json")
    do {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ContentFile.self, from: data)
    } catch {
        fputs("❌ Failed to load \(url.path): \(error)\n", stderr)
        exit(1)
    }
}

let CONTENT = loadContent()
let SLIDES: [Slide] = CONTENT.slides.map(Slide.init)
let COPY: [String: [String: Copy]] = CONTENT.copy.mapValues { perSlide in
    perSlide.mapValues(Copy.init)
}

// ──────────────────────────────────────────────────────────────────────────
// MARK: Design tokens
// ──────────────────────────────────────────────────────────────────────────

enum Tokens {
    static let canvasSize = CGSize(width: 1320, height: 2868)
    static let previewSize = CGSize(width: 880, height: 1912)

    static let inkDark  = hex("#0E1524")   // for cream / warm backgrounds
    static let inkLight = hex("#F6F2E6")   // for dusk gradient backgrounds

    // ── Device mockup widths per layout (max; may shrink if text block forces it)
    static let deviceWidth_poster: CGFloat      = 1160
    static let deviceWidth_top: CGFloat         = 1080
    static let deviceWidth_bottom: CGFloat      = 1060
    static let deviceWidth_bleed: CGFloat       = 1150
    static let deviceWidth_peekBottom: CGFloat  = 1220

    /// Aspect of the Apple bezel PNG (height / width = 3000 / 1470).
    /// Use this for all layout math — the bezel is slightly shorter per unit
    /// width than the raw 1320 × 2868 capture.
    static let bezelAspect: CGFloat = 3000.0 / 1470.0

    // ── Typography
    static let iconSize: CGFloat = 78
    // Generous breathing room between the marker and the headline — keeps the
    // editorial label calm instead of making the slide feel like an ad banner.
    static let iconToHeadlineGap: CGFloat = 40

    static let eyebrowSize: CGFloat = 32
    static let eyebrowKerning: CGFloat = 2.4
    static let eyebrowToHeadlineGap: CGFloat = 30

    // Tight leading for punchier display type. 0.82 packs the 2-line headlines
    // (common across all 6 locales) into a cohesive block without clipping
    // descenders at the largest step sizes.
    static let headlineStepSizes: [CGFloat] = [136, 128, 120, 110, 100, 90, 80]
    static let headlineLeading: CGFloat = 0.90
    static let headlineKerning: CGFloat = 0

    static let headlineToSubheadGap: CGFloat = 30
    static let subheadSize: CGFloat = 54
    static let subheadLeading: CGFloat = 1.16

    // ── Layout padding
    static let textSideMargin: CGFloat = 80
    static let posterLayout_topPadding: CGFloat    = 124
    static let posterLayout_gap: CGFloat           = 78
    static let topLayout_topPadding: CGFloat       = 150
    static let topLayout_gap: CGFloat              = 76
    static let bottomLayout_topPadding: CGFloat    = 110
    static let bottomLayout_gap: CGFloat           = 70
    static let bottomLayout_bottomPadding: CGFloat = 88
    static let bleedLayout_topPadding: CGFloat     = 66
    static let bleedLayout_bottomPadding: CGFloat  = 76
    static let peekLayout_topPadding: CGFloat      = 130
    static let peekLayout_gap: CGFloat             = 74
}

// ──────────────────────────────────────────────────────────────────────────
// MARK: Helpers
// ──────────────────────────────────────────────────────────────────────────

func hex(_ s: String) -> NSColor {
    var h = s
    if h.hasPrefix("#") { h.removeFirst() }
    let v = UInt32(h, radix: 16) ?? 0
    return NSColor(
        srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
        green: CGFloat((v >> 8) & 0xFF) / 255,
        blue: CGFloat(v & 0xFF) / 255,
        alpha: 1
    )
}

func displayFont(_ size: CGFloat, weight: NSFont.Weight) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: weight)
}

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)
        for i in 0..<elementCount {
            switch element(at: i, associatedPoints: &points) {
            case .moveTo:    path.move(to: points[0])
            case .lineTo:    path.addLine(to: points[0])
            case .curveTo:   path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            case .closePath: path.closeSubpath()
            @unknown default: break
            }
        }
        return path
    }
}

// ──────────────────────────────────────────────────────────────────────────
// MARK: Background renderers
// ──────────────────────────────────────────────────────────────────────────

func drawBackground(slide: Slide) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let rect = CGRect(origin: .zero, size: Tokens.canvasSize)

    switch slide.background {
    case .warmGradient:
        // 3-stop warm sunset → coral → peach. Angled top-to-bottom.
        let cs = CGColorSpaceCreateDeviceRGB()
        let grad = CGGradient(
            colorsSpace: cs,
            colors: [
                hex("#F6DFA5").cgColor,   // pale dawn top
                hex("#F2B868").cgColor,   // warm mid
                hex("#DE7C3E").cgColor    // saturated copper bottom
            ] as CFArray,
            locations: [0, 0.52, 1]
        )!
        ctx.drawLinearGradient(grad,
                               start: CGPoint(x: rect.midX, y: rect.maxY),
                               end:   CGPoint(x: rect.midX, y: rect.minY),
                               options: [])

    case .creamRadial:
        // Cream base.
        hex("#F4ECD6").setFill()
        NSBezierPath(rect: rect).fill()
        // Radial accent glow roughly behind where the device will sit.
        let cs = CGColorSpaceCreateDeviceRGB()
        let glow = CGGradient(
            colorsSpace: cs,
            colors: [
                slide.accent.blended(withFraction: 0.65, of: hex("#F4ECD6"))!
                    .withAlphaComponent(0.55).cgColor,
                slide.accent.withAlphaComponent(0.0).cgColor
            ] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawRadialGradient(
            glow,
            startCenter: CGPoint(x: rect.midX, y: rect.midY + 160),
            startRadius: 0,
            endCenter:   CGPoint(x: rect.midX, y: rect.midY + 160),
            endRadius:   rect.width * 0.75,
            options: []
        )

    case .duskGradient:
        let cs = CGColorSpaceCreateDeviceRGB()
        let grad = CGGradient(
            colorsSpace: cs,
            colors: [
                hex("#1A1F38").cgColor,   // deep indigo top
                hex("#2C2244").cgColor,   // plum mid
                hex("#10172A").cgColor    // near-black bottom
            ] as CFArray,
            locations: [0, 0.55, 1]
        )!
        ctx.drawLinearGradient(grad,
                               start: CGPoint(x: rect.midX, y: rect.maxY),
                               end:   CGPoint(x: rect.midX, y: rect.minY),
                               options: [])
        // Accent glow near center.
        let glow = CGGradient(
            colorsSpace: cs,
            colors: [
                slide.accent.withAlphaComponent(0.40).cgColor,
                slide.accent.withAlphaComponent(0.0).cgColor
            ] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawRadialGradient(
            glow,
            startCenter: CGPoint(x: rect.midX, y: rect.midY + 120),
            startRadius: 0,
            endCenter:   CGPoint(x: rect.midX, y: rect.midY + 120),
            endRadius:   rect.width * 0.9,
            options: []
        )

    case .studioGradient:
        let cs = CGColorSpaceCreateDeviceRGB()
        let grad = CGGradient(
            colorsSpace: cs,
            colors: [
                hex("#0E1715").cgColor,
                hex("#16332E").cgColor,
                hex("#0B111C").cgColor
            ] as CFArray,
            locations: [0, 0.54, 1]
        )!
        ctx.drawLinearGradient(grad,
                               start: CGPoint(x: rect.midX - 180, y: rect.maxY),
                               end:   CGPoint(x: rect.midX + 220, y: rect.minY),
                               options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        drawRadialGlow(color: hex("#E4A45A"), center: CGPoint(x: rect.midX, y: rect.minY + 520),
                       radius: rect.width * 0.82, alpha: 0.48)
        drawRadialGlow(color: hex("#42B6A1"), center: CGPoint(x: rect.minX + 210, y: rect.maxY - 340),
                       radius: rect.width * 0.58, alpha: 0.22)

    case .sageMist:
        let cs = CGColorSpaceCreateDeviceRGB()
        let grad = CGGradient(
            colorsSpace: cs,
            colors: [
                hex("#F6F1E4").cgColor,
                hex("#E4ECDC").cgColor,
                hex("#F2E1CF").cgColor
            ] as CFArray,
            locations: [0, 0.56, 1]
        )!
        ctx.drawLinearGradient(grad,
                               start: CGPoint(x: rect.minX, y: rect.maxY),
                               end:   CGPoint(x: rect.maxX, y: rect.minY),
                               options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        drawRadialGlow(color: slide.accent, center: CGPoint(x: rect.midX, y: rect.midY + 180),
                       radius: rect.width * 0.72, alpha: 0.22)

    case .spatialGradient:
        let cs = CGColorSpaceCreateDeviceRGB()
        let grad = CGGradient(
            colorsSpace: cs,
            colors: [
                hex("#11172B").cgColor,
                hex("#12343A").cgColor,
                hex("#2E2448").cgColor
            ] as CFArray,
            locations: [0, 0.50, 1]
        )!
        ctx.drawLinearGradient(grad,
                               start: CGPoint(x: rect.midX, y: rect.maxY),
                               end:   CGPoint(x: rect.midX, y: rect.minY),
                               options: [])
        drawRadialGlow(color: slide.accent, center: CGPoint(x: rect.midX + 110, y: rect.midY + 120),
                       radius: rect.width * 0.86, alpha: 0.38)
        drawRadialGlow(color: hex("#63D2B6"), center: CGPoint(x: rect.minX + 190, y: rect.minY + 520),
                       radius: rect.width * 0.62, alpha: 0.20)

    case .midnightCopper:
        let cs = CGColorSpaceCreateDeviceRGB()
        let grad = CGGradient(
            colorsSpace: cs,
            colors: [
                hex("#171019").cgColor,
                hex("#2A1C24").cgColor,
                hex("#0E111A").cgColor
            ] as CFArray,
            locations: [0, 0.52, 1]
        )!
        ctx.drawLinearGradient(grad,
                               start: CGPoint(x: rect.midX + 120, y: rect.maxY),
                               end:   CGPoint(x: rect.midX - 160, y: rect.minY),
                               options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        drawRadialGlow(color: hex("#E08B46"), center: CGPoint(x: rect.midX, y: rect.minY + 460),
                       radius: rect.width * 0.76, alpha: 0.42)
        drawRadialGlow(color: slide.accent, center: CGPoint(x: rect.maxX - 220, y: rect.maxY - 420),
                       radius: rect.width * 0.48, alpha: 0.18)
    }

    drawAcousticField(slide: slide, in: rect)
    drawGrainOverlay(in: rect, opacity: 0.028)
    drawVignette(in: rect, darkness: slide.darkText ? 0.14 : 0.34)
}

func drawRadialGlow(color: NSColor, center: CGPoint, radius: CGFloat, alpha: CGFloat) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let cs = CGColorSpaceCreateDeviceRGB()
    let glow = CGGradient(
        colorsSpace: cs,
        colors: [
            color.withAlphaComponent(alpha).cgColor,
            color.withAlphaComponent(0.0).cgColor
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(
        glow,
        startCenter: center,
        startRadius: 0,
        endCenter: center,
        endRadius: radius,
        options: []
    )
}

func drawAcousticField(slide: Slide, in rect: CGRect) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    ctx.saveGState()
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    switch slide.background {
    case .studioGradient:
        drawSoundBand(in: rect, baseY: rect.maxY - 760, height: 360,
                      amplitude: 78, wavelength: 620, phase: 40,
                      color: hex("#4FC8B3"), alpha: 0.075)
        drawSoundBand(in: rect, baseY: rect.minY + 360, height: 520,
                      amplitude: 96, wavelength: 540, phase: 130,
                      color: hex("#E4A45A"), alpha: 0.105)
        drawTopographicContours(center: CGPoint(x: rect.maxX - 120, y: rect.maxY - 300),
                                color: hex("#80DEC9"), count: 5,
                                baseRadius: 118, gap: 62, alpha: 0.065,
                                lineWidth: 2.4, angle: -0.28)
        for i in 0..<7 {
            drawWaveRibbon(
                in: rect,
                baseY: rect.minY + 520 + CGFloat(i) * 86,
                amplitude: 34 + CGFloat(i % 3) * 10,
                wavelength: 360 + CGFloat(i) * 34,
                phase: CGFloat(i) * 62,
                color: i % 2 == 0 ? slide.accent : hex("#5ED0BA"),
                alpha: 0.13 - CGFloat(i) * 0.008,
                lineWidth: 5 - CGFloat(i % 2)
            )
        }
        drawOrbitalRings(center: CGPoint(x: rect.midX, y: rect.minY + 660),
                         color: slide.accent, count: 4, baseRadius: 250,
                         gap: 86, alpha: 0.12, lineWidth: 3.5,
                         angle: -0.14, flattening: 0.42)

    case .spatialGradient, .duskGradient:
        drawSoundBand(in: rect, baseY: rect.minY + 620, height: 610,
                      amplitude: 92, wavelength: 700, phase: 10,
                      color: hex("#54C8B7"), alpha: 0.070)
        drawSoundBand(in: rect, baseY: rect.maxY - 700, height: 360,
                      amplitude: 64, wavelength: 570, phase: 190,
                      color: slide.accent, alpha: 0.060)
        drawOrbitalRings(center: CGPoint(x: rect.midX + 70, y: rect.midY + 40),
                         color: slide.accent, count: 7, baseRadius: 220,
                         gap: 92, alpha: 0.16, lineWidth: 4,
                         angle: -0.22, flattening: 0.38)
        drawOrbitalRings(center: CGPoint(x: rect.minX + 215, y: rect.minY + 530),
                         color: hex("#65D8C3"), count: 4, baseRadius: 150,
                         gap: 74, alpha: 0.10, lineWidth: 3,
                         angle: 0.34, flattening: 0.58)
        for i in 0..<4 {
            drawWaveRibbon(
                in: rect,
                baseY: rect.maxY - 510 - CGFloat(i) * 110,
                amplitude: 24,
                wavelength: 430 + CGFloat(i) * 70,
                phase: CGFloat(i) * 95,
                color: hex("#FFFFFF"),
                alpha: 0.045,
                lineWidth: 3
            )
        }

    case .sageMist, .creamRadial:
        drawSoundBand(in: rect, baseY: rect.midY - 120, height: 520,
                      amplitude: 58, wavelength: 650, phase: 100,
                      color: slide.accent, alpha: 0.065)
        drawSoundBand(in: rect, baseY: rect.minY + 320, height: 420,
                      amplitude: 46, wavelength: 520, phase: 220,
                      color: hex("#85A884"), alpha: 0.052)
        drawTopographicContours(center: CGPoint(x: rect.maxX - 210, y: rect.maxY - 510),
                                color: slide.accent, count: 9,
                                baseRadius: 105, gap: 58, alpha: 0.105,
                                lineWidth: 2.6, angle: -0.20)
        drawTopographicContours(center: CGPoint(x: rect.minX + 160, y: rect.minY + 600),
                                color: hex("#7EA887"), count: 6,
                                baseRadius: 92, gap: 54, alpha: 0.075,
                                lineWidth: 2.2, angle: 0.28)
        for i in 0..<4 {
            drawWaveRibbon(
                in: rect,
                baseY: rect.minY + 780 + CGFloat(i) * 148,
                amplitude: 18 + CGFloat(i) * 4,
                wavelength: 520,
                phase: CGFloat(i) * 110,
                color: slide.accent,
                alpha: 0.055,
                lineWidth: 2.4
            )
        }

    case .midnightCopper, .warmGradient:
        drawSoundBand(in: rect, baseY: rect.minY + 390, height: 520,
                      amplitude: 82, wavelength: 610, phase: 40,
                      color: slide.accent, alpha: 0.095)
        drawSoundBand(in: rect, baseY: rect.maxY - 760, height: 380,
                      amplitude: 72, wavelength: 590, phase: 210,
                      color: hex("#9D6BFF"), alpha: 0.038)
        drawOrbitalRings(center: CGPoint(x: rect.midX, y: rect.minY + 560),
                         color: slide.accent, count: 5, baseRadius: 190,
                         gap: 84, alpha: 0.13, lineWidth: 3.6,
                         angle: 0.16, flattening: 0.46)
        for i in 0..<6 {
            drawWaveRibbon(
                in: rect,
                baseY: rect.minY + 430 + CGFloat(i) * 92,
                amplitude: 28,
                wavelength: 390 + CGFloat(i) * 38,
                phase: CGFloat(i) * 80,
                color: i % 2 == 0 ? slide.accent : hex("#FFFFFF"),
                alpha: i % 2 == 0 ? 0.12 : 0.05,
                lineWidth: 3.2
            )
        }
    }

    ctx.restoreGState()
}

func drawSoundBand(in rect: CGRect, baseY: CGFloat, height: CGFloat,
                   amplitude: CGFloat, wavelength: CGFloat, phase: CGFloat,
                   color: NSColor, alpha: CGFloat) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let left = rect.minX - 220
    let right = rect.maxX + 220
    let step: CGFloat = 34
    let path = CGMutablePath()

    var x = left
    var first = true
    while x <= right {
        let p = (x + phase) / wavelength
        let y = baseY
            + sin(p * .pi * 2) * amplitude
            + sin(p * .pi * 4.8) * amplitude * 0.12
        if first {
            path.move(to: CGPoint(x: x, y: y))
            first = false
        } else {
            path.addLine(to: CGPoint(x: x, y: y))
        }
        x += step
    }

    x = right
    while x >= left {
        let p = (x + phase + 180) / wavelength
        let y = baseY - height
            + sin(p * .pi * 2) * amplitude * 0.64
            + sin(p * .pi * 4.1) * amplitude * 0.10
        path.addLine(to: CGPoint(x: x, y: y))
        x -= step
    }
    path.closeSubpath()

    ctx.saveGState()
    ctx.addPath(path)
    ctx.setFillColor(color.withAlphaComponent(alpha).cgColor)
    ctx.fillPath()
    ctx.restoreGState()
}

func drawWaveRibbon(in rect: CGRect, baseY: CGFloat, amplitude: CGFloat,
                    wavelength: CGFloat, phase: CGFloat, color: NSColor,
                    alpha: CGFloat, lineWidth: CGFloat) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let path = CGMutablePath()
    let left = rect.minX - 180
    let right = rect.maxX + 180
    let step: CGFloat = 28
    var x = left
    var isFirst = true
    while x <= right {
        let p = (x + phase) / wavelength
        let y = baseY
            + sin(p * .pi * 2) * amplitude
            + sin(p * .pi * 5.3) * amplitude * 0.18
        if isFirst {
            path.move(to: CGPoint(x: x, y: y))
            isFirst = false
        } else {
            path.addLine(to: CGPoint(x: x, y: y))
        }
        x += step
    }
    ctx.saveGState()
    ctx.addPath(path)
    ctx.setLineWidth(lineWidth)
    ctx.setStrokeColor(color.withAlphaComponent(alpha).cgColor)
    ctx.strokePath()
    ctx.restoreGState()
}

func drawOrbitalRings(center: CGPoint, color: NSColor, count: Int,
                      baseRadius: CGFloat, gap: CGFloat, alpha: CGFloat,
                      lineWidth: CGFloat, angle: CGFloat, flattening: CGFloat) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    for i in 0..<count {
        let radius = baseRadius + CGFloat(i) * gap
        ctx.saveGState()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: angle)
        ctx.scaleBy(x: 1, y: flattening)
        ctx.setLineWidth(lineWidth)
        ctx.setStrokeColor(color.withAlphaComponent(max(0.02, alpha - CGFloat(i) * 0.013)).cgColor)
        ctx.strokeEllipse(in: CGRect(x: -radius, y: -radius,
                                     width: radius * 2, height: radius * 2))
        ctx.restoreGState()
    }
}

func drawTopographicContours(center: CGPoint, color: NSColor, count: Int,
                             baseRadius: CGFloat, gap: CGFloat, alpha: CGFloat,
                             lineWidth: CGFloat, angle: CGFloat) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    for i in 0..<count {
        let radius = baseRadius + CGFloat(i) * gap
        ctx.saveGState()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: angle + CGFloat(i).truncatingRemainder(dividingBy: 2) * 0.045)
        ctx.scaleBy(x: 1.08, y: 0.62)
        ctx.setLineWidth(lineWidth)
        ctx.setStrokeColor(color.withAlphaComponent(max(0.018, alpha - CGFloat(i) * 0.008)).cgColor)
        ctx.strokeEllipse(in: CGRect(x: -radius, y: -radius,
                                     width: radius * 2, height: radius * 2))
        ctx.restoreGState()
    }
}

/// Very fine film grain — adds tactile quality that stops the background
/// reading as "flat vector fill".
func drawGrainOverlay(in rect: CGRect, opacity: CGFloat) {
    let ci = CIContext(options: nil)
    let filter = CIFilter(name: "CIRandomGenerator")!
    guard let image = filter.outputImage?.cropped(to: CGRect(origin: .zero, size: rect.size))
    else { return }
    let monoMatrix = CIFilter(name: "CIColorMatrix")!
    monoMatrix.setValue(image, forKey: kCIInputImageKey)
    monoMatrix.setValue(CIVector(x: 0.3, y: 0.3, z: 0.3, w: 0), forKey: "inputRVector")
    monoMatrix.setValue(CIVector(x: 0.3, y: 0.3, z: 0.3, w: 0), forKey: "inputGVector")
    monoMatrix.setValue(CIVector(x: 0.3, y: 0.3, z: 0.3, w: 0), forKey: "inputBVector")
    monoMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: opacity), forKey: "inputAVector")
    monoMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
    guard let output = monoMatrix.outputImage,
          let cg = ci.createCGImage(output, from: output.extent)
    else { return }
    NSGraphicsContext.current?.cgContext.draw(cg, in: rect)
}

func drawVignette(in rect: CGRect, darkness: CGFloat) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let cs = CGColorSpaceCreateDeviceRGB()
    let grad = CGGradient(
        colorsSpace: cs,
        colors: [
            NSColor.black.withAlphaComponent(0.0).cgColor,
            NSColor.black.withAlphaComponent(darkness).cgColor
        ] as CFArray,
        locations: [0.55, 1]
    )!
    ctx.drawRadialGradient(
        grad,
        startCenter: CGPoint(x: rect.midX, y: rect.midY),
        startRadius: 0,
        endCenter:   CGPoint(x: rect.midX, y: rect.midY),
        endRadius:   hypot(rect.width, rect.height) / 2,
        options: [.drawsAfterEndLocation]
    )
}

// ──────────────────────────────────────────────────────────────────────────
// MARK: Device mockup — Apple's official iPhone 17 Pro Max bezel overlay
//
// Uses the PNG bezel shipped in Apple's Design Resources (licensed for iOS
// app mock-ups, which App Store screenshots explicitly are).
//
//   · Bezel PNG    : 1470 × 3000, with transparent screen area centered
//   · Screen inset : 75 px horizontal, 66 px vertical at native bezel size
//   · Screen inner : matches the capture native 1320 × 2868
//
// Any `rect` passed in is treated as the outer bezel rect, so its width/height
// must follow the 1470:3000 aspect. The helper `Tokens.bezelHeight(for:)` does
// this conversion.
// ──────────────────────────────────────────────────────────────────────────

let BEZEL_SIZE = CGSize(width: 1470, height: 3000)
let BEZEL_SCREEN_INSET_X: CGFloat = 75   // horizontal bezel thickness
let BEZEL_SCREEN_INSET_Y: CGFloat = 66   // vertical bezel thickness

func loadBezel() -> NSImage? {
    let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let url = repoRoot.appendingPathComponent(CONTENT.bezelImage)
    return NSImage(contentsOf: url)
}

let _cachedBezel: NSImage? = loadBezel()

func drawDevice(_ capture: NSImage, slide: Slide, rect: CGRect, clipToCanvas: Bool) {
    guard let bezel = _cachedBezel else {
        print("⚠️ bezel PNG not found; falling back to plain capture")
        capture.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
        return
    }

    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let w = rect.width

    // Build an offscreen composite of capture + bezel so the shadow casts from
    // the FULL iPhone silhouette (not a hand-picked rounded rect that may be
    // slightly off from Apple's actual body curvature).
    let scale = w / BEZEL_SIZE.width
    let screenInsetX = BEZEL_SCREEN_INSET_X * scale
    let screenInsetY = BEZEL_SCREEN_INSET_Y * scale

    let composite = NSImage(size: rect.size)
    composite.lockFocus()
    let localRect = CGRect(origin: .zero, size: rect.size)
    let localScreenRect = localRect.insetBy(dx: screenInsetX, dy: screenInsetY)
    let screenRadius = w * 0.115

    // Fill the screen area (with rounded-corner clip) with opaque black so
    // any sub-pixel seam between capture and bezel reads as iPhone bezel, not
    // as background bleeding through.
    NSGraphicsContext.current?.cgContext.saveGState()
    NSBezierPath(roundedRect: localScreenRect,
                 xRadius: screenRadius, yRadius: screenRadius).addClip()
    NSColor.black.setFill()
    NSBezierPath(rect: localScreenRect).fill()
    capture.draw(in: localScreenRect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.current?.cgContext.restoreGState()

    bezel.draw(in: localRect, from: .zero, operation: .sourceOver, fraction: 1)
    composite.unlockFocus()

    // Now draw the composite once, with a two-layer shadow. The shadow is cast
    // from the composite's alpha, which matches Apple's bezel silhouette
    // exactly — no pale halo, no corner overshoot.
    ctx.saveGState()
    let ambient = NSShadow()
    let isDark = !slide.darkText
    ambient.shadowColor = (isDark
        ? NSColor.black.withAlphaComponent(0.55)
        : slide.accent.blended(withFraction: 0.78, of: .black)!.withAlphaComponent(0.28))
    ambient.shadowBlurRadius = 120
    ambient.shadowOffset = CGSize(width: 0, height: -40)
    ambient.set()
    composite.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    ctx.restoreGState()

    ctx.saveGState()
    let contact = NSShadow()
    contact.shadowColor = NSColor.black.withAlphaComponent(0.40)
    contact.shadowBlurRadius = 28
    contact.shadowOffset = CGSize(width: 0, height: -10)
    contact.set()
    composite.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    ctx.restoreGState()

    _ = clipToCanvas
}

// ──────────────────────────────────────────────────────────────────────────
// MARK: Icon
// ──────────────────────────────────────────────────────────────────────────

func drawIcon(symbolName: String, accent: NSColor, centreX: CGFloat, topY: CGFloat) {
    guard !symbolName.isEmpty else { return }
    let config = NSImage.SymbolConfiguration(pointSize: Tokens.iconSize, weight: .semibold)
    let base = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
        .withSymbolConfiguration(config)
        ?? NSImage(size: CGSize(width: Tokens.iconSize, height: Tokens.iconSize))
    let tinted = NSImage(size: base.size)
    tinted.lockFocus()
    base.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1)
    accent.setFill()
    NSRect(origin: .zero, size: base.size).fill(using: .sourceAtop)
    tinted.unlockFocus()
    let x = centreX - tinted.size.width / 2
    let y = Tokens.canvasSize.height - topY - tinted.size.height
    tinted.draw(at: CGPoint(x: x, y: y), from: .zero, operation: .sourceOver, fraction: 1)
}

// ──────────────────────────────────────────────────────────────────────────
// MARK: Text
// ──────────────────────────────────────────────────────────────────────────

func headlineAttributes(size: CGFloat, ink: NSColor) -> [NSAttributedString.Key: Any] {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineHeightMultiple = Tokens.headlineLeading
    return [
        .font: displayFont(size, weight: .heavy),
        .foregroundColor: ink,
        .kern: size * Tokens.headlineKerning,
        .paragraphStyle: paragraph
    ]
}

func subheadAttributes(ink: NSColor) -> [NSAttributedString.Key: Any] {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineHeightMultiple = Tokens.subheadLeading
    return [
        .font: displayFont(Tokens.subheadSize, weight: .medium),
        .foregroundColor: ink.withAlphaComponent(0.80),
        .paragraphStyle: paragraph
    ]
}

func eyebrowAttributes(slide: Slide) -> [NSAttributedString.Key: Any] {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineBreakMode = .byClipping
    return [
        .font: displayFont(Tokens.eyebrowSize, weight: .medium),
        .foregroundColor: slide.darkText
            ? slide.accent.withAlphaComponent(0.92)
            : slide.accent.blended(withFraction: 0.26, of: .white)!.withAlphaComponent(0.94),
        .kern: Tokens.eyebrowKerning,
        .paragraphStyle: paragraph
    ]
}

func measureText(_ text: String, width: CGFloat,
                 attributes: [NSAttributedString.Key: Any]) -> CGFloat {
    let bounding = NSString(string: text).boundingRect(
        with: CGSize(width: width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: attributes
    )
    return ceil(bounding.height)
}

func pickHeadlineSize(_ text: String, width: CGFloat, maxHeight: CGFloat,
                      ink: NSColor) -> CGFloat {
    for s in Tokens.headlineStepSizes {
        if measureText(text, width: width,
                       attributes: headlineAttributes(size: s, ink: ink)) <= maxHeight {
            return s
        }
    }
    return Tokens.headlineStepSizes.last!
}

func drawText(_ text: String, attributes: [NSAttributedString.Key: Any],
              at topY: CGFloat, width: CGFloat, height: CGFloat) {
    let x = (Tokens.canvasSize.width - width) / 2
    let y = Tokens.canvasSize.height - topY - height
    let rect = CGRect(x: x, y: y, width: width, height: height)
    NSString(string: text).draw(with: rect,
                                options: [.usesLineFragmentOrigin, .usesFontLeading],
                                attributes: attributes)
}

func normalizedEyebrow(_ copy: Copy) -> String? {
    let value = copy.eyebrow?.trimmingCharacters(in: .whitespacesAndNewlines)
    return (value?.isEmpty ?? true) ? nil : value
}

func drawMarker(slide: Slide, copy: Copy, topY: CGFloat) {
    if let eyebrow = normalizedEyebrow(copy) {
        let attrs = eyebrowAttributes(slide: slide)
        drawText(eyebrow,
                 attributes: attrs,
                 at: topY,
                 width: Tokens.canvasSize.width - 2 * Tokens.textSideMargin,
                 height: measureText(eyebrow,
                                     width: Tokens.canvasSize.width - 2 * Tokens.textSideMargin,
                                     attributes: attrs))
    } else {
        drawIcon(symbolName: slide.iconSymbol, accent: slide.accent,
                 centreX: Tokens.canvasSize.width / 2, topY: topY)
    }
}

func markerHeight(slide: Slide, copy: Copy) -> CGFloat {
    guard let eyebrow = normalizedEyebrow(copy) else { return Tokens.iconSize }
    return measureText(eyebrow,
                       width: Tokens.canvasSize.width - 2 * Tokens.textSideMargin,
                       attributes: eyebrowAttributes(slide: slide))
}

func markerToHeadlineGap(copy: Copy) -> CGFloat {
    normalizedEyebrow(copy) == nil ? Tokens.iconToHeadlineGap : Tokens.eyebrowToHeadlineGap
}

// ──────────────────────────────────────────────────────────────────────────
// MARK: Layout compositors
// ──────────────────────────────────────────────────────────────────────────

func composePosterLayout(slide: Slide, copy: Copy, capture: NSImage) {
    let ink = slide.darkText ? Tokens.inkDark : Tokens.inkLight
    let textWidth = Tokens.canvasSize.width - 2 * Tokens.textSideMargin
    let aspect = Tokens.bezelAspect
    let markerH = markerHeight(slide: slide, copy: copy)
    let markerGap = markerToHeadlineGap(copy: copy)

    let subheadH = measureText(copy.subhead, width: textWidth,
                               attributes: subheadAttributes(ink: ink))
    let textBudget = Tokens.canvasSize.height * 0.30
    let headlineBudget = textBudget
        - markerH
        - markerGap
        - Tokens.headlineToSubheadGap
        - subheadH
    let size = pickHeadlineSize(copy.headline, width: textWidth,
                                maxHeight: max(headlineBudget, 82), ink: ink)
    let headlineH = measureText(copy.headline, width: textWidth,
                                attributes: headlineAttributes(size: size, ink: ink))
    let textBlockH = markerH
        + markerGap
        + headlineH
        + Tokens.headlineToSubheadGap
        + subheadH

    // Poster slides intentionally crop the phone slightly below the canvas,
    // giving the first frame the confidence of a product ad instead of a
    // centered template.
    let maxBottomCrop: CGFloat = 220
    let deviceBudget = Tokens.canvasSize.height
        + maxBottomCrop
        - Tokens.posterLayout_topPadding
        - textBlockH
        - Tokens.posterLayout_gap
    let mockupW = min(Tokens.deviceWidth_poster, deviceBudget / aspect)
    let mockupH = mockupW * aspect

    let markerTopY = Tokens.posterLayout_topPadding
    let headlineTopY = markerTopY + markerH + markerGap
    let subheadTopY = headlineTopY + headlineH + Tokens.headlineToSubheadGap
    let deviceTopY = subheadTopY + subheadH + Tokens.posterLayout_gap

    drawMarker(slide: slide, copy: copy, topY: markerTopY)
    drawText(copy.headline,
             attributes: headlineAttributes(size: size, ink: ink),
             at: headlineTopY, width: textWidth, height: headlineH)
    drawText(copy.subhead,
             attributes: subheadAttributes(ink: ink),
             at: subheadTopY, width: textWidth, height: subheadH)

    let deviceX = (Tokens.canvasSize.width - mockupW) / 2
    let deviceY = Tokens.canvasSize.height - deviceTopY - mockupH
    drawDevice(capture, slide: slide,
               rect: CGRect(x: deviceX, y: deviceY, width: mockupW, height: mockupH),
               clipToCanvas: true)
}

func composeTopLayout(slide: Slide, copy: Copy, capture: NSImage) {
    let ink = slide.darkText ? Tokens.inkDark : Tokens.inkLight
    let textWidth = Tokens.canvasSize.width - 2 * Tokens.textSideMargin
    let aspect = Tokens.bezelAspect
    let markerH = markerHeight(slide: slide, copy: copy)
    let markerGap = markerToHeadlineGap(copy: copy)

    // Text budget: up to 32% of canvas height for top layout.
    let textBudget = Tokens.canvasSize.height * 0.32
    let subheadH = measureText(copy.subhead, width: textWidth,
                               attributes: subheadAttributes(ink: ink))
    let headlineBudget = textBudget
        - markerH
        - markerGap
        - Tokens.headlineToSubheadGap
        - subheadH
    let size = pickHeadlineSize(copy.headline, width: textWidth,
                                maxHeight: max(headlineBudget, 60), ink: ink)
    let headlineH = measureText(copy.headline, width: textWidth,
                                attributes: headlineAttributes(size: size, ink: ink))
    let textBlockH = markerH
        + markerGap
        + headlineH
        + Tokens.headlineToSubheadGap
        + subheadH

    // Device fills the rest, capped at max width.
    let deviceBudget = Tokens.canvasSize.height
        - Tokens.topLayout_topPadding
        - textBlockH
        - Tokens.topLayout_gap
        - 30 // bottom safety
    let mockupW = min(Tokens.deviceWidth_top, deviceBudget / aspect)
    let mockupH = mockupW * aspect

    let markerTopY = Tokens.topLayout_topPadding
    let headlineTopY = markerTopY + markerH + markerGap
    let subheadTopY = headlineTopY + headlineH + Tokens.headlineToSubheadGap
    let deviceTopY = subheadTopY + subheadH + Tokens.topLayout_gap

    drawMarker(slide: slide, copy: copy, topY: markerTopY)
    drawText(copy.headline,
             attributes: headlineAttributes(size: size, ink: ink),
             at: headlineTopY, width: textWidth, height: headlineH)
    drawText(copy.subhead,
             attributes: subheadAttributes(ink: ink),
             at: subheadTopY, width: textWidth, height: subheadH)

    let deviceX = (Tokens.canvasSize.width - mockupW) / 2
    let deviceY = Tokens.canvasSize.height - deviceTopY - mockupH
    drawDevice(capture, slide: slide,
               rect: CGRect(x: deviceX, y: deviceY, width: mockupW, height: mockupH),
               clipToCanvas: false)
}

func composeBottomLayout(slide: Slide, copy: Copy, capture: NSImage) {
    let ink = slide.darkText ? Tokens.inkDark : Tokens.inkLight
    let textWidth = Tokens.canvasSize.width - 2 * Tokens.textSideMargin
    let aspect = Tokens.bezelAspect
    let markerH = markerHeight(slide: slide, copy: copy)
    let markerGap = markerToHeadlineGap(copy: copy)

    // Size text first using a budget of 32% of canvas height.
    let textBudget = Tokens.canvasSize.height * 0.32
    let subheadH = measureText(copy.subhead, width: textWidth,
                               attributes: subheadAttributes(ink: ink))
    let headlineBudget = textBudget - markerH - markerGap - Tokens.headlineToSubheadGap - subheadH
    let size = pickHeadlineSize(copy.headline, width: textWidth,
                                maxHeight: max(headlineBudget, 60), ink: ink)
    let headlineH = measureText(copy.headline, width: textWidth,
                                attributes: headlineAttributes(size: size, ink: ink))
    let textBlockH = markerH + markerGap + headlineH + Tokens.headlineToSubheadGap + subheadH

    // Device shrinks if needed to keep text inside the canvas.
    let deviceBudget = Tokens.canvasSize.height
        - Tokens.bottomLayout_topPadding
        - Tokens.bottomLayout_gap
        - Tokens.bottomLayout_bottomPadding
        - textBlockH
    let mockupW = min(Tokens.deviceWidth_bottom, deviceBudget / aspect)
    let mockupH = mockupW * aspect

    let deviceTopY = Tokens.bottomLayout_topPadding
    let textBlockTopY = deviceTopY + mockupH + Tokens.bottomLayout_gap

    let deviceX = (Tokens.canvasSize.width - mockupW) / 2
    let deviceY = Tokens.canvasSize.height - deviceTopY - mockupH
    drawDevice(capture, slide: slide,
               rect: CGRect(x: deviceX, y: deviceY, width: mockupW, height: mockupH),
               clipToCanvas: false)

    let markerTopY = textBlockTopY
    let headlineTopY = markerTopY + markerH + markerGap
    let subheadTopY = headlineTopY + headlineH + Tokens.headlineToSubheadGap

    drawMarker(slide: slide, copy: copy, topY: markerTopY)
    drawText(copy.headline,
             attributes: headlineAttributes(size: size, ink: ink),
             at: headlineTopY, width: textWidth, height: headlineH)
    drawText(copy.subhead,
             attributes: subheadAttributes(ink: ink),
             at: subheadTopY, width: textWidth, height: subheadH)
}

func composeBleedLayout(slide: Slide, copy: Copy, capture: NSImage) {
    let ink = slide.darkText ? Tokens.inkDark : Tokens.inkLight
    let textWidth = Tokens.canvasSize.width - 2 * Tokens.textSideMargin
    let aspect = Tokens.bezelAspect
    let bleedGap: CGFloat = 34
    let markerH = markerHeight(slide: slide, copy: copy)
    let markerGap = markerToHeadlineGap(copy: copy)

    // Compact text budget: 20% of canvas height.
    let textBudget = Tokens.canvasSize.height * 0.20
    let subheadH = measureText(copy.subhead, width: textWidth,
                               attributes: subheadAttributes(ink: ink))
    let headlineBudget = textBudget - markerH - markerGap - Tokens.headlineToSubheadGap - subheadH
    let size = pickHeadlineSize(copy.headline, width: textWidth,
                                maxHeight: max(headlineBudget, 60), ink: ink)
    let headlineH = measureText(copy.headline, width: textWidth,
                                attributes: headlineAttributes(size: size, ink: ink))
    let textBlockH = markerH + markerGap + headlineH + Tokens.headlineToSubheadGap + subheadH

    let deviceBudget = Tokens.canvasSize.height
        - Tokens.bleedLayout_topPadding
        - bleedGap
        - Tokens.bleedLayout_bottomPadding
        - textBlockH
    let mockupW = min(Tokens.deviceWidth_bleed, deviceBudget / aspect)
    let mockupH = mockupW * aspect

    let deviceTopY = Tokens.bleedLayout_topPadding
    let deviceX = (Tokens.canvasSize.width - mockupW) / 2
    let deviceY = Tokens.canvasSize.height - deviceTopY - mockupH
    let textBlockTopY = deviceTopY + mockupH + bleedGap

    drawDevice(capture, slide: slide,
               rect: CGRect(x: deviceX, y: deviceY, width: mockupW, height: mockupH),
               clipToCanvas: false)

    let markerTopY = textBlockTopY
    let headlineTopY = markerTopY + markerH + markerGap
    let subheadTopY = headlineTopY + headlineH + Tokens.headlineToSubheadGap
    drawMarker(slide: slide, copy: copy, topY: markerTopY)
    drawText(copy.headline,
             attributes: headlineAttributes(size: size, ink: ink),
             at: headlineTopY, width: textWidth, height: headlineH)
    drawText(copy.subhead,
             attributes: subheadAttributes(ink: ink),
             at: subheadTopY, width: textWidth, height: subheadH)
}

/// PeekBottom: text at top (icon + headline + subhead), then device positioned
/// so its TOP sits at `peekLayout_topPadding + textHeight + peekLayout_gap`,
/// but its height extends beyond the canvas bottom by `peekLayout_deviceOverflow`.
/// Effect: we see ONLY the top ~70-75% of the phone → zoomed feel on the
/// interesting sheet/popover at the top of the capture.
func composePeekBottomLayout(slide: Slide, copy: Copy, capture: NSImage) {
    let ink = slide.darkText ? Tokens.inkDark : Tokens.inkLight
    let textWidth = Tokens.canvasSize.width - 2 * Tokens.textSideMargin
    let mockupW = Tokens.deviceWidth_peekBottom
    let mockupH = mockupW * Tokens.bezelAspect

    // Text block at top.
    let markerH = markerHeight(slide: slide, copy: copy)
    let markerGap = markerToHeadlineGap(copy: copy)
    let subheadH = measureText(copy.subhead, width: textWidth,
                               attributes: subheadAttributes(ink: ink))
    // Text block cap: keep top text compact so the device dominates.
    let textCapH = Tokens.canvasSize.height * 0.30
    let headlineBudget = textCapH - markerH - markerGap - Tokens.headlineToSubheadGap - subheadH
    let size = pickHeadlineSize(copy.headline, width: textWidth,
                                maxHeight: max(headlineBudget, 60), ink: ink)
    let headlineH = measureText(copy.headline, width: textWidth,
                                attributes: headlineAttributes(size: size, ink: ink))

    let markerTopY = Tokens.peekLayout_topPadding
    let headlineTopY = markerTopY + markerH + markerGap
    let subheadTopY = headlineTopY + headlineH + Tokens.headlineToSubheadGap
    let deviceTopY = subheadTopY + subheadH + Tokens.peekLayout_gap

    drawMarker(slide: slide, copy: copy, topY: markerTopY)
    drawText(copy.headline,
             attributes: headlineAttributes(size: size, ink: ink),
             at: headlineTopY, width: textWidth, height: headlineH)
    drawText(copy.subhead,
             attributes: subheadAttributes(ink: ink),
             at: subheadTopY, width: textWidth, height: subheadH)

    let deviceX = (Tokens.canvasSize.width - mockupW) / 2
    // Device overflows the bottom: deviceY can be negative.
    let deviceY = Tokens.canvasSize.height - deviceTopY - mockupH
    drawDevice(capture, slide: slide,
               rect: CGRect(x: deviceX, y: deviceY, width: mockupW, height: mockupH),
               clipToCanvas: true)
}

// ──────────────────────────────────────────────────────────────────────────
// MARK: Pipeline
// ──────────────────────────────────────────────────────────────────────────

func renderSlide(slide: Slide, copy: Copy, inputURL: URL,
                 outputURL: URL, previewURL: URL) throws {
    guard let capture = NSImage(contentsOf: inputURL) else {
        throw NSError(
            domain: "oasis.generate_store_screenshot_comps",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Missing capture \(inputURL.path)"]
        )
    }

    let w = Int(Tokens.canvasSize.width)
    let h = Int(Tokens.canvasSize.height)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: w, pixelsHigh: h,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [], bytesPerRow: 0, bitsPerPixel: 32
    ) else {
        throw NSError(
            domain: "oasis.generate_store_screenshot_comps", code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Bitmap alloc failed"]
        )
    }
    bitmap.size = Tokens.canvasSize

    let gc = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = gc

    // Clip drawing to the canvas so overflow (peekBottom) doesn't smear
    // shadows over the surrounding filesystem.
    let clipPath = NSBezierPath(rect: CGRect(origin: .zero, size: Tokens.canvasSize))
    clipPath.addClip()

    drawBackground(slide: slide)

    switch slide.layout {
    case .poster:     composePosterLayout(slide: slide, copy: copy, capture: capture)
    case .top:        composeTopLayout(slide: slide, copy: copy, capture: capture)
    case .bottom:     composeBottomLayout(slide: slide, copy: copy, capture: capture)
    case .bleed:      composeBleedLayout(slide: slide, copy: copy, capture: capture)
    case .peekBottom: composePeekBottomLayout(slide: slide, copy: copy, capture: capture)
    }

    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .jpeg,
                                           properties: [.compressionFactor: 0.92]) else {
        throw NSError(
            domain: "oasis.generate_store_screenshot_comps", code: 2,
            userInfo: [NSLocalizedDescriptionKey: "JPEG encode failed"]
        )
    }
    try data.write(to: outputURL)

    // Preview: downscale to fit Tokens.previewSize (≤2000px per side).
    guard let cg = bitmap.cgImage else { return }
    let pw = Int(Tokens.previewSize.width)
    let ph = Int(Tokens.previewSize.height)
    guard let previewBitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pw, pixelsHigh: ph,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [], bytesPerRow: 0, bitsPerPixel: 32
    ) else { return }
    previewBitmap.size = Tokens.previewSize
    let previewCtx = NSGraphicsContext(bitmapImageRep: previewBitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = previewCtx
    previewCtx.imageInterpolation = .high
    let previewRect = CGRect(origin: .zero, size: Tokens.previewSize)
    NSGraphicsContext.current?.cgContext.draw(cg, in: previewRect)
    NSGraphicsContext.restoreGraphicsState()
    if let previewData = previewBitmap.representation(
        using: .jpeg, properties: [.compressionFactor: 0.85]) {
        try previewData.write(to: previewURL)
    }
}

// ──────────────────────────────────────────────────────────────────────────
// MARK: Entry point
// ──────────────────────────────────────────────────────────────────────────

var onlySlug: String? = nil
var onlyLang: String? = nil
var args = Array(CommandLine.arguments.dropFirst())
while !args.isEmpty {
    let a = args.removeFirst()
    switch a {
    case "--only":
        onlySlug = args.isEmpty ? nil : args.removeFirst()
    case "--lang":
        onlyLang = args.isEmpty ? nil : args.removeFirst()
    default:
        break
    }
}

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let screenshotsRoot = repoRoot.appendingPathComponent(CONTENT.capturesDir)

var produced = 0
var skipped: [String] = []

let languages = onlyLang.map { [$0] } ?? Array(COPY.keys).sorted()

for language in languages {
    guard let localisedCopy = COPY[language] else {
        skipped.append("\(language) — no copy entries")
        continue
    }
    let langDir = screenshotsRoot.appendingPathComponent(language)
    let outputDir = langDir.appendingPathComponent("figma-pro")
    let previewDir = langDir.appendingPathComponent("figma-pro/preview")
    try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: previewDir, withIntermediateDirectories: true)

    for slide in SLIDES {
        if let only = onlySlug, slide.slug != only { continue }
        guard let copy = localisedCopy[slide.slug] else {
            skipped.append("\(language)/\(slide.slug) — no copy entry")
            continue
        }
        let inputURL = langDir.appendingPathComponent("\(CONTENT.capturePrefix)\(slide.source)")
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            skipped.append("\(language)/\(slide.slug) — missing capture")
            continue
        }
        let outputURL = outputDir.appendingPathComponent("\(slide.slug).jpg")
        let previewURL = previewDir.appendingPathComponent("\(slide.slug).jpg")
        try renderSlide(slide: slide, copy: copy,
                        inputURL: inputURL,
                        outputURL: outputURL,
                        previewURL: previewURL)
        produced += 1
        print("✓ \(language)/\(slide.slug).jpg")
    }
}

print("\nProduced \(produced) composites.")
if !skipped.isEmpty {
    print("Skipped:")
    for s in skipped { print("  - \(s)") }
}
