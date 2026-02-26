import Foundation
import CoreSpotlight
import MobileCoreServices
import os

/// Indexes flights and airports into Spotlight for system-wide search.
final class SpotlightIndexer {
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "spotlight")
    private static let domainFlights = "com.skytrack.flights"
    private static let domainAirports = "com.skytrack.airports"

    // MARK: - Flight Indexing

    static func indexFlight(_ flight: Flight) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.title = "\(flight.displayName) — \(flight.routeDescription)"
        attributeSet.contentDescription = buildFlightDescription(flight)
        attributeSet.keywords = buildFlightKeywords(flight)
        attributeSet.displayName = flight.displayName
        attributeSet.supportsNavigation = true

        let item = CSSearchableItem(
            uniqueIdentifier: "flight_\(flight.id)",
            domainIdentifier: domainFlights,
            attributeSet: attributeSet
        )
        item.expirationDate = Date().addingTimeInterval(86400) // 24h

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error {
                logger.error("Failed to index flight \(flight.displayName): \(error)")
            } else {
                logger.info("Indexed flight: \(flight.displayName)")
            }
        }
    }

    static func indexFlights(_ flights: [Flight]) {
        let items = flights.map { flight -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.title = "\(flight.displayName) — \(flight.routeDescription)"
            attributeSet.contentDescription = buildFlightDescription(flight)
            attributeSet.keywords = buildFlightKeywords(flight)
            attributeSet.displayName = flight.displayName

            let item = CSSearchableItem(
                uniqueIdentifier: "flight_\(flight.id)",
                domainIdentifier: domainFlights,
                attributeSet: attributeSet
            )
            item.expirationDate = Date().addingTimeInterval(86400)
            return item
        }

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error {
                logger.error("Failed to index \(items.count) flights: \(error)")
            } else {
                logger.info("Indexed \(items.count) flights")
            }
        }
    }

    // MARK: - Airport Indexing

    static func indexAirport(_ airport: Airport) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.title = "\(airport.displayCode) — \(airport.fullName)"
        attributeSet.contentDescription = buildAirportDescription(airport)
        attributeSet.keywords = buildAirportKeywords(airport)
        attributeSet.displayName = airport.displayCode

        if let lat = airport.latitude, let lon = airport.longitude {
            attributeSet.latitude = NSNumber(value: lat)
            attributeSet.longitude = NSNumber(value: lon)
            attributeSet.supportsNavigation = true
        }

        let item = CSSearchableItem(
            uniqueIdentifier: "airport_\(airport.id)",
            domainIdentifier: domainAirports,
            attributeSet: attributeSet
        )
        item.expirationDate = Date().addingTimeInterval(604800) // 7 days

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error {
                logger.error("Failed to index airport \(airport.displayCode): \(error)")
            }
        }
    }

    static func indexAirports(_ airports: [Airport]) {
        let items = airports.map { airport -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.title = "\(airport.displayCode) — \(airport.fullName)"
            attributeSet.contentDescription = buildAirportDescription(airport)
            attributeSet.keywords = buildAirportKeywords(airport)

            if let lat = airport.latitude, let lon = airport.longitude {
                attributeSet.latitude = NSNumber(value: lat)
                attributeSet.longitude = NSNumber(value: lon)
            }

            let item = CSSearchableItem(
                uniqueIdentifier: "airport_\(airport.id)",
                domainIdentifier: domainAirports,
                attributeSet: attributeSet
            )
            item.expirationDate = Date().addingTimeInterval(604800)
            return item
        }

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error {
                logger.error("Failed to index \(items.count) airports: \(error)")
            }
        }
    }

    // MARK: - Remove

    static func removeFlight(id: String) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: ["flight_\(id)"]
        ) { _ in }
    }

    static func removeAllFlights() {
        CSSearchableIndex.default().deleteSearchableItems(
            withDomainIdentifiers: [domainFlights]
        ) { _ in }
    }

    static func removeAllAirports() {
        CSSearchableIndex.default().deleteSearchableItems(
            withDomainIdentifiers: [domainAirports]
        ) { _ in }
    }

    static func removeAll() {
        CSSearchableIndex.default().deleteAllSearchableItems { _ in }
    }

    // MARK: - Deep Link Handling

    static func handleSpotlightActivity(_ activity: NSUserActivity) -> SpotlightDeepLink? {
        guard activity.activityType == CSSearchableItemActionType,
              let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return nil
        }

        if identifier.hasPrefix("flight_") {
            let flightId = String(identifier.dropFirst("flight_".count))
            return .flight(id: flightId)
        } else if identifier.hasPrefix("airport_") {
            let airportId = String(identifier.dropFirst("airport_".count))
            return .airport(id: airportId)
        }

        return nil
    }

    // MARK: - Helpers

    private static func buildFlightDescription(_ flight: Flight) -> String {
        var parts: [String] = []
        parts.append(flight.status.displayName)
        if let airline = flight.airline?.name { parts.append(airline) }
        parts.append(flight.routeDescription)
        if let delay = flight.delayMinutes, delay > 0 {
            parts.append("Delayed \(delay) min")
        }
        if let gate = flight.departure.gate { parts.append("Gate \(gate)") }
        return parts.joined(separator: " • ")
    }

    private static func buildFlightKeywords(_ flight: Flight) -> [String] {
        var keywords: [String] = [flight.displayName, flight.flightNumber]
        if let iata = flight.flightIata { keywords.append(iata) }
        if let icao = flight.flightIcao { keywords.append(icao) }
        if let airline = flight.airline?.name { keywords.append(airline) }
        if let depCode = flight.departure.airportIata { keywords.append(depCode) }
        if let arrCode = flight.arrival.airportIata { keywords.append(arrCode) }
        if let depCity = flight.departure.city { keywords.append(depCity) }
        if let arrCity = flight.arrival.city { keywords.append(arrCity) }
        return keywords
    }

    private static func buildAirportDescription(_ airport: Airport) -> String {
        var parts: [String] = [airport.fullName]
        if let city = airport.city { parts.append(city) }
        if let country = airport.country { parts.append(country) }
        return parts.joined(separator: ", ")
    }

    private static func buildAirportKeywords(_ airport: Airport) -> [String] {
        var keywords: [String] = [airport.displayCode]
        if let iata = airport.iataCode { keywords.append(iata) }
        if let icao = airport.icaoCode { keywords.append(icao) }
        if let name = airport.name { keywords.append(name) }
        if let city = airport.city { keywords.append(city) }
        if let country = airport.country { keywords.append(country) }
        return keywords
    }
}

// MARK: - Deep Link

enum SpotlightDeepLink {
    case flight(id: String)
    case airport(id: String)
}
