import SwiftUI
import CarPlay
import os

/// CarPlay scene delegate providing flight dashboard on vehicle displays.
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "carplay")

    // MARK: - CPTemplateApplicationSceneDelegate

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        Self.logger.info("CarPlay connected")
        showDashboard()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        Self.logger.info("CarPlay disconnected")
    }

    // MARK: - Dashboard

    private func showDashboard() {
        let tabBar = CPTabBarTemplate(templates: [
            makeMyFlightsTab(),
            makeSearchTab(),
        ])
        interfaceController?.setRootTemplate(tabBar, animated: true, completion: nil)
    }

    // MARK: - My Flights Tab

    private func makeMyFlightsTab() -> CPTemplate {
        let flights = loadSavedFlights()

        let items: [CPListItem] = flights.map { flight in
            let item = CPListItem(
                text: flight.flightNumber,
                detailText: flight.statusText
            )
            item.handler = { [weak self] _, completion in
                self?.showFlightDetail(flight)
                completion()
            }
            return item
        }

        let section = CPListSection(items: items.isEmpty ? [emptyFlightItem()] : items)
        let template = CPListTemplate(title: "My Flights", sections: [section])
        template.tabTitle = "My Flights"
        template.tabImage = UIImage(systemName: "airplane")
        return template
    }

    private func emptyFlightItem() -> CPListItem {
        CPListItem(text: "No tracked flights", detailText: "Add flights in the SkyTrack app")
    }

    // MARK: - Search Tab

    private func makeSearchTab() -> CPTemplate {
        let recentItems: [CPListItem] = [
            CPListItem(text: "Search for flights", detailText: "Use the SkyTrack app to search"),
        ]
        let section = CPListSection(items: recentItems)
        let template = CPListTemplate(title: "Search", sections: [section])
        template.tabTitle = "Search"
        template.tabImage = UIImage(systemName: "magnifyingglass")
        return template
    }

    // MARK: - Flight Detail

    private func showFlightDetail(_ flight: CarPlayFlight) {
        let items: [CPListItem] = [
            CPListItem(text: "Route", detailText: "\(flight.origin) → \(flight.destination)"),
            CPListItem(text: "Status", detailText: flight.statusText),
            CPListItem(text: "Departure", detailText: flight.departureTime),
            CPListItem(text: "Arrival", detailText: flight.arrivalTime),
        ]

        if let gate = flight.gate {
            items.last?.detailText = "Gate \(gate)"
        }

        let section = CPListSection(items: items)
        let detail = CPListTemplate(title: flight.flightNumber, sections: [section])
        interfaceController?.pushTemplate(detail, animated: true, completion: nil)
    }

    // MARK: - Data

    private func loadSavedFlights() -> [CarPlayFlight] {
        guard let defaults = UserDefaults(suiteName: "group.com.skytrack.shared"),
              let data = defaults.data(forKey: "carplay_flights"),
              let flights = try? JSONDecoder().decode([CarPlayFlight].self, from: data) else {
            return []
        }
        return flights
    }
}

// MARK: - CarPlay Flight Model

struct CarPlayFlight: Codable, Identifiable {
    var id: String { flightNumber }
    let flightNumber: String
    let origin: String
    let destination: String
    let statusText: String
    let departureTime: String
    let arrivalTime: String
    let gate: String?
}
