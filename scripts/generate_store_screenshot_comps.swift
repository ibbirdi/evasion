// Oasis — App Store screenshot composer
//
// Content (slide catalogue + localized copy + bezel image path) lives in
// `scripts/screenshot_content.json`. Edit that file to add a language, tweak
// headlines, swap images, or change per-slide layouts and accent colors —
// no Swift changes needed.
//
// Canvas: 1320 × 2868.
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
    case coastalSand       // soft beach palette inspired by Pok Rie's Pexels shoreline
}

enum RenderStyle: String {
    case dynamic
    case classic
}

enum SceneMood: String, Codable {
    case aurora
    case mist
    case violet
    case copper
    case dawn
    case lagoon
    case graphite
    case coast
}

enum TextAlignmentToken: String, Codable {
    case left
    case center
    case right
}

enum SceneShadow: String, Codable {
    case soft
    case lifted
    case deep
    case glow
}

struct SceneTextConfig: Codable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let align: TextAlignmentToken?
    let tone: String?
}

struct SceneDeviceConfig: Codable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let rotation: CGFloat?
    let opacity: CGFloat?
}

struct DynamicSceneConfig: Codable {
    let mood: SceneMood?
    let text: SceneTextConfig?
    let device: SceneDeviceConfig?
}

struct ExtractedAssetMetadata: Codable {
    struct Padding: Codable {
        let horizontal: CGFloat
        let vertical: CGFloat
    }

    struct Rect: Codable {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat

        private enum CodingKeys: String, CodingKey {
            case x, y, width, height
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            x = try container.decodeIfPresent(CGFloat.self, forKey: .x) ?? 0
            y = try container.decodeIfPresent(CGFloat.self, forKey: .y) ?? 0
            width = try container.decode(CGFloat.self, forKey: .width)
            height = try container.decode(CGFloat.self, forKey: .height)
        }
    }

    let name: String
    let elementFramePoints: Rect
    let visibleFramePoints: Rect
    let paddingPoints: Padding
    let screenPoints: Rect
}

struct AnchoredAsset {
    let name: String
    let scale: CGFloat
    let cornerRadius: CGFloat

    init(name: String, scale: CGFloat, cornerRadius: CGFloat = 64) {
        self.name = name
        self.scale = scale
        self.cornerRadius = cornerRadius
    }
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
    let scene: DynamicSceneConfig?
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
    let scene: DynamicSceneConfig?
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
        self.scene = cfg.scene
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

    static let eyebrowSize: CGFloat = 48
    static let eyebrowKerning: CGFloat = 3.6
    static let eyebrowToHeadlineGap: CGFloat = 30

    // Tight leading for punchier display type. 0.82 packs the 2-line headlines
    // (common across all 6 locales) into a cohesive block without clipping
    // descenders at the largest step sizes.
    static let headlineStepSizes: [CGFloat] = [148, 140, 132, 124, 116, 108, 100, 92, 84]
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

    // ── Dynamic v4 scene renderer
    static let dynamicEyebrowSize: CGFloat = 48
    static let dynamicEyebrowKerning: CGFloat = 4.2
    static let dynamicEyebrowToHeadlineGap: CGFloat = 16
    static let dynamicHeadlineStepSizes: [CGFloat] = [180, 172, 164, 156, 148, 140, 132, 124, 116, 108, 100, 92, 84]
    static let dynamicHeadlineLeading: CGFloat = 0.90
    static let dynamicHeadlineToSubheadGap: CGFloat = 16
    static let dynamicSubheadSize: CGFloat = 54
    static let dynamicSubheadLeading: CGFloat = 0.96
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
    let name: String
    switch weight {
    case .black, .heavy, .bold:
        name = "AvenirNext-Heavy"
    case .semibold:
        name = "AvenirNext-DemiBold"
    case .medium:
        name = "AvenirNext-Medium"
    default:
        name = "AvenirNext-Regular"
    }

    return NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size, weight: weight)
}

func headlineFont(_ size: CGFloat) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: .black)
    let condensed = NSFontManager.shared.convert(base, toHaveTrait: .condensedFontMask)
    return condensed.pointSize == size ? condensed : base
}

func color(_ value: String?, fallback: NSColor) -> NSColor {
    guard let value else { return fallback }
    return hex(value)
}

func paragraphAlignment(_ token: TextAlignmentToken?) -> NSTextAlignment {
    switch token {
    case .left: return .left
    case .center, .none: return .center
    case .right: return .right
    }
}

func topLeftRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
    CGRect(
        x: x,
        y: Tokens.canvasSize.height - y - height,
        width: width,
        height: height
    )
}

