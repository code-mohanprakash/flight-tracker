import Foundation
import os

@Observable
final class FlightDetailViewModel {
    // MARK: - State
    var flight: Flight?
    var isLoading = false
    var error: AppError?

    // MARK: - Private
    private let flightId: String
    private let trackFlightUseCase: TrackFlightUseCase
    private var refreshTask: Task<Void, Never>?
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "flight-detail")

    init(flightId: String, trackFlightUseCase: TrackFlightUseCase) {
        self.flightId = flightId
        self.trackFlightUseCase = trackFlightUseCase
    }

    // MARK: - Actions

    func loadFlight() async {
        isLoading = true
        error = nil

        do {
            flight = try await trackFlightUseCase.execute(flightNumber: flightId)
            if flight == nil {
                error = .api(.notFound)
            }
        } catch {
            Self.logger.error("Failed to load flight \(self.flightId): \(error)")
            self.error = error as? AppError ?? .unknown(error.localizedDescription)
        }

        isLoading = false
    }

    func startAutoRefresh() {
        guard flight?.status.isActive == true else { return }
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Configuration.flightRefreshInterval))
                await self?.loadFlight()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
