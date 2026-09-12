import Foundation
import UniformTypeIdentifiers
import ZIPFoundation

struct OfficeExtractor: MetadataExtractor {
    private static let officeExtensions: Set<String> = [
        "docx", "xlsx", "pptx", "docm", "xlsm", "pptm",
        "dotx", "dotm", "xltx", "xltm", "potx", "potm",
        "odt", "ods", "odp",
    ]

    func canHandle(url: URL, uti: UTType?) -> Bool {
        Self.officeExtensions.contains(url.pathExtension.lowercased())
    }

    func extract(url: URL) -> [MetadataSection] {
        guard let archive = try? Archive(url: url, accessMode: .read, pathEncoding: nil) else { return [] }
        var sections: [MetadataSection] = []

        func parseEntry(_ entryName: String, title: String) {
            guard let entry = archive[entryName] else { return }
            var data = Data()
            _ = try? archive.extract(entry) { data.append($0) }
            guard !data.isEmpty else { return }
            let fields = SimpleXMLTextExtractor.extract(from: data)
            if !fields.isEmpty {
                sections.append(MetadataSection(title: title, fields: fields))
            }
        }

        parseEntry("docProps/core.xml", title: "Core Properties")
        parseEntry("docProps/app.xml", title: "Application Properties")
        parseEntry("docProps/custom.xml", title: "Custom Properties")
        parseEntry("meta.xml", title: "OpenDocument Metadata")

        var entryFields: [MetadataField] = []
        for entry in archive {
            entryFields.append(MetadataField(key: entry.path, value: "\(entry.uncompressedSize) bytes"))
        }
        if !entryFields.isEmpty {
            sections.append(MetadataSection(title: "Archive Contents (\(entryFields.count) entries)", fields: entryFields))
        }

        return sections
    }
}
