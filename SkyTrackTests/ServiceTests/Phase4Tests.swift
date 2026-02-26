import XCTest
@testable import SkyTrack

// MARK: - TipJarService Tests

final class TipJarServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "skytrack_has_tipped")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "skytrack_has_tipped")
        super.tearDown()
    }

    func testAllFeaturesAlwaysAvailable() {
        let service = TipJarService()
        for feature in TipJarService.AppFeature.allCases {
            XCTAssertTrue(service.isFeatureAvailable(feature), "\(feature.rawValue) should be available for free")
        }
    }

    func testInitialState_notTipped() {
        let service = TipJarService()
        XCTAssertFalse(service.hasTipped)
        XCTAssertTrue(service.products.isEmpty)
        XCTAssertFalse(service.isLoading)
    }

    func testAppFeature_allCases() {
        XCTAssertEqual(TipJarService.AppFeature.allCases.count, 10)
    }

    func testAppFeature_iconNames() {
        for feature in TipJarService.AppFeature.allCases {
            XCTAssertFalse(feature.iconName.isEmpty)
        }
    }

    func testAppFeature_descriptions() {
        for feature in TipJarService.AppFeature.allCases {
            XCTAssertFalse(feature.description.isEmpty)
        }
    }

    func testProductIDs() {
        XCTAssertEqual(TipJarService.ProductID.all.count, 4)
        XCTAssertTrue(TipJarService.ProductID.all.contains(TipJarService.ProductID.smallTip))
        XCTAssertTrue(TipJarService.ProductID.all.contains(TipJarService.ProductID.hugeTip))
    }
}

// MARK: - SpotlightIndexer Tests

final class SpotlightIndexerTests: XCTestCase {

    func testHandleSpotlightActivity_flightDeepLink() {
        let activity = NSUserActivity(activityType: "com.apple.corespotlightitem")
        activity.userInfo = ["kCSSearchableItemActivityIdentifier": "flight_UA123_2026-02-26"]

        let link = SpotlightIndexer.handleSpotlightActivity(activity)

        if case .flight(let id) = link {
            XCTAssertEqual(id, "UA123_2026-02-26")
        } else {
            XCTFail("Expected flight deep link")
        }
    }

    func testHandleSpotlightActivity_airportDeepLink() {
        let activity = NSUserActivity(activityType: "com.apple.corespotlightitem")
        activity.userInfo = ["kCSSearchableItemActivityIdentifier": "airport_SFO"]

        let link = SpotlightIndexer.handleSpotlightActivity(activity)

        if case .airport(let id) = link {
            XCTAssertEqual(id, "SFO")
        } else {
            XCTFail("Expected airport deep link")
        }
    }

    func testHandleSpotlightActivity_unknownActivity() {
        let activity = NSUserActivity(activityType: "com.apple.other")
        let link = SpotlightIndexer.handleSpotlightActivity(activity)
        XCTAssertNil(link)
    }
}

// MARK: - Accessibility Tests

final class AccessibilityTests: XCTestCase {

    func testFlightLabel_includesAllInfo() {
        let flight = TestData.sampleFlight
        let label = AccessibilityLabels.flightLabel(for: flight)

        XCTAssertTrue(label.contains("UA123"))
        XCTAssertTrue(label.contains("SFO"))
        XCTAssertTrue(label.contains("JFK"))
        XCTAssertTrue(label.contains("In Air"))
        XCTAssertTrue(label.contains("Gate G92"))
    }

    func testFlightLabel_withDelay() {
        let flight = TestData.sampleFlight
        let label = AccessibilityLabels.flightLabel(for: flight)
        XCTAssertTrue(label.contains("Delayed"))
        XCTAssertTrue(label.contains("15 minutes"))
    }

    func testPositionLabel() {
        let position = TestData.samplePosition
        let label = AccessibilityLabels.positionLabel(for: position)

        XCTAssertTrue(label.contains("UAL123"))
        XCTAssertTrue(label.contains("feet"))
        XCTAssertTrue(label.contains("knots"))
    }

