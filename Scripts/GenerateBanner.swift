import AppKit

let width = 1700
let height = 600

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("could not create bitmap rep") }

NSGraphicsContext.saveGraphicsState()
let gctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = gctx
let ctx = gctx.cgContext
let w = CGFloat(width)
let h = CGFloat(height)

// Background: same slate-navy as the app icon.
let bgColors = [
    NSColor(calibratedRed: 0.11, green: 0.14, blue: 0.21, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.13, alpha: 1).cgColor,
]
let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bgColors as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 0, y: h), end: CGPoint(x: 0, y: 0), options: [])

let ringColor = NSColor(calibratedRed: 0.92, green: 0.94, blue: 0.98, alpha: 1)
let accentColor = NSColor(calibratedRed: 0.38, green: 0.55, blue: 0.92, alpha: 1)
let lensCenter = CGPoint(x: 300, y: 310)
let lensRadius: CGFloat = 104

// Lens interior.
ctx.setFillColor(NSColor(calibratedRed: 0.15, green: 0.18, blue: 0.26, alpha: 1).cgColor)
ctx.fillEllipse(in: CGRect(x: lensCenter.x - lensRadius, y: lensCenter.y - lensRadius, width: lensRadius * 2, height: lensRadius * 2))

// Document lines inside the lens.
let lineSpecs: [(width: CGFloat, color: NSColor)] = [
    (76, accentColor),
    (56, ringColor.withAlphaComponent(0.85)),
    (66, ringColor.withAlphaComponent(0.85)),
]
let lineHeight: CGFloat = 12
let lineSpacing: CGFloat = 26
var lineY = lensCenter.y + lineSpacing
for spec in lineSpecs {
    ctx.setFillColor(spec.color.cgColor)
    let rect = CGRect(x: lensCenter.x - spec.width / 2, y: lineY - lineHeight / 2, width: spec.width, height: lineHeight)
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: lineHeight / 2, cornerHeight: lineHeight / 2, transform: nil))
    ctx.fillPath()
    lineY -= lineSpacing
}

// Ring and handle.
ctx.setStrokeColor(ringColor.cgColor)
ctx.setLineWidth(24)
ctx.setLineCap(.round)
ctx.strokeEllipse(in: CGRect(x: lensCenter.x - lensRadius, y: lensCenter.y - lensRadius, width: lensRadius * 2, height: lensRadius * 2))

let handleStart = CGPoint(
    x: lensCenter.x + lensRadius * cos(-.pi / 4),
    y: lensCenter.y + lensRadius * sin(-.pi / 4)
)
ctx.move(to: handleStart)
ctx.addLine(to: CGPoint(x: handleStart.x + 68, y: handleStart.y - 68))
ctx.strokePath()

// Wordmark and tagline.
let wordmark = NSAttributedString(string: "MetaPeek", attributes: [
    .font: NSFont.systemFont(ofSize: 116, weight: .bold),
    .foregroundColor: NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.98, alpha: 1),
])
let tagline = NSAttributedString(string: "Metadata inspection for any file, built for CTF & OSINT", attributes: [
    .font: NSFont.systemFont(ofSize: 40, weight: .regular),
    .foregroundColor: NSColor(calibratedRed: 0.60, green: 0.64, blue: 0.72, alpha: 1),
])

let textX: CGFloat = 560
let taglineHeight = tagline.size().height
let wordmarkHeight = wordmark.size().height
let blockHeight = wordmarkHeight + 14 + taglineHeight
let blockBottom = (h - blockHeight) / 2

tagline.draw(at: CGPoint(x: textX + 4, y: blockBottom))
wordmark.draw(at: CGPoint(x: textX, y: blockBottom + taglineHeight + 14))

NSGraphicsContext.restoreGraphicsState()

guard let pngData = rep.representation(using: .png, properties: [:]) else { fatalError("could not encode png") }
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "banner.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("wrote \(outputPath)")
