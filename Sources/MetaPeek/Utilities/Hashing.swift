import CryptoKit
import Foundation

enum Hashing {
    struct Result {
        let md5: String
        let sha1: String
        let sha256: String
    }

    static func hash(fileAt url: URL, chunkSize: Int = 1 << 20) -> Result? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        var md5 = Insecure.MD5()
        var sha1 = Insecure.SHA1()
        var sha256 = SHA256()

        while true {
            let chunk = handle.readData(ofLength: chunkSize)
            if chunk.isEmpty { break }
            md5.update(data: chunk)
            sha1.update(data: chunk)
            sha256.update(data: chunk)
        }

        func hex(_ digest: some Sequence<UInt8>) -> String {
            digest.map { String(format: "%02x", $0) }.joined()
        }

        return Result(
            md5: hex(md5.finalize()),
            sha1: hex(sha1.finalize()),
            sha256: hex(sha256.finalize())
        )
    }
}
