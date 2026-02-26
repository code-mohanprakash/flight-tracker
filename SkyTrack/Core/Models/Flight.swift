import Foundation
import CoreLocation

struct Flight: Identifiable, Codable, Hashable {
    let id: String
    let flightNumber: String
    let flightIata: String?
    let flightIcao: String?
    let airline: Airline?
    let aircraft: Aircraft?
    let departure: FlightEndpoint
    let arrival: FlightEndpoint
    let status: FlightStatus
    let liveData: LiveFlightData?
    let lastUpdated: Date

    var displayName: String {
        flightIata ?? flightIcao ?? flightNumber
    }

    var routeDescription: String {
        "\(departure.airportIata ?? "???") → \(arrival.airportIata ?? "???")"
    }

    var progress: Double? {
        guard status == .active else {
            if status == .landed { return 1.0 }
            return nil
        }
        guard let depTime = departure.actualTime ?? departure.estimatedTime ?? departure.scheduledTime,
              let arrTime = arrival.estimatedTime ?? arrival.scheduledTime else {
            return nil
        }
        let total = arrTime.timeIntervalSince(depTime)
        guard total > 0 else { return nil }
        let elapsed = Date().timeIntervalSince(depTime)
        return min(max(elapsed / total, 0), 1)
    }

    var delayMinutes: Int? {
        if let depDelay = departure.delayMinutes, depDelay > 0 { return depDelay }
        if let arrDelay = arrival.delayMinutes, arrDelay > 0 { return arrDelay }
        return nil
    }
}

struct FlightEndpoint: Codable, Hashable {
    let airportIata: String?
    let airportIcao: String?
    let airportName: String?
    let city: String?
    let country: String?
    let timezone: String?
    let gate: String?
    let terminal: String?
    let baggageClaim: String?
    let scheduledTime: Date?
    let estimatedTime: Date?
    let actualTime: Date?
    let delayMinutes: Int?

    var displayTime: Date? {
        actualTime ?? estimatedTime ?? scheduledTime
    }

    var isDelayed: Bool {
        guard let delay = delayMinutes else { return false }
        return delay > 5
    }

    var displayCode: String {
        airportIata ?? airportIcao ?? "???"
    }
}

struct LiveFlightData: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    let altitude: Double       // meters
    let speed: Double          // km/h
    let heading: Double        // degrees 0-360
    let verticalSpeed: Double  // m/s
    let isGround: Bool
    let updated: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var altitudeFeet: Int {
        Int(altitude * 3.28084)
    }

    var speedKnots: Int {
        Int(speed * 0.539957)
    }

    var verticalRateFPM: Int {
        Int(verticalSpeed * 196.85)
    }
}
