import SwiftUI
import MapKit

struct FlightMapView: View {
    @Bindable var viewModel: FlightMapViewModel
    @State private var showingFlightDetail = false
    @State private var selectedCallsign: String?

    var body: some View {
        ZStack {
            mapContent

            // Aircraft count overlay
            VStack {
                HStack {
                    Spacer()
                    aircraftCountBadge
                }
                Spacer()
            }
            .padding(AppSpacing.screenPadding)

            if viewModel.isLoading && viewModel.positions.isEmpty {
                LoadingView(message: "Loading aircraft...")
            }

            if let error = viewModel.error, viewModel.positions.isEmpty {
                ErrorView(error: error) {
                    viewModel.startTracking()
                }
            }
        }
        .onAppear { viewModel.startTracking() }
        .onDisappear { viewModel.stopTracking() }
        .sheet(isPresented: $showingFlightDetail) {
            if let position = viewModel.selectedPosition {
                FlightPositionDetailSheet(position: position)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Map Content

    private var mapContent: some View {
        Map(position: $viewModel.cameraPosition) {
            ForEach(viewModel.positions) { position in
                Annotation(position.cleanCallsign, coordinate: position.coordinate) {
                    AircraftAnnotationView(
                        position: position,
                        isSelected: viewModel.selectedPosition?.id == position.id
                    )
                    .onTapGesture {
                        viewModel.selectAircraft(position)
                        showingFlightDetail = true
                    }
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll, showsTraffic: false))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.updateVisibleRegion(context.region)
        }
    }

    // MARK: - Aircraft Count Badge

    private var aircraftCountBadge: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: AppIcons.aircraftMarker)
                .font(.system(size: 12, weight: .bold))
            Text("\(viewModel.positions.count)")
                .font(AppTypography.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Flight Position Detail Sheet

struct FlightPositionDetailSheet: View {
    let position: FlightPosition

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(position.cleanCallsign)
                                .font(AppTypography.flightNumber)
                                .foregroundStyle(AppColors.textPrimary)
                            if let country = position.originCountry {
                                Text(country)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        Spacer()
                        StatusBadge(status: position.onGround ? .landed : .active)
                    }
                    .card()

                    // Live Data Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: AppSpacing.md) {
                        dataCard(icon: AppIcons.altitude, label: "Altitude", value: "\(position.altitudeFeet) ft")
                        dataCard(icon: AppIcons.speed, label: "Speed", value: "\(position.speedKnots) kts")
                        dataCard(icon: AppIcons.heading, label: "Heading", value: "\(Int(position.trueTrack))°")
                        dataCard(icon: AppIcons.verticalRate, label: "Vertical Rate", value: "\(Int(position.verticalRate)) m/s")
                    }

                    // Position
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("POSITION")
                            .font(AppTypography.small)
                            .foregroundStyle(AppColors.textTertiary)
                            .tracking(1)
                        Text(String(format: "%.4f°, %.4f°", position.latitude, position.longitude))
                            .font(AppTypography.altitude)
                            .foregroundStyle(AppColors.textSecondary)
                        Text("Updated \(position.lastUpdate.timeAgo)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .card()
                }
                .padding(AppSpacing.screenPadding)
            }
            .background(AppColors.background)
            .navigationTitle(position.cleanCallsign)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func dataCard(icon: String, label: String, value: String) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AppColors.primary)
            Text(label)
                .font(AppTypography.small)
                .foregroundStyle(AppColors.textTertiary)
            Text(value)
                .font(AppTypography.time)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .card()
    }
}

#Preview {
    FlightMapView(viewModel: FlightMapViewModel(
        flightRepository: FlightRepository(
            apiClient: APIClient(session: .shared, configuration: .init(
                baseURL: URL(string: "https://api.aviationstack.com/v1")!,
                apiKey: "demo"
            )),
            openSkyClient: OpenSkyClient(session: .shared),
            cache: FlightCache()
        )
    ))
}
