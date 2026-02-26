import Foundation

enum SearchResult: Identifiable, Hashable {
    case flight(Flight)
    case airport(Airport)

    var id: String {
        switch self {
        case .flight(let f): "flight_\(f.id)"
        case .airport(let a): "airport_\(a.id)"
        }
    }
}

final class SearchFlightsUseCase: Sendable {
    private let flightRepository: FlightRepositoryProtocol
    private let airportRepository: AirportRepositoryProtocol

    init(flightRepository: FlightRepositoryProtocol, airportRepository: AirportRepositoryProtocol) {
        self.flightRepository = flightRepository
        self.airportRepository = airportRepository
    }

    func searchFlights(query: String) async throws -> [Flight] {
        try await flightRepository.searchFlights(query: query)
    }

    func searchAirports(query: String) async throws -> [Airport] {
        try await airportRepository.searchAirports(query: query)
    }

    func search(query: String) async throws -> [SearchResult] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanQuery.isEmpty else { return [] }

        // If it looks like a flight number (starts with 2 letters + digits), search flights
        let looksLikeFlightNumber = cleanQuery.count >= 3 &&
            cleanQuery.prefix(2).allSatisfy(\.isLetter) &&
            cleanQuery.dropFirst(2).first?.isNumber == true

        if looksLikeFlightNumber {
            let flights = try await flightRepository.searchFlights(query: cleanQuery)
            return flights.map { .flight($0) }
        }

        // If it's exactly 3 letters, could be IATA code — search both
        if cleanQuery.count == 3 && cleanQuery.allSatisfy(\.isLetter) {
            async let flightsResult = flightRepository.searchFlights(query: cleanQuery)
            async let airportsResult = airportRepository.searchAirports(query: cleanQuery)

            let flights = (try? await flightsResult) ?? []
            let airports = (try? await airportsResult) ?? []

            var results: [SearchResult] = airports.map { .airport($0) }
            results.append(contentsOf: flights.map { .flight($0) })
            return results
        }

        // Otherwise search airports by name
        let airports = try await airportRepository.searchAirports(query: cleanQuery)
        return airports.map { .airport($0) }
    }
}
