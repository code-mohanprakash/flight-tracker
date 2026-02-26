import Foundation
import CoreLocation
import MapKit

enum Constants {
    enum Map {
        static let defaultCenter = CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795) // US center
        static let defaultSpan = MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
        static let minZoomForAircraft: Double = 3.0
        static let maxVisibleAircraft = 500
    }

    enum API {
        static let positionUpdateInterval: TimeInterval = 10
        static let flightRefreshInterval: TimeInterval = 60
        static let searchDebounce: TimeInterval = 0.3
        static let cacheTTL: TimeInterval = 300
    }

    enum Formatting {
        static let distanceFormatter: MKDistanceFormatter = {
            let f = MKDistanceFormatter()
            f.unitStyle = .abbreviated
            return f
        }()
    }
}
