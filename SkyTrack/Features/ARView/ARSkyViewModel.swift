import Foundation
import CoreLocation
import os

/// ViewModel for AR Sky View — identifies flights overhead using device location and flight data.
@Observable
final class ARSkyViewModel {
    var nearbyFlights: [OverheadFlight] = []
    var isScanning = false
    var deviceLocation: CLLocationCoordinate2D?
    var deviceHeading: Double = 0

    private let flightRepository: FlightRepositoryProtocol
    private let locationManager = CLLocationManager()
    private var scanTask: Task<Void, Never>?
    private static let logger = Logger(subsystem: "com.skytrack.app", category: "ar-sky")

    /// Maximum distance (km) to consider a flight as "overhead"
    private let overheadRadiusKm: Double = 50

    init(flightRepository: FlightRepositoryProtocol) {
        self.flightRepository = flightRepository
    }

    // MARK: - Scanning

    func startScanning() {
        guard !isScanning else { return }
        isScanning = true
        locationManager.requestWhenInUseAuthorization()

        scanTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.scanForOverheadFlights()
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }

    func stopScanning() {
        isScanning = false
        scanTask?.cancel()
        scanTask = nil
    }

    /// Scan for flights overhead the device's current location
    private func scanForOverheadFlights() async {
        guard let location = getCurrentLocation() else {
            Self.logger.warning("No device location available for AR scan")
            return
        }
        deviceLocation = location

        do {
            let bounds = MapBounds(
                minLatitude: location.latitude - 0.5,
                maxLatitude: location.latitude + 0.5,
                minLongitude: location.longitude - 0.5,
                maxLongitude: location.longitude + 0.5
            )
            let positions = try await flightRepository.getPositions(bounds: bounds)

            let overheadList: [OverheadFlight] = positions.compactMap { position in
                let distance = haversineDistance(
                    lat1: location.latitude, lon1: location.longitude,
                    lat2: position.latitude, lon2: position.longitude
                )

                guard distance <= overheadRadiusKm else { return nil }

                let bearing = calculateBearing(
                    from: location,
                    to: CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
                )

                let elevationAngle = calculateElevation(
                    distanceKm: distance,
                    altitudeMeters: position.altitude
                )

                return OverheadFlight(
                    position: position,
                    distanceKm: distance,
                    bearing: bearing,
                    elevationAngle: elevationAngle
                )
            }
            .sorted { $0.distanceKm < $1.distanceKm }

            nearbyFlights = overheadList
            Self.logger.info("Found \(overheadList.count) flights within \(self.overheadRadiusKm)km")

        } catch {
            Self.logger.error("Failed to scan for overhead flights: \(error)")
        }
    }

    // MARK: - Location

    private func getCurrentLocation() -> CLLocationCoordinate2D? {
        if let coord = locationManager.location?.coordinate {
            return coord
        }
        // Fallback for testing
        return deviceLocation
    }

    // MARK: - Geometry

    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0 // Earth radius km
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    private func calculateElevation(distanceKm: Double, altitudeMeters: Double) -> Double {
        let distanceMeters = distanceKm * 1000
        guard distanceMeters > 0 else { return 90 }
        return atan(altitudeMeters / distanceMeters) * 180 / .pi
    }
}

// MARK: - Overhead Flight Model

struct OverheadFlight: Identifiable {
    var id: String { position.id }
    let position: FlightPosition
    let distanceKm: Double
    let bearing: Double        // Compass bearing from device
    let elevationAngle: Double // Angle above horizon (degrees)

    var formattedDistance: String {
        if distanceKm < 1 {
            return String(format: "%.0f m", distanceKm * 1000)
        }
        return String(format: "%.1f km", distanceKm)
    }

    var formattedAltitude: String {
        let feet = position.altitudeFeet
        if feet >= 1000 {
            return "FL\(feet / 100)"
        }
        return "\(feet) ft"
    }

    var compassDirection: String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int(round(bearing / 45)) % 8
        return directions[index]
    }
}
