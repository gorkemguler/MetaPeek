import AppKit
import CoreLocation
import MapKit
import SwiftUI

struct MapPreviewView: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        Map(position: .constant(.region(
            MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        ))) {
            Marker("GPS", coordinate: coordinate)
        }
        .overlay(alignment: .bottomTrailing) {
            Button(L10n.openInMaps) {
                if let url = URL(string: "http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(10)
        }
    }
}