func withRotation(degrees: CGFloat, around rect: CGRect, draw: () -> Void) {
    guard abs(degrees) > 0.01,
          let ctx = NSGraphicsContext.current?.cgContext
    else {
        draw()
        return
    }

    ctx.saveGState()
    ctx.translateBy(x: rect.midX, y: rect.midY)
    ctx.rotate(by: degrees * .pi / 180)
    ctx.translateBy(x: -rect.midX, y: -rect.midY)
    draw()
    ctx.restoreGState()
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

    case .coastalSand:
        let cs = CGColorSpaceCreateDeviceRGB()
        let grad = CGGradient(
            colorsSpace: cs,
            colors: [
                hex("#E9D1BD").cgColor,
                hex("#9FB5B2").cgColor,
                hex("#DFA07D").cgColor
            ] as CFArray,
            locations: [0, 0.46, 1]
        )!
        ctx.drawLinearGradient(grad,
                               start: CGPoint(x: rect.minX, y: rect.maxY),
                               end:   CGPoint(x: rect.maxX, y: rect.minY),
                               options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        drawRadialGlow(color: hex("#F2E9DC"), center: CGPoint(x: rect.midX + 80, y: rect.maxY - 520),
                       radius: rect.width * 0.68, alpha: 0.28)
        drawRadialGlow(color: hex("#C9775E"), center: CGPoint(x: rect.minX + 240, y: rect.minY + 420),
                       radius: rect.width * 0.58, alpha: 0.20)
    }

    drawAcousticField(slide: slide, in: rect)
    drawGrainOverlay(in: rect, opacity: 0.028)
    drawVignette(in: rect, darkness: slide.darkText ? 0.14 : 0.34)
}

struct ScenePalette {
    let top: NSColor
    let middle: NSColor
    let bottom: NSColor
    let glowPrimary: NSColor
    let glowSecondary: NSColor
    let text: NSColor
    let mutedText: NSColor
    let surface: NSColor
    let hairline: NSColor
}

func palette(for mood: SceneMood, slide: Slide) -> ScenePalette {
    switch mood {
    case .aurora:
        return ScenePalette(
            top: hex("#07110F"),
            middle: hex("#103D37"),
            bottom: hex("#080A14"),
            glowPrimary: hex("#47D1B6"),
            glowSecondary: hex("#F0B866"),
            text: hex("#FFF7EA"),
            mutedText: hex("#D6E4DC"),
            surface: hex("#10201F"),
            hairline: hex("#9FE2D0")
        )
    case .mist:
        return ScenePalette(
            top: hex("#F8F1E6"),
            middle: hex("#DAECE7"),
            bottom: hex("#F0D4C5"),
            glowPrimary: slide.accent,
            glowSecondary: hex("#7ECFC1"),
            text: hex("#101724"),
            mutedText: hex("#38404A"),
            surface: hex("#F8F3EA"),
            hairline: hex("#FFFFFF")
        )
    case .violet:
        return ScenePalette(
            top: hex("#090D1D"),
            middle: hex("#163445"),
            bottom: hex("#33234D"),
            glowPrimary: slide.accent,
            glowSecondary: hex("#64D5BD"),
            text: hex("#F8F5FF"),
            mutedText: hex("#D8D0F2"),
            surface: hex("#121727"),
            hairline: hex("#CFC1FF")
        )
    case .copper:
        return ScenePalette(
            top: hex("#120D13"),
            middle: hex("#30201B"),
            bottom: hex("#0B0F18"),
            glowPrimary: hex("#F1A85C"),
            glowSecondary: hex("#78E2B8"),
            text: hex("#FFF2E2"),
            mutedText: hex("#E7D3BE"),
            surface: hex("#211712"),
            hairline: hex("#F4BE75")
        )
    case .dawn:
        return ScenePalette(
            top: hex("#FFF0E5"),
            middle: hex("#F6D0BE"),
            bottom: hex("#E8F0DF"),
            glowPrimary: hex("#F2A06A"),
            glowSecondary: slide.accent,
            text: hex("#171421"),
            mutedText: hex("#514956"),
            surface: hex("#FFF8F0"),
            hairline: hex("#FFFFFF")
        )
    case .lagoon:
        return ScenePalette(
            top: hex("#071A23"),
            middle: hex("#0D4C4B"),
            bottom: hex("#07101C"),
            glowPrimary: hex("#5BE1C0"),
            glowSecondary: hex("#58A8FF"),
            text: hex("#F4FFF9"),
            mutedText: hex("#CDE9E1"),
            surface: hex("#0D2429"),
            hairline: hex("#A8F4DF")
        )
    case .graphite:
        return ScenePalette(
            top: hex("#F4F1EA"),
            middle: hex("#DDE4DE"),
            bottom: hex("#C9D4CD"),
            glowPrimary: slide.accent,
            glowSecondary: hex("#92B6A3"),
            text: hex("#0C1218"),
            mutedText: hex("#394047"),
            surface: hex("#F8F8F4"),
            hairline: hex("#FFFFFF")
        )
    case .coast:
        return ScenePalette(
            top: hex("#F0DAC8"),
            middle: hex("#A5B8B6"),
            bottom: hex("#E3A17D"),
            glowPrimary: hex("#C9775E"),
            glowSecondary: hex("#F3ECE2"),
            text: hex("#121923"),
            mutedText: hex("#495158"),
            surface: hex("#FAEEE4"),
            hairline: hex("#FFFFFF")
        )
    }
}

