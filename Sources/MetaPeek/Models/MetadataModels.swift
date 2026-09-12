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

struct FileReport: Identifiable {
    let id = UUID()
    let url: URL
    var sections: [MetadataSection] = []
    var thumbnail: NSImage?
    var gpsCoordinate: CLLocationCoordinate2D?
}
