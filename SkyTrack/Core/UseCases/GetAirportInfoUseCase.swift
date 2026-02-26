import Foundation

final class GetAirportInfoUseCase: Sendable {
    private let airportRepository: AirportRepositoryProtocol

    init(airportRepository: AirportRepositoryProtocol) {
        self.airportRepository = airportRepository
    }

    func execute(code: String) async throws -> Airport? {
        try await airportRepository.getAirport(code: code)
    }

    func search(query: String) async throws -> [Airport] {
        try await airportRepository.searchAirports(query: query)
    }
}