func drawDynamicBackground(slide: Slide, mood: SceneMood) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let rect = CGRect(origin: .zero, size: Tokens.canvasSize)
    let p = palette(for: mood, slide: slide)
    let usesSoftLight = mood == .mist || mood == .dawn || mood == .graphite || mood == .coast
    let cs = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(
        colorsSpace: cs,
        colors: [p.top.cgColor, p.middle.cgColor, p.bottom.cgColor] as CFArray,
        locations: [0, 0.50, 1]
    )!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.minX - 180, y: rect.maxY),
        end: CGPoint(x: rect.maxX + 140, y: rect.minY),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )

    drawRadialGlow(color: p.glowPrimary, center: CGPoint(x: rect.maxX - 180, y: rect.maxY - 520),
                   radius: rect.width * 0.84, alpha: usesSoftLight ? 0.26 : 0.38)
    drawRadialGlow(color: p.glowSecondary, center: CGPoint(x: rect.minX + 210, y: rect.minY + 620),
                   radius: rect.width * 0.72, alpha: usesSoftLight ? 0.18 : 0.28)

    drawKineticWash(in: rect, color: p.glowSecondary, alpha: usesSoftLight ? 0.16 : 0.09,
                    y: rect.maxY - 610, rotation: -11)
    drawKineticWash(in: rect, color: p.glowPrimary, alpha: usesSoftLight ? 0.13 : 0.07,
                    y: rect.minY + 560, rotation: 8)

    drawSoundBand(in: rect, baseY: rect.midY + 270, height: 460,
                  amplitude: 54, wavelength: 720, phase: 90,
                  color: p.glowPrimary, alpha: usesSoftLight ? 0.055 : 0.075)
    drawSoundBand(in: rect, baseY: rect.minY + 420, height: 510,
                  amplitude: 70, wavelength: 610, phase: 210,
                  color: p.glowSecondary, alpha: usesSoftLight ? 0.050 : 0.080)

    drawGrainOverlay(in: rect, opacity: 0.035)
    drawVignette(in: rect, darkness: usesSoftLight ? 0.10 : 0.31)
}

