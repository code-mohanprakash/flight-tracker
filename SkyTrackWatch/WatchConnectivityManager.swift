import Foundation
import WatchConnectivity
import os

/// Manages bidirectional communication between iPhone and Apple Watch
/// for syncing flight data.
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var receivedFlights: [WatchFlightData] = []
    @Published var isReachable = false

    private static let logger = Logger(subsystem: "com.skytrack.app", category: "watch-connectivity")

    override init() {
        super.init()
        #if !os(macOS)
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        #endif
    }

    // MARK: - Send Data to Watch

    func sendFlightsToWatch(_ flights: [WatchFlightData]) {
        guard WCSession.default.activationState == .activated else {
            Self.logger.warning("WCSession not activated")
            return
        }

        do {
            let data = try JSONEncoder().encode(flights)
            let message = ["flights": data]

            if WCSession.default.isReachable {
                WCSession.default.sendMessage(message, replyHandler: nil) { error in
                    Self.logger.error("Failed to send message: \(error)")
                }
            } else {
                try WCSession.default.updateApplicationContext(message)
            }

            // Also store in shared UserDefaults
            UserDefaults(suiteName: "group.com.skytrack.app")?.set(data, forKey: "watchFlights")

            Self.logger.info("Sent \(flights.count) flights to Watch")
        } catch {
            Self.logger.error("Failed to encode flights: \(error)")
        }
    }

    // MARK: - Send Complication Update

    func updateComplication(with flight: WatchFlightData?) {
        guard WCSession.default.activationState == .activated else { return }

        do {
            let data = flight.flatMap { try? JSONEncoder().encode($0) }
            let context: [String: Any] = ["complicationFlight": data as Any]
            try WCSession.default.updateApplicationContext(context)
        } catch {
            Self.logger.error("Failed to update complication: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
        Self.logger.info("WCSession activated: \(activationState.rawValue)")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let data = message["flights"] as? Data,
           let flights = try? JSONDecoder().decode([WatchFlightData].self, from: data) {
            DispatchQueue.main.async {
                self.receivedFlights = flights
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext["flights"] as? Data,
           let flights = try? JSONDecoder().decode([WatchFlightData].self, from: data) {
            DispatchQueue.main.async {
                self.receivedFlights = flights
            }
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        Self.logger.info("WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        Self.logger.info("WCSession deactivated")
        session.activate()
    }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
}
