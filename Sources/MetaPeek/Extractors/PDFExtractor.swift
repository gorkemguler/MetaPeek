import Foundation
import PDFKit
import UniformTypeIdentifiers

struct PDFExtractor: MetadataExtractor {
    func canHandle(url: URL, uti: UTType?) -> Bool {
        uti == .pdf || url.pathExtension.lowercased() == "pdf"
    }

    func extract(url: URL) -> [MetadataSection] {
        guard let document = PDFDocument(url: url) else { return [] }

        var fields: [MetadataField] = []
        for (key, value) in document.documentAttributes ?? [:] {
            fields.append(MetadataField(key: "\(key)", value: "\(value)"))
        }
        fields.append(MetadataField(key: "Page Count", value: "\(document.pageCount)"))
        fields.append(MetadataField(key: "Is Encrypted", value: "\(document.isEncrypted)"))
        fields.append(MetadataField(key: "Is Locked", value: "\(document.isLocked)"))
        fields.append(MetadataField(key: "Allows Copying", value: "\(document.allowsCopying)"))
        fields.append(MetadataField(key: "Allows Printing", value: "\(document.allowsPrinting)"))
        fields.append(MetadataField(key: "PDF Version", value: "\(document.majorVersion).\(document.minorVersion)"))

        return [MetadataSection(title: "PDF", fields: fields.sorted { $0.key < $1.key })]
    }
}