func drawKineticWash(in rect: CGRect, color: NSColor, alpha: CGFloat, y: CGFloat, rotation: CGFloat) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let washRect = CGRect(x: -260, y: y, width: rect.width + 520, height: 430)
    withRotation(degrees: rotation, around: washRect) {
        ctx.saveGState()
        let path = NSBezierPath(roundedRect: washRect, xRadius: 210, yRadius: 210)
        color.withAlphaComponent(alpha).setFill()
        path.fill()
        ctx.restoreGState()
    }
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

    switch slide.background {
    case .studioGradient:
        drawSoundBand(in: rect, baseY: rect.maxY - 760, height: 360,
                      amplitude: 78, wavelength: 620, phase: 40,
                      color: hex("#4FC8B3"), alpha: 0.075)
        drawSoundBand(in: rect, baseY: rect.minY + 360, height: 520,
                      amplitude: 96, wavelength: 540, phase: 130,
                      color: hex("#E4A45A"), alpha: 0.105)

    case .spatialGradient, .duskGradient:
        drawSoundBand(in: rect, baseY: rect.minY + 620, height: 610,
                      amplitude: 92, wavelength: 700, phase: 10,
                      color: hex("#54C8B7"), alpha: 0.070)
        drawSoundBand(in: rect, baseY: rect.maxY - 700, height: 360,
                      amplitude: 64, wavelength: 570, phase: 190,
                      color: slide.accent, alpha: 0.060)

    case .sageMist, .creamRadial:
        drawSoundBand(in: rect, baseY: rect.midY - 120, height: 520,
                      amplitude: 58, wavelength: 650, phase: 100,
                      color: slide.accent, alpha: 0.065)
        drawSoundBand(in: rect, baseY: rect.minY + 320, height: 420,
                      amplitude: 46, wavelength: 520, phase: 220,
                      color: hex("#85A884"), alpha: 0.052)

    case .coastalSand:
        drawSoundBand(in: rect, baseY: rect.midY + 180, height: 500,
                      amplitude: 58, wavelength: 640, phase: 70,
                      color: hex("#C9775E"), alpha: 0.060)
        drawSoundBand(in: rect, baseY: rect.minY + 430, height: 430,
                      amplitude: 48, wavelength: 560, phase: 210,
                      color: hex("#F3ECE2"), alpha: 0.075)

    case .midnightCopper, .warmGradient:
        drawSoundBand(in: rect, baseY: rect.minY + 390, height: 520,
                      amplitude: 82, wavelength: 610, phase: 40,
                      color: slide.accent, alpha: 0.095)
        drawSoundBand(in: rect, baseY: rect.maxY - 760, height: 380,
                      amplitude: 72, wavelength: 590, phase: 210,
                      color: hex("#9D6BFF"), alpha: 0.038)
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

func makeDeviceComposite(_ capture: NSImage, size: CGSize) -> NSImage? {
    guard let bezel = _cachedBezel else {
        return nil
    }

    // Build an offscreen composite of capture + bezel so the shadow casts from
    // the FULL iPhone silhouette (not a hand-picked rounded rect that may be
    // slightly off from Apple's actual body curvature).
    let w = size.width
    let scale = w / BEZEL_SIZE.width
    let screenInsetX = BEZEL_SCREEN_INSET_X * scale
    let screenInsetY = BEZEL_SCREEN_INSET_Y * scale

    let composite = NSImage(size: size)
    composite.lockFocus()
    let localRect = CGRect(origin: .zero, size: size)
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
    return composite
}

func drawDeviceImage(_ composite: NSImage, slide: Slide, rect: CGRect,
                     rotation: CGFloat = 0, opacity: CGFloat = 1,
                     shadowScale: CGFloat = 1) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }

    // Now draw the composite once, with a two-layer shadow. The shadow is cast
    // from the composite's alpha, which matches Apple's bezel silhouette
    // exactly — no pale halo, no corner overshoot.
    withRotation(degrees: rotation, around: rect) {
        ctx.saveGState()
        let ambient = NSShadow()
        let isDark = !slide.darkText
        ambient.shadowColor = (isDark
            ? NSColor.black.withAlphaComponent(0.56)
            : slide.accent.blended(withFraction: 0.78, of: .black)!.withAlphaComponent(0.30))
        ambient.shadowBlurRadius = 120 * shadowScale
        ambient.shadowOffset = CGSize(width: 0, height: -40 * shadowScale)
        ambient.set()
        composite.draw(in: rect, from: .zero, operation: .sourceOver, fraction: opacity)
        ctx.restoreGState()

        ctx.saveGState()
        let contact = NSShadow()
        contact.shadowColor = NSColor.black.withAlphaComponent(0.40)
        contact.shadowBlurRadius = 28 * shadowScale
        contact.shadowOffset = CGSize(width: 0, height: -10 * shadowScale)
        contact.set()
        composite.draw(in: rect, from: .zero, operation: .sourceOver, fraction: opacity)
        ctx.restoreGState()
    }
}

