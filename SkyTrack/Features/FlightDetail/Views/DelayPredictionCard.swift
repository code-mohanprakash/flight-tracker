import SwiftUI

/// Displays the delay prediction analysis for a flight.
struct DelayPredictionCard: View {
    let prediction: DelayPrediction
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                Image(systemName: prediction.primaryReason.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(predictionColor)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("DELAY PREDICTION")
                        .font(AppTypography.small)
                        .foregroundStyle(AppColors.textTertiary)
                        .tracking(1)
                    Text(prediction.summaryText)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                }

                Spacer()

                confidenceBadge
            }

            // Delay bar
            if prediction.predictedDelayMinutes > 0 {
                delayBar
            }

            // Primary reason
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: prediction.primaryReason.iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(predictionColor)
                Text("Primary reason: \(prediction.primaryReason.rawValue)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            // Expandable factors
            if !prediction.factors.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(isExpanded ? "Hide analysis" : "Show detailed analysis")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.primary)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.primary)
                    }
                }

                if isExpanded {
                    factorsList
                }
            }

            // Validity
            Text("Updated \(prediction.generatedAt.timeAgo)")
                .font(AppTypography.small)
                .foregroundStyle(AppColors.textTertiary)
        }
        .card()
    }

    // MARK: - Subviews

    private var confidenceBadge: some View {
        VStack(spacing: AppSpacing.xxs) {
            Text("\(Int(prediction.confidence * 100))%")
                .font(AppTypography.iataCode)
                .foregroundStyle(predictionColor)
            Text("confidence")
                .font(.system(size: 9))
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private var delayBar: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.surfaceElevated)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(predictionColor)
                        .frame(width: min(geo.size.width, geo.size.width * Double(prediction.predictedDelayMinutes) / 60.0), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("0 min")
                    .font(.system(size: 9))
                    .foregroundStyle(AppColors.textTertiary)
                Spacer()
                Text("\(prediction.predictedDelayMinutes) min predicted")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(predictionColor)
                Spacer()
                Text("60+ min")
                    .font(.system(size: 9))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }

    private var factorsList: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(prediction.factors) { factor in
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Circle()
                        .fill(severityColor(factor.severity))
                        .frame(width: 8, height: 8)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(factor.description)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textPrimary)

                        HStack {
                            Text("Impact: \(factor.estimatedImpactMinutes) min")
                                .font(AppTypography.small)
                                .foregroundStyle(AppColors.textTertiary)
                            Text("Weight: \(Int(factor.weight * 100))%")
                                .font(AppTypography.small)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }

                    Spacer()
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
    }

    // MARK: - Helpers

    private var predictionColor: Color {
        if prediction.predictedDelayMinutes == 0 { return AppColors.onTime }
        if prediction.predictedDelayMinutes <= 15 { return AppColors.delayed }
        return AppColors.cancelled
    }

    private func severityColor(_ severity: DelayFactor.Severity) -> Color {
        switch severity {
        case .low: return AppColors.onTime
        case .medium: return AppColors.delayed
        case .high: return AppColors.cancelled
        }
    }
}

#Preview {
    DelayPredictionCard(prediction: DelayPrediction(
        flightId: "test",
        predictedDelayMinutes: 25,
        confidence: 0.72,
        primaryReason: .lateAircraft,
        factors: [
            DelayFactor(type: .lateAircraft, description: "Inbound aircraft (UA456) is 35 min late",
                        estimatedImpactMinutes: 20, weight: 0.35, severity: .medium,
                        details: ["Inbound flight": "UA456"]),
            DelayFactor(type: .airportCongestion, description: "SFO congestion level: 45%",
                        estimatedImpactMinutes: 15, weight: 0.20, severity: .medium,
                        details: ["Airport": "SFO"]),
        ],
        inboundFlightId: "UA456",
        generatedAt: Date(),
        validUntil: Date().addingTimeInterval(1800)
    ))
    .padding()
    .background(AppColors.background)
}
