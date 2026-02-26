import Foundation

// MARK: - ADSB.lol / ADSB.One Response (ADSBExchange v2 Format)

/// Shared response format used by ADSB.lol and ADSB.One APIs.
/// Both services use the ADSBExchange v2 compatible format.
struct ADSBResponse: Decodable {
    let ac: [ADSBAircraft]?
    let msg: String?
    let now: Double?
    let total: Int?
    let ctime: Double?
    let ptime: Int?
}

struct ADSBAircraft: Decodable {
    // MARK: - Identity
    let hex: String?               // ICAO 24-bit hex address
    let flight: String?            // Callsign (may be padded with spaces)
    let r: String?                 // Registration (e.g., "N12345")
    let t: String?                 // Aircraft type (e.g., "B738", "A320")

    // MARK: - Position
    let lat: Double?
    let lon: Double?
    let altBaro: AltitudeValue?    // Barometric altitude (feet) or "ground"
    let altGeom: Int?              // Geometric altitude (feet)

    // MARK: - Movement
    let gs: Double?                // Ground speed (knots)
    let track: Double?             // Track/heading (degrees 0-360)
    let baroRate: Int?             // Barometric vertical rate (fpm)
    let geomRate: Int?             // Geometric vertical rate (fpm)

    // MARK: - Navigation
    let navAltitudeMcp: Int?       // MCP selected altitude
    let navHeading: Double?        // Selected heading
    let navQnh: Double?            // Altimeter setting (hPa)

    // MARK: - Speeds
    let ias: Int?                  // Indicated airspeed (knots)
    let tas: Int?                  // True airspeed (knots)
    let mach: Double?              // Mach number

    // MARK: - Weather
    let wd: Int?                   // Wind direction
    let ws: Int?                   // Wind speed (knots)
    let oat: Int?                  // Outside air temperature (C)
    let tat: Int?                  // Total air temperature (C)

    // MARK: - Transponder
    let squawk: String?            // Squawk code
    let emergency: String?         // Emergency status
    let category: String?          // Emitter category (A0-D7)

    // MARK: - Data quality
    let nic: Int?                  // Navigation integrity category
    let rc: Int?                   // Radius of containment
    let seenPos: Double?           // Seconds since last position update
    let seen: Double?              // Seconds since any message
    let messages: Int?             // Total messages received
    let rssi: Double?              // Signal strength (dBFS)

    // MARK: - Flags
    let alert: Int?
    let spi: Int?                  // Special position identification
    let dbFlags: Int?              // Database flags

    // MARK: - Coding Keys (snake_case from API)
    enum CodingKeys: String, CodingKey {
        case hex, flight, r, t
        case lat, lon
        case altBaro = "alt_baro"
        case altGeom = "alt_geom"
        case gs, track
        case baroRate = "baro_rate"
        case geomRate = "geom_rate"
        case navAltitudeMcp = "nav_altitude_mcp"
        case navHeading = "nav_heading"
        case navQnh = "nav_qnh"
        case ias, tas, mach
        case wd, ws, oat, tat
        case squawk, emergency, category
        case nic, rc
        case seenPos = "seen_pos"
        case seen, messages, rssi
        case alert, spi
        case dbFlags = "db_flags"
    }
}

/// Altitude can be an integer (feet) or the string "ground"
enum AltitudeValue: Decodable {
    case feet(Int)
    case ground

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self = .feet(intVal)
        } else if let strVal = try? container.decode(String.self), strVal == "ground" {
            self = .ground
        } else {
            self = .feet(0)
        }
    }

    var isGround: Bool {
        if case .ground = self { return true }
        return false
    }

    var feetValue: Int {
        switch self {
        case .feet(let ft): return ft
        case .ground: return 0
        }
    }
}

// MARK: - Conversion to Domain Models

