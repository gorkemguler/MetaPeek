import AppKit
import CoreLocation
import Foundation
import QuickLookThumbnailing
import UniformTypeIdentifiers

enum MetadataService {
    private static let extractors: [MetadataExtractor] = [
        GeneralInfoExtractor(),
        ImageExtractor(),
        PDFExtractor(),
        OfficeExtractor(),
        ArchiveExtractor(),
        AudioVideoExtractor(),
        MachOExtractor(),
        ExifToolExtractor(),
    ]

    static func buildReport(for url: URL) async -> FileReport {
        var report = FileReport(url: url)
        let uti = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType

        for extractor in extractors where extractor.canHandle(url: url, uti: uti) {
            report.sections.append(contentsOf: extractor.extract(url: url))
        }

        report.gpsCoordinate = extractGPSCoordinate(from: report.sections)
        if uti?.conforms(to: .image) == true {
            report.imageAnalyses = ImageForensics.analyses(for: url)
        }
        report.thumbnail = await generateThumbnail(url: url)
        return report
    }

    private static func extractGPSCoordinate(from sections: [MetadataSection]) -> CLLocationCoordinate2D? {
        guard let gpsSection = sections.first(where: { $0.title == "GPS" }) else { return nil }

        func exactField(_ name: String) -> String? {
            gpsSection.fields.first { $0.key == name }?.value
        }

        guard let latString = exactField("Latitude"), let latitude = Double(latString),
              let lonString = exactField("Longitude"), let longitude = Double(lonString) else {
            return nil
        }

        let latRef = exactField("LatitudeRef") ?? "N"
        let lonRef = exactField("LongitudeRef") ?? "E"
        let signedLatitude = latRef.uppercased().hasPrefix("S") ? -latitude : latitude
        let signedLongitude = lonRef.uppercased().hasPrefix("W") ? -longitude : longitude
        return CLLocationCoordinate2D(latitude: signedLatitude, longitude: signedLongitude)
    }

    private static func generateThumbnail(url: URL) async -> NSImage? {
        let size = CGSize(width: 240, height: 240)
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: 2, representationTypes: .thumbnail)

        return await withCheckedContinuation { continuation in
            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { thumbnail, _ in
                if let cgImage = thumbnail?.cgImage {
                    continuation.resume(returning: NSImage(cgImage: cgImage, size: size))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
