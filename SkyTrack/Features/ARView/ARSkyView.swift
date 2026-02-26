import SwiftUI
import ARKit

/// AR camera overlay for identifying flights in the sky above.
struct ARSkyView: View {
    @State var viewModel: ARSkyViewModel
    @State private var selectedFlight: OverheadFlight?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // AR Camera view
            ARCameraView()
                .ignoresSafeArea()

            // Flight overlay
            ForEach(viewModel.nearbyFlights) { flight in
                ARFlightLabel(
                    flight: flight,
                    deviceHeading: viewModel.deviceHeading,
                    isSelected: selectedFlight?.id == flight.id
                )
                .onTapGesture {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedFlight = flight
                    }
                }
            }

            // HUD Overlay
            VStack {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: AppIcons.close)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("\(viewModel.nearbyFlights.count) flights")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("within 50km")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                    Spacer()

                    Button {
                        if viewModel.isScanning {
                            viewModel.stopScanning()
                        } else {
                            viewModel.startScanning()
                        }
                    } label: {
                        Image(systemName: viewModel.isScanning ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                            .font(.title3)
                            .foregroundStyle(viewModel.isScanning ? AppColors.primary : .white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()

                // Compass bar
                CompassBarView(heading: viewModel.deviceHeading)
                    .padding(.bottom, 8)

                // Selected flight detail
                if let selected = selectedFlight {
                    ARFlightDetailCard(flight: selected)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
        }
        .onAppear { viewModel.startScanning() }
        .onDisappear { viewModel.stopScanning() }
    }
}

// MARK: - AR Camera View (UIKit bridge)

struct ARCameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravityAndHeading
        arView.session.run(config)
        arView.autoenablesDefaultLighting = true
        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: ()) {
        uiView.session.pause()
    }
}

// MARK: - AR Flight Label

struct ARFlightLabel: View {
    let flight: OverheadFlight
    let deviceHeading: Double
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "airplane")
                .font(.system(size: isSelected ? 20 : 14))
                .rotationEffect(.degrees(flight.position.trueTrack - deviceHeading))
                .foregroundStyle(isSelected ? AppColors.primary : .white)

            VStack(spacing: 1) {
                Text(flight.position.cleanCallsign)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                Text(flight.formattedAltitude)
                    .font(.system(size: 8))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .offset(arOffset)
        .animation(.spring(duration: 0.5), value: flight.position.latitude)
    }

    private var arOffset: CGSize {
        // Convert bearing + elevation to screen position
        let relativeBearing = flight.bearing - deviceHeading
        let normalizedBearing = ((relativeBearing + 180).truncatingRemainder(dividingBy: 360)) - 180
        let x = normalizedBearing / 60 * UIScreen.main.bounds.width // 60° FOV
        let y = -(flight.elevationAngle - 30) / 50 * UIScreen.main.bounds.height // Elevation mapping
        return CGSize(width: x, height: y)
    }
}

// MARK: - Compass Bar

struct CompassBarView: View {
    let heading: Double

    var body: some View {
        HStack(spacing: 0) {
            ForEach(compassPoints, id: \.self) { point in
                Text(point)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(point == "N" ? AppColors.cancelled : .white.opacity(0.7))
                    .frame(width: 40)
            }
        }
        .offset(x: -heading / 360 * 320)
        .frame(width: UIScreen.main.bounds.width - 40, alignment: .center)
        .clipped()
        .padding(.horizontal, 20)
    }

    private var compassPoints: [String] {
        ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]
    }
}

// MARK: - AR Flight Detail Card

struct ARFlightDetailCard: View {
    let flight: OverheadFlight

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Callsign + bearing
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.position.cleanCallsign)
                    .font(.headline.monospaced())
                    .foregroundStyle(.white)
                Text("\(flight.compassDirection) • \(flight.formattedDistance)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Altitude
            VStack(alignment: .center, spacing: 2) {
                Image(systemName: AppIcons.altitude)
                    .font(.caption)
                Text(flight.formattedAltitude)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.8))

            Divider()
                .background(.white.opacity(0.3))
                .frame(height: 30)

            // Speed
            VStack(alignment: .center, spacing: 2) {
                Image(systemName: AppIcons.speed)
                    .font(.caption)
                Text("\(flight.position.speedKnots) kts")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.8))

            Divider()
                .background(.white.opacity(0.3))
                .frame(height: 30)

            // Heading
            VStack(alignment: .center, spacing: 2) {
                Image(systemName: AppIcons.heading)
                    .font(.caption)
                Text("\(Int(flight.position.trueTrack))°")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
