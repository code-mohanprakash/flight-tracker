import Foundation
import os

// MARK: - ADSB Client Protocol

protocol ADSBClientProtocol: Sendable {
    /// Get all aircraft positions within a bounding box
    func getPositions(bounds: MapBounds) async throws -> [FlightPosition]

    /// Get a single aircraft position by ICAO hex address
    func getPosition(hex: String) async throws -> FlightPosition?

    /// Get all aircraft positions (global)
    func getAllPositions() async throws -> [FlightPosition]

    /// Search for aircraft by callsign (flight number)
    func getByCallsign(_ callsign: String) async throws -> ADSBResponse

    /// Search for aircraft by registration
    func getByRegistration(_ registration: String) async throws -> ADSBResponse

    /// Search for aircraft by ICAO hex
    func getByHex(_ hex: String) async throws -> ADSBResponse

    /// Get aircraft by type (e.g., "B738", "A320")
    func getByType(_ type: String) async throws -> ADSBResponse

    /// Get aircraft near a point (lat, lon, radius in nautical miles)
    func getNearby(latitude: Double, longitude: Double, radiusNM: Double) async throws -> ADSBResponse
}

// MARK: - ADSB.lol Client (Primary — No Rate Limits, No API Key, Fully Open Source)

final class ADSBLolClient: ADSBClientProtocol, Sendable {
    private let session: URLSession
    private let baseURL = URL(string: "https://api.adsb.lol/v2")!
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "adsb-lol")

    init(session: URLSession) {
        self.session = session
    }

    func getPositions(bounds: MapBounds) async throws -> [FlightPosition] {
        // ADSB.lol doesn't have a direct bounding box endpoint,
        // so we use the center + radius approach
        let centerLat = (bounds.minLatitude + bounds.maxLatitude) / 2.0
        let centerLon = (bounds.minLongitude + bounds.maxLongitude) / 2.0

        // Calculate radius in nautical miles from bounding box
        let latDiff = abs(bounds.maxLatitude - bounds.minLatitude)
        let lonDiff = abs(bounds.maxLongitude - bounds.minLongitude)
        let maxDiff = max(latDiff, lonDiff)
        let radiusNM = maxDiff * 60 / 2 // degrees to NM (1 degree ≈ 60 NM)
        let clampedRadius = min(radiusNM, 250) // cap at 250 NM

        let response = try await getNearby(
            latitude: centerLat,
            longitude: centerLon,
            radiusNM: clampedRadius
        )
        return response.toFlightPositions()
    }

    func getPosition(hex: String) async throws -> FlightPosition? {
        let response = try await getByHex(hex)
        return response.toFlightPositions().first
    }

    func getAllPositions() async throws -> [FlightPosition] {
        let url = baseURL.appendingPathComponent("all")
        let response: ADSBResponse = try await fetch(url: url)
        return response.toFlightPositions()
    }

    func getByCallsign(_ callsign: String) async throws -> ADSBResponse {
        let clean = callsign.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let url = baseURL.appendingPathComponent("callsign/\(clean)")
        return try await fetch(url: url)
    }

    func getByRegistration(_ registration: String) async throws -> ADSBResponse {
        let clean = registration.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let url = baseURL.appendingPathComponent("reg/\(clean)")
        return try await fetch(url: url)
    }

    func getByHex(_ hex: String) async throws -> ADSBResponse {
        let clean = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let url = baseURL.appendingPathComponent("hex/\(clean)")
        return try await fetch(url: url)
    }

    func getByType(_ type: String) async throws -> ADSBResponse {
        let clean = type.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let url = baseURL.appendingPathComponent("type/\(clean)")
        return try await fetch(url: url)
    }

    func getNearby(latitude: Double, longitude: Double, radiusNM: Double) async throws -> ADSBResponse {
        let url = baseURL.appendingPathComponent("lat/\(latitude)/lon/\(longitude)/dist/\(radiusNM)")
        return try await fetch(url: url)
    }

    private func fetch<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        Self.logger.info("→ GET \(url.path)")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw AppError.network(.noConnection)
            case .timedOut:
                throw AppError.network(.timeout)
            default:
                throw AppError.network(.serverError)
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.api(.invalidResponse)
        }

        Self.logger.info("← \(httpResponse.statusCode) \(url.path) (\(data.count) bytes)")

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw AppError.api(.rateLimited)
            }
            throw AppError.network(.serverError)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            Self.logger.error("Decode error: \(error)")
            throw AppError.api(.decodingError)
        }
    }
}

// MARK: - ADSB.One Client (Fallback — 1 req/sec, No API Key)

