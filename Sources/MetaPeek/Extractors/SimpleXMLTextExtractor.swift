import Foundation

/// Flattens a small, flat property-bag XML document (Office docProps / ODF meta.xml)
/// into key/value fields, keyed by each leaf element's qualified name.
final class SimpleXMLTextExtractor: NSObject, XMLParserDelegate {
    private var fields: [MetadataField] = []
    private var currentText = ""

    static func extract(from data: Data) -> [MetadataField] {
        let extractor = SimpleXMLTextExtractor()
        let parser = XMLParser(data: data)
        parser.delegate = extractor
        parser.parse()
        return extractor.fields
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentText = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            fields.append(MetadataField(key: qName ?? elementName, value: text))
        }
        currentText = ""
    }
}
