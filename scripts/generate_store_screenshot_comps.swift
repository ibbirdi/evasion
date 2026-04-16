import AppKit
import CoreImage
import Foundation

struct Slide {
    let source: String
    let output: String
    let kicker: String
    let title: String
    let subtitle: String
    let badge: String
    let accent: NSColor
    let top: NSColor
    let bottom: NSColor
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let inputDir = root.appendingPathComponent("fastlane/screenshots/fr-FR")
let outputDir = inputDir.appendingPathComponent("figma-pro")
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let slides = [
    Slide(
        source: "iPhone 17-01_free_sleep.png",
        output: "FR-01-dormir-malgre-le-bruit.jpg",
        kicker: "SOMMEIL",
        title: "Dormez malgré le bruit",
        subtitle: "Créez un fond sonore stable avec oiseaux, vent et plage.",
        badge: "Gratuit pour commencer",
        accent: NSColor(calibratedRed: 0.70, green: 0.95, blue: 0.88, alpha: 1),
        top: NSColor(calibratedRed: 0.04, green: 0.08, blue: 0.09, alpha: 1),
        bottom: NSColor(calibratedRed: 0.13, green: 0.18, blue: 0.15, alpha: 1)
    ),
    Slide(
        source: "iPhone 17-03_free_shuffle.png",
        output: "FR-02-audio-3d.jpg",
        kicker: "AUDIO 3D",
        title: "Votre mix, autour de vous",
        subtitle: "Placez chaque son dans l’espace et dosez le volume.",
        badge: "Spatial sur les sons gratuits",
        accent: NSColor(calibratedRed: 0.58, green: 0.80, blue: 1.00, alpha: 1),
        top: NSColor(calibratedRed: 0.03, green: 0.07, blue: 0.12, alpha: 1),
        bottom: NSColor(calibratedRed: 0.08, green: 0.14, blue: 0.22, alpha: 1)
    ),
    Slide(
        source: "iPhone 17-02_free_timer.png",
        output: "FR-03-minuteur.jpg",
        kicker: "MINUTEUR",
        title: "L’audio s’arrête tout seul",
        subtitle: "15 et 30 min gratuits. 1 h et 2 h avec Premium.",
        badge: "Pensé pour la nuit",
        accent: NSColor(calibratedRed: 1.00, green: 0.83, blue: 0.38, alpha: 1),
        top: NSColor(calibratedRed: 0.08, green: 0.07, blue: 0.04, alpha: 1),
        bottom: NSColor(calibratedRed: 0.20, green: 0.15, blue: 0.08, alpha: 1)
    ),
    Slide(
        source: "iPhone 17-04_premium_library.png",
        output: "FR-04-sons-premium.jpg",
        kicker: "PREMIUM",
        title: "11 sons en plus, hors ligne",
        subtitle: "Pluie, forêt, orage, rivière, train et autres ambiances.",
        badge: "Achat unique",
        accent: NSColor(calibratedRed: 0.71, green: 0.95, blue: 0.62, alpha: 1),
        top: NSColor(calibratedRed: 0.04, green: 0.10, blue: 0.08, alpha: 1),
        bottom: NSColor(calibratedRed: 0.12, green: 0.22, blue: 0.14, alpha: 1)
    ),
    Slide(
        source: "iPhone 17-05_timer_upsell.png",
        output: "FR-05-sans-abonnement.jpg",
        kicker: "SANS ABONNEMENT",
        title: "Premium à vie",
        subtitle: "Débloquez les sons, les mix favoris et les minuteurs longs.",
        badge: "Une seule fois",
        accent: NSColor(calibratedRed: 1.00, green: 0.76, blue: 0.78, alpha: 1),
        top: NSColor(calibratedRed: 0.10, green: 0.05, blue: 0.07, alpha: 1),
        bottom: NSColor(calibratedRed: 0.20, green: 0.10, blue: 0.11, alpha: 1)
    ),
    Slide(
        source: "iPhone 17-06_premium_binaural.png",
        output: "FR-06-focus.jpg",
        kicker: "FOCUS",
        title: "Moins de distractions",
        subtitle: "Un fond sonore régulier pour lire, travailler ou se poser.",
        badge: "Sommeil, détente, concentration",
        accent: NSColor(calibratedRed: 0.82, green: 0.82, blue: 1.00, alpha: 1),
        top: NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.11, alpha: 1),
        bottom: NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.22, alpha: 1)
    ),
]

let canvas = CGSize(width: 1284, height: 2778)
let ciContext = CIContext(options: [.workingColorSpace: NSColorSpace.sRGB.cgColorSpace!])

extension NSColor {
    var cg: CGColor { cgColor }
}

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)
        for i in 0..<elementCount {
            switch element(at: i, associatedPoints: &points) {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        return path
    }
}

func font(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: weight)
}

