import Foundation

struct WeatherInfo: Codable, Hashable {
    let temperature: Double?     // Celsius
    let windSpeed: Double?       // km/h
    let windDirection: Int?      // degrees
    let visibility: Double?      // km
    let cloudCover: String?
    let conditions: String?
    let pressure: Double?        // hPa
    let humidity: Int?           // percentage
    let icon: String?
    let updatedAt: Date?

    var temperatureFahrenheit: Double? {
        guard let temperature else { return nil }
        return temperature * 9 / 5 + 32
    }

    var windSpeedKnots: Double? {
        guard let windSpeed else { return nil }
        return windSpeed * 0.539957
    }

    var conditionsIcon: String {
        guard let conditions = conditions?.lowercased() else { return "cloud.fill" }
        if conditions.contains("clear") || conditions.contains("sunny") { return "sun.max.fill" }
        if conditions.contains("cloud") && conditions.contains("part") { return "cloud.sun.fill" }
        if conditions.contains("cloud") { return "cloud.fill" }
        if conditions.contains("rain") || conditions.contains("drizzle") { return "cloud.rain.fill" }
        if conditions.contains("thunder") || conditions.contains("storm") { return "cloud.bolt.rain.fill" }
        if conditions.contains("snow") { return "cloud.snow.fill" }
        if conditions.contains("fog") || conditions.contains("mist") { return "cloud.fog.fill" }
        if conditions.contains("wind") { return "wind" }
        return "cloud.fill"
    }

    var temperatureDisplay: String {
        guard let temperature else { return "--" }
        return "\(Int(temperature))°C"
    }

    var windDisplay: String {
        guard let windSpeed else { return "--" }
        let dir = windDirection.map { "\($0)°" } ?? ""
        return "\(Int(windSpeed)) km/h \(dir)"
    }
}
