import SwiftUI

/// Year-in-Review: Animated summary of a year's travel (like Spotify Wrapped for flights).
struct YearInReviewView: View {
    let stats: TravelStats
    @State private var currentPage = 0
    @State private var isAnimating = false
    @Environment(\.dismiss) private var dismiss

    private let totalPages = 6

    var body: some View {
        ZStack {
            // Background gradient per page
            backgroundGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: currentPage)

            TabView(selection: $currentPage) {
                // Page 1: Total Flights
                ReviewPage(page: 0) {
                    VStack(spacing: AppSpacing.xl) {
                        AnimatedCounter(value: stats.totalFlights)
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("flights this year")
                            .font(.title2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                        if stats.totalHours > 0 {
                            Text("That's \(stats.totalHours) hours in the sky")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                .tag(0)

                // Page 2: Airports
                ReviewPage(page: 1) {
                    VStack(spacing: AppSpacing.xl) {
                        AnimatedCounter(value: stats.uniqueAirports)
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("airports visited")
                            .font(.title2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                        Text("across \(stats.uniqueCountries) countries")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))

                        // Airport badges
                        FlowLayout(spacing: 8) {
                            ForEach(stats.visitedAirports.prefix(12)) { airport in
                                Text(airport.code)
                                    .font(.caption.weight(.bold).monospaced())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.white.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .tag(1)

                // Page 3: Top Airline
                ReviewPage(page: 2) {
                    VStack(spacing: AppSpacing.xl) {
                        Image(systemName: "airplane.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)

                        if let topAirline = stats.topAirlines.first {
                            Text("Your top airline")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                            Text(topAirline.name)
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(.white)
                            Text("\(topAirline.flightCount) flights")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.8))
                        } else {
                            Text("No airlines tracked yet")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .tag(2)

                // Page 4: Top Route
                ReviewPage(page: 3) {
                    VStack(spacing: AppSpacing.xl) {
                        if let topRoute = stats.topRoutes.first {
                            let parts = topRoute.route.split(separator: "-")
                            HStack(spacing: AppSpacing.lg) {
                                Text(String(parts.first ?? "???"))
                                    .font(.system(size: 40, weight: .black, design: .monospaced))
                                    .foregroundStyle(.white)

                                VStack(spacing: 4) {
                                    Image(systemName: "airplane")
                                        .foregroundStyle(.white.opacity(0.5))
                                    Text("\(topRoute.flightCount)x")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white.opacity(0.7))
                                }

                                Text(String(parts.last ?? "???"))
                                    .font(.system(size: 40, weight: .black, design: .monospaced))
                                    .foregroundStyle(.white)
                            }

                            Text("Your most-flown route")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                .tag(3)

                // Page 5: Punctuality
                ReviewPage(page: 4) {
                    VStack(spacing: AppSpacing.xl) {
                        ZStack {
                            Circle()
                                .stroke(.white.opacity(0.15), lineWidth: 10)
                                .frame(width: 120, height: 120)
                            Circle()
                                .trim(from: 0, to: isAnimating ? stats.onTimeRate : 0)
                                .stroke(.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeOut(duration: 1.5), value: isAnimating)
                            Text(String(format: "%.0f%%", stats.onTimeRate * 100))
                                .font(.system(size: 28, weight: .black))
                                .foregroundStyle(.white)
                        }
                        Text("on-time rate")
                            .font(.title2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                        if stats.totalDelayMinutes > 0 {
                            Text("\(stats.totalDelayMinutes) minutes delayed total")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .onAppear { isAnimating = true }
                }
                .tag(4)

                // Page 6: Summary
                ReviewPage(page: 5) {
                    VStack(spacing: AppSpacing.xl) {
                        Text("Your Year\nin Review")
                            .font(.system(size: 36, weight: .black))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)

                        VStack(spacing: AppSpacing.md) {
                            SummaryRow(label: "Flights", value: "\(stats.totalFlights)")
                            SummaryRow(label: "Hours", value: "\(stats.totalHours)")
                            SummaryRow(label: "Airports", value: "\(stats.uniqueAirports)")
                            SummaryRow(label: "Countries", value: "\(stats.uniqueCountries)")
                            SummaryRow(label: "On-time", value: String(format: "%.0f%%", stats.onTimeRate * 100))
                        }
                        .padding()
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(10)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding()
                Spacer()
            }
        }
    }

    private var backgroundGradient: some View {
        let gradients: [[Color]] = [
            [Color(hex: "1a1a2e"), Color(hex: "16213e")],
            [Color(hex: "0f3460"), Color(hex: "16213e")],
            [Color(hex: "533483"), Color(hex: "0f3460")],
            [Color(hex: "e94560"), Color(hex: "533483")],
            [Color(hex: "0f3460"), Color(hex: "1a1a2e")],
            [Color(hex: "1a1a2e"), Color(hex: "0A0E1A")],
        ]
        let colors = gradients[min(currentPage, gradients.count - 1)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Review Page Container

struct ReviewPage<Content: View>: View {
    let page: Int
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack {
            Spacer()
            content()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Animated Counter

struct AnimatedCounter: View {
    let value: Int
    @State private var displayedValue = 0

    var body: some View {
        Text("\(displayedValue)")
            .contentTransition(.numericText())
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    displayedValue = value
                }
            }
    }
}

// MARK: - Summary Row

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold).monospaced())
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = max(totalHeight, y + rowHeight)
        }

        return (positions, CGSize(width: maxWidth, height: totalHeight))
    }
}
