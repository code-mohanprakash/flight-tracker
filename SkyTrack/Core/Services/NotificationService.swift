import Foundation
import UserNotifications
import os

/// Manages all push and local notification delivery for flight events.
final class NotificationService: @unchecked Sendable {
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "notifications")

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert])
            Self.logger.info("Notification permission \(granted ? "granted" : "denied")")
            return granted
        } catch {
            Self.logger.error("Failed to request notification permission: \(error)")
            return false
        }
    }

    func checkPermission() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Flight Status Notifications

    func sendStatusChangeNotification(flight: Flight, oldStatus: FlightStatus, newStatus: FlightStatus) async {
        let content = UNMutableNotificationContent()
        content.title = "\(flight.displayName) — \(newStatus.displayName)"

        switch newStatus {
        case .active:
            content.body = "\(flight.displayName) has departed from \(flight.departure.displayCode)"
            content.sound = .default
        case .landed:
            content.body = "\(flight.displayName) has landed at \(flight.arrival.displayCode)"
            if let baggage = flight.arrival.baggageClaim {
                content.body += ". Baggage claim: \(baggage)"
            }
            content.sound = .default
        case .cancelled:
            content.title = "\(flight.displayName) — CANCELLED"
            content.body = "Your flight has been cancelled. Contact the airline for rebooking."
            content.sound = UNNotificationSound.defaultCritical
            content.interruptionLevel = .critical
        case .diverted:
            content.title = "\(flight.displayName) — DIVERTED"
            content.body = "Your flight has been diverted."
            content.sound = UNNotificationSound.defaultCritical
            content.interruptionLevel = .critical
        default:
            content.body = "Status changed to \(newStatus.displayName)"
            content.sound = .default
        }

        content.categoryIdentifier = NotificationCategory.flightStatus.rawValue
        content.userInfo = ["flightId": flight.id, "type": "status_change"]
        content.threadIdentifier = "flight_\(flight.id)"

        await scheduleNotification(id: "status_\(flight.id)_\(newStatus.rawValue)", content: content)
    }

    func sendGateChangeNotification(flight: Flight, oldGate: String?, newGate: String) async {
        let content = UNMutableNotificationContent()
        content.title = "\(flight.displayName) — Gate Changed"
        if let oldGate {
            content.body = "Gate changed from \(oldGate) to \(newGate)"
        } else {
            content.body = "Gate assigned: \(newGate)"
        }
        if let terminal = flight.departure.terminal {
            content.body += " (Terminal \(terminal))"
        }
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.gateChange.rawValue
        content.userInfo = ["flightId": flight.id, "type": "gate_change"]
        content.threadIdentifier = "flight_\(flight.id)"

        await scheduleNotification(id: "gate_\(flight.id)_\(newGate)", content: content)
    }

    func sendDelayChangeNotification(flight: Flight, oldDelay: Int, newDelay: Int) async {
        let content = UNMutableNotificationContent()

        if newDelay > oldDelay {
            content.title = "\(flight.displayName) — Delayed \(newDelay) min"
            content.body = "Departure now estimated at \(flight.departure.estimatedTime?.formatted(date: .omitted, time: .shortened) ?? "TBD")"
        } else {
            content.title = "\(flight.displayName) — Delay Reduced"
            content.body = "Delay reduced to \(newDelay) min"
        }

        content.sound = .default
        content.categoryIdentifier = NotificationCategory.delay.rawValue
        content.userInfo = ["flightId": flight.id, "type": "delay_change"]
        content.threadIdentifier = "flight_\(flight.id)"

        await scheduleNotification(id: "delay_\(flight.id)_\(newDelay)", content: content)
    }

    func sendBaggageClaimNotification(flight: Flight, carousel: String) async {
        let content = UNMutableNotificationContent()
        content.title = "\(flight.displayName) — Baggage Claim"
        content.body = "Collect your bags at carousel \(carousel)"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.baggage.rawValue
        content.userInfo = ["flightId": flight.id, "type": "baggage"]
        content.threadIdentifier = "flight_\(flight.id)"

        await scheduleNotification(id: "baggage_\(flight.id)", content: content)
    }

    func sendPredictiveDelayAlert(flight: Flight, prediction: DelayPrediction) async {
        let content = UNMutableNotificationContent()
        content.title = "\(flight.displayName) — Delay Likely"
        content.body = "We predict a ~\(prediction.predictedDelayMinutes) min delay. Reason: \(prediction.primaryReason.rawValue)"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.prediction.rawValue
        content.userInfo = [
            "flightId": flight.id,
            "type": "prediction",
            "predictedDelay": prediction.predictedDelayMinutes
        ]
        content.threadIdentifier = "flight_\(flight.id)"

        await scheduleNotification(id: "prediction_\(flight.id)", content: content)
    }

    func sendBoardingReminder(flight: Flight) async {
        let content = UNMutableNotificationContent()
        content.title = "\(flight.displayName) — Boarding Soon"
        content.body = "Your flight boards in 30 minutes"
        if let gate = flight.departure.gate {
            content.body += " at Gate \(gate)"
        }
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.boarding.rawValue
        content.userInfo = ["flightId": flight.id, "type": "boarding"]
        content.threadIdentifier = "flight_\(flight.id)"

        // Schedule 30 min before departure
        if let depTime = flight.departure.estimatedTime ?? flight.departure.scheduledTime {
            let triggerDate = depTime.addingTimeInterval(-1800)
            if triggerDate > Date() {
                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: triggerDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                await scheduleNotification(
                    id: "boarding_\(flight.id)",
                    content: content,
                    trigger: trigger
                )
                return
            }
        }

        await scheduleNotification(id: "boarding_\(flight.id)", content: content)
    }

    // MARK: - Notification Management

    func cancelNotifications(for flightId: String) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.content.userInfo["flightId"] as? String == flightId }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Private

    private func scheduleNotification(
        id: String,
        content: UNMutableNotificationContent,
        trigger: UNNotificationTrigger? = nil
    ) async {
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger ?? UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            Self.logger.info("Scheduled notification: \(id)")
        } catch {
            Self.logger.error("Failed to schedule notification \(id): \(error)")
        }
    }

    // MARK: - Registration

    static func registerCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_FLIGHT",
            title: "View Flight",
            options: [.foreground]
        )

        let shareAction = UNNotificationAction(
            identifier: "SHARE_UPDATE",
            title: "Share Update",
            options: []
        )

        let categories: [UNNotificationCategory] = NotificationCategory.allCases.map { category in
            UNNotificationCategory(
                identifier: category.rawValue,
                actions: [viewAction, shareAction],
                intentIdentifiers: [],
                hiddenPreviewsBodyPlaceholder: "Flight Update"
            )
        }

        UNUserNotificationCenter.current().setNotificationCategories(Set(categories))
    }
}

// MARK: - Notification Categories

enum NotificationCategory: String, CaseIterable {
    case flightStatus = "FLIGHT_STATUS"
    case gateChange = "GATE_CHANGE"
    case delay = "DELAY"
    case boarding = "BOARDING"
    case baggage = "BAGGAGE"
    case prediction = "PREDICTION"
}
