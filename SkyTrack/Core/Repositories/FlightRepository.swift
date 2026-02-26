import Foundation
import os

final class FlightRepository: FlightRepositoryProtocol, @unchecked Sendable {
    private let adsbClient: ADSBClientProtocol
    private let cache: FlightCache
    private let airportDB: LocalAirportDatabase
    private let airlineDB: LocalAirlineDatabase

    private static let logger = Logger(subsystem: "com.skytrack.app", category: "flight-repo")

    init(
        adsbClient: ADSBClientProtocol,
        cache: FlightCache,
        airportDB: LocalAirportDatabase = .shared,
        airlineDB: LocalAirlineDatabase = .shared
    ) {
        self.adsbClient = adsbClient
        self.cache = cache
        self.airportDB = airportDB
        self.airlineDB = airlineDB
    }

    func getFlight(flightNumber: String) async throws -> Flight? {
        let cleanNumber = flightNumber
            .replacingOccurrences(of: " ", with: "")
            .uppercased()

        if let cached = cache.getFlight(flightNumber: cleanNumber) {
            Self.logger.info("Cache hit for flight \(cleanNumber)")
            return cached
        }

        // Convert IATA flight number (e.g., "UA123") to ICAO callsign (e.g., "UAL123")
        let callsign = iataToCallsign(cleanNumber)
        let response = try await adsbClient.getByCallsign(callsign)

        guard let aircraft = response.ac, !aircraft.isEmpty else {
            // Try original number in case it's already ICAO format
            if callsign != cleanNumber {
                let fallback = try await adsbClient.getByCallsign(cleanNumber)
                let flights = (fallback.ac ?? []).compactMap { $0.toFlight(airportDB: airportDB, airlineDB: airlineDB) }
                flights.forEach { cache.store(flight: $0) }
                return flights.first
            }
            return nil
        }

        let flights = aircraft.compactMap { $0.toFlight(airportDB: airportDB, airlineDB: airlineDB) }
        flights.forEach { cache.store(flight: $0) }
        return flights.first
    }

    func searchFlights(query: String) async throws -> [Flight] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Try as callsign first
        let callsign = iataToCallsign(cleanQuery)
        let response = try await adsbClient.getByCallsign(callsign)
        var flights = (response.ac ?? []).compactMap { $0.toFlight(airportDB: airportDB, airlineDB: airlineDB) }

        // If no results and query differs from callsign, try original
        if flights.isEmpty && callsign != cleanQuery {
            let fallback = try await adsbClient.getByCallsign(cleanQuery)
            flights = (fallback.ac ?? []).compactMap { $0.toFlight(airportDB: airportDB, airlineDB: airlineDB) }
        }

        // If still empty, try as registration
        if flights.isEmpty {
            let regResponse = try await adsbClient.getByRegistration(cleanQuery)
            flights = (regResponse.ac ?? []).compactMap { $0.toFlight(airportDB: airportDB, airlineDB: airlineDB) }
        }

        return flights
    }

    func getDepartures(airportCode: String) async throws -> [Flight] {
        let code = airportCode.uppercased()
        guard let airport = airportDB.getAirport(code: code) else { return [] }

        // Get flights near the airport (within 5 NM — on the ground or just departed)
        let response = try await adsbClient.getNearby(
            latitude: airport.latitude,
            longitude: airport.longitude,
            radiusNM: 5
        )

        return (response.ac ?? []).compactMap { ac -> Flight? in
            guard let flight = ac.toFlight(airportDB: airportDB, airlineDB: airlineDB) else { return nil }
            let altFeet = ac.altBaro?.feetValue ?? ac.altGeom ?? 0
            let isOnGround = ac.altBaro?.isGround ?? false
            guard isOnGround || altFeet < 10000 else { return nil }
            return flight
        }
    }

    func getArrivals(airportCode: String) async throws -> [Flight] {
        let code = airportCode.uppercased()
        guard let airport = airportDB.getAirport(code: code) else { return [] }

        // Get flights near the airport (within 30 NM — approaching for landing)
        let response = try await adsbClient.getNearby(
            latitude: airport.latitude,
            longitude: airport.longitude,
            radiusNM: 30
        )

        return (response.ac ?? []).compactMap { ac -> Flight? in
            guard let flight = ac.toFlight(airportDB: airportDB, airlineDB: airlineDB) else { return nil }
            let altFeet = ac.altBaro?.feetValue ?? ac.altGeom ?? 0
            let vertRate = ac.baroRate ?? ac.geomRate ?? 0
            let isOnGround = ac.altBaro?.isGround ?? false
            guard isOnGround || altFeet < 15000 || vertRate < -200 else { return nil }
            return flight
        }
    }

    func getPositions(bounds: MapBounds) async throws -> [FlightPosition] {
        try await adsbClient.getPositions(bounds: bounds)
    }

    func getActiveFlights() async throws -> [Flight] {
        // Active flights are shown via live positions on the map
        return []
    }

    // MARK: - Helpers

    /// Convert IATA flight number (e.g., "UA123") to ICAO callsign (e.g., "UAL123")
    private func iataToCallsign(_ flightNumber: String) -> String {
        var iataPrefix = ""
        var numericPart = ""
        var foundDigit = false

        for char in flightNumber {
            if char.isNumber {
                foundDigit = true
                numericPart.append(char)
            } else if !foundDigit {
                iataPrefix.append(char)
            } else {
                numericPart.append(char)
            }
        }

        if let airline = airlineDB.getAirline(code: iataPrefix),
           let icao = airline.icaoCode {
            return "\(icao)\(numericPart)"
        }

        return flightNumber
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
