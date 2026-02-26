import Foundation

enum AppError: Error, Equatable {
    case network(NetworkError)
    case api(APIError)
    case persistence(String)
    case unknown(String)

    var title: String {
        switch self {
        case .network: "Connection Issue"
        case .api: "Service Error"
        case .persistence: "Storage Error"
        case .unknown: "Something Went Wrong"
        }
    }

    var message: String {
        switch self {
        case .network(.noConnection):
            "No internet connection. Please check your network and try again."
        case .network(.timeout):
            "The request timed out. Please try again."
        case .network(.serverError):
            "The server is temporarily unavailable. Please try again later."
        case .api(.notFound):
            "Flight not found. Please check the flight number and try again."
        case .api(.rateLimited):
            "Too many requests. Please wait a moment and try again."
        case .api(.unauthorized):
            "Authentication error. Please restart the app."
        case .api(.decodingError):
            "Unable to process the response. Please try again."
        case .api(.invalidResponse):
            "Received an unexpected response. Please try again."
        case .persistence(let msg):
            msg
        case .unknown(let msg):
            msg
        }
    }

    var iconName: String {
        switch self {
        case .network: "wifi.slash"
        case .api(.notFound): "magnifyingglass"
        case .api: "exclamationmark.triangle"
        case .persistence: "externaldrive.badge.exclamationmark"
        case .unknown: "exclamationmark.circle"
        }
    }
}

enum NetworkError: Error, Equatable {
    case noConnection
    case timeout
    case serverError
}

enum APIError: Error, Equatable {
    case notFound
    case rateLimited
    case unauthorized
    case decodingError
    case invalidResponse
    case httpError(statusCode: Int)
}
