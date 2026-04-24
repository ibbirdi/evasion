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
    case top          // Text at top, device fully visible below
    case bottom       // Device fully visible at top, text below
    case bleed        // Oversized device, compact caption at bottom
    case peekBottom   // Text at top, device oversized and bleeding off bottom
}

enum BackgroundStyle: String, Codable {
    case warmGradient      // 3-stop sunset gradient (hero, paywall)
    case creamRadial       // cream base with centered accent radial glow
    case duskGradient      // deep teal/indigo gradient for focus/calm slides
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
    static let deviceWidth_top: CGFloat         = 1020
    static let deviceWidth_bottom: CGFloat      = 1080
    static let deviceWidth_bleed: CGFloat       = 1160
    static let deviceWidth_peekBottom: CGFloat  = 1220

    /// Aspect of the Apple bezel PNG (height / width = 3000 / 1470).
    /// Use this for all layout math — the bezel is slightly shorter per unit
    /// width than the raw 1320 × 2868 capture.
    static let bezelAspect: CGFloat = 3000.0 / 1470.0

    // ── Typography
    static let iconSize: CGFloat = 84
    // Generous breathing room between the symbol and the headline — gives the
    // icon visual authority as a "section marker" rather than feeling pinned
    // against the title.
    static let iconToHeadlineGap: CGFloat = 48

    // Tight leading for punchier display type. 0.82 packs the 2-line headlines
    // (common across all 6 locales) into a cohesive block without clipping
    // descenders at the largest step sizes.
    static let headlineStepSizes: [CGFloat] = [122, 112, 104, 96, 88]
    static let headlineLeading: CGFloat = 0.82
    static let headlineKerning: CGFloat = -0.028

    static let headlineToSubheadGap: CGFloat = 28
    static let subheadSize: CGFloat = 58
    static let subheadLeading: CGFloat = 1.14

    // ── Layout padding
    static let textSideMargin: CGFloat = 76
    static let topLayout_topPadding: CGFloat       = 140
    static let topLayout_gap: CGFloat              = 60
    static let bottomLayout_topPadding: CGFloat    = 110
    static let bottomLayout_gap: CGFloat           = 48
    static let bottomLayout_bottomPadding: CGFloat = 88
    static let bleedLayout_topPadding: CGFloat     = 66
    static let bleedLayout_bottomPadding: CGFloat  = 76
    static let peekLayout_topPadding: CGFloat      = 130
    static let peekLayout_gap: CGFloat             = 56
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
    }

    drawGrainOverlay(in: rect, opacity: 0.035)
    drawVignette(in: rect, darkness: slide.background == .duskGradient ? 0.38 : 0.14)
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
    let isDark = slide.background == .duskGradient
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
        .font: displayFont(size, weight: .black),
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

// ──────────────────────────────────────────────────────────────────────────
// MARK: Layout compositors
// ──────────────────────────────────────────────────────────────────────────

