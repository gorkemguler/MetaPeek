import AppKit

let size = 1024
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("could not create bitmap rep") }

NSGraphicsContext.saveGraphicsState()
let gctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = gctx
let ctx = gctx.cgContext
let s = CGFloat(size)

// Background: flat, professional slate-navy gradient.
let bgColors = [
    NSColor(calibratedRed: 0.11, green: 0.14, blue: 0.21, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.13, alpha: 1).cgColor,
]
let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bgColors as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])

let ringColor = NSColor(calibratedRed: 0.92, green: 0.94, blue: 0.98, alpha: 1)
let accentColor = NSColor(calibratedRed: 0.38, green: 0.55, blue: 0.92, alpha: 1)
let lensCenter = CGPoint(x: s * 0.46, y: s * 0.56)
let lensRadius: CGFloat = 200

// Lens interior: subtly lighter than the background, flat fill.
ctx.setFillColor(NSColor(calibratedRed: 0.15, green: 0.18, blue: 0.26, alpha: 1).cgColor)
ctx.fillEllipse(in: CGRect(x: lensCenter.x - lensRadius, y: lensCenter.y - lensRadius, width: lensRadius * 2, height: lensRadius * 2))

// Minimal "text lines" glyph inside the lens, reads as document/metadata, not binary.
ctx.saveGState()
let lensPath = CGPath(ellipseIn: CGRect(x: lensCenter.x - lensRadius, y: lensCenter.y - lensRadius, width: lensRadius * 2, height: lensRadius * 2), transform: nil)
ctx.addPath(lensPath)
ctx.clip()
let lineWidths: [CGFloat] = [150, 110, 130]
let lineHeight: CGFloat = 22
let lineSpacing: CGFloat = 42
let totalHeight = CGFloat(lineWidths.count - 1) * lineSpacing
var lineY = lensCenter.y + totalHeight / 2
for (index, width) in lineWidths.enumerated() {
    let color = index == 0 ? accentColor : ringColor.withAlphaComponent(0.85)
    ctx.setFillColor(color.cgColor)
    let rect = CGRect(x: lensCenter.x - width / 2, y: lineY - lineHeight / 2, width: width, height: lineHeight)
    let path = CGPath(roundedRect: rect, cornerWidth: lineHeight / 2, cornerHeight: lineHeight / 2, transform: nil)
    ctx.addPath(path)
    ctx.fillPath()
    lineY -= lineSpacing
}
ctx.restoreGState()

// Lens ring: clean, flat, no glow.
ctx.setStrokeColor(ringColor.cgColor)
ctx.setLineWidth(42)
ctx.setLineCap(.round)
ctx.strokeEllipse(in: CGRect(x: lensCenter.x - lensRadius, y: lensCenter.y - lensRadius, width: lensRadius * 2, height: lensRadius * 2))

// Handle.
let handleStart = CGPoint(
    x: lensCenter.x + lensRadius * cos(.pi / 4),
    y: lensCenter.y - lensRadius * sin(.pi / 4)
)
let handleEnd = CGPoint(x: handleStart.x + 175, y: handleStart.y - 175)
ctx.setStrokeColor(ringColor.cgColor)
ctx.setLineWidth(42)
ctx.setLineCap(.round)
ctx.move(to: handleStart)
ctx.addLine(to: handleEnd)
ctx.strokePath()

NSGraphicsContext.restoreGraphicsState()

guard let pngData = rep.representation(using: .png, properties: [:]) else { fatalError("could not encode png") }
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("wrote \(outputPath)")
