import Foundation
import os

final class AirportRepository: AirportRepositoryProtocol, @unchecked Sendable {
    private let apiClient: APIClientProtocol
    private let cache: AirportCache

    private static let logger = Logger(subsystem: "com.skytrack.app", category: "airport-repo")

    init(apiClient: APIClientProtocol, cache: AirportCache) {
        self.apiClient = apiClient
        self.cache = cache
    }

    func getAirport(code: String) async throws -> Airport? {
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if let cached = cache.getAirport(code: cleanCode) {
            Self.logger.info("Cache hit for airport \(cleanCode)")
            return cached
        }

        let endpoint = AviationStackEndpoints.airports(iataCode: cleanCode)
        let response: AviationStackResponse<AviationStackAirport> = try await apiClient.request(endpoint)
        let airports = APIModelMapper.mapAirports(response.data)

        for airport in airports {
            cache.store(airport: airport)
        }

        return airports.first
    }

    func searchAirports(query: String) async throws -> [Airport] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanQuery.count >= 2 else { return [] }

        let endpoint = AviationStackEndpoints.airports(search: cleanQuery)
        let response: AviationStackResponse<AviationStackAirport> = try await apiClient.request(endpoint)
        let airports = APIModelMapper.mapAirports(response.data)

        for airport in airports {
            cache.store(airport: airport)
        }

        return airports
    }
}

// MARK: - Airport Cache
final class AirportCache: @unchecked Sendable {
    private var airports: [String: FlightCache.CacheEntry<Airport>] = [:]
    private let lock = NSLock()
    private let ttl: TimeInterval

    init(ttl: TimeInterval = 3600) { // 1 hour TTL for airports
        self.ttl = ttl
    }

    func getAirport(code: String) -> Airport? {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = airports[code],
              Date().timeIntervalSince(entry.timestamp) < ttl else {
            return nil
        }
        return entry.value
    }

    func store(airport: Airport) {
        lock.lock()
        defer { lock.unlock() }
        if let iata = airport.iataCode {
            airports[iata] = FlightCache.CacheEntry(value: airport, timestamp: Date())
        }
        if let icao = airport.icaoCode {
            airports[icao] = FlightCache.CacheEntry(value: airport, timestamp: Date())
        }
    }
}