final class ADSBOneClient: ADSBClientProtocol, Sendable {
    private let session: URLSession
    private let baseURL = URL(string: "https://api.adsb.one/v2")!
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "adsb-one")

    init(session: URLSession) {
        self.session = session
    }

    func getPositions(bounds: MapBounds) async throws -> [FlightPosition] {
        let centerLat = (bounds.minLatitude + bounds.maxLatitude) / 2.0
        let centerLon = (bounds.minLongitude + bounds.maxLongitude) / 2.0
        let latDiff = abs(bounds.maxLatitude - bounds.minLatitude)
        let lonDiff = abs(bounds.maxLongitude - bounds.minLongitude)
        let maxDiff = max(latDiff, lonDiff)
        let radiusNM = min(maxDiff * 60 / 2, 250)

        let response = try await getNearby(
            latitude: centerLat,
            longitude: centerLon,
            radiusNM: radiusNM
        )
        return response.toFlightPositions()
    }

    func getPosition(hex: String) async throws -> FlightPosition? {
        let response = try await getByHex(hex)
        return response.toFlightPositions().first
    }

    func getAllPositions() async throws -> [FlightPosition] {
        let url = baseURL.appendingPathComponent("all")
        let response: ADSBResponse = try await fetch(url: url)
        return response.toFlightPositions()
    }

    func getByCallsign(_ callsign: String) async throws -> ADSBResponse {
        let clean = callsign.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let url = baseURL.appendingPathComponent("callsign/\(clean)")
        return try await fetch(url: url)
    }

    func getByRegistration(_ registration: String) async throws -> ADSBResponse {
        let clean = registration.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let url = baseURL.appendingPathComponent("reg/\(clean)")
        return try await fetch(url: url)
    }

    func getByHex(_ hex: String) async throws -> ADSBResponse {
        let clean = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let url = baseURL.appendingPathComponent("hex/\(clean)")
        return try await fetch(url: url)
    }

    func getByType(_ type: String) async throws -> ADSBResponse {
        let clean = type.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let url = baseURL.appendingPathComponent("type/\(clean)")
        return try await fetch(url: url)
    }

    func getNearby(latitude: Double, longitude: Double, radiusNM: Double) async throws -> ADSBResponse {
        let url = baseURL.appendingPathComponent("lat/\(latitude)/lon/\(longitude)/dist/\(radiusNM)")
        return try await fetch(url: url)
    }

    private func fetch<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        Self.logger.info("→ GET \(url.path)")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw AppError.network(.noConnection)
            case .timedOut:
                throw AppError.network(.timeout)
            default:
                throw AppError.network(.serverError)
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.api(.invalidResponse)
        }

        Self.logger.info("← \(httpResponse.statusCode) \(url.path) (\(data.count) bytes)")

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw AppError.api(.rateLimited)
            }
            throw AppError.network(.serverError)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            Self.logger.error("Decode error: \(error)")
            throw AppError.api(.decodingError)
        }
    }
}

// MARK: - Multi-Source ADSB Client (Auto-Failover)

/// Combines ADSB.lol (primary) with ADSB.One (fallback) and OpenSky (last resort).
/// Automatically falls over to the next source if the primary fails.
final class MultiSourceADSBClient: ADSBClientProtocol, Sendable {
    private let primary: ADSBClientProtocol
    private let fallback: ADSBClientProtocol
    private let openSky: OpenSkyClientProtocol
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "adsb-multi")

    init(primary: ADSBClientProtocol, fallback: ADSBClientProtocol, openSky: OpenSkyClientProtocol) {
        self.primary = primary
        self.fallback = fallback
        self.openSky = openSky
    }

    func getPositions(bounds: MapBounds) async throws -> [FlightPosition] {
        do {
            return try await primary.getPositions(bounds: bounds)
        } catch {
            Self.logger.warning("Primary ADSB failed for positions, trying fallback: \(error.localizedDescription)")
            do {
                return try await fallback.getPositions(bounds: bounds)
            } catch {
                Self.logger.warning("Fallback ADSB failed, trying OpenSky: \(error.localizedDescription)")
                return try await openSky.getPositions(bounds: bounds)
            }
        }
    }

    func getPosition(hex: String) async throws -> FlightPosition? {
        do {
            return try await primary.getPosition(hex: hex)
        } catch {
            Self.logger.warning("Primary ADSB failed for hex \(hex), trying fallback")
            do {
                return try await fallback.getPosition(hex: hex)
            } catch {
                Self.logger.warning("Fallback ADSB failed, trying OpenSky for \(hex)")
                return try await openSky.getPosition(icao24: hex)
            }
        }
    }

    func getAllPositions() async throws -> [FlightPosition] {
        do {
            return try await primary.getAllPositions()
        } catch {
            Self.logger.warning("Primary ADSB failed for all positions, trying fallback")
            do {
                return try await fallback.getAllPositions()
            } catch {
                Self.logger.warning("Fallback ADSB failed, trying OpenSky")
                return try await openSky.getAllPositions()
            }
        }
    }

    func getByCallsign(_ callsign: String) async throws -> ADSBResponse {
        do {
            return try await primary.getByCallsign(callsign)
        } catch {
            Self.logger.warning("Primary ADSB failed for callsign \(callsign), trying fallback")
            return try await fallback.getByCallsign(callsign)
        }
    }

    func getByRegistration(_ registration: String) async throws -> ADSBResponse {
        do {
            return try await primary.getByRegistration(registration)
        } catch {
            Self.logger.warning("Primary ADSB failed for reg \(registration), trying fallback")
            return try await fallback.getByRegistration(registration)
        }
    }

    func getByHex(_ hex: String) async throws -> ADSBResponse {
        do {
            return try await primary.getByHex(hex)
        } catch {
            Self.logger.warning("Primary ADSB failed for hex \(hex), trying fallback")
            return try await fallback.getByHex(hex)
        }
    }

    func getByType(_ type: String) async throws -> ADSBResponse {
        do {
            return try await primary.getByType(type)
        } catch {
            Self.logger.warning("Primary ADSB failed for type \(type), trying fallback")
            return try await fallback.getByType(type)
        }
    }

    func getNearby(latitude: Double, longitude: Double, radiusNM: Double) async throws -> ADSBResponse {
        do {
            return try await primary.getNearby(latitude: latitude, longitude: longitude, radiusNM: radiusNM)
        } catch {
            Self.logger.warning("Primary ADSB failed for nearby, trying fallback")
            return try await fallback.getNearby(latitude: latitude, longitude: longitude, radiusNM: radiusNM)
        }
    }
}
