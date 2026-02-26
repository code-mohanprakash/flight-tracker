import XCTest
@testable import SkyTrack

final class NotificationServiceTests: XCTestCase {

    // MARK: - NotificationCategory Tests

    func testNotificationCategory_allCases() {
        let categories = NotificationCategory.allCases
        XCTAssertEqual(categories.count, 6)
        XCTAssertTrue(categories.contains(.flightStatus))
        XCTAssertTrue(categories.contains(.gateChange))
        XCTAssertTrue(categories.contains(.delay))
        XCTAssertTrue(categories.contains(.boarding))
        XCTAssertTrue(categories.contains(.baggage))
        XCTAssertTrue(categories.contains(.prediction))
    }

    func testNotificationCategory_rawValues() {
        XCTAssertEqual(NotificationCategory.flightStatus.rawValue, "FLIGHT_STATUS")
        XCTAssertEqual(NotificationCategory.gateChange.rawValue, "GATE_CHANGE")
        XCTAssertEqual(NotificationCategory.delay.rawValue, "DELAY")
        XCTAssertEqual(NotificationCategory.boarding.rawValue, "BOARDING")
        XCTAssertEqual(NotificationCategory.baggage.rawValue, "BAGGAGE")
        XCTAssertEqual(NotificationCategory.prediction.rawValue, "PREDICTION")
    }

    // MARK: - Service Initialization

    func testServiceInitialization() {
        let service = NotificationService()
        XCTAssertNotNil(service)
    }
}