func drawDevice(_ capture: NSImage, slide: Slide, rect: CGRect, clipToCanvas: Bool) {
    guard let composite = makeDeviceComposite(capture, size: rect.size) else {
        print("⚠️ bezel PNG not found; falling back to plain capture")
        capture.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
        return
    }

    drawDeviceImage(composite, slide: slide, rect: rect)

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
        .font: headlineFont(size),
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
        .font: displayFont(Tokens.eyebrowSize, weight: .semibold),
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

func dynamicHeadlineAttributes(size: CGFloat, ink: NSColor,
                               alignment: TextAlignmentToken?) -> [NSAttributedString.Key: Any] {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = paragraphAlignment(alignment)
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineHeightMultiple = Tokens.dynamicHeadlineLeading
    return [
        .font: headlineFont(size),
        .foregroundColor: ink,
        .kern: 0,
        .paragraphStyle: paragraph
    ]
}

func dynamicSubheadAttributes(ink: NSColor,
                              alignment: TextAlignmentToken?) -> [NSAttributedString.Key: Any] {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = paragraphAlignment(alignment)
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineHeightMultiple = Tokens.dynamicSubheadLeading
    return [
        .font: displayFont(Tokens.dynamicSubheadSize, weight: .medium),
        .foregroundColor: ink.withAlphaComponent(0.76),
        .paragraphStyle: paragraph
    ]
}

func dynamicEyebrowAttributes(accent: NSColor,
                              alignment: TextAlignmentToken?) -> [NSAttributedString.Key: Any] {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = paragraphAlignment(alignment)
    paragraph.lineBreakMode = .byClipping
    return [
        .font: displayFont(Tokens.dynamicEyebrowSize, weight: .semibold),
        .foregroundColor: accent.withAlphaComponent(0.96),
        .kern: Tokens.dynamicEyebrowKerning,
        .paragraphStyle: paragraph
    ]
}

func pickDynamicHeadlineSize(_ text: String, width: CGFloat, maxHeight: CGFloat,
                             ink: NSColor, alignment: TextAlignmentToken?) -> CGFloat {
    for size in Tokens.dynamicHeadlineStepSizes {
        let attrs = dynamicHeadlineAttributes(size: size, ink: ink, alignment: alignment)
        if measureText(text, width: width, attributes: attrs) <= maxHeight,
           maxUnbreakableTextWidth(text, attributes: attrs) <= width {
            return size
        }
    }
    return Tokens.dynamicHeadlineStepSizes.last!
}

func maxUnbreakableTextWidth(_ text: String, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
    text
        .components(separatedBy: CharacterSet.whitespacesAndNewlines)
        .map { token in
            guard !token.isEmpty else { return CGFloat(0) }
            return ceil(NSString(string: token).size(withAttributes: attributes).width)
        }
        .max() ?? 0
}

func drawTextInRect(_ text: String, attributes: [NSAttributedString.Key: Any], rect: CGRect) {
    NSString(string: text).draw(
        with: rect,
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: attributes
    )
}

func drawDynamicText(slide: Slide, copy: Copy, scene: DynamicSceneConfig, palette: ScenePalette) {
    guard let config = scene.text else { return }
    let align = config.align
    let textRect = topLeftRect(x: config.x, y: config.y, width: config.width, height: config.height)
    let useDark = config.tone == "dark"
    let ink = useDark ? Tokens.inkDark : palette.text
    let accent = slide.accent.blended(withFraction: useDark ? 0.02 : 0.22, of: useDark ? .black : .white)!

    let eyebrow = normalizedEyebrow(copy)
    let eyebrowAttrs = dynamicEyebrowAttributes(accent: accent, alignment: align)
    let eyebrowH = eyebrow.map {
        measureText($0, width: textRect.width, attributes: eyebrowAttrs)
    } ?? 0
    let subheadAttrs = dynamicSubheadAttributes(ink: ink, alignment: align)
    let subheadH = measureText(copy.subhead, width: textRect.width, attributes: subheadAttrs)
    let headlineBudget = textRect.height
        - eyebrowH
        - (eyebrow == nil ? 0 : Tokens.dynamicEyebrowToHeadlineGap)
        - Tokens.dynamicHeadlineToSubheadGap
        - subheadH
    let headlineSize = pickDynamicHeadlineSize(
        copy.headline,
        width: textRect.width,
        maxHeight: max(74, headlineBudget),
        ink: ink,
        alignment: align
    )
    let headlineAttrs = dynamicHeadlineAttributes(size: headlineSize, ink: ink, alignment: align)
    let headlineH = measureText(copy.headline, width: textRect.width, attributes: headlineAttrs)

    var cursor = textRect.maxY
    if let eyebrow {
        let rect = CGRect(x: textRect.minX, y: cursor - eyebrowH, width: textRect.width, height: eyebrowH)
        drawTextInRect(eyebrow, attributes: eyebrowAttrs, rect: rect)
        cursor -= eyebrowH + Tokens.dynamicEyebrowToHeadlineGap
    }

    let headlineRect = CGRect(x: textRect.minX, y: cursor - headlineH, width: textRect.width, height: headlineH)
    drawTextInRect(copy.headline, attributes: headlineAttrs, rect: headlineRect)
    cursor -= headlineH + Tokens.dynamicHeadlineToSubheadGap

    let subheadRect = CGRect(x: textRect.minX, y: cursor - subheadH, width: textRect.width, height: subheadH)
    drawTextInRect(copy.subhead, attributes: subheadAttrs, rect: subheadRect)
}

func shadow(_ style: SceneShadow, color: NSColor = .black) -> NSShadow {
    let shadow = NSShadow()
    switch style {
    case .soft:
        shadow.shadowColor = color.withAlphaComponent(0.24)
        shadow.shadowBlurRadius = 34
        shadow.shadowOffset = CGSize(width: 0, height: -12)
    case .lifted:
        shadow.shadowColor = color.withAlphaComponent(0.30)
        shadow.shadowBlurRadius = 56
        shadow.shadowOffset = CGSize(width: 0, height: -20)
    case .deep:
        shadow.shadowColor = color.withAlphaComponent(0.42)
        shadow.shadowBlurRadius = 82
        shadow.shadowOffset = CGSize(width: 0, height: -28)
    case .glow:
        shadow.shadowColor = color.withAlphaComponent(0.46)
        shadow.shadowBlurRadius = 72
        shadow.shadowOffset = .zero
    }
    return shadow
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

func composeDynamicScene(slide: Slide, copy: Copy, capture: NSImage,
                         scene: DynamicSceneConfig, assetsDir: URL?) {
    let mood = scene.mood ?? (slide.darkText ? .mist : .aurora)
    let scenePalette = palette(for: mood, slide: slide)

    drawDynamicBackground(slide: slide, mood: mood)

    var deviceRect: CGRect?
    var deviceRotation: CGFloat = 0
    if let device = scene.device {
        let width = device.width
        let height = width * Tokens.bezelAspect
        let rect = topLeftRect(x: device.x, y: device.y, width: width, height: height)
        deviceRect = rect
        deviceRotation = device.rotation ?? 0
        if let composite = makeDeviceComposite(capture, size: rect.size) {
            drawDeviceImage(
                composite,
                slide: slide,
                rect: rect,
                rotation: device.rotation ?? 0,
                opacity: device.opacity ?? 1,
                shadowScale: 1.08
            )
        } else {
            capture.draw(in: rect, from: .zero, operation: .sourceOver, fraction: device.opacity ?? 1)
        }
    }

    if let deviceRect, let assetsDir {
        drawAnchoredElementAssets(
            for: slide,
            deviceRect: deviceRect,
            deviceRotation: deviceRotation,
            assetsDir: assetsDir
        )
    }

    drawDynamicText(slide: slide, copy: copy, scene: scene, palette: scenePalette)
}

func anchoredAssets(for slide: Slide) -> [AnchoredAsset] {
    switch slide.slug {
    case "01_hero":
        return [AnchoredAsset(name: "01_active_forest", scale: 1.34, cornerRadius: 68)]
    case "02_library":
        return [AnchoredAsset(name: "02_active_river", scale: 1.34, cornerRadius: 68)]
    case "03_detail_sheet":
        return [AnchoredAsset(name: "03_detail_map", scale: 1.34, cornerRadius: 74)]
    case "04_binaural":
        return [AnchoredAsset(name: "04_binaural_modes", scale: 1.24, cornerRadius: 82)]
    case "05_spatial":
        return [AnchoredAsset(name: "05_spatial_stage", scale: 1.42, cornerRadius: 88)]
    case "06_ambiences":
        return [
            AnchoredAsset(name: "06_saved_starter", scale: 1.46, cornerRadius: 74),
            AnchoredAsset(name: "06_saved_reset", scale: 1.36, cornerRadius: 74)
        ]
    case "07_timer":
        return [AnchoredAsset(name: "07_active_rain", scale: 1.34, cornerRadius: 68)]
    case "08_free_home":
        return [AnchoredAsset(name: "08_active_birds", scale: 1.34, cornerRadius: 68)]
    case "09_noise":
        return [
            AnchoredAsset(name: "09_noise_green", scale: 1.32, cornerRadius: 68),
            AnchoredAsset(name: "09_noise_fan", scale: 1.28, cornerRadius: 68)
        ]
    case "10_paywall":
        return [AnchoredAsset(name: "10_paywall_primary", scale: 1.26, cornerRadius: 74)]
    default:
        return []
    }
}

func expectedCapturedAssetNames() -> Set<String> {
    Set([
        "01_active_forest",
        "02_active_river",
        "03_detail_map",
        "04_binaural_modes",
        "05_spatial_stage",
        "06_ambience_duration",
        "06_saved_starter",
        "06_saved_reset",
        "06_saved_storm",
        "07_active_rain",
        "08_active_birds",
        "09_noise_green",
        "09_noise_fan",
        "10_paywall_primary"
    ])
}

func appStoreOutputFileName(for slide: Slide) -> String {
    switch slide.slug {
    case "06_ambiences":
        return "03_ambiences.jpg"
    case "07_timer":
        return "04_timer.jpg"
    case "05_spatial":
        return "05_spatial.jpg"
    case "08_free_home":
        return "06_free_home.jpg"
    case "03_detail_sheet":
        return "07_detail_sheet.jpg"
    case "04_binaural":
        return "08_binaural.jpg"
    default:
        return "\(slide.slug).jpg"
    }
}

func validateExtractedAssetsDirectory(_ assetsDir: URL, expectedNames: Set<String>) throws {
    guard !expectedNames.isEmpty else { return }

    let fm = FileManager.default
    guard fm.fileExists(atPath: assetsDir.path) else {
        throw NSError(
            domain: "oasis.generate_store_screenshot_comps",
            code: 20,
            userInfo: [NSLocalizedDescriptionKey: "Missing extracted simulator assets directory: \(assetsDir.path)"]
        )
    }

    let files = try fm.contentsOfDirectory(atPath: assetsDir.path)
        .filter { $0.hasSuffix(".png") || $0.hasSuffix(".json") }
    let actualNames = Set(files.map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent })
    let extraNames = actualNames.subtracting(expectedNames)
    let missingNames = expectedNames.subtracting(actualNames)
    guard extraNames.isEmpty, missingNames.isEmpty else {
        let details = [
            extraNames.isEmpty ? nil : "unexpected: \(extraNames.sorted().joined(separator: ", "))",
            missingNames.isEmpty ? nil : "missing: \(missingNames.sorted().joined(separator: ", "))"
        ].compactMap { $0 }.joined(separator: "; ")
        throw NSError(
            domain: "oasis.generate_store_screenshot_comps",
            code: 21,
            userInfo: [NSLocalizedDescriptionKey: "Extracted simulator assets are not clean for \(assetsDir.path) (\(details))"]
        )
    }

    for name in expectedNames.sorted() {
        let imageURL = assetsDir.appendingPathComponent("\(name).png")
        let metadataURL = assetsDir.appendingPathComponent("\(name).json")
        guard fm.fileExists(atPath: imageURL.path),
              let image = NSImage(contentsOf: imageURL),
              image.size.width > 1,
              image.size.height > 1
        else {
            throw NSError(
                domain: "oasis.generate_store_screenshot_comps",
                code: 22,
                userInfo: [NSLocalizedDescriptionKey: "Invalid extracted simulator asset image: \(imageURL.path)"]
            )
        }
        guard let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode(ExtractedAssetMetadata.self, from: data),
              metadata.name == name,
              metadata.elementFramePoints.width > 0,
              metadata.elementFramePoints.height > 0,
              metadata.visibleFramePoints.width >= metadata.elementFramePoints.width,
              metadata.visibleFramePoints.height >= metadata.elementFramePoints.height,
              metadata.paddingPoints.horizontal >= 0,
              metadata.paddingPoints.vertical >= 0
        else {
            throw NSError(
                domain: "oasis.generate_store_screenshot_comps",
                code: 23,
                userInfo: [NSLocalizedDescriptionKey: "Invalid or stale extracted simulator asset metadata: \(metadataURL.path)"]
            )
        }
    }
}

func drawAnchoredElementAssets(for slide: Slide,
                               deviceRect: CGRect,
                               deviceRotation: CGFloat,
                               assetsDir: URL) {
    let assets = anchoredAssets(for: slide)
    guard !assets.isEmpty else { return }

    for asset in assets {
        let imageURL = assetsDir.appendingPathComponent("\(asset.name).png")
        let metadataURL = assetsDir.appendingPathComponent("\(asset.name).json")
        guard let image = NSImage(contentsOf: imageURL) else {
            fatalError("Missing extracted simulator asset: \(imageURL.path)")
        }
        guard let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode(ExtractedAssetMetadata.self, from: data)
        else {
            fatalError("Missing or stale extracted simulator asset metadata: \(metadataURL.path)")
        }
        guard metadata.name == asset.name else {
            fatalError("Extracted simulator asset metadata mismatch: expected \(asset.name), got \(metadata.name)")
        }

        let rect = anchoredRect(
            metadata.visibleFramePoints,
            screen: metadata.screenPoints,
            deviceRect: deviceRect
        )
        let scaled = rect.scaled(around: CGPoint(x: rect.midX, y: rect.midY), factor: asset.scale)

        withRotation(degrees: deviceRotation, around: deviceRect) {
            NSGraphicsContext.current?.imageInterpolation = .high
            drawRoundedExtractedAsset(
                image,
                in: scaled,
                cornerRadius: asset.cornerRadius,
                darkText: slide.darkText
            )
        }
    }
}

func drawRoundedExtractedAsset(_ image: NSImage,
                               in rect: CGRect,
                               cornerRadius: CGFloat,
                               darkText: Bool) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let radius = min(cornerRadius, rect.height / 2, rect.width / 2)
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    ctx.saveGState()
    let ambientShadow = NSShadow()
    ambientShadow.shadowColor = NSColor.black.withAlphaComponent(darkText ? 0.48 : 0.70)
    ambientShadow.shadowBlurRadius = darkText ? 130 : 160
    ambientShadow.shadowOffset = CGSize(width: 0, height: -44)
    ambientShadow.set()
    NSColor.black.withAlphaComponent(0.72).setFill()
    path.fill()
    ctx.restoreGState()

    ctx.saveGState()
    let contactShadow = NSShadow()
    contactShadow.shadowColor = NSColor.black.withAlphaComponent(darkText ? 0.56 : 0.78)
    contactShadow.shadowBlurRadius = darkText ? 72 : 88
    contactShadow.shadowOffset = CGSize(width: 0, height: -32)
    contactShadow.set()
    NSColor.black.withAlphaComponent(0.82).setFill()
    path.fill()
    ctx.restoreGState()

    ctx.saveGState()
    path.addClip()
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    ctx.restoreGState()

    // Keep highlight crops borderless so they read as lifted UI, not framed cards.
}

