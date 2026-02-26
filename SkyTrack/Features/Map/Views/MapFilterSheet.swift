import SwiftUI

/// Advanced map filter sheet — filter aircraft by airline, altitude, speed, and type.
struct MapFilterSheet: View {
    @Binding var filter: MapFilter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Altitude range
                Section {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Min: \(formattedAltitude(filter.minAltitude))")
                                .font(.caption.monospaced())
                                .foregroundStyle(AppColors.textSecondary)
                            Spacer()
                            Text("Max: \(formattedAltitude(filter.maxAltitude))")
                                .font(.caption.monospaced())
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        HStack {
                            Slider(value: $filter.minAltitude, in: 0...45000, step: 1000)
                                .tint(AppColors.primary)
                            Slider(value: $filter.maxAltitude, in: 0...45000, step: 1000)
                                .tint(AppColors.primary)
                        }
                    }
                } header: {
                    Text("Altitude (feet)")
                }

                // Speed range
                Section {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Min: \(Int(filter.minSpeed)) kts")
                                .font(.caption.monospaced())
                                .foregroundStyle(AppColors.textSecondary)
                            Spacer()
                            Text("Max: \(Int(filter.maxSpeed)) kts")
                                .font(.caption.monospaced())
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        HStack {
                            Slider(value: $filter.minSpeed, in: 0...600, step: 10)
                                .tint(AppColors.primary)
                            Slider(value: $filter.maxSpeed, in: 0...600, step: 10)
                                .tint(AppColors.primary)
                        }
                    }
                } header: {
                    Text("Ground Speed (knots)")
                }

                // Airline filter
                Section {
                    TextField("e.g. UA, DL, BA", text: $filter.airlineFilter)
                        .textInputAutocapitalization(.characters)
                        .font(.subheadline.monospaced())
                } header: {
                    Text("Airline Code")
                } footer: {
                    Text("Leave empty to show all airlines")
                }

                // Show on ground
                Section {
                    Toggle("Show Aircraft on Ground", isOn: $filter.showOnGround)
                        .tint(AppColors.primary)
                    Toggle("Show Military", isOn: $filter.showMilitary)
                        .tint(AppColors.primary)
                }

                // Map layers
                Section("Map Layers") {
                    Toggle("Weather Overlay", isOn: $filter.showWeatherLayer)
                        .tint(AppColors.primary)
                    Toggle("ATC Boundaries", isOn: $filter.showATCBoundaries)
                        .tint(AppColors.primary)
                    Toggle("Airport Regions", isOn: $filter.showAirportRegions)
                        .tint(AppColors.primary)
                }

                // Reset
                Section {
                    Button("Reset All Filters", role: .destructive) {
                        filter = MapFilter()
                    }
                }
            }
            .navigationTitle("Map Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formattedAltitude(_ feet: Double) -> String {
        if feet >= 1000 {
            return "FL\(Int(feet / 100))"
        }
        return "\(Int(feet)) ft"
    }
}

// MARK: - Map Filter Model

struct MapFilter: Equatable {
    var minAltitude: Double = 0
    var maxAltitude: Double = 45000
    var minSpeed: Double = 0
    var maxSpeed: Double = 600
    var airlineFilter: String = ""
    var showOnGround: Bool = false
    var showMilitary: Bool = true
    var showWeatherLayer: Bool = false
    var showATCBoundaries: Bool = false
    var showAirportRegions: Bool = false

    var isActive: Bool {
        self != MapFilter()
    }

    func matches(_ position: FlightPosition) -> Bool {
        let altFeet = Double(position.altitudeFeet)
        let speedKts = Double(position.speedKnots)

        if altFeet < minAltitude || altFeet > maxAltitude { return false }
        if speedKts < minSpeed || speedKts > maxSpeed { return false }
        if !showOnGround && position.onGround { return false }

        if !airlineFilter.isEmpty {
            let callsign = position.cleanCallsign.uppercased()
            let filterUpper = airlineFilter.uppercased()
            if !callsign.hasPrefix(filterUpper) { return false }
        }

        return true
    }
}

// MARK: - Weather Layer View

struct WeatherLayerOverlay: View {
    let isEnabled: Bool

    var body: some View {
        if isEnabled {
            // Placeholder for weather tile overlay
            // In production, integrate OpenWeatherMap or similar tile server
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "cloud.rain")
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Weather layer")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 80)
            }
        }
    }
}

// MARK: - ATC Boundary Data

struct ATCBoundary: Identifiable {
    let id = UUID()
    let name: String
    let centerLat: Double
    let centerLon: Double
    let radiusKm: Double
    let type: BoundaryType

    enum BoundaryType: String {
        case artcc = "ARTCC"    // Air Route Traffic Control Center
        case tracon = "TRACON"  // Terminal Radar Approach Control
        case tower = "Tower"
    }

    static let sampleBoundaries: [ATCBoundary] = [
        ATCBoundary(name: "ZNY (New York)", centerLat: 40.75, centerLon: -73.95, radiusKm: 300, type: .artcc),
        ATCBoundary(name: "ZLA (Los Angeles)", centerLat: 34.05, centerLon: -118.25, radiusKm: 350, type: .artcc),
        ATCBoundary(name: "ZOA (Oakland)", centerLat: 37.77, centerLon: -122.42, radiusKm: 300, type: .artcc),
        ATCBoundary(name: "ZAU (Chicago)", centerLat: 41.88, centerLon: -87.63, radiusKm: 320, type: .artcc),
        ATCBoundary(name: "ZTL (Atlanta)", centerLat: 33.75, centerLon: -84.39, radiusKm: 280, type: .artcc),
        ATCBoundary(name: "ZDC (Washington)", centerLat: 38.90, centerLon: -77.04, radiusKm: 260, type: .artcc),
        ATCBoundary(name: "N90 TRACON", centerLat: 40.63, centerLon: -73.78, radiusKm: 80, type: .tracon),
        ATCBoundary(name: "SCT TRACON", centerLat: 33.94, centerLon: -118.41, radiusKm: 100, type: .tracon),
    ]
}
