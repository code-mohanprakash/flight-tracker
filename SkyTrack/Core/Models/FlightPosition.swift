import Foundation
import CoreLocation

struct FlightPosition: Identifiable, Hashable {
    let id: String           // ICAO24 transponder address
    let callsign: String?
    let latitude: Double
    let longitude: Double
    let altitude: Double     // meters (barometric)
    let velocity: Double     // m/s ground speed
    let trueTrack: Double    // degrees heading (0-360)
    let verticalRate: Double // m/s
    let onGround: Bool
    let lastUpdate: Date
    let originCountry: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var altitudeFeet: Int {
        Int(altitude * 3.28084)
    }

    var speedKnots: Int {
        Int(velocity * 1.94384)
    }

    var headingRadians: Double {
        trueTrack * .pi / 180.0
    }

    var cleanCallsign: String {
        callsign?.trimmingCharacters(in: .whitespaces) ?? id
    }
}
