import AppKit
import CoreLocation
import Foundation

struct MetadataField: Identifiable, Hashable {
    let id = UUID()
    let key: String
    let value: String
}

struct MetadataSection: Identifiable, Hashable {
    let id = UUID()
    let title: String
    var fields: [MetadataField]
}

/// A rendered forensic view of an image (ELA, LSB planes) plus the numbers
/// behind it. Kept separate from MetadataSection because the picture, not the
/// key/value pairs, is the actual result.
struct ImageAnalysis: Identifiable {
    let id = UUID()
    let title: String
    /// Stable English title for JSON export, so scripts don't have to cope
    /// with the interface language changing the keys.
    let exportTitle: String
    let icon: String
    let explanation: String
    /// CGImage, not NSImage: this is produced on a background task during app
    /// launch, and touching AppKit there races AppKit's own initialization.
    let image: CGImage
    var fields: [MetadataField] = []
}

struct FileReport: Identifiable {
    let id = UUID()
    let url: URL
    var sections: [MetadataSection] = []
    var thumbnail: NSImage?
    var gpsCoordinate: CLLocationCoordinate2D?
    var imageAnalyses: [ImageAnalysis] = []
}
