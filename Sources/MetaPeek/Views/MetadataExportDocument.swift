import SwiftUI
import UniformTypeIdentifiers

struct MetadataExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let report: FileReport

    init(report: FileReport) {
        self.report = report
    }

    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadUnsupportedScheme)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var sectionsArray: [[String: Any]] = report.sections.map { section in
            var fieldsDict: [String: String] = [:]
            for field in section.fields { fieldsDict[field.key] = field.value }
            return ["title": section.title, "fields": fieldsDict]
        }
        for analysis in report.imageAnalyses {
            var fieldsDict: [String: String] = [:]
            for field in analysis.fields { fieldsDict[field.key] = field.value }
            sectionsArray.append(["title": analysis.exportTitle, "fields": fieldsDict])
        }
        let dict: [String: Any] = [
            "file": report.url.path,
            "sections": sectionsArray,
        ]
        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        return FileWrapper(regularFileWithContents: data)
    }
}
