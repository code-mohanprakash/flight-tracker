import Foundation
import EventKit
import os

/// Service for importing flights from iOS Calendar and email confirmations.
@Observable
final class ImportService {
    // MARK: - State
    var importedFlights: [ImportedFlight] = []
    var isImporting = false
    var importError: String?
    var calendarAccessGranted = false

    // MARK: - Private
    private let eventStore = EKEventStore()
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "import-service")

    // MARK: - Calendar Import

    /// Request calendar access
    func requestCalendarAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            calendarAccessGranted = granted
            Self.logger.info("Calendar access \(granted ? "granted" : "denied")")
            return granted
        } catch {
            Self.logger.error("Calendar access error: \(error)")
            return false
        }
    }

    /// Scan calendar for flight events
    func importFromCalendar(daysAhead: Int = 90) async -> [ImportedFlight] {
        guard calendarAccessGranted else {
            let granted = await requestCalendarAccess()
            guard granted else {
                importError = "Calendar access not granted"
                return []
            }
        }

        isImporting = true
        defer { isImporting = false }

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: startDate)!

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)
        Self.logger.info("Found \(events.count) calendar events to scan")

        var flights: [ImportedFlight] = []

        for event in events {
            if let flight = parseFlightFromEvent(event) {
                flights.append(flight)
            }
        }

        importedFlights = flights
        Self.logger.info("Imported \(flights.count) flights from calendar")
        return flights
    }

    /// Parse a calendar event to detect flight information
    private func parseFlightFromEvent(_ event: EKEvent) -> ImportedFlight? {
        let title = event.title ?? ""
        let notes = event.notes ?? ""
        let location = event.location ?? ""
        let combined = "\(title) \(notes) \(location)"

        // Pattern: Match airline code + flight number (e.g., UA123, BA4567, DL89)
        let flightPattern = #"(?i)\b([A-Z]{2})\s*(\d{1,4})\b"#
        guard let regex = try? NSRegularExpression(pattern: flightPattern),
              let match = regex.firstMatch(
                in: combined,
                range: NSRange(combined.startIndex..., in: combined)
              ) else {
            return nil
        }

        let airlineRange = Range(match.range(at: 1), in: combined)!
        let numberRange = Range(match.range(at: 2), in: combined)!
        let airlineCode = String(combined[airlineRange]).uppercased()
        let flightNum = String(combined[numberRange])
        let flightNumber = "\(airlineCode)\(flightNum)"

        // Try to extract airport codes from location/notes
        let airportPattern = #"\b([A-Z]{3})\b"#
        var airports: [String] = []
        if let airportRegex = try? NSRegularExpression(pattern: airportPattern) {
            let matches = airportRegex.matches(
                in: combined,
                range: NSRange(combined.startIndex..., in: combined)
            )
            airports = matches.compactMap { match in
                guard let range = Range(match.range(at: 1), in: combined) else { return nil }
                return String(combined[range])
            }
        }

        Self.logger.info("Parsed flight \(flightNumber) from event: \(title)")

        return ImportedFlight(
            flightNumber: flightNumber,
            date: event.startDate,
            origin: airports.count >= 1 ? airports[0] : nil,
            destination: airports.count >= 2 ? airports[1] : nil,
            source: .calendar,
            sourceEventId: event.eventIdentifier,
            rawText: title
        )
    }

    // MARK: - Email Parsing

    /// Parse flight information from a forwarded booking confirmation email
    func parseBookingEmail(text: String) -> [ImportedFlight] {
        var flights: [ImportedFlight] = []

        // Common patterns in airline booking confirmations
        let patterns: [String] = [
            // "Flight: UA 123" or "Flight UA123"
            #"(?i)flight[:\s]+([A-Z]{2})\s*(\d{1,4})"#,
            // "UA 123 SFO → JFK"
            #"(?i)([A-Z]{2})\s*(\d{1,4})\s+([A-Z]{3})\s*[→\-to]+\s*([A-Z]{3})"#,
            // "Confirmation: ABC123 | Flight: UA123"
            #"(?i)(?:flight|flt)[#:\s]+([A-Z]{2})\s*(\d{1,4})"#,
        ]

        // Date patterns
        let datePatterns: [String] = [
            #"(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\s+(\d{4})"#,
            #"(\d{4})-(\d{2})-(\d{2})"#,
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

            for match in matches {
                guard match.numberOfRanges >= 3,
                      let airlineRange = Range(match.range(at: 1), in: text),
                      let numRange = Range(match.range(at: 2), in: text) else {
                    continue
                }

                let airline = String(text[airlineRange]).uppercased()
                let num = String(text[numRange])
                let flightNumber = "\(airline)\(num)"

                var origin: String?
                var destination: String?
                if match.numberOfRanges >= 5,
                   let origRange = Range(match.range(at: 3), in: text),
                   let destRange = Range(match.range(at: 4), in: text) {
                    origin = String(text[origRange])
                    destination = String(text[destRange])
                }

                // Try to extract date
                var flightDate = Date()
                for datePattern in datePatterns {
                    if let dateRegex = try? NSRegularExpression(pattern: datePattern),
                       let dateMatch = dateRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                        let dateStr = String(text[Range(dateMatch.range, in: text)!])
                        let formatter = DateFormatter()
                        formatter.dateFormat = "d MMM yyyy"
                        if let date = formatter.date(from: dateStr) {
                            flightDate = date
                        }
                        break
                    }
                }

                flights.append(ImportedFlight(
                    flightNumber: flightNumber,
                    date: flightDate,
                    origin: origin,
                    destination: destination,
                    source: .email,
                    sourceEventId: nil,
                    rawText: text.prefix(200).description
                ))
            }
        }

        Self.logger.info("Parsed \(flights.count) flights from email text")
        return flights
    }
}

// MARK: - Imported Flight Model

struct ImportedFlight: Identifiable, Codable {
    let id = UUID()
    let flightNumber: String
    let date: Date
    let origin: String?
    let destination: String?
    let source: ImportSource
    let sourceEventId: String?
    let rawText: String

    var displayRoute: String {
        if let origin, let destination {
            return "\(origin) → \(destination)"
        }
        return flightNumber
    }
}

enum ImportSource: String, Codable {
    case calendar
    case email
    case manual
}
