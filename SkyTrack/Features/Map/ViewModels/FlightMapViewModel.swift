import Foundation
import MapKit
import os

@Observable
final class FlightMapViewModel {
    // MARK: - State
    var positions: [FlightPosition] = []
    var selectedPosition: FlightPosition?
    var isLoading = false
    var error: AppError?
    var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: Constants.Map.defaultCenter,
            span: Constants.Map.defaultSpan
        )
    )

    // MARK: - Private
    private let flightRepository: FlightRepositoryProtocol
    private var refreshTask: Task<Void, Never>?
    private var visibleBounds: MapBounds?
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "flight-map")

    init(flightRepository: FlightRepositoryProtocol) {
        self.flightRepository = flightRepository
    }

    // MARK: - Actions

    func startTracking() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.loadPositions()
                try? await Task.sleep(for: .seconds(Configuration.positionUpdateInterval))
            }
        }
    }

    func stopTracking() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func updateVisibleRegion(_ region: MKCoordinateRegion) {
        visibleBounds = MapBounds(
            minLatitude: region.center.latitude - region.span.latitudeDelta / 2,
            maxLatitude: region.center.latitude + region.span.latitudeDelta / 2,
            minLongitude: region.center.longitude - region.span.longitudeDelta / 2,
            maxLongitude: region.center.longitude + region.span.longitudeDelta / 2
        )
    }

    func selectAircraft(_ position: FlightPosition) {
        selectedPosition = position
    }

    func clearSelection() {
        selectedPosition = nil
    }

    // MARK: - Data Loading

    private func loadPositions() async {
        guard let bounds = visibleBounds else {
            // Use wide default bounds for initial load
            visibleBounds = MapBounds(
                minLatitude: 20, maxLatitude: 55,
                minLongitude: -130, maxLongitude: -60
            )
            await loadPositions()
            return
        }

        if positions.isEmpty {
            isLoading = true
        }

        do {
            let newPositions = try await flightRepository.getPositions(bounds: bounds)
            // Limit to max visible for performance
            let limited = Array(newPositions.prefix(Constants.Map.maxVisibleAircraft))
            await MainActor.run {
                self.positions = limited
                self.isLoading = false
                self.error = nil
            }
            Self.logger.info("Loaded \(limited.count) aircraft positions")
        } catch {
            Self.logger.error("Failed to load positions: \(error)")
            await MainActor.run {
                self.isLoading = false
                if self.positions.isEmpty {
                    self.error = error as? AppError ?? .unknown(error.localizedDescription)
                }
            }
        }
    }
}
