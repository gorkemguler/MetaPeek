import Foundation

/// JPEG encodes in whole MCU blocks, so an image whose dimensions are not a
/// multiple of the MCU size carries padding pixels that decoders crop away.
/// That padding can still hold content from before a crop, which makes its
/// presence worth reporting.
enum JPEGPadding {
    struct Result {
        let width: Int
        let height: Int
        let mcuWidth: Int
        let mcuHeight: Int
        let paddingWidth: Int
        let paddingHeight: Int
    }

    static func inspect(url: URL) -> Result? {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              data.count > 4,
              data[0] == 0xFF, data[1] == 0xD8 else { return nil }

        var index = 2
        while index + 3 < data.count {
            guard data[index] == 0xFF else {
                index += 1
                continue
            }
            let marker = data[index + 1]

            // Padding fill bytes and standalone markers carry no length field.
            if marker == 0xFF { index += 1; continue }
            if marker == 0x01 || (0xD0...0xD9).contains(marker) { index += 2; continue }
            // Start of scan: entropy-coded data follows, no more headers to read.
            if marker == 0xDA { return nil }

            let length = Int(data[index + 2]) << 8 | Int(data[index + 3])
            guard length >= 2, index + 2 + length <= data.count else { return nil }

            if isStartOfFrame(marker) {
                return parseFrame(data, payloadStart: index + 4, payloadEnd: index + 2 + length)
            }
            index += 2 + length
        }
        return nil
    }

    private static func isStartOfFrame(_ marker: UInt8) -> Bool {
        switch marker {
        case 0xC0...0xC3, 0xC5...0xC7, 0xC9...0xCB, 0xCD...0xCF: return true
        default: return false
        }
    }

    private static func parseFrame(_ data: Data, payloadStart: Int, payloadEnd: Int) -> Result? {
        // precision(1) height(2) width(2) components(1), then 3 bytes each.
        guard payloadStart + 6 <= payloadEnd else { return nil }
        let height = Int(data[payloadStart + 1]) << 8 | Int(data[payloadStart + 2])
        let width = Int(data[payloadStart + 3]) << 8 | Int(data[payloadStart + 4])
        let componentCount = Int(data[payloadStart + 5])
        guard width > 0, height > 0, componentCount > 0,
              payloadStart + 6 + componentCount * 3 <= payloadEnd else { return nil }

        var maxHorizontal = 1
        var maxVertical = 1
        for component in 0..<componentCount {
            let sampling = data[payloadStart + 6 + component * 3 + 1]
            maxHorizontal = max(maxHorizontal, Int(sampling >> 4))
            maxVertical = max(maxVertical, Int(sampling & 0x0F))
        }

        let mcuWidth = maxHorizontal * 8
        let mcuHeight = maxVertical * 8
        let paddedWidth = (width + mcuWidth - 1) / mcuWidth * mcuWidth
        let paddedHeight = (height + mcuHeight - 1) / mcuHeight * mcuHeight

        return Result(
            width: width,
            height: height,
            mcuWidth: mcuWidth,
            mcuHeight: mcuHeight,
            paddingWidth: paddedWidth - width,
            paddingHeight: paddedHeight - height
        )
    }
}
