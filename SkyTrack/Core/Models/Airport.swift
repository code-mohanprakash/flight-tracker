import Foundation
import CoreLocation

struct Airport: Identifiable, Codable, Hashable {
    let id: String
    let iataCode: String?
    let icaoCode: String?
    let name: String
    let city: String?
    let country: String?
    let countryCode: String?
    let latitude: Double
    let longitude: Double
    let timezone: String?
    let altitude: Int?

    var displayCode: String {
        iataCode ?? icaoCode ?? id
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var fullName: String {
        if let city {
            return "\(name) (\(city))"
        }
        return name
    }
}
