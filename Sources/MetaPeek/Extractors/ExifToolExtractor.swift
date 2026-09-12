import Foundation
import UniformTypeIdentifiers

/// Optional enrichment: if the user has exiftool installed (e.g. `brew install exiftool`),
/// surface whatever extra fields it finds beyond the native extractors above.
struct ExifToolExtractor: MetadataExtractor {
    func canHandle(url: URL, uti: UTType?) -> Bool {
        ProcessRunner.findExecutable("exiftool") != nil
    }

    func extract(url: URL) -> [MetadataSection] {
        guard let exiftool = ProcessRunner.findExecutable("exiftool"),
              let result = ProcessRunner.run(exiftool, ["-json", "-G", "-a", "-u", url.path]),
              let data = result.stdout.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let dict = array.first else { return [] }

        var grouped: [String: [MetadataField]] = [:]
        for (key, value) in dict {
            guard key != "SourceFile" else { continue }
            let parts = key.split(separator: ":", maxSplits: 1)
            let group = parts.count == 2 ? String(parts[0]) : "Other"
            let name = parts.count == 2 ? String(parts[1]) : key
            grouped[group, default: []].append(MetadataField(key: name, value: "\(value)"))
        }

        return grouped.keys.sorted().compactMap { group in
            guard let fields = grouped[group] else { return nil }
            return MetadataSection(title: "ExifTool: \(group)", fields: fields.sorted { $0.key < $1.key })
        }
    }
}
