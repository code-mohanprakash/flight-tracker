import SwiftUI

/// Service for generating shareable flight cards and tracking URLs.
@Observable
final class SharingService {
    // MARK: - Share Card Generation

    /// Generate a rich image card for sharing a flight
    @MainActor
    func generateShareCard(for flight: Flight) -> UIImage? {
        let renderer = ImageRenderer(content: FlightShareCardView(flight: flight))
        renderer.scale = 3.0
        renderer.proposedSize = .init(width: 400, height: 240)
        return renderer.uiImage
    }

    /// Generate shareable items for a flight
    @MainActor
    func shareItems(for flight: Flight) -> [Any] {
        var items: [Any] = []

        // Rich text summary
        let statusEmoji = flight.status == .active ? "✈️" : (flight.status == .landed ? "🛬" : "📋")
        let text = """
        \(statusEmoji) \(flight.displayName) — \(flight.routeDescription)
        Status: \(flight.status.displayName)
        \(formatDepartureInfo(flight))
        \(formatArrivalInfo(flight))
        Tracked with SkyTrack
        """
        items.append(text)

        // Share card image
        if let image = generateShareCard(for: flight) {
            items.append(image)
        }

        // Live tracking URL
        if let url = liveTrackingURL(for: flight) {
            items.append(url)
        }

        return items
    }

    /// Generate a live tracking URL for a flight
    func liveTrackingURL(for flight: Flight) -> URL? {
        guard let iata = flight.flightIata else { return nil }
        // Deep link URL scheme
        return URL(string: "skytrack://flight/\(iata)")
    }

    // MARK: - Private

    private func formatDepartureInfo(_ flight: Flight) -> String {
        let dep = flight.departure
        var info = "Departure: \(dep.displayCode)"
        if let gate = dep.gate { info += " Gate \(gate)" }
        if let terminal = dep.terminal { info += " (T\(terminal))" }
        if let time = dep.displayTime {
            info += " at \(time.formatted(date: .omitted, time: .shortened))"
        }
        if dep.isDelayed, let delay = dep.delayMinutes {
            info += " (delayed \(delay)min)"
        }
        return info
    }

    private func formatArrivalInfo(_ flight: Flight) -> String {
        let arr = flight.arrival
        var info = "Arrival: \(arr.displayCode)"
        if let time = arr.displayTime {
            info += " at \(time.formatted(date: .omitted, time: .shortened))"
        }
        if let baggage = arr.baggageClaim {
            info += " Baggage: \(baggage)"
        }
        return info
    }
}

// MARK: - Share Card View (rendered to image)

struct FlightShareCardView: View {
    let flight: Flight

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(flight.displayName)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    if let airline = flight.airline?.name {
                        Text(airline)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                Spacer()
                Text(flight.status.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }
            .padding()

            // Route
            HStack(alignment: .center, spacing: 16) {
                VStack(spacing: 4) {
                    Text(flight.departure.displayCode)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(flight.departure.city ?? "")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                    if let time = flight.departure.displayTime {
                        Text(time.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }

                VStack(spacing: 4) {
                    Image(systemName: "airplane")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.5))
                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 60, height: 1)
                    if let progress = flight.progress {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                VStack(spacing: 4) {
                    Text(flight.arrival.displayCode)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(flight.arrival.city ?? "")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                    if let time = flight.arrival.displayTime {
                        Text(time.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)

            // Footer
            HStack {
                Image(systemName: "airplane.circle.fill")
                    .foregroundStyle(.white.opacity(0.4))
                Text("SkyTrack")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                if let delay = flight.delayMinutes, delay > 0 {
                    Text("+\(delay) min")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.delayed)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0A0E1A"), Color(hex: "141929")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statusColor: Color {
        switch flight.status {
        case .active: AppColors.inAir
        case .landed: AppColors.landed
        case .delayed: AppColors.delayed
        case .cancelled: AppColors.cancelled
        case .diverted: AppColors.diverted
        default: AppColors.scheduled
        }
    }
}

// MARK: - Share Sheet View

struct FlightShareSheet: View {
    let flight: Flight
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Text("Share Flight")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)

                FlightShareCardView(flight: flight)
                    .frame(width: 340, height: 200)
                    .padding()

                VStack(spacing: AppSpacing.md) {
                    ShareOptionButton(
                        icon: "square.and.arrow.up",
                        title: "Share Card",
                        subtitle: "Rich image with flight details"
                    ) {
                        showShareSheet = true
                    }

                    ShareOptionButton(
                        icon: "link",
                        title: "Copy Tracking Link",
                        subtitle: "Live flight tracking URL"
                    ) {
                        if let url = SharingService().liveTrackingURL(for: flight) {
                            UIPasteboard.general.string = url.absoluteString
                        }
                        dismiss()
                    }

                    ShareOptionButton(
                        icon: "doc.on.clipboard",
                        title: "Copy Status",
                        subtitle: "Plain text flight status"
                    ) {
                        let text = "\(flight.displayName) \(flight.routeDescription) — \(flight.status.displayName)"
                        UIPasteboard.general.string = text
                        dismiss()
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct ShareOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 40, height: 40)
                    .background(AppColors.primaryDim)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: AppIcons.chevronRight)
                    .font(.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
