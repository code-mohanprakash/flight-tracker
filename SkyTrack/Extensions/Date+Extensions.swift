import Foundation

extension Date {
    var timeAgo: String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    var relativeCountdown: String {
        let interval = self.timeIntervalSince(Date())
        if interval <= 0 { return "now" }
        if interval < 3600 {
            let min = Int(interval / 60)
            return "\(min)m"
        }
        let hours = Int(interval / 3600)
        let min = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(min)m"
    }

    func formatted(in timezone: String?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let tz = timezone, let timeZone = TimeZone(identifier: tz) {
            formatter.timeZone = timeZone
        }
        return formatter.string(from: self)
    }

    static func from(isoString: String?) -> Date? {
        guard let isoString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoString) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: isoString) { return date }
        // Try without timezone
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return df.date(from: isoString)
    }
}
