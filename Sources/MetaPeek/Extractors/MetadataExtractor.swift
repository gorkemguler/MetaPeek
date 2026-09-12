import Foundation
import UniformTypeIdentifiers

protocol MetadataExtractor {
    func canHandle(url: URL, uti: UTType?) -> Bool
    func extract(url: URL) -> [MetadataSection]
}
