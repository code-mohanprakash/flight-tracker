import Foundation
import os

final class FlightRepository: FlightRepositoryProtocol, @unchecked Sendable {
    private let apiClient: APIClientProtocol
    private let openSkyClient: OpenSkyClientProtocol
    private let cache: FlightCache

    private static let logger = Logger(subsystem: "com.skytrack.app", category: "flight-repo")

    init(apiClient: APIClientProtocol, openSkyClient: OpenSkyClientProtocol, cache: FlightCache) {
        self.apiClient = apiClient
        self.openSkyClient = openSkyClient
        self.cache = cache
    }

    func getFlight(flightNumber: String) async throws -> Flight? {
        let cleanNumber = flightNumber
            .replacingOccurrences(of: " ", with: "")
            .uppercased()

        if let cached = cache.getFlight(flightNumber: cleanNumber) {
            Self.logger.info("Cache hit for flight \(cleanNumber)")
            return cached
        }

        let endpoint = AviationStackEndpoints.flightByNumber(cleanNumber)
        let response: AviationStackResponse<AviationStackFlight> = try await apiClient.request(endpoint)
        let flights = APIModelMapper.mapFlights(response.data)

        for flight in flights {
            cache.store(flight: flight)
        }

        return flights.first
    }

    func searchFlights(query: String) async throws -> [Flight] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let endpoint = AviationStackEndpoints.flights(flightIata: cleanQuery)
        let response: AviationStackResponse<AviationStackFlight> = try await apiClient.request(endpoint)
        return APIModelMapper.mapFlights(response.data)
    }

    func getDepartures(airportCode: String) async throws -> [Flight] {
        let endpoint = AviationStackEndpoints.departures(airportCode: airportCode.uppercased())
        let response: AviationStackResponse<AviationStackFlight> = try await apiClient.request(endpoint)
        return APIModelMapper.mapFlights(response.data)
            .sorted { ($0.departure.scheduledTime ?? .distantFuture) < ($1.departure.scheduledTime ?? .distantFuture) }
    }

    func getArrivals(airportCode: String) async throws -> [Flight] {
        let endpoint = AviationStackEndpoints.arrivals(airportCode: airportCode.uppercased())
        let response: AviationStackResponse<AviationStackFlight> = try await apiClient.request(endpoint)
        return APIModelMapper.mapFlights(response.data)
            .sorted { ($0.arrival.scheduledTime ?? .distantFuture) < ($1.arrival.scheduledTime ?? .distantFuture) }
    }

    func getPositions(bounds: MapBounds) async throws -> [FlightPosition] {
        try await openSkyClient.getPositions(bounds: bounds)
    }

    func getActiveFlights() async throws -> [Flight] {
        let endpoint = AviationStackEndpoints.flights(flightStatus: "active")
        let response: AviationStackResponse<AviationStackFlight> = try await apiClient.request(endpoint)
        return APIModelMapper.mapFlights(response.data)
    }
}

// MARK: - Flight Cache
final class FlightCache: @unchecked Sendable {
    private var flights: [String: CacheEntry<Flight>] = [:]
    private let lock = NSLock()
    private let ttl: TimeInterval

    struct CacheEntry<T> {
        let value: T
        let timestamp: Date
    }

    init(ttl: TimeInterval = Configuration.cacheTTL) {
        self.ttl = ttl
    }

    func getFlight(flightNumber: String) -> Flight? {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = flights[flightNumber],
              Date().timeIntervalSince(entry.timestamp) < ttl else {
            return nil
        }
        return entry.value
    }

    func store(flight: Flight) {
        lock.lock()
        defer { lock.unlock() }
        let key = flight.flightIata ?? flight.flightIcao ?? flight.flightNumber
        flights[key] = CacheEntry(value: flight, timestamp: Date())
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        flights.removeAll()
    }
}
