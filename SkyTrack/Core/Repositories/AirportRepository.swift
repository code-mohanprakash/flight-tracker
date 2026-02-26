import Foundation
import os

/// Airport repository powered by the bundled local database.
/// No API calls needed — instant lookups with zero rate limits.
final class AirportRepository: AirportRepositoryProtocol, @unchecked Sendable {
    private let localDB: LocalAirportDatabase

    private static let logger = Logger(subsystem: "com.skytrack.app", category: "airport-repo")

    init(localDB: LocalAirportDatabase = .shared) {
        self.localDB = localDB
    }

    func getAirport(code: String) async throws -> Airport? {
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        Self.logger.info("Looking up airport \(cleanCode) from local database")
        return localDB.getAirport(code: cleanCode)
    }

    func searchAirports(query: String) async throws -> [Airport] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanQuery.count >= 2 else { return [] }
        return localDB.searchAirports(query: cleanQuery)
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
