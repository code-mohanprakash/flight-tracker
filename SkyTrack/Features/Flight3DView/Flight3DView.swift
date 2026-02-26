import SwiftUI
import SceneKit

/// 3D flight visualization with terrain, aircraft model, and camera modes.
struct Flight3DView: View {
    @State var viewModel: Flight3DViewModel
    let flight: Flight
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 3D Scene
            SceneView(
                scene: viewModel.scene,
                pointOfView: viewModel.cameraNode,
                options: [.allowsCameraControl, .autoenablesDefaultLighting]
            )
            .ignoresSafeArea()

            // Overlay controls
            VStack {
                // Top bar
                topBar

                Spacer()

                // Bottom controls
                bottomControls
            }
        }
        .onAppear {
            viewModel.loadFlight(flight)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: AppIcons.close)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            // Flight info
            VStack(spacing: 2) {
                Text(flight.displayName)
                    .font(.subheadline.weight(.bold).monospaced())
                    .foregroundStyle(.white)
                Text(flight.routeDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

            Spacer()

            // Live data badge
            if let live = flight.liveData {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("FL\(live.altitudeFeet / 100)")
                        .font(.caption.weight(.semibold).monospaced())
                    Text("\(live.speedKnots) kts")
                        .font(.caption2)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: AppSpacing.md) {
            // Camera mode picker
            HStack(spacing: 8) {
                ForEach(Flight3DViewModel.ViewMode.allCases, id: \.rawValue) { mode in
                    Button {
                        withAnimation(.spring(duration: 0.5)) {
                            viewModel.setViewMode(mode)
                        }
                    } label: {
                        Text(mode.rawValue)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(viewModel.viewMode == mode ? .white : .white.opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                viewModel.viewMode == mode
                                    ? AnyShapeStyle(AppColors.primary)
                                    : AnyShapeStyle(.ultraThinMaterial)
                            )
                            .clipShape(Capsule())
                    }
                }
            }

            // Flight stats bar
            if let live = flight.liveData {
                HStack(spacing: AppSpacing.xl) {
                    statItem(icon: AppIcons.altitude, value: "\(live.altitudeFeet.formatted()) ft", label: "ALT")
                    statItem(icon: AppIcons.speed, value: "\(live.speedKnots) kts", label: "GS")
                    statItem(icon: AppIcons.heading, value: "\(Int(live.heading))°", label: "HDG")
                    statItem(icon: AppIcons.verticalRate, value: "\(live.verticalRateFPM) fpm", label: "VS")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.caption.weight(.semibold).monospaced())
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
