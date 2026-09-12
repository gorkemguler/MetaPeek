import Foundation

enum FileSignature {
    private static let signatures: [(bytes: [UInt8], name: String)] = [
        ([0x89, 0x50, 0x4E, 0x47], "PNG image"),
        ([0xFF, 0xD8, 0xFF], "JPEG image"),
        ([0x47, 0x49, 0x46, 0x38], "GIF image"),
        ([0x25, 0x50, 0x44, 0x46], "PDF document"),
        ([0x50, 0x4B, 0x03, 0x04], "ZIP archive (or Office/OpenDocument/JAR)"),
        ([0x50, 0x4B, 0x05, 0x06], "ZIP archive (empty)"),
        ([0x7F, 0x45, 0x4C, 0x46], "ELF executable"),
        ([0x4D, 0x5A], "Windows PE/DOS executable"),
        ([0xFE, 0xED, 0xFA, 0xCE], "Mach-O 32-bit binary"),
        ([0xCE, 0xFA, 0xED, 0xFE], "Mach-O 32-bit binary (reversed)"),
        ([0xFE, 0xED, 0xFA, 0xCF], "Mach-O 64-bit binary"),
        ([0xCF, 0xFA, 0xED, 0xFE], "Mach-O 64-bit binary (reversed)"),
        ([0xCA, 0xFE, 0xBA, 0xBE], "Mach-O fat binary / Java class file"),
        ([0xBE, 0xBA, 0xFE, 0xCA], "Mach-O fat binary (reversed)"),
        ([0x1F, 0x8B], "GZIP archive"),
        ([0x42, 0x5A, 0x68], "BZIP2 archive"),
        ([0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C], "7-Zip archive"),
        ([0x52, 0x61, 0x72, 0x21, 0x1A, 0x07], "RAR archive"),
        ([0x49, 0x44, 0x33], "MP3 audio (ID3)"),
        ([0x66, 0x4C, 0x61, 0x43], "FLAC audio"),
        ([0x4F, 0x67, 0x67, 0x53], "OGG container"),
        ([0x52, 0x49, 0x46, 0x46], "RIFF container (WAV/AVI)"),
        ([0x53, 0x51, 0x4C, 0x69, 0x74, 0x65], "SQLite database"),
        ([0x25, 0x21, 0x50, 0x53], "PostScript document"),
        ([0x7B, 0x5C, 0x72, 0x74, 0x66], "RTF document"),
        ([0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1], "Legacy Office (OLE2) document"),
    ]

    static func detect(prefix: Data) -> String? {
        let bytes = [UInt8](prefix)
        for signature in signatures where bytes.starts(with: signature.bytes) {
            return signature.name
        }
        if bytes.count >= 12, bytes[4] == 0x66, bytes[5] == 0x74, bytes[6] == 0x79, bytes[7] == 0x70 {
            let brand = String(bytes: bytes[8..<12], encoding: .ascii)?.trimmingCharacters(in: .whitespaces) ?? ""
            let heifBrands: Set<String> = ["heic", "heix", "heim", "heis", "hevc", "hevx", "hevm", "hevs", "mif1", "msf1"]
            if heifBrands.contains(brand) {
                return "HEIC/HEIF image (ftyp: \(brand))"
            }
            return "MP4/QuickTime media (ftyp: \(brand))"
        }
        return nil
    }
}