func anchoredRect(_ frame: ExtractedAssetMetadata.Rect,
                  screen: ExtractedAssetMetadata.Rect,
                  deviceRect: CGRect) -> CGRect {
    let scale = deviceRect.width / BEZEL_SIZE.width
    let screenInsetX = BEZEL_SCREEN_INSET_X * scale
    let screenInsetY = BEZEL_SCREEN_INSET_Y * scale
    let screenRect = deviceRect.insetBy(dx: screenInsetX, dy: screenInsetY)
    let screenWidth = max(screen.width, 1)
    let screenHeight = max(screen.height, 1)

    let x = screenRect.minX + (frame.x / screenWidth) * screenRect.width
    let width = (frame.width / screenWidth) * screenRect.width
    let height = (frame.height / screenHeight) * screenRect.height
    let y = screenRect.minY + ((screenHeight - frame.y - frame.height) / screenHeight) * screenRect.height

    return CGRect(x: x, y: y, width: width, height: height)
}

extension CGRect {
    func scaled(around center: CGPoint, factor: CGFloat) -> CGRect {
        CGRect(
            x: center.x - (width * factor / 2),
            y: center.y - (height * factor / 2),
            width: width * factor,
            height: height * factor
        )
    }
}

// ──────────────────────────────────────────────────────────────────────────
// MARK: Pipeline
// ──────────────────────────────────────────────────────────────────────────

