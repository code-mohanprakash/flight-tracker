import Foundation

final class TrackFlightUseCase: Sendable {
    private let flightRepository: FlightRepositoryProtocol

    init(flightRepository: FlightRepositoryProtocol) {
        self.flightRepository = flightRepository
    }

    func execute(flightNumber: String) async throws -> Flight? {
        try await flightRepository.getFlight(flightNumber: flightNumber)
    }
}
