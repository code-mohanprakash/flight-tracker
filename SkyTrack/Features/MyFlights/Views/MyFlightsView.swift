import SwiftUI

struct MyFlightsView: View {
    @Bindable var viewModel: MyFlightsViewModel
    @Environment(DependencyContainer.self) private var container
    @State private var selectedFlight: Flight?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEmpty {
                    emptyState
                } else {
                    flightsList
                }
            }
            .background(AppColors.background)
            .navigationTitle("My Flights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingAddFlight = true
                    } label: {
                        Image(systemName: AppIcons.add)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddFlight) {
                AddFlightSheet(viewModel: viewModel)
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
                            Button { selectedFlight = nil } label: {
                                Image(systemName: AppIcons.close)
                            }
                        }
                    }
                }
            }
            .onAppear { viewModel.loadFlights() }
            .refreshable { await viewModel.refreshFlightDetails() }
        }
    }

    // MARK: - Flights List

    private var flightsList: some View {
        List {
            if !viewModel.upcomingFlights.isEmpty {
                Section {
                    ForEach(viewModel.upcomingFlights) { saved in
                        FlightCardView(
                            saved: saved,
                            flight: viewModel.flightDetails[saved.id]
                        )
                        .listRowBackground(AppColors.surface)
                        .onTapGesture {
                            if let flight = viewModel.flightDetails[saved.id] {
                                selectedFlight = flight
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deleteFlight(saved)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Upcoming")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            if !viewModel.pastFlights.isEmpty {
                Section {
                    ForEach(viewModel.pastFlights) { saved in
                        FlightCardView(
                            saved: saved,
                            flight: viewModel.flightDetails[saved.id]
                        )
                        .listRowBackground(AppColors.surface)
                        .opacity(0.7)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deleteFlight(saved)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Past")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.textTertiary)

            VStack(spacing: AppSpacing.sm) {
                Text("No Flights Yet")
                    .font(AppTypography.heading)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Add your first flight to start tracking departures, arrivals, and gate changes.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.showingAddFlight = true
            } label: {
                Label("Add Flight", systemImage: AppIcons.add)
                    .font(AppTypography.body)
                    .fontWeight(.semibold)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(AppSpacing.xxl)
    }
}

// MARK: - Flight Card

struct FlightCardView: View {
    let saved: SavedFlight
    let flight: Flight?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header row
            HStack {
                FlightNumberLabelCompact(flightNumber: saved.flightNumber)
                Spacer()
                if let flight {
                    StatusBadge(status: flight.status)
                } else {
                    Text(saved.date.formatted(date: .abbreviated, time: .omitted))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }

            // Route info
            if let flight {
                HStack {
                    AirportCodeLabel(code: flight.departure.displayCode, alignment: .leading)
                    Spacer()
                    RouteIndicator(progress: flight.progress, compact: true)
                        .frame(maxWidth: 100)
                    Spacer()
                    AirportCodeLabel(code: flight.arrival.displayCode, alignment: .trailing)
                }

                // Times
                HStack {
                    if let depTime = flight.departure.displayTime {
                        Text(depTime.formatted(date: .omitted, time: .shortened))
                            .font(AppTypography.timeSmall)
                            .foregroundStyle(flight.departure.isDelayed ? AppColors.delayed : AppColors.textSecondary)
                    }
                    Spacer()
                    if let arrTime = flight.arrival.displayTime {
                        Text(arrTime.formatted(date: .omitted, time: .shortened))
                            .font(AppTypography.timeSmall)
                            .foregroundStyle(flight.arrival.isDelayed ? AppColors.delayed : AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Add Flight Sheet

struct AddFlightSheet: View {
    @Bindable var viewModel: MyFlightsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Flight Number", text: $viewModel.newFlightNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(AppTypography.flightNumber)

                    DatePicker("Date", selection: $viewModel.newFlightDate, displayedComponents: .date)
                }

                if let error = viewModel.addFlightError {
                    Section {
                        Text(error)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.cancelled)
                    }
                }

                Section {
                    Text("Enter the airline code and flight number, e.g. UA123, BA456, DL789")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .navigationTitle("Add Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { viewModel.addFlight() }
                        .fontWeight(.semibold)
                        .disabled(viewModel.newFlightNumber.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
