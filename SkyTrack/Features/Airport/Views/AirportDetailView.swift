import SwiftUI

struct AirportDetailView: View {
    @Bindable var viewModel: AirportViewModel
    @Environment(DependencyContainer.self) private var container
    @State private var selectedFlight: Flight?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.airport == nil {
                LoadingView(message: "Loading airport...")
            } else if let error = viewModel.error, viewModel.airport == nil {
                ErrorView(error: error) {
                    Task { await viewModel.loadAirport() }
                }
            } else {
                airportContent
            }
        }
        .background(AppColors.background)
        .task { await viewModel.loadAirport() }
        .onAppear { viewModel.startAutoRefresh() }
        .onDisappear { viewModel.stopAutoRefresh() }
        .sheet(item: $selectedFlight) { flight in
            NavigationStack {
                FlightDetailView(
                    viewModel: container.makeFlightDetailViewModel(flightId: flight.displayName)
                )
                .navigationTitle(flight.displayName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { selectedFlight = nil } label: {
                            Image(systemName: AppIcons.close)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Content

    private var airportContent: some View {
        VStack(spacing: 0) {
            // Airport Header
            if let airport = viewModel.airport {
                airportHeader(airport)
            }

            // Board Picker
            Picker("Board", selection: $viewModel.selectedBoard) {
                ForEach(AirportViewModel.BoardType.allCases, id: \.self) { board in
                    Text(board.rawValue).tag(board)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.vertical, AppSpacing.sm)
            .onChange(of: viewModel.selectedBoard) { _, newValue in
                viewModel.switchBoard(to: newValue)
            }

            // Board Content
            if viewModel.isBoardLoading && viewModel.currentBoardFlights.isEmpty {
                LoadingView(message: "Loading flights...")
            } else if viewModel.currentBoardFlights.isEmpty {
                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: viewModel.selectedBoard == .departures ? AppIcons.departures : AppIcons.arrivals)
                        .font(.system(size: 40))
                        .foregroundStyle(AppColors.textTertiary)
                    Text("No \(viewModel.selectedBoard.rawValue.lowercased()) found")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                boardList
            }
        }
    }

    // MARK: - Airport Header

    private func airportHeader(_ airport: Airport) -> some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(airport.displayCode)
                        .font(AppTypography.flightNumber)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(airport.name)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                    if let city = airport.city, let country = airport.country {
                        Text("\(city), \(country)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
                Spacer()
                if let tz = airport.timezone {
                    VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                        Text("Local Time")
                            .font(AppTypography.small)
                            .foregroundStyle(AppColors.textTertiary)
                        Text(Date().formatted(in: tz))
                            .font(AppTypography.time)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }
        }
        .padding(AppSpacing.screenPadding)
        .background(AppColors.surface)
    }

    // MARK: - Board List

    private var boardList: some View {
        List {
            ForEach(viewModel.currentBoardFlights) { flight in
                BoardFlightRow(
                    flight: flight,
                    boardType: viewModel.selectedBoard
                )
                .listRowBackground(AppColors.surface)
                .onTapGesture {
                    selectedFlight = flight
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.loadBoard() }
    }
}

// MARK: - Board Flight Row

struct BoardFlightRow: View {
    let flight: Flight
    let boardType: AirportViewModel.BoardType

    private var time: Date? {
        switch boardType {
        case .departures: flight.departure.displayTime
        case .arrivals: flight.arrival.displayTime
        }
    }

    private var scheduledTime: Date? {
        switch boardType {
        case .departures: flight.departure.scheduledTime
        case .arrivals: flight.arrival.scheduledTime
        }
    }

    private var destination: String {
        switch boardType {
        case .departures: flight.arrival.displayCode
        case .arrivals: flight.departure.displayCode
        }
    }

    private var gate: String? {
        switch boardType {
        case .departures: flight.departure.gate
        case .arrivals: flight.arrival.gate
        }
    }

    private var isDelayed: Bool {
        switch boardType {
        case .departures: flight.departure.isDelayed
        case .arrivals: flight.arrival.isDelayed
        }
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Time
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                if let time {
                    Text(time.formatted(date: .omitted, time: .shortened))
                        .font(AppTypography.time)
                        .foregroundStyle(isDelayed ? AppColors.delayed : AppColors.textPrimary)
                }
                if isDelayed, let scheduled = scheduledTime {
                    Text(scheduled.formatted(date: .omitted, time: .shortened))
                        .font(AppTypography.timeSmall)
                        .foregroundStyle(AppColors.textTertiary)
                        .strikethrough()
                }
            }
            .frame(width: 65, alignment: .leading)

            // Flight & Destination
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                FlightNumberLabelCompact(flightNumber: flight.displayName)
                Text(destination)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            // Gate
            if let gate {
                VStack(spacing: AppSpacing.xxs) {
                    Text("Gate")
                        .font(AppTypography.small)
                        .foregroundStyle(AppColors.textTertiary)
                    Text(gate)
                        .font(AppTypography.iataCode)
                        .foregroundStyle(AppColors.textPrimary)
                }
            }

            // Status
            StatusBadge(status: flight.status)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
