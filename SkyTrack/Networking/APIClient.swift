import Foundation
import os

protocol APIClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

final class APIClient: APIClientProtocol, Sendable {
    private let session: URLSession
    private let configuration: APIConfiguration

    private static let logger = Logger(subsystem: "com.skytrack.app", category: "networking")

    struct APIConfiguration: Sendable {
        let baseURL: URL
        let apiKey: String
    }

    init(session: URLSession, configuration: APIConfiguration) {
        self.session = session
        self.configuration = configuration
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let url = buildURL(for: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = 30

        Self.logger.info("→ \(endpoint.method.rawValue) \(endpoint.path)")

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

        Self.logger.info("← \(httpResponse.statusCode) \(endpoint.path) (\(data.count) bytes)")

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401, 403:
            throw AppError.api(.unauthorized)
        case 404:
            throw AppError.api(.notFound)
        case 429:
            throw AppError.api(.rateLimited)
        case 500...599:
            throw AppError.network(.serverError)
        default:
            throw AppError.api(.httpError(statusCode: httpResponse.statusCode))
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let string = try container.decode(String.self)
                if let date = Date.from(isoString: string) {
                    return date
                }
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date: \(string)"
                )
            }
            return try decoder.decode(T.self, from: data)
        } catch {
            Self.logger.error("Decode error for \(endpoint.path): \(error)")
            throw AppError.api(.decodingError)
        }
    }

    private func buildURL(for endpoint: APIEndpoint) -> URL {
        var components = URLComponents(url: configuration.baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)!
        var queryItems = endpoint.queryItems ?? []
        queryItems.append(URLQueryItem(name: "access_key", value: configuration.apiKey))
        components.queryItems = queryItems
        return components.url!
    }
}
