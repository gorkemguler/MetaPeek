import AVFoundation
import Foundation
import UniformTypeIdentifiers

struct AudioVideoExtractor: MetadataExtractor {
    func canHandle(url: URL, uti: UTType?) -> Bool {
        guard let uti else { return false }
        return uti.conforms(to: .audiovisualContent) || uti.conforms(to: .audio) || uti.conforms(to: .movie)
    }

    func extract(url: URL) -> [MetadataSection] {
        let asset = AVURLAsset(url: url)
        var sections: [MetadataSection] = []

        var general: [MetadataField] = []
        let seconds = CMTimeGetSeconds(asset.duration)
        if seconds.isFinite {
            general.append(MetadataField(key: "Duration", value: String(format: "%.2f s", seconds)))
        }
        for track in asset.tracks {
            let size = track.naturalSize
            general.append(MetadataField(
                key: "Track (\(track.mediaType.rawValue))",
                value: "\(Int(size.width))x\(Int(size.height)), \(String(format: "%.2f", track.nominalFrameRate)) fps, ~\(Int(track.estimatedDataRate)) bps"
            ))
        }
        if !general.isEmpty {
            sections.append(MetadataSection(title: "Media", fields: general))
        }

        var seenKeys = Set<String>()
        var metaFields: [MetadataField] = []
        for item in asset.commonMetadata + asset.metadata {
            let key = item.commonKey?.rawValue ?? item.identifier?.rawValue ?? "unknown"
            guard !seenKeys.contains(key) else { continue }
            seenKeys.insert(key)
            if let value = item.stringValue, !value.isEmpty {
                metaFields.append(MetadataField(key: key, value: value))
            } else if let value = item.value {
                metaFields.append(MetadataField(key: key, value: "\(value)"))
            }
        }
        if !metaFields.isEmpty {
            sections.append(MetadataSection(title: "Embedded Metadata", fields: metaFields.sorted { $0.key < $1.key }))
        }

        return sections
    }
}
