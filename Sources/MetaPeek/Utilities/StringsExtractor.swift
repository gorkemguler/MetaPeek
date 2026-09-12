import Foundation

enum StringsExtractor {
    static func extract(from data: Data, minLength: Int = 4, limit: Int = 200) -> [String] {
        var results: [String] = []
        var current: [UInt8] = []

        func flush() {
            if current.count >= minLength, let s = String(bytes: current, encoding: .ascii) {
                results.append(s)
            }
            current.removeAll(keepingCapacity: true)
        }

        for byte in data {
            if byte >= 0x20 && byte < 0x7F {
                current.append(byte)
            } else {
                flush()
                if results.count >= limit { return results }
            }
        }
        flush()
        return results
    }
}
