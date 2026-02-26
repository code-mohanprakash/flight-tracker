import Foundation
import CoreLocation

enum DistanceCalculator {
    /// Calculate great circle distance in kilometers
    static func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let loc2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return loc1.distance(from: loc2) / 1000.0
    }

    /// Calculate great circle distance in nautical miles
    static func distanceNM(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        distance(from: from, to: to) * 0.539957
    }

    /// Format distance for display
    static func formatDistance(km: Double) -> String {
        if km < 1 {
            return "\(Int(km * 1000)) m"
        }
        if km < 100 {
            return String(format: "%.1f km", km)
        }
        return "\(Int(km)) km"
    }

    /// Format distance in nautical miles for display
    static func formatDistanceNM(km: Double) -> String {
        let nm = km * 0.539957
        return "\(Int(nm)) nm"
    }

    /// Calculate bearing between two coordinates
    static func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180 / .pi

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}
