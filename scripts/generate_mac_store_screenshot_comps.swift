// Oasis macOS App Store screenshot composer.
//
// Produces 2880 x 1800 Mac screenshots from real OasisMac panel captures.
// Content lives in scripts/mac_screenshot_content.json.

import AppKit
import Foundation

enum PanelSide: String, Codable {
    case right
}

struct SlideConfig: Codable {
    let slug: String
    let source: String
    let accent: String
    let panelSide: PanelSide
}

struct CopyEntry: Codable {
    let eyebrow: String
    let headline: String
    let subhead: String
}

struct ContentFile: Codable {
    let capturesDir: String
    let outputDir: String
    let stagingDir: String
    let slides: [SlideConfig]
    let copy: [String: [String: CopyEntry]]
}

enum Tokens {
    static let canvasSize = CGSize(width: 2880, height: 1800)
    static let previewSize = CGSize(width: 1440, height: 900)
    static let leftMargin: CGFloat = 160
    static let textTop: CGFloat = 245
    static let textWidth: CGFloat = 1040
    static let panelMaxWidth: CGFloat = 1190
    static let panelMaxHeight: CGFloat = 1540
    static let panelRightMargin: CGFloat = 148
}

func repositoryRoot() -> URL {
    let fileManager = FileManager.default
    let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    let invokedPath = CommandLine.arguments.first ?? ""
    let invokedURL = URL(fileURLWithPath: invokedPath, relativeTo: currentDirectory).standardizedFileURL
    let scriptParent = invokedURL.deletingLastPathComponent()
    let candidates = [
        scriptParent.deletingLastPathComponent(),
        currentDirectory,
        currentDirectory.deletingLastPathComponent()
    ]

    for candidate in candidates {
        let contentPath = candidate.appendingPathComponent("scripts/mac_screenshot_content.json").path
        if fileManager.fileExists(atPath: contentPath) {
            return candidate
        }
    }

    return currentDirectory
}

func loadContent() -> ContentFile {
    let url = repositoryRoot().appendingPathComponent("scripts/mac_screenshot_content.json")
    do {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ContentFile.self, from: data)
    } catch {
        fputs("Failed to load \(url.path): \(error)\n", stderr)
        exit(1)
    }
}

func hex(_ string: String) -> NSColor {
    var value = string
    if value.hasPrefix("#") { value.removeFirst() }
    let intValue = UInt32(value, radix: 16) ?? 0
    return NSColor(
        srgbRed: CGFloat((intValue >> 16) & 0xff) / 255,
        green: CGFloat((intValue >> 8) & 0xff) / 255,
        blue: CGFloat(intValue & 0xff) / 255,
        alpha: 1
    )
}

func rgba(_ hexString: String, _ alpha: CGFloat) -> NSColor {
    hex(hexString).withAlphaComponent(alpha)
}

func drawBackground(accent: NSColor) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    let rect = CGRect(origin: .zero, size: Tokens.canvasSize)
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            hex("#151A22").cgColor,
            hex("#0A0D12").cgColor,
            hex("#030509").cgColor
        ] as CFArray,
        locations: [0, 0.54, 1]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: rect.maxY),
        end: CGPoint(x: rect.maxX, y: rect.minY),
        options: []
    )

    drawAcousticBand(
        from: CGPoint(x: -180, y: 1350),
        to: CGPoint(x: 3080, y: 1230),
        control1: CGPoint(x: 680, y: 1605),
        control2: CGPoint(x: 1900, y: 1040),
        color: accent.withAlphaComponent(0.13),
        width: 360
    )
    drawAcousticBand(
        from: CGPoint(x: -260, y: 500),
        to: CGPoint(x: 3180, y: 760),
        control1: CGPoint(x: 820, y: 230),
        control2: CGPoint(x: 2040, y: 980),
        color: rgba("#FFFFFF", 0.045),
        width: 300
    )

    let topLine = NSBezierPath()
    topLine.move(to: NSPoint(x: 0, y: 1684))
    topLine.line(to: NSPoint(x: Tokens.canvasSize.width, y: 1684))
    rgba("#FFFFFF", 0.055).setStroke()
    topLine.lineWidth = 1
    topLine.stroke()
}

