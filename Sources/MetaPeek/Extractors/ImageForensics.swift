import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Visual forensics for images: Error Level Analysis and least-significant-bit
/// inspection. Both produce a picture rather than key/value metadata, so they
/// live outside the MetadataExtractor pipeline.
enum ImageForensics {
    /// Analysis runs on a downscaled copy so a 50 MP photo doesn't stall the UI.
    private static let maxDimension = 1400
    private static let recompressionQuality: CGFloat = 0.90
    private static let uniqueColorCap = 65_536
    private static let alphaScanPixelCap = 40_000_000

    static func analyses(for url: URL) -> [ImageAnalysis] {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let original = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return [] }

        let working = scaledDown(original)
        guard let pixels = Pixels(image: working) else { return [] }

        var results: [ImageAnalysis] = []
        if let ela = errorLevelAnalysis(image: working, pixels: pixels) {
            results.append(ela)
        }
        if let hidden = hiddenPixels(pixels: pixels, url: url) {
            results.append(hidden)
        }
        return results
    }

    // MARK: - Error Level Analysis

    private static func errorLevelAnalysis(image: CGImage, pixels: Pixels) -> ImageAnalysis? {
        guard let recompressed = recompress(image),
              let resaved = Pixels(image: recompressed),
              resaved.bytes.count == pixels.bytes.count else { return nil }

        var diff = [UInt8](repeating: 255, count: pixels.bytes.count)
        var maxDifference = 0
        var differenceTotal = 0
        let pixelCount = pixels.width * pixels.height

        for index in 0..<pixelCount {
            let offset = index * 4
            var pixelPeak = 0
            for channel in 0..<3 {
                let delta = abs(Int(pixels.bytes[offset + channel]) - Int(resaved.bytes[offset + channel]))
                diff[offset + channel] = UInt8(delta)
                pixelPeak = max(pixelPeak, delta)
            }
            maxDifference = max(maxDifference, pixelPeak)
            differenceTotal += pixelPeak
        }

        // Amplify so the differences are actually visible; without this an
        // untouched JPEG renders as near-black.
        let amplification = maxDifference > 0 ? min(255.0 / Double(maxDifference), 40.0) : 1.0
        for index in 0..<pixelCount {
            let offset = index * 4
            for channel in 0..<3 {
                diff[offset + channel] = UInt8(min(255.0, Double(diff[offset + channel]) * amplification))
            }
        }

        guard let rendered = makeImage(bytes: diff, width: pixels.width, height: pixels.height) else { return nil }

        let mean = Double(differenceTotal) / Double(pixelCount)
        return ImageAnalysis(
            title: L10n.elaTitle,
            icon: "square.3.layers.3d.down.right",
            explanation: L10n.elaExplanation,
            image: rendered,
            fields: [
                MetadataField(key: "Max Difference", value: "\(maxDifference) / 255"),
                MetadataField(key: "Mean Difference", value: String(format: "%.2f / 255", mean)),
                MetadataField(key: "Amplification", value: String(format: "%.1fx", amplification)),
                MetadataField(key: "Recompression Quality", value: String(format: "%.0f%%", recompressionQuality * 100)),
                MetadataField(key: "Analyzed Size", value: "\(pixels.width)x\(pixels.height)"),
            ]
        )
    }

    private static func recompress(_ image: CGImage) -> CGImage? {
        let buffer = CFDataCreateMutable(nil, 0)!
        guard let destination = CGImageDestinationCreateWithData(buffer, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, [
            kCGImageDestinationLossyCompressionQuality: recompressionQuality,
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination),
              let source = CGImageSourceCreateWithData(buffer, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    // MARK: - Hidden pixels

    private static func hiddenPixels(pixels: Pixels, url: URL) -> ImageAnalysis? {
        var plane = [UInt8](repeating: 255, count: pixels.bytes.count)
        var uniqueColors = Set<UInt32>()
        var colorsCapped = false
        var fullyTransparent = 0
        let pixelCount = pixels.width * pixels.height

        for index in 0..<pixelCount {
            let offset = index * 4
            let red = pixels.bytes[offset]
            let green = pixels.bytes[offset + 1]
            let blue = pixels.bytes[offset + 2]

            plane[offset] = (red & 1) == 1 ? 255 : 0
            plane[offset + 1] = (green & 1) == 1 ? 255 : 0
            plane[offset + 2] = (blue & 1) == 1 ? 255 : 0

            if pixels.bytes[offset + 3] == 0 { fullyTransparent += 1 }

            if !colorsCapped {
                uniqueColors.insert(UInt32(red) << 16 | UInt32(green) << 8 | UInt32(blue))
                if uniqueColors.count >= uniqueColorCap { colorsCapped = true }
            }
        }

        guard let rendered = makeImage(bytes: plane, width: pixels.width, height: pixels.height) else { return nil }

        var fields = [
            MetadataField(key: "Unique Colors", value: colorsCapped ? "\(uniqueColorCap)+" : "\(uniqueColors.count)"),
            MetadataField(key: "Fully Transparent Pixels", value: "\(fullyTransparent)"),
        ]
        if let concealed = colorUnderTransparency(url: url) {
            let note = concealed > 0 ? " (\(L10n.hiddenDataSuspected))" : ""
            fields.append(MetadataField(key: "Transparent Pixels With Color Data", value: "\(concealed)\(note)"))
        }
        fields.append(MetadataField(key: "Analyzed Size", value: "\(pixels.width)x\(pixels.height)"))

        return ImageAnalysis(
            title: L10n.hiddenPixelsTitle,
            icon: "eye.trianglebadge.exclamationmark",
            explanation: L10n.hiddenPixelsExplanation,
            image: rendered,
            fields: fields
        )
    }

    /// Fully transparent pixels that still carry colour are a classic place to
    /// stash data. Only answerable when the decoder hands back straight (not
    /// premultiplied) alpha, since premultiplication zeroes those channels.
    private static func colorUnderTransparency(url: URL) -> Int? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              image.bitsPerComponent == 8,
              image.bitsPerPixel == 32,
              image.width * image.height <= alphaScanPixelCap else { return nil }

        let alphaInfo = image.alphaInfo
        guard alphaInfo == .last || alphaInfo == .first else { return nil }

        guard let data = image.dataProvider?.data as Data?,
              data.count >= image.height * image.bytesPerRow else { return nil }

        let bytesPerRow = image.bytesPerRow
        let width = image.width
        let height = image.height
        let alphaLast = alphaInfo == .last

        return data.withUnsafeBytes { raw -> Int in
            guard let base = raw.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
            var concealed = 0
            for y in 0..<height {
                let row = base + y * bytesPerRow
                for x in 0..<width {
                    let pixel = row + x * 4
                    let alpha = alphaLast ? pixel[3] : pixel[0]
                    guard alpha == 0 else { continue }
                    let a = alphaLast ? pixel[0] : pixel[1]
                    let b = alphaLast ? pixel[1] : pixel[2]
                    let c = alphaLast ? pixel[2] : pixel[3]
                    if a != 0 || b != 0 || c != 0 { concealed += 1 }
                }
            }
            return concealed
        }
    }

    // MARK: - Pixel plumbing

    private struct Pixels {
        let bytes: [UInt8]
        let width: Int
        let height: Int

        init?(image: CGImage) {
            let width = image.width
            let height = image.height
            guard width > 0, height > 0 else { return nil }
            guard let context = CGContext(
                data: nil, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return nil }

            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            guard let base = context.data else { return nil }
            let raw = base.bindMemory(to: UInt8.self, capacity: width * height * 4)
            self.bytes = Array(UnsafeBufferPointer(start: raw, count: width * height * 4))
            self.width = width
            self.height = height
        }
    }

    private static func scaledDown(_ image: CGImage) -> CGImage {
        let longestSide = max(image.width, image.height)
        guard longestSide > maxDimension else { return image }

        let scale = Double(maxDimension) / Double(longestSide)
        let width = max(1, Int((Double(image.width) * scale).rounded()))
        let height = max(1, Int((Double(image.height) * scale).rounded()))
        guard let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return image }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage() ?? image
    }

    private static func makeImage(bytes: [UInt8], width: Int, height: Int) -> CGImage? {
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(
            width: width, height: height,
            bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )
    }
}
