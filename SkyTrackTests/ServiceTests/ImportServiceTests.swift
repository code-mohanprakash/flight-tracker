import XCTest
@testable import SkyTrack

final class ImportServiceTests: XCTestCase {

    private var service: ImportService!

    override func setUp() {
        super.setUp()
        service = ImportService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Email Parsing Tests

    func testParseBookingEmail_standardFormat() {
        let email = """
        Your booking is confirmed!
        Flight: UA 1234
        Date: 15 Mar 2026
        From: SFO To: JFK
        """

        let flights = service.parseBookingEmail(text: email)

        XCTAssertEqual(flights.count, 1)
        XCTAssertEqual(flights[0].flightNumber, "UA1234")
        XCTAssertEqual(flights[0].source, .email)
    }

    func testParseBookingEmail_routeFormat() {
        let email = """
        Itinerary:
        UA 456 SFO → JFK
        15 Mar 2026
        """

        let flights = service.parseBookingEmail(text: email)

        XCTAssertGreaterThanOrEqual(flights.count, 1)
        let flight = flights[0]
        XCTAssertEqual(flight.flightNumber, "UA456")
        XCTAssertEqual(flight.origin, "SFO")
        XCTAssertEqual(flight.destination, "JFK")
    }

    func testParseBookingEmail_multipleFlights() {
        let email = """
        Your booking:
        Flight: UA 123
        Flight: DL 456
        Date: 20 Mar 2026
        """

        let flights = service.parseBookingEmail(text: email)

        XCTAssertGreaterThanOrEqual(flights.count, 2)
        let flightNumbers = flights.map(\.flightNumber)
        XCTAssertTrue(flightNumbers.contains("UA123"))
        XCTAssertTrue(flightNumbers.contains("DL456"))
    }

    func testParseBookingEmail_noFlightNumber_returnsEmpty() {
        let email = "Thank you for your purchase! Your order #ABC123 is confirmed."

        let flights = service.parseBookingEmail(text: email)

        XCTAssertTrue(flights.isEmpty)
    }

    func testParseBookingEmail_flightHashFormat() {
        let email = """
        Confirmation: XYZ789
        Flt# BA 2490
        Date: 1 Apr 2026
        """

        let flights = service.parseBookingEmail(text: email)

        XCTAssertGreaterThanOrEqual(flights.count, 1)
        XCTAssertEqual(flights[0].flightNumber, "BA2490")
    }

    func testParseBookingEmail_parsesDate() {
        let email = """
        Flight: AA 100
        Date: 25 Mar 2026
        SFO to JFK
        """

        let flights = service.parseBookingEmail(text: email)

        XCTAssertEqual(flights.count, 1)
        let flight = flights[0]

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: flight.date)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 25)
    }

    func testParseBookingEmail_truncatesRawText() {
        let longEmail = String(repeating: "A", count: 500) + "\nFlight: UA 100\n"

        let flights = service.parseBookingEmail(text: longEmail)

        XCTAssertGreaterThanOrEqual(flights.count, 1)
        XCTAssertLessThanOrEqual(flights[0].rawText.count, 200)
    }

    // MARK: - ImportedFlight Model Tests

    func testImportedFlight_displayRoute_withAirports() {
        let flight = ImportedFlight(
            flightNumber: "UA123",
            date: Date(),
            origin: "SFO",
            destination: "JFK",
            source: .email,
            sourceEventId: nil,
            rawText: "test"
        )
        XCTAssertEqual(flight.displayRoute, "SFO → JFK")
    }

    func testImportedFlight_displayRoute_noAirports() {
        let flight = ImportedFlight(
            flightNumber: "UA123",
            date: Date(),
            origin: nil,
            destination: nil,
            source: .email,
            sourceEventId: nil,
            rawText: "test"
        )
        XCTAssertEqual(flight.displayRoute, "UA123")
    }

    func testImportedFlight_uniqueIds() {
        let f1 = ImportedFlight(
            flightNumber: "UA123", date: Date(),
            origin: nil, destination: nil,
            source: .email, sourceEventId: nil, rawText: "test"
        )
        let f2 = ImportedFlight(
            flightNumber: "UA123", date: Date(),
            origin: nil, destination: nil,
            source: .email, sourceEventId: nil, rawText: "test"
        )
        XCTAssertNotEqual(f1.id, f2.id)
    }

    // MARK: - ImportSource Tests

    func testImportSource_rawValues() {
        XCTAssertEqual(ImportSource.calendar.rawValue, "calendar")
        XCTAssertEqual(ImportSource.email.rawValue, "email")
        XCTAssertEqual(ImportSource.manual.rawValue, "manual")
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(service.importedFlights.isEmpty)
        XCTAssertFalse(service.isImporting)
        XCTAssertNil(service.importError)
        XCTAssertFalse(service.calendarAccessGranted)
    }
}