extension ADSBResponse {
    func toFlightPositions() -> [FlightPosition] {
        guard let aircraft = ac else { return [] }
        return aircraft.compactMap { ac in
            guard let hex = ac.hex,
                  let lat = ac.lat,
                  let lon = ac.lon,
                  lat != 0 || lon != 0 else {
                return nil
            }

            let callsign = ac.flight?.trimmingCharacters(in: .whitespaces)
            let isOnGround = ac.altBaro?.isGround ?? false
            let altitudeFeet = ac.altBaro?.feetValue ?? ac.altGeom ?? 0
            let altitudeMeters = Double(altitudeFeet) * 0.3048
            let speedKnots = ac.gs ?? 0
            let speedMS = speedKnots * 0.514444
            let heading = ac.track ?? 0
            let vertRateFPM = ac.baroRate ?? ac.geomRate ?? 0
            let vertRateMS = Double(vertRateFPM) * 0.00508

            let lastSeen = ac.seen ?? 0
            let timestamp: Date
            if let now = now {
                timestamp = Date(timeIntervalSince1970: (now / 1000.0) - lastSeen)
            } else {
                timestamp = Date().addingTimeInterval(-lastSeen)
            }

            return FlightPosition(
                id: hex,
                callsign: callsign,
                latitude: lat,
                longitude: lon,
                altitude: altitudeMeters,
                velocity: speedMS,
                trueTrack: heading,
                verticalRate: vertRateMS,
                onGround: isOnGround,
                lastUpdate: timestamp,
                originCountry: nil
            )
        }
    }
}

extension ADSBAircraft {
    /// Convert to a partial Flight object using ADSB data + local databases
    func toFlight(airportDB: LocalAirportDatabase, airlineDB: LocalAirlineDatabase) -> Flight? {
        guard let hex = hex else { return nil }
        let callsign = flight?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !callsign.isEmpty else { return nil }

        let airline = airlineDB.airlineFromCallsign(callsign)
        let flightIata = airline?.iataCode.flatMap { iata in
            let suffix = String(callsign.dropFirst(airline?.icaoCode?.count ?? 3))
            return "\(iata)\(suffix)"
        }

        let isOnGround = altBaro?.isGround ?? false
        let altitudeFeet = altBaro?.feetValue ?? altGeom ?? 0
        let altitudeMeters = Double(altitudeFeet) * 0.3048
        let speedKnots = gs ?? 0
        let speedKMH = speedKnots * 1.852
        let heading = track ?? 0
        let vertRateFPM = baroRate ?? geomRate ?? 0
        let vertRateMS = Double(vertRateFPM) * 0.00508

        let liveData = LiveFlightData(
            latitude: lat ?? 0,
            longitude: lon ?? 0,
            altitude: altitudeMeters,
            speed: speedKMH,
            heading: heading,
            verticalSpeed: vertRateMS,
            isGround: isOnGround,
            updated: Date()
        )

        let aircraft = Aircraft(
            id: r ?? hex,
            registration: r,
            icao24: hex,
            type: t,
            modelName: nil,
            manufacturer: nil,
            age: nil,
            airlineName: airline?.name
        )

        let status: FlightStatus
        if isOnGround && (speedKnots < 30) {
            status = .landed
        } else {
            status = .active
        }

        let dateStr = ISO8601DateFormatter().string(from: Date()).prefix(10)

        return Flight(
            id: "\(callsign)_\(dateStr)",
            flightNumber: callsign,
            flightIata: flightIata,
            flightIcao: callsign,
            airline: airline,
            aircraft: aircraft,
            departure: FlightEndpoint(
                airportIata: nil, airportIcao: nil, airportName: nil,
                city: nil, country: nil, timezone: nil, gate: nil,
                terminal: nil, baggageClaim: nil, scheduledTime: nil,
                estimatedTime: nil, actualTime: nil, delayMinutes: nil
            ),
            arrival: FlightEndpoint(
                airportIata: nil, airportIcao: nil, airportName: nil,
                city: nil, country: nil, timezone: nil, gate: nil,
                terminal: nil, baggageClaim: nil, scheduledTime: nil,
                estimatedTime: nil, actualTime: nil, delayMinutes: nil
            ),
            status: status,
            liveData: liveData,
            lastUpdated: Date()
        )
    }
}
