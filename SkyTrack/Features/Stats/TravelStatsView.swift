import SwiftUI
import Charts

/// Travel statistics dashboard with charts and travel history.
struct TravelStatsView: View {
    @State var statsService: TravelStatsService
    @State private var selectedPeriod: StatsPeriod = .allTime

    var body: some View {
        NavigationStack {
            ScrollView {
                if statsService.isLoading {
                    ProgressView()
                        .padding(.top, 60)
                } else if let stats = statsService.stats {
                    VStack(spacing: AppSpacing.lg) {
                        // Period picker
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(StatsPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        // Summary cards
                        summarySection(stats)

                        // Monthly chart
                        monthlyChartSection(stats)

                        // Top airlines
                        if !stats.topAirlines.isEmpty {
                            topAirlinesSection(stats)
                        }

                        // Top routes
                        if !stats.topRoutes.isEmpty {
                            topRoutesSection(stats)
                        }

                        // On-time performance
                        onTimeSection(stats)

                        // Airports visited
                        airportsSection(stats)

                        // Flight history
                        historySection(stats)
                    }
                    .padding(.bottom, AppSpacing.xxxl)
                } else {
                    emptyState
                }
            }
            .background(AppColors.background)
            .navigationTitle("Travel Stats")
            .task {
                await statsService.computeStats()
            }
        }
    }

    // MARK: - Summary Cards

    private func summarySection(_ stats: TravelStats) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppSpacing.md) {
            StatCard(value: "\(stats.totalFlights)", label: "Flights", icon: "airplane")
            StatCard(value: "\(stats.totalHours)h", label: "In Air", icon: "clock")
            StatCard(value: "\(stats.uniqueAirports)", label: "Airports", icon: "building.2")
            StatCard(value: "\(stats.uniqueCountries)", label: "Countries", icon: "globe")
            StatCard(value: "\(stats.uniqueCities)", label: "Cities", icon: "mappin.and.ellipse")
            StatCard(value: String(format: "%.0f%%", stats.onTimeRate * 100), label: "On Time", icon: "checkmark.circle")
        }
        .padding(.horizontal)
    }

    // MARK: - Monthly Chart

    private func monthlyChartSection(_ stats: TravelStats) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Flights by Month")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal)

            Chart {
                ForEach(1...12, id: \.self) { month in
                    BarMark(
                        x: .value("Month", monthName(month)),
                        y: .value("Flights", stats.monthlyDistribution[month] ?? 0)
                    )
                    .foregroundStyle(AppColors.primary.gradient)
                    .cornerRadius(4)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel()
                        .font(.system(size: 8))
                }
            }
            .frame(height: 180)
            .padding()
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    // MARK: - Top Airlines

    private func topAirlinesSection(_ stats: TravelStats) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Top Airlines")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(stats.topAirlines) { airline in
                    HStack {
                        Text(airline.name)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Text("\(airline.flightCount) flights")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                    if airline.id != stats.topAirlines.last?.id {
                        Divider()
                            .background(AppColors.separator)
                    }
                }
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    // MARK: - Top Routes

    private func topRoutesSection(_ stats: TravelStats) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Top Routes")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(stats.topRoutes) { route in
                    HStack {
                        Text(route.route.replacingOccurrences(of: "-", with: " → "))
                            .font(.subheadline.monospaced())
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Text("\(route.flightCount)x")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.primary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                    if route.id != stats.topRoutes.last?.id {
                        Divider()
                            .background(AppColors.separator)
                    }
                }
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    // MARK: - On-Time Section

    private func onTimeSection(_ stats: TravelStats) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Punctuality")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal)

            HStack(spacing: AppSpacing.lg) {
                // Gauge
                ZStack {
                    Circle()
                        .stroke(AppColors.surfaceElevated, lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: stats.onTimeRate)
                        .stroke(
                            stats.onTimeRate > 0.8 ? AppColors.onTime : AppColors.delayed,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f%%", stats.onTimeRate * 100))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppColors.textPrimary)
                        Text("on time")
                            .font(.caption2)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .frame(width: 90, height: 90)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Circle().fill(AppColors.onTime).frame(width: 8, height: 8)
                        Text("\(stats.totalFlights - stats.delayedFlightCount) on time")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    HStack {
                        Circle().fill(AppColors.delayed).frame(width: 8, height: 8)
                        Text("\(stats.delayedFlightCount) delayed")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    if stats.totalDelayMinutes > 0 {
                        Text("Total delay: \(stats.totalDelayMinutes) min")
                            .font(.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    // MARK: - Airports

    private func airportsSection(_ stats: TravelStats) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Airports Visited")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text("\(stats.uniqueAirports)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.primary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(stats.visitedAirports.prefix(15)) { airport in
                        VStack(spacing: 4) {
                            Text(airport.code)
                                .font(.caption.weight(.bold).monospaced())
                                .foregroundStyle(AppColors.textPrimary)
                            Text("\(airport.visitCount)x")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .frame(width: 50, height: 50)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - History

    private func historySection(_ stats: TravelStats) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Flight History")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(stats.flightHistory.prefix(10)) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.flightNumber)
                                .font(.caption.weight(.bold).monospaced())
                                .foregroundStyle(AppColors.textPrimary)
                            Text("\(record.origin) → \(record.destination)")
                                .font(.caption2)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(AppColors.textTertiary)
                            if record.wasDelayed {
                                Text("+\(record.delayMinutes)m")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(AppColors.delayed)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    if record.id != stats.flightHistory.prefix(10).last?.id {
                        Divider().background(AppColors.separator)
                    }
                }
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "chart.bar")
                .font(.system(size: 50))
                .foregroundStyle(AppColors.textTertiary)
            Text("No Stats Yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
            Text("Track flights to build your travel statistics")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Helpers

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var comps = DateComponents()
        comps.month = month
        guard let date = Calendar.current.date(from: comps) else { return "" }
        return formatter.string(from: date)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppColors.primary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Stats Period

enum StatsPeriod: String, CaseIterable {
    case thisYear = "This Year"
    case allTime = "All Time"
    case last90Days = "90 Days"
}
