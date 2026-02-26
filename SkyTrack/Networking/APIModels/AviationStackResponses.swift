import Foundation

// MARK: - Generic Paginated Response
struct AviationStackResponse<T: Decodable>: Decodable {
    let pagination: Pagination?
    let data: [T]

    struct Pagination: Decodable {
        let limit: Int?
        let offset: Int?
        let count: Int?
        let total: Int?
    }
}

// MARK: - Flight Response
struct AviationStackFlight: Decodable {
    let flightDate: String?
    let flightStatus: String?
    let departure: ASDeparture?
    let arrival: ASArrival?
    let airline: ASAirline?
    let flight: ASFlightInfo?
    let aircraft: ASAircraft?
    let live: ASLive?

    struct ASDeparture: Decodable {
        let airport: String?
        let timezone: String?
        let iata: String?
        let icao: String?
        let terminal: String?
        let gate: String?
        let delay: Int?
        let scheduled: String?
        let estimated: String?
        let actual: String?
    }

    struct ASArrival: Decodable {
        let airport: String?
        let timezone: String?
        let iata: String?
        let icao: String?
        let terminal: String?
        let gate: String?
        let baggage: String?
        let delay: Int?
        let scheduled: String?
        let estimated: String?
        let actual: String?
    }

    struct ASAirline: Decodable {
        let name: String?
        let iata: String?
        let icao: String?
    }

    struct ASFlightInfo: Decodable {
        let number: String?
        let iata: String?
        let icao: String?
    }

    struct ASAircraft: Decodable {
        let registration: String?
        let iata: String?
        let icao: String?
        let icao24: String?
    }

    struct ASLive: Decodable {
        let updated: String?
        let latitude: Double?
        let longitude: Double?
        let altitude: Double?
        let direction: Double?
        let speedHorizontal: Double?
        let speedVertical: Double?
        let isGround: Bool?
    }
}

// MARK: - Airport Response
struct AviationStackAirport: Decodable {
    let airportName: String?
    let iataCode: String?
    let icaoCode: String?
    let latitude: String?
    let longitude: String?
    let geonameCityId: String?
    let timezone: String?
    let gmt: String?
    let countryName: String?
    let countryIso2: String?
    let cityIataCode: String?
    let phoneNumber: String?
}

// MARK: - Airline Response
struct AviationStackAirline: Decodable {
    let airlineName: String?
    let iataCode: String?
    let icaoCode: String?
    let countryName: String?
}
