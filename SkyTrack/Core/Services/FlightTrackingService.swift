import Foundation
import os

/// Central service coordinating real-time flight tracking, delay predictions,
/// and notification dispatch for all tracked flights.
@Observable
final class FlightTrackingService {
    // MARK: - State
    var trackedFlights: [String: Flight] = [:]
    var predictions: [String: DelayPrediction] = [:]
    var isTracking = false

    // MARK: - Private
    private let flightRepository: FlightRepositoryProtocol
    private let delayPredictionService: DelayPredictionService
    private let notificationService: NotificationService
    private var trackingTask: Task<Void, Never>?
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "tracking-service")

    init(
        flightRepository: FlightRepositoryProtocol,
        delayPredictionService: DelayPredictionService,
        notificationService: NotificationService
    ) {
        self.flightRepository = flightRepository
        self.delayPredictionService = delayPredictionService
        self.notificationService = notificationService
    }

    // MARK: - Tracking Lifecycle

    func startTracking(flightNumbers: [String]) {
        trackingTask?.cancel()
        isTracking = true

        trackingTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                await self.refreshAllFlights(flightNumbers)
                try? await Task.sleep(for: .seconds(Configuration.flightRefreshInterval))
            }
        }

        Self.logger.info("Started tracking \(flightNumbers.count) flights")
    }

    func stopTracking() {
        trackingTask?.cancel()
        trackingTask = nil
        isTracking = false
        Self.logger.info("Stopped tracking")
    }

    func addFlight(_ flightNumber: String) async {
        do {
            if let flight = try await flightRepository.getFlight(flightNumber: flightNumber) {
                trackedFlights[flightNumber] = flight

                // Generate prediction for non-terminal flights
                if !flight.status.isTerminal {
                    let prediction = await delayPredictionService.predict(for: flight)
                    predictions[flightNumber] = prediction
                }
            }
        } catch {
            Self.logger.error("Failed to add flight \(flightNumber): \(error)")
        }
    }

    func removeFlight(_ flightNumber: String) {
        trackedFlights.removeValue(forKey: flightNumber)
        predictions.removeValue(forKey: flightNumber)
    }

    // MARK: - Private

    private func refreshAllFlights(_ flightNumbers: [String]) async {
        for number in flightNumbers {
            guard !Task.isCancelled else { break }

            do {
                guard let flight = try await flightRepository.getFlight(flightNumber: number) else {
                    continue
                }

                let previousFlight = trackedFlights[number]
                trackedFlights[number] = flight

                // Detect changes and send notifications
                if let previous = previousFlight {
                    await detectAndNotifyChanges(previous: previous, current: flight)
                }

                // Refresh prediction if not terminal and prediction expired
                if !flight.status.isTerminal {
                    if predictions[number]?.isExpired != false {
                        let prediction = await delayPredictionService.predict(for: flight)
                        predictions[number] = prediction

                        // Notify if prediction shows significant delay
                        if prediction.isLikelyDelayed {
                            await notificationService.sendPredictiveDelayAlert(
                                flight: flight,
                                prediction: prediction
                            )
                        }
                    }
                }
            } catch {
                Self.logger.error("Failed to refresh \(number): \(error)")
            }
        }
    }

    private func detectAndNotifyChanges(previous: Flight, current: Flight) async {
        // Status change
        if previous.status != current.status {
            await notificationService.sendStatusChangeNotification(
                flight: current,
                oldStatus: previous.status,
                newStatus: current.status
            )
        }

        // Gate change
        if previous.departure.gate != current.departure.gate, current.departure.gate != nil {
            await notificationService.sendGateChangeNotification(
                flight: current,
                oldGate: previous.departure.gate,
                newGate: current.departure.gate!
            )
        }

        // Delay change (> 10 min difference)
        let prevDelay = previous.delayMinutes ?? 0
        let currDelay = current.delayMinutes ?? 0
        if abs(currDelay - prevDelay) > 10 {
            await notificationService.sendDelayChangeNotification(
                flight: current,
                oldDelay: prevDelay,
                newDelay: currDelay
            )
        }

        // Baggage claim assigned
        if previous.arrival.baggageClaim == nil && current.arrival.baggageClaim != nil {
            await notificationService.sendBaggageClaimNotification(
                flight: current,
                carousel: current.arrival.baggageClaim!
            )
        }
    }
}
