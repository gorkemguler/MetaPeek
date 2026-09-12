import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ImageExtractor: MetadataExtractor {
    func canHandle(url: URL, uti: UTType?) -> Bool {
        guard let uti else { return false }
        return uti.conforms(to: .image)
    }

    func extract(url: URL) -> [MetadataSection] {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return []
        }

        var sections: [MetadataSection] = []

        var topFields: [MetadataField] = []
        let topKeys: [CFString] = [
            kCGImagePropertyPixelWidth, kCGImagePropertyPixelHeight,
            kCGImagePropertyDPIWidth, kCGImagePropertyDPIHeight,
            kCGImagePropertyColorModel, kCGImagePropertyDepth,
            kCGImagePropertyOrientation, kCGImagePropertyProfileName,
        ]
        for key in topKeys {
            if let value = props[key] {
                topFields.append(MetadataField(key: describe(key), value: "\(value)"))
            }
        }
        if !topFields.isEmpty {
            sections.append(MetadataSection(title: "Image", fields: topFields))
        }

        addDictionarySection(&sections, title: "EXIF", dict: props[kCGImagePropertyExifDictionary] as? [CFString: Any])
        addDictionarySection(&sections, title: "EXIF Aux", dict: props[kCGImagePropertyExifAuxDictionary] as? [CFString: Any])
        addDictionarySection(&sections, title: "TIFF", dict: props[kCGImagePropertyTIFFDictionary] as? [CFString: Any])
        addDictionarySection(&sections, title: "GPS", dict: props[kCGImagePropertyGPSDictionary] as? [CFString: Any])
        addDictionarySection(&sections, title: "IPTC", dict: props[kCGImagePropertyIPTCDictionary] as? [CFString: Any])
        addDictionarySection(&sections, title: "PNG", dict: props[kCGImagePropertyPNGDictionary] as? [CFString: Any])
        addDictionarySection(&sections, title: "JFIF", dict: props[kCGImagePropertyJFIFDictionary] as? [CFString: Any])
        addDictionarySection(&sections, title: "GIF", dict: props[kCGImagePropertyGIFDictionary] as? [CFString: Any])
        addDictionarySection(&sections, title: "HEIC (Apple Maker)", dict: props[kCGImagePropertyMakerAppleDictionary] as? [CFString: Any])

        return sections
    }

    private func describe(_ key: CFString) -> String {
        "\(key)"
    }

    private func addDictionarySection(_ sections: inout [MetadataSection], title: String, dict: [CFString: Any]?) {
        guard let dict, !dict.isEmpty else { return }
        let fields = dict
            .map { MetadataField(key: describe($0.key), value: "\($0.value)") }
            .sorted { $0.key < $1.key }
        sections.append(MetadataSection(title: title, fields: fields))
    }
}
