import SwiftUI

struct FlightDetailView: View {
    @Bindable var viewModel: FlightDetailViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.flight == nil {
                LoadingView(message: "Loading flight...")
            } else if let error = viewModel.error, viewModel.flight == nil {
                ErrorView(error: error) {
                    Task { await viewModel.loadFlight() }
                }
            } else if let flight = viewModel.flight {
                flightContent(flight)
            }
        }
        .background(AppColors.background)
        .task { await viewModel.loadFlight() }
        .onAppear { viewModel.startAutoRefresh() }
        .onDisappear { viewModel.stopAutoRefresh() }
    }

    // MARK: - Flight Content

    @ViewBuilder
    private func flightContent(_ flight: Flight) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                headerSection(flight)
                routeProgressSection(flight)
                timesSection(flight)
                gateTerminalSection(flight)
                if let liveData = flight.liveData, flight.status == .active {
                    liveDataSection(liveData)
                }
                if let aircraft = flight.aircraft {
                    aircraftSection(aircraft)
                }
            }
            .padding(AppSpacing.screenPadding)
        }
        .refreshable { await viewModel.loadFlight() }
    }

    // MARK: - Header

    private func headerSection(_ flight: Flight) -> some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    if let airline = flight.airline {
                        Text(airline.name)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    FlightNumberLabel(flightNumber: flight.displayName)
                }
                Spacer()
                StatusBadge(status: flight.status)
            }

            if let delay = flight.delayMinutes, delay > 0 {
                HStack {
                    Image(systemName: AppIcons.delayed)
                        .foregroundStyle(AppColors.delayed)
                    Text("Delayed \(delay) min")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.delayed)
                    Spacer()
                }
            }
        }
        .card()
    }

    // MARK: - Route & Progress

    private func routeProgressSection(_ flight: Flight) -> some View {
        VStack(spacing: AppSpacing.lg) {
            HStack(alignment: .top) {
                AirportCodeLabel(
                    code: flight.departure.displayCode,
                    cityName: flight.departure.airportName,
                    alignment: .leading
                )
                Spacer()
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: AppIcons.inAir)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.primary)
                    if let progress = flight.progress {
                        Text("\(Int(progress * 100))%")
                            .font(AppTypography.small)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
                Spacer()
                AirportCodeLabel(
                    code: flight.arrival.displayCode,
                    cityName: flight.arrival.airportName,
                    alignment: .trailing
                )
            }

            RouteIndicator(progress: flight.progress)
        }
        .card()
    }

    // MARK: - Times

    private func timesSection(_ flight: Flight) -> some View {
        HStack {
            TimeDisplay(
                scheduled: flight.departure.scheduledTime,
                actual: flight.departure.actualTime ?? flight.departure.estimatedTime,
                label: "Departure",
                alignment: .leading
            )
            Spacer()
            TimeDisplay(
                scheduled: flight.arrival.scheduledTime,
                actual: flight.arrival.actualTime ?? flight.arrival.estimatedTime,
                label: "Arrival",
                alignment: .trailing
            )
        }
        .card()
    }

    // MARK: - Gate & Terminal

    private func gateTerminalSection(_ flight: Flight) -> some View {
        HStack(spacing: AppSpacing.lg) {
            if flight.departure.gate != nil || flight.departure.terminal != nil {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("DEPARTURE")
                        .font(AppTypography.small)
                        .foregroundStyle(AppColors.textTertiary)
                        .tracking(1)
                    if let gate = flight.departure.gate {
                        infoRow(icon: AppIcons.gate, label: "Gate", value: gate)
                    }
                    if let terminal = flight.departure.terminal {
                        infoRow(icon: AppIcons.terminal, label: "Terminal", value: terminal)
                    }
                }
            }

            Spacer()

            if flight.arrival.gate != nil || flight.arrival.terminal != nil || flight.arrival.baggageClaim != nil {
                VStack(alignment: .trailing, spacing: AppSpacing.sm) {
                    Text("ARRIVAL")
                        .font(AppTypography.small)
                        .foregroundStyle(AppColors.textTertiary)
                        .tracking(1)
                    if let gate = flight.arrival.gate {
                        infoRow(icon: AppIcons.gate, label: "Gate", value: gate)
                    }
                    if let terminal = flight.arrival.terminal {
                        infoRow(icon: AppIcons.terminal, label: "Terminal", value: terminal)
                    }
                    if let baggage = flight.arrival.baggageClaim {
                        infoRow(icon: AppIcons.baggage, label: "Baggage", value: baggage)
                    }
                }
            }
        }
        .card()
    }

    // MARK: - Live Data

    private func liveDataSection(_ liveData: LiveFlightData) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("LIVE DATA")
                .font(AppTypography.small)
                .foregroundStyle(AppColors.textTertiary)
                .tracking(1)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: AppSpacing.md) {
                liveDataItem(icon: AppIcons.altitude, label: "Altitude", value: "\(liveData.altitudeFeet) ft")
                liveDataItem(icon: AppIcons.speed, label: "Speed", value: "\(liveData.speedKnots) kts")
                liveDataItem(icon: AppIcons.heading, label: "Heading", value: "\(Int(liveData.heading))°")
            }
        }
        .card()
    }

    // MARK: - Aircraft

    private func aircraftSection(_ aircraft: Aircraft) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("AIRCRAFT")
                .font(AppTypography.small)
                .foregroundStyle(AppColors.textTertiary)
                .tracking(1)

            HStack {
                Image(systemName: AppIcons.aircraft)
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.primary)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(aircraft.displayType)
                        .font(AppTypography.subheading)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(aircraft.displayRegistration)
                        .font(AppTypography.iataCode)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
            }
        }
        .card()
    }

    // MARK: - Helpers

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.primary)
            Text(value)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    private func liveDataItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.primary)
            Text(value)
                .font(AppTypography.timeSmall)
                .foregroundStyle(AppColors.textPrimary)
            Text(label)
                .font(AppTypography.small)
                .foregroundStyle(AppColors.textTertiary)
        }
    }
}
