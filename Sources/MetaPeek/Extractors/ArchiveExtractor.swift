import Foundation
import UniformTypeIdentifiers
import ZIPFoundation

struct ArchiveExtractor: MetadataExtractor {
    private static let zipExtensions: Set<String> = ["zip", "jar", "ipa", "apk"]
    private static let tarSuffixes = ["tar", "tar.gz", "tgz", "tar.bz2", "tbz2", "tar.xz", "txz"]

    func canHandle(url: URL, uti: UTType?) -> Bool {
        let ext = url.pathExtension.lowercased()
        if Self.zipExtensions.contains(ext) { return true }
        let name = url.lastPathComponent.lowercased()
        return Self.tarSuffixes.contains { name.hasSuffix(".\($0)") }
    }

    func extract(url: URL) -> [MetadataSection] {
        let ext = url.pathExtension.lowercased()

        if Self.zipExtensions.contains(ext), let archive = try? Archive(url: url, accessMode: .read, pathEncoding: nil) {
            var fields: [MetadataField] = []
            for entry in archive {
                fields.append(MetadataField(key: entry.path, value: "\(entry.type) · \(entry.uncompressedSize) bytes"))
            }
            return [MetadataSection(title: "Archive Contents (\(fields.count) entries)", fields: fields)]
        }

        if let tarBin = ProcessRunner.findExecutable("tar"),
           let out = ProcessRunner.run(tarBin, ["-tvf", url.path])?.stdout, !out.isEmpty {
            let lines = out.split(separator: "\n").map(String.init)
            let fields = lines.prefix(500).enumerated().map {
                MetadataField(key: "Entry \($0.offset + 1)", value: $0.element)
            }
            return [MetadataSection(title: "Archive Contents (\(lines.count) entries)", fields: fields)]
        }

        return []
    }
}
