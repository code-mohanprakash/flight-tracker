import Foundation
import os

@Observable
final class AirportViewModel {
    // MARK: - State
    var airport: Airport?
    var departures: [Flight] = []
    var arrivals: [Flight] = []
    var selectedBoard: BoardType = .departures
    var isLoading = false
    var isBoardLoading = false
    var error: AppError?

    enum BoardType: String, CaseIterable {
        case departures = "Departures"
        case arrivals = "Arrivals"
    }

    // MARK: - Private
    private let airportCode: String
    private let airportUseCase: GetAirportInfoUseCase
    private let flightRepository: FlightRepositoryProtocol
    private var refreshTask: Task<Void, Never>?
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "airport")

    init(airportCode: String, airportUseCase: GetAirportInfoUseCase, flightRepository: FlightRepositoryProtocol) {
        self.airportCode = airportCode
        self.airportUseCase = airportUseCase
        self.flightRepository = flightRepository
    }

    // MARK: - Computed

    var currentBoardFlights: [Flight] {
        switch selectedBoard {
        case .departures: departures
        case .arrivals: arrivals
        }
    }

    // MARK: - Actions

    func loadAirport() async {
        isLoading = true
        error = nil

        do {
            airport = try await airportUseCase.execute(code: airportCode)
            await loadBoard()
        } catch {
            Self.logger.error("Failed to load airport \(self.airportCode): \(error)")
            self.error = error as? AppError ?? .unknown(error.localizedDescription)
        }

        isLoading = false
    }

    func loadBoard() async {
        isBoardLoading = true

        do {
            switch selectedBoard {
            case .departures:
                departures = try await flightRepository.getDepartures(airportCode: airportCode)
                Self.logger.info("Loaded \(self.departures.count) departures for \(self.airportCode)")
            case .arrivals:
                arrivals = try await flightRepository.getArrivals(airportCode: airportCode)
                Self.logger.info("Loaded \(self.arrivals.count) arrivals for \(self.airportCode)")
            }
        } catch {
            Self.logger.error("Failed to load board: \(error)")
        }

        isBoardLoading = false
    }

    func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Configuration.airportBoardRefreshInterval))
                await self?.loadBoard()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func switchBoard(to board: BoardType) {
        selectedBoard = board
        Task { await loadBoard() }
    }
}