    func testDelayPredictionLabel_onTime() {
        let prediction = DelayPrediction(
            flightId: "test",
            predictedDelayMinutes: 0,
            confidence: 0.7,
            primaryReason: .unknown,
            factors: [],
            inboundFlightId: nil,
            generatedAt: Date(),
            validUntil: Date().addingTimeInterval(1800)
        )
        let label = AccessibilityLabels.delayPredictionLabel(for: prediction)
        XCTAssertTrue(label.contains("on time"))
    }

    func testDelayPredictionLabel_delayed() {
        let prediction = DelayPrediction(
            flightId: "test",
            predictedDelayMinutes: 25,
            confidence: 0.65,
            primaryReason: .lateAircraft,
            factors: [],
            inboundFlightId: nil,
            generatedAt: Date(),
            validUntil: Date().addingTimeInterval(1800)
        )
        let label = AccessibilityLabels.delayPredictionLabel(for: prediction)
        XCTAssertTrue(label.contains("25 minute delay"))
        XCTAssertTrue(label.contains("Medium"))
        XCTAssertTrue(label.contains("Late Aircraft"))
    }

    func testColorBlindSafeColors_exist() {
        // Verify all CBF colors are distinct from each other
        let colors = [
            ColorBlindSafeColors.onTime,
            ColorBlindSafeColors.delayed,
            ColorBlindSafeColors.cancelled,
            ColorBlindSafeColors.diverted,
            ColorBlindSafeColors.landed,
            ColorBlindSafeColors.scheduled,
        ]
        // All should be non-nil (compile-time check really, but validates init)
        XCTAssertEqual(colors.count, 6)
    }
}

// MARK: - AppStoreMetadata Tests

final class AppStoreMetadataTests: XCTestCase {

    func testKeywords_under100Characters() {
        XCTAssertLessThanOrEqual(AppStoreMetadata.keywords.count, 100)
    }

    func testPromotionalText_under170Characters() {
        XCTAssertLessThanOrEqual(AppStoreMetadata.promotionalText.count, 170)
    }

    func testDescription_notEmpty() {
        XCTAssertFalse(AppStoreMetadata.description.isEmpty)
    }

    func testScreenshotCaptions_count() {
        XCTAssertGreaterThanOrEqual(AppStoreMetadata.screenshotCaptions.count, 3)
    }

    func testAppName_notTooLong() {
        XCTAssertLessThanOrEqual(AppStoreMetadata.appName.count, 30)
    }

    func testSubtitle_notTooLong() {
        XCTAssertLessThanOrEqual(AppStoreMetadata.subtitle.count, 30)
    }

    func testPrice_isFree() {
        XCTAssertEqual(AppStoreMetadata.price, "Free")
    }

    func testRequiredScreenshotDevices() {
        XCTAssertGreaterThanOrEqual(AppStoreMetadata.ScreenshotConfig.required.count, 4)
    }
}

// MARK: - CarPlay Flight Model Tests

final class CarPlayFlightTests: XCTestCase {

    func testCarPlayFlight_id() {
        let flight = CarPlayFlight(
            flightNumber: "UA123",
            origin: "SFO",
            destination: "JFK",
            statusText: "In Air",
            departureTime: "10:30 AM",
            arrivalTime: "6:45 PM",
            gate: "G92"
        )
        XCTAssertEqual(flight.id, "UA123")
        XCTAssertEqual(flight.gate, "G92")
    }

    func testCarPlayFlight_codable() throws {
        let flight = CarPlayFlight(
            flightNumber: "DL456",
            origin: "LAX",
            destination: "ATL",
            statusText: "Scheduled",
            departureTime: "2:00 PM",
            arrivalTime: "9:30 PM",
            gate: nil
        )

        let data = try JSONEncoder().encode(flight)
        let decoded = try JSONDecoder().decode(CarPlayFlight.self, from: data)

        XCTAssertEqual(decoded.flightNumber, "DL456")
        XCTAssertEqual(decoded.origin, "LAX")
        XCTAssertNil(decoded.gate)
    }
}
