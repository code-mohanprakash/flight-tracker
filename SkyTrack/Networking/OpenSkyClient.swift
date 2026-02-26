import Foundation
import os

protocol OpenSkyClientProtocol: Sendable {
    func getPositions(bounds: MapBounds) async throws -> [FlightPosition]
    func getPosition(icao24: String) async throws -> FlightPosition?
    func getAllPositions() async throws -> [FlightPosition]
}

struct MapBounds: Sendable {
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double
}

final class OpenSkyClient: OpenSkyClientProtocol, Sendable {
    private let session: URLSession
    private let baseURL = URL(string: "https://opensky-network.org/api")!
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "opensky")

    init(session: URLSession) {
        self.session = session
    }

    func getPositions(bounds: MapBounds) async throws -> [FlightPosition] {
        var components = URLComponents(url: baseURL.appendingPathComponent("states/all"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "lamin", value: String(bounds.minLatitude)),
            URLQueryItem(name: "lamax", value: String(bounds.maxLatitude)),
            URLQueryItem(name: "lomin", value: String(bounds.minLongitude)),
            URLQueryItem(name: "lomax", value: String(bounds.maxLongitude)),
        ]

        return try await fetchPositions(url: components.url!)
    }

    func getPosition(icao24: String) async throws -> FlightPosition? {
        var components = URLComponents(url: baseURL.appendingPathComponent("states/all"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "icao24", value: icao24.lowercased()),
        ]

        let positions = try await fetchPositions(url: components.url!)
        return positions.first
    }

    func getAllPositions() async throws -> [FlightPosition] {
        let url = baseURL.appendingPathComponent("states/all")
        return try await fetchPositions(url: url)
    }

    private func fetchPositions(url: URL) async throws -> [FlightPosition] {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15

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

        Self.logger.info("← \(httpResponse.statusCode) \(url.path)")

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw AppError.api(.rateLimited)
            }
            throw AppError.network(.serverError)
        }

        let decoder = JSONDecoder()
        let statesResponse = try decoder.decode(OpenSkyStatesResponse.self, from: data)
        let positions = statesResponse.toFlightPositions()

        Self.logger.info("Parsed \(positions.count) aircraft positions")
        return positions
    }
}