func drawAcousticBand(
    from start: CGPoint,
    to end: CGPoint,
    control1: CGPoint,
    control2: CGPoint,
    color: NSColor,
    width: CGFloat
) {
    let path = NSBezierPath()
    path.move(to: start)
    path.curve(to: end, controlPoint1: control1, controlPoint2: control2)
    color.setStroke()
    path.lineCapStyle = .round
    path.lineWidth = width
    path.stroke()
}

func paragraphStyle(lineHeightMultiple: CGFloat = 1.0, alignment: NSTextAlignment = .left) -> NSMutableParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = alignment
    style.lineBreakMode = .byWordWrapping
    style.lineHeightMultiple = lineHeightMultiple
    return style
}

func textHeight(_ text: String, width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
    let attributed = NSAttributedString(string: text, attributes: attributes)
    let rect = attributed.boundingRect(
        with: CGSize(width: width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    )
    return ceil(rect.height)
}

func drawText(_ text: String, rect: CGRect, attributes: [NSAttributedString.Key: Any]) {
    (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes)
}

func drawCopy(_ copy: CopyEntry, accent: NSColor) {
    let textX = Tokens.leftMargin
    var y = Tokens.textTop

    let eyebrowAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 50, weight: .semibold),
        .foregroundColor: accent,
        .kern: 3.4,
        .paragraphStyle: paragraphStyle()
    ]
    drawText(copy.eyebrow.uppercased(), rect: CGRect(x: textX, y: y + 12, width: Tokens.textWidth, height: 78), attributes: eyebrowAttributes)

    y += 132

    let headlineSize = fittingHeadlineSize(copy.headline, maxWidth: Tokens.textWidth, maxHeight: 390)
    let headlineAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: headlineSize, weight: .heavy),
        .foregroundColor: hex("#F7F2E8"),
        .kern: 0,
        .paragraphStyle: paragraphStyle(lineHeightMultiple: 0.92)
    ]
    let headlineHeight = textHeight(copy.headline, width: Tokens.textWidth, attributes: headlineAttributes)
    drawText(copy.headline, rect: CGRect(x: textX, y: y, width: Tokens.textWidth, height: headlineHeight + 20), attributes: headlineAttributes)

    y += headlineHeight + 48

    let subheadSize = fittingSubheadSize(copy.subhead, maxWidth: 1020, maxHeight: 270)
    let subheadAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: subheadSize, weight: .medium),
        .foregroundColor: hex("#F7F2E8").withAlphaComponent(0.78),
        .paragraphStyle: paragraphStyle(lineHeightMultiple: 1.12)
    ]
    drawText(copy.subhead, rect: CGRect(x: textX, y: y, width: 1020, height: 290), attributes: subheadAttributes)
}

func fittingHeadlineSize(_ text: String, maxWidth: CGFloat, maxHeight: CGFloat) -> CGFloat {
    for size in stride(from: CGFloat(132), through: CGFloat(82), by: CGFloat(-4)) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: .heavy),
            .paragraphStyle: paragraphStyle(lineHeightMultiple: 0.92)
        ]
        if textHeight(text, width: maxWidth, attributes: attributes) <= maxHeight {
            return size
        }
    }
    return 82
}

func fittingSubheadSize(_ text: String, maxWidth: CGFloat, maxHeight: CGFloat) -> CGFloat {
    for size in stride(from: CGFloat(66), through: CGFloat(48), by: CGFloat(-1)) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: .medium),
            .paragraphStyle: paragraphStyle(lineHeightMultiple: 1.12)
        ]
        if textHeight(text, width: maxWidth, attributes: attributes) <= maxHeight {
            return size
        }
    }
    return 48
}

