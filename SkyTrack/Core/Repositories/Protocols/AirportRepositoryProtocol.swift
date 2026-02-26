import Foundation

protocol AirportRepositoryProtocol: Sendable {
    func getAirport(code: String) async throws -> Airport?
    func searchAirports(query: String) async throws -> [Airport]
}