func drawWrapped(_ text: String, in rect: CGRect, font: NSFont, color: NSColor, lineHeight: CGFloat, alignment: NSTextAlignment = .left) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = max(0, lineHeight - font.pointSize)
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph,
        .kern: -0.4,
    ]
    NSString(string: text).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes)
}

func drawPill(_ text: String, origin: CGPoint, accent: NSColor) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font(31, .semibold),
        .foregroundColor: NSColor.white.withAlphaComponent(0.94),
    ]
    let size = NSString(string: text).size(withAttributes: attrs)
    let rect = CGRect(x: origin.x, y: origin.y, width: size.width + 48, height: 66)
    NSColor.white.withAlphaComponent(0.10).setFill()
    NSBezierPath(roundedRect: rect, xRadius: 33, yRadius: 33).fill()
    accent.withAlphaComponent(0.95).setFill()
    NSBezierPath(ovalIn: CGRect(x: rect.minX + 24, y: rect.midY - 5, width: 10, height: 10)).fill()
    NSString(string: text).draw(at: CGPoint(x: rect.minX + 46, y: rect.minY + 15), withAttributes: attrs)
}

func gradientImage(top: NSColor, bottom: NSColor) -> NSGradient {
    NSGradient(colors: [top, bottom])!
}

func blurredBackground(from image: NSImage, in rect: CGRect) {
    guard let tiff = image.tiffRepresentation, let ciImage = CIImage(data: tiff) else { return }
    let blur = ciImage
        .clampedToExtent()
        .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 38])
        .cropped(to: ciImage.extent)
    guard let cg = ciContext.createCGImage(blur, from: blur.extent) else { return }
    let bg = NSImage(cgImage: cg, size: image.size)
    bg.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 0.16)
}

func drawPhone(_ image: NSImage, y: CGFloat) {
    let phoneWidth: CGFloat = 1016
    let phoneHeight = phoneWidth * image.size.height / image.size.width
    let x = (canvas.width - phoneWidth) / 2
    let rect = CGRect(x: x, y: y, width: phoneWidth, height: phoneHeight)
    let radius: CGFloat = 86

    NSGraphicsContext.current?.cgContext.saveGState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
    shadow.shadowBlurRadius = 44
    shadow.shadowOffset = CGSize(width: 0, height: -24)
    shadow.set()
    NSColor.black.withAlphaComponent(0.65).setFill()
    NSBezierPath(roundedRect: rect.insetBy(dx: -10, dy: -10), xRadius: radius + 10, yRadius: radius + 10).fill()
    NSGraphicsContext.current?.cgContext.restoreGState()

    let clip = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSGraphicsContext.current?.cgContext.saveGState()
    NSGraphicsContext.current?.cgContext.addPath(clip.cgPath)
    NSGraphicsContext.current?.cgContext.clip()
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.current?.cgContext.restoreGState()

    NSColor.white.withAlphaComponent(0.16).setStroke()
    clip.lineWidth = 3
    clip.stroke()
}

for slide in slides {
    let inputURL = inputDir.appendingPathComponent(slide.source)
    guard let appImage = NSImage(contentsOf: inputURL) else {
        throw NSError(domain: "OasisScreenshots", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing \(slide.source)"])
    }

    let output = NSImage(size: canvas)
    output.lockFocus()

    gradientImage(top: slide.top, bottom: slide.bottom).draw(in: CGRect(origin: .zero, size: canvas), angle: 90)
    blurredBackground(from: appImage, in: CGRect(origin: .zero, size: canvas))

    NSColor.black.withAlphaComponent(0.24).setFill()
    NSBezierPath(rect: CGRect(origin: .zero, size: canvas)).fill()

    slide.accent.withAlphaComponent(0.17).setFill()
    NSBezierPath(ovalIn: CGRect(x: -340, y: 1840, width: 980, height: 980)).fill()
    slide.accent.withAlphaComponent(0.13).setFill()
    NSBezierPath(ovalIn: CGRect(x: 730, y: 1410, width: 820, height: 820)).fill()

    drawWrapped(slide.kicker, in: CGRect(x: 86, y: 164, width: 780, height: 46), font: font(28, .bold), color: slide.accent, lineHeight: 34)
    drawWrapped(slide.title, in: CGRect(x: 82, y: 228, width: 1110, height: 230), font: font(91, .heavy), color: .white, lineHeight: 98)
    drawWrapped(slide.subtitle, in: CGRect(x: 86, y: 476, width: 1010, height: 126), font: font(39, .medium), color: NSColor.white.withAlphaComponent(0.78), lineHeight: 52)
    drawPill(slide.badge, origin: CGPoint(x: 86, y: 628), accent: slide.accent)

    drawPhone(appImage, y: 832)

    output.unlockFocus()

    guard let tiff = output.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else {
        throw NSError(domain: "OasisScreenshots", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to encode \(slide.output)"])
    }
    try data.write(to: outputDir.appendingPathComponent(slide.output))
    print("Generated \(outputDir.appendingPathComponent(slide.output).path)")
}
