import XCTest
import CoreLocation
@testable import SkyTrack

final class DistanceCalculatorTests: XCTestCase {

    func testDistance_SFOtoJFK() {
        let sfo = CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.379)
        let jfk = CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)

        let distance = DistanceCalculator.distance(from: sfo, to: jfk)

        // SFO to JFK is approximately 4,148 km
        XCTAssertEqual(distance, 4148, accuracy: 50)
    }

    func testDistance_samePoint() {
        let point = CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.379)
        let distance = DistanceCalculator.distance(from: point, to: point)
        XCTAssertEqual(distance, 0, accuracy: 0.1)
    }

    func testDistanceNM() {
        let sfo = CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.379)
        let jfk = CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)

        let distanceNM = DistanceCalculator.distanceNM(from: sfo, to: jfk)

        // ~2,240 nm
        XCTAssertEqual(distanceNM, 2240, accuracy: 30)
    }

    func testFormatDistance_meters() {
        XCTAssertEqual(DistanceCalculator.formatDistance(km: 0.5), "500 m")
    }

    func testFormatDistance_smallKm() {
        XCTAssertEqual(DistanceCalculator.formatDistance(km: 42.5), "42.5 km")
    }

    func testFormatDistance_largeKm() {
        XCTAssertEqual(DistanceCalculator.formatDistance(km: 4148), "4148 km")
    }

    func testBearing_eastward() {
        let from = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let to = CLLocationCoordinate2D(latitude: 0, longitude: 10)

        let bearing = DistanceCalculator.bearing(from: from, to: to)
        XCTAssertEqual(bearing, 90, accuracy: 1)
    }

    func testBearing_northward() {
        let from = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let to = CLLocationCoordinate2D(latitude: 10, longitude: 0)

        let bearing = DistanceCalculator.bearing(from: from, to: to)
        XCTAssertEqual(bearing, 0, accuracy: 1)
    }
}
