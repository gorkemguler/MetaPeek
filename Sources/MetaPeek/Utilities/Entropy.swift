import Foundation

enum Entropy {
    static func shannon(of data: Data) -> Double {
        guard !data.isEmpty else { return 0 }
        var counts = [Int](repeating: 0, count: 256)
        for byte in data { counts[Int(byte)] += 1 }
        let total = Double(data.count)
        return counts.reduce(0.0) { acc, count in
            guard count > 0 else { return acc }
            let p = Double(count) / total
            return acc - p * log2(p)
        }
    }
}