func drawPanel(image: NSImage) {
    let imageSize = image.size
    let scale = min(Tokens.panelMaxWidth / imageSize.width, Tokens.panelMaxHeight / imageSize.height)
    let width = floor(imageSize.width * scale)
    let height = floor(imageSize.height * scale)
    let x = Tokens.canvasSize.width - Tokens.panelRightMargin - width
    let y = floor((Tokens.canvasSize.height - height) / 2)
    let rect = CGRect(x: x, y: y, width: width, height: height)
    let shape = NSBezierPath(roundedRect: rect, xRadius: 46, yRadius: 46)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.34)
    shadow.shadowBlurRadius = 38
    shadow.shadowOffset = NSSize(width: 0, height: -18)
    shadow.set()
    rgba("#000000", 0.01).setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    shape.addClip()
    hex("#0B0F15").withAlphaComponent(0.88).setFill()
    rect.fill()
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    rgba("#FFFFFF", 0.14).setStroke()
    shape.lineWidth = 1
    shape.stroke()
}

func bitmap(size: CGSize, draw: () -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func writeJPEG(_ rep: NSBitmapImageRep, to url: URL, quality: CGFloat = 0.92) throws {
    guard let data = rep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
        throw NSError(domain: "oasis.mac_screenshots", code: 1)
    }
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url)
}

func drawSlide(slide: SlideConfig, copy: CopyEntry, panelImage: NSImage) -> NSBitmapImageRep {
    bitmap(size: Tokens.canvasSize) {
        drawBackground(accent: hex(slide.accent))
        drawCopy(copy, accent: hex(slide.accent))
        drawPanel(image: panelImage)
    }
}

func resize(_ image: NSBitmapImageRep, to size: CGSize) -> NSBitmapImageRep {
    bitmap(size: size) {
        NSGraphicsContext.current?.imageInterpolation = .high
        let nsImage = NSImage(size: image.size)
        nsImage.addRepresentation(image)
        nsImage.draw(in: CGRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1)
    }
}

let content = loadContent()
let repoRoot = repositoryRoot()
let capturesRoot = repoRoot.appendingPathComponent(content.capturesDir)
let outputRoot = repoRoot.appendingPathComponent(content.outputDir)
let stagingRoot = repoRoot.appendingPathComponent(content.stagingDir)
let locales = content.copy.keys.sorted()
let fileManager = FileManager.default

try? fileManager.removeItem(at: stagingRoot)

var rendered = 0

for locale in locales {
    let localeOutput = outputRoot.appendingPathComponent(locale).appendingPathComponent("appstore")
    let previewOutput = localeOutput.appendingPathComponent("preview")
    let localeStaging = stagingRoot.appendingPathComponent(locale)
    try? fileManager.removeItem(at: localeOutput)
    try fileManager.createDirectory(at: localeOutput, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: previewOutput, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: localeStaging, withIntermediateDirectories: true)

    for (index, slide) in content.slides.enumerated() {
        guard let copy = content.copy[locale]?[slide.slug] else {
            fputs("Missing copy for \(locale) / \(slide.slug)\n", stderr)
            exit(2)
        }

        let source = capturesRoot.appendingPathComponent(locale).appendingPathComponent(slide.source)
        guard let panelImage = NSImage(contentsOf: source) else {
            fputs("Missing capture \(source.path)\n", stderr)
            exit(3)
        }

        let renderedImage = drawSlide(slide: slide, copy: copy, panelImage: panelImage)
        let filename = String(format: "%02d_%@.jpg", index + 1, slide.slug)
        let outputURL = localeOutput.appendingPathComponent(filename)
        try writeJPEG(renderedImage, to: outputURL)
        try writeJPEG(resize(renderedImage, to: Tokens.previewSize), to: previewOutput.appendingPathComponent(filename), quality: 0.88)
        try fileManager.copyItem(at: outputURL, to: localeStaging.appendingPathComponent(filename))
        rendered += 1
    }
}

print("Rendered \(rendered) macOS App Store screenshots into \(stagingRoot.path)")
