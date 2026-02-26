import ActivityKit
import SwiftUI
import WidgetKit

struct FlightLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlightActivityAttributes.self) { context in
            // Lock screen banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    expandedCenter(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(context: context)
                }
            } compactLeading: {
                // Compact leading (left pill half)
                Image(systemName: "airplane")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.blue)
            } compactTrailing: {
                // Compact trailing (right pill half)
                Text(context.state.statusDisplay)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(context.state.isDelayed ? .orange : .primary)
            } minimal: {
                // Minimal (when competing with other activities)
                Image(systemName: "airplane")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<FlightActivityAttributes>) -> some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text(context.attributes.flightNumber)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                Spacer()
                Text(context.state.statusDisplay)
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor(context.state).opacity(0.2))
                    .foregroundStyle(statusColor(context.state))
                    .clipShape(Capsule())
            }

            // Route with progress
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.departureCode)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                    if let depTime = context.state.departureTime {
                        Text(depTime.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(context.state.isDelayed ? .orange : .secondary)
                    }
                }

                Spacer()

                // Progress bar
                progressIndicator(progress: context.state.progress)
                    .frame(maxWidth: 120)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.attributes.arrivalCode)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                    if let arrTime = context.state.arrivalTime {
                        Text(arrTime.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Footer
            HStack {
                if let gate = context.state.gate {
                    Label("Gate \(gate)", systemImage: "door.left.hand.open")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if context.state.isDelayed, let delay = context.state.delayMinutes {
                    Text("Delayed \(delay) min")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.orange)
                } else if let eta = context.state.etaCountdown, eta > 0 {
                    let hours = Int(eta) / 3600
                    let mins = (Int(eta) % 3600) / 60
                    Text("ETA: \(hours)h \(mins)m")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .activityBackgroundTint(.black.opacity(0.75))
    }

    // MARK: - Dynamic Island Expanded

    @ViewBuilder
    private func expandedLeading(context: ActivityViewContext<FlightActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.departureCode)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
            if let depTime = context.state.departureTime {
                Text(depTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func expandedTrailing(context: ActivityViewContext<FlightActivityAttributes>) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(context.attributes.arrivalCode)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
            if let arrTime = context.state.arrivalTime {
                Text(arrTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func expandedCenter(context: ActivityViewContext<FlightActivityAttributes>) -> some View {
        VStack(spacing: 4) {
            Text(context.attributes.flightNumber)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
            progressIndicator(progress: context.state.progress)
        }
    }

    @ViewBuilder
    private func expandedBottom(context: ActivityViewContext<FlightActivityAttributes>) -> some View {
        HStack {
            if let gate = context.state.gate {
                Label("Gate \(gate)", systemImage: "door.left.hand.open")
                    .font(.system(size: 11))
            }
            Spacer()
            Text(context.state.statusDisplay)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(statusColor(context.state))
        }
    }

    // MARK: - Helpers

    private func progressIndicator(progress: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 3)
                Capsule()
                    .fill(Color.blue)
                    .frame(width: geo.size.width * max(0, min(progress, 1)), height: 3)
                if progress > 0 && progress < 1 {
                    Image(systemName: "airplane")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.blue)
                        .offset(x: geo.size.width * progress - 5)
                }
            }
        }
        .frame(height: 12)
    }

    private func statusColor(_ state: FlightActivityAttributes.ContentState) -> Color {
        if state.isDelayed { return .orange }
        switch state.status {
        case "landed": return .green
        case "cancelled": return .red
        case "diverted": return .purple
        default: return .blue
        }
    }
}