func composeTopLayout(slide: Slide, copy: Copy, capture: NSImage) {
    let ink = slide.darkText ? Tokens.inkDark : Tokens.inkLight
    let textWidth = Tokens.canvasSize.width - 2 * Tokens.textSideMargin
    let aspect = Tokens.bezelAspect
    let iconH = Tokens.iconSize
    let iconGap = Tokens.iconToHeadlineGap

    // Text budget: up to 32% of canvas height for top layout.
    let textBudget = Tokens.canvasSize.height * 0.32
    let subheadH = measureText(copy.subhead, width: textWidth,
                               attributes: subheadAttributes(ink: ink))
    let headlineBudget = textBudget - iconH - iconGap - Tokens.headlineToSubheadGap - subheadH
    let size = pickHeadlineSize(copy.headline, width: textWidth,
                                maxHeight: max(headlineBudget, 60), ink: ink)
    let headlineH = measureText(copy.headline, width: textWidth,
                                attributes: headlineAttributes(size: size, ink: ink))
    let textBlockH = iconH + iconGap + headlineH + Tokens.headlineToSubheadGap + subheadH

    // Device fills the rest, capped at max width.
    let deviceBudget = Tokens.canvasSize.height
        - Tokens.topLayout_topPadding
        - textBlockH
        - Tokens.topLayout_gap
        - 30 // bottom safety
    let mockupW = min(Tokens.deviceWidth_top, deviceBudget / aspect)
    let mockupH = mockupW * aspect

    let iconTopY = Tokens.topLayout_topPadding
    let headlineTopY = iconTopY + iconH + iconGap
    let subheadTopY = headlineTopY + headlineH + Tokens.headlineToSubheadGap
    let deviceTopY = subheadTopY + subheadH + Tokens.topLayout_gap

    drawIcon(symbolName: slide.iconSymbol, accent: slide.accent,
             centreX: Tokens.canvasSize.width / 2, topY: iconTopY)
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
    let iconH = Tokens.iconSize
    let iconGap = Tokens.iconToHeadlineGap

    // Size text first using a budget of 32% of canvas height.
    let textBudget = Tokens.canvasSize.height * 0.32
    let subheadH = measureText(copy.subhead, width: textWidth,
                               attributes: subheadAttributes(ink: ink))
    let headlineBudget = textBudget - iconH - iconGap - Tokens.headlineToSubheadGap - subheadH
    let size = pickHeadlineSize(copy.headline, width: textWidth,
                                maxHeight: max(headlineBudget, 60), ink: ink)
    let headlineH = measureText(copy.headline, width: textWidth,
                                attributes: headlineAttributes(size: size, ink: ink))
    let textBlockH = iconH + iconGap + headlineH + Tokens.headlineToSubheadGap + subheadH

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

    let iconTopY = textBlockTopY
    let headlineTopY = iconTopY + iconH + iconGap
    let subheadTopY = headlineTopY + headlineH + Tokens.headlineToSubheadGap

    drawIcon(symbolName: slide.iconSymbol, accent: slide.accent,
             centreX: Tokens.canvasSize.width / 2, topY: iconTopY)
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

    // Compact text budget: 20% of canvas height.
    let textBudget = Tokens.canvasSize.height * 0.20
    let subheadH = measureText(copy.subhead, width: textWidth,
                               attributes: subheadAttributes(ink: ink))
    let headlineBudget = textBudget - Tokens.headlineToSubheadGap - subheadH
    let size = pickHeadlineSize(copy.headline, width: textWidth,
                                maxHeight: max(headlineBudget, 60), ink: ink)
    let headlineH = measureText(copy.headline, width: textWidth,
                                attributes: headlineAttributes(size: size, ink: ink))
    let textBlockH = headlineH + Tokens.headlineToSubheadGap + subheadH

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

    let headlineTopY = textBlockTopY
    let subheadTopY = headlineTopY + headlineH + Tokens.headlineToSubheadGap
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
    let iconH = Tokens.iconSize
    let iconGap = Tokens.iconToHeadlineGap
    let subheadH = measureText(copy.subhead, width: textWidth,
                               attributes: subheadAttributes(ink: ink))
    // Text block cap: keep top text compact so the device dominates.
    let textCapH = Tokens.canvasSize.height * 0.30
    let headlineBudget = textCapH - iconH - iconGap - Tokens.headlineToSubheadGap - subheadH
    let size = pickHeadlineSize(copy.headline, width: textWidth,
                                maxHeight: max(headlineBudget, 60), ink: ink)
    let headlineH = measureText(copy.headline, width: textWidth,
                                attributes: headlineAttributes(size: size, ink: ink))

    let iconTopY = Tokens.peekLayout_topPadding
    let headlineTopY = iconTopY + iconH + iconGap
    let subheadTopY = headlineTopY + headlineH + Tokens.headlineToSubheadGap
    let deviceTopY = subheadTopY + subheadH + Tokens.peekLayout_gap

    drawIcon(symbolName: slide.iconSymbol, accent: slide.accent,
             centreX: Tokens.canvasSize.width / 2, topY: iconTopY)
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