func renderSlide(slide: Slide, copy: Copy, inputURL: URL,
                 outputURL: URL) throws {
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

    if renderStyle == .dynamic, let scene = slide.scene {
        let assetsDir = inputURL
            .deletingLastPathComponent()
            .appendingPathComponent("extracted-assets", isDirectory: true)
        composeDynamicScene(slide: slide, copy: copy, capture: capture, scene: scene, assetsDir: assetsDir)
    } else {
        drawBackground(slide: slide)

        switch slide.layout {
        case .poster:     composePosterLayout(slide: slide, copy: copy, capture: capture)
        case .top:        composeTopLayout(slide: slide, copy: copy, capture: capture)
        case .bottom:     composeBottomLayout(slide: slide, copy: copy, capture: capture)
        case .bleed:      composeBleedLayout(slide: slide, copy: copy, capture: capture)
        case .peekBottom: composePeekBottomLayout(slide: slide, copy: copy, capture: capture)
        }
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
}

// ──────────────────────────────────────────────────────────────────────────
// MARK: Entry point
// ──────────────────────────────────────────────────────────────────────────

var onlySlug: String? = nil
var onlyLang: String? = nil
var renderStyle: RenderStyle = .dynamic
var outputFolderOverride: String? = nil
var args = Array(CommandLine.arguments.dropFirst())
while !args.isEmpty {
    let a = args.removeFirst()
    switch a {
    case "--only":
        onlySlug = args.isEmpty ? nil : args.removeFirst()
    case "--lang":
        onlyLang = args.isEmpty ? nil : args.removeFirst()
    case "--style":
        let value = args.isEmpty ? nil : args.removeFirst()
        renderStyle = RenderStyle(rawValue: value ?? "") ?? .dynamic
    case "--classic":
        renderStyle = .classic
    case "--output-folder":
        outputFolderOverride = args.isEmpty ? nil : args.removeFirst()
    default:
        break
    }
}

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let screenshotsRoot = repoRoot.appendingPathComponent(CONTENT.capturesDir)

var produced = 0
var skipped: [String] = []

let languages = onlyLang.map { [$0] } ?? Array(COPY.keys).sorted()
let expectedExtractedNames = expectedCapturedAssetNames()

for language in languages {
    guard let localisedCopy = COPY[language] else {
        skipped.append("\(language) — no copy entries")
        continue
    }
    let langDir = screenshotsRoot.appendingPathComponent(language)
    let outputFolder = outputFolderOverride
        ?? (renderStyle == .dynamic ? "figma-pro" : "figma-pro-classic")
    let outputDir = langDir.appendingPathComponent(outputFolder)
    try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    if onlySlug == nil {
        let existingOutputs = try FileManager.default.contentsOfDirectory(at: outputDir, includingPropertiesForKeys: nil)
        for output in existingOutputs where output.pathExtension == "jpg" {
            try FileManager.default.removeItem(at: output)
        }
    }
    if renderStyle == .dynamic {
        try validateExtractedAssetsDirectory(
            langDir.appendingPathComponent("extracted-assets", isDirectory: true),
            expectedNames: expectedExtractedNames
        )
    }

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
        let outputFileName = appStoreOutputFileName(for: slide)
        let outputURL = outputDir.appendingPathComponent(outputFileName)
        try renderSlide(slide: slide, copy: copy,
                        inputURL: inputURL,
                        outputURL: outputURL)
        produced += 1
        print("✓ \(language)/\(outputFileName)")
    }
}

print("\nProduced \(produced) composites.")
if !skipped.isEmpty {
    print("Skipped:")
    for s in skipped { print("  - \(s)") }
}
