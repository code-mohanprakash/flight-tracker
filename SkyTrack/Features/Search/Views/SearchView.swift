import SwiftUI

struct SearchView: View {
    @Bindable var viewModel: SearchViewModel
    @Environment(DependencyContainer.self) private var container
    @State private var selectedFlight: Flight?
    @State private var selectedAirport: Airport?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Type Picker
                Picker("Search Type", selection: $viewModel.selectedSearchType) {
                    ForEach(SearchViewModel.SearchType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.vertical, AppSpacing.sm)

                // Results
                if viewModel.isSearching {
                    LoadingView(message: "Searching...")
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        viewModel.performSearch()
                    }
                } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                    emptyResultsView
                } else if viewModel.results.isEmpty {
                    recentSearchesView
                } else {
                    resultsList
                }
            }
            .background(AppColors.background)
            .navigationTitle("Search")
            .searchable(text: $viewModel.query, prompt: "Flight number, airport, or city")
            .onSubmit(of: .search) {
                viewModel.performSearch()
            }
            .sheet(item: $selectedFlight) { flight in
                NavigationStack {
                    FlightDetailView(
                        viewModel: container.makeFlightDetailViewModel(flightId: flight.displayName)
                    )
                    .navigationTitle(flight.displayName)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                selectedFlight = nil
                            } label: {
                                Image(systemName: AppIcons.close)
                            }
                        }
                    }
                }
                .presentationDetents([.large])
            }
            .sheet(item: $selectedAirport) { airport in
                NavigationStack {
                    AirportDetailView(
                        viewModel: container.makeAirportViewModel(airportCode: airport.displayCode)
                    )
                    .navigationTitle(airport.displayCode)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                selectedAirport = nil
                            } label: {
                                Image(systemName: AppIcons.close)
                            }
                        }
                    }
                }
                .presentationDetents([.large])
            }
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            ForEach(viewModel.results) { result in
                switch result {
                case .flight(let flight):
                    FlightSearchResultRow(flight: flight)
                        .listRowBackground(AppColors.surface)
                        .onTapGesture { selectedFlight = flight }
                case .airport(let airport):
                    AirportSearchResultRow(airport: airport)
                        .listRowBackground(AppColors.surface)
                        .onTapGesture { selectedAirport = airport }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty Results

    private var emptyResultsView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textTertiary)
            Text("No results found")
                .font(AppTypography.subheading)
                .foregroundStyle(AppColors.textPrimary)
            Text("Try a flight number (e.g. UA123) or airport code (e.g. SFO)")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Recent Searches

    private var recentSearchesView: some View {
        Group {
            if viewModel.recentSearches.isEmpty {
                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.textTertiary)
                    Text("Search for flights or airports")
                        .font(AppTypography.subheading)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Enter a flight number, airport code, or city name")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(AppSpacing.xxl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        ForEach(viewModel.recentSearches, id: \.self) { search in
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(AppColors.textTertiary)
                                Text(search)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.textPrimary)
                                Spacer()
                                Image(systemName: AppIcons.chevronRight)
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                            .listRowBackground(AppColors.surface)
                            .onTapGesture {
                                viewModel.query = search
                                viewModel.performSearch()
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.removeRecentSearch(search)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text("Recent Searches")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

// MARK: - Search Result Rows

struct FlightSearchResultRow: View {
    let flight: Flight

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.sm) {
                    FlightNumberLabelCompact(flightNumber: flight.displayName)
                    if let airline = flight.airline {
                        Text(airline.name)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                Text(flight.routeDescription)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            StatusBadge(status: flight.status)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

struct AirportSearchResultRow: View {
    let airport: Airport

    var body: some View {
        HStack {
            Image(systemName: "building.2")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.primary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.sm) {
                    Text(airport.displayCode)
                        .font(AppTypography.iataCode)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(airport.name)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
                if let city = airport.city, let country = airport.country {
                    Text("\(city), \(country)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            Spacer()
            Image(systemName: AppIcons.chevronRight)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
