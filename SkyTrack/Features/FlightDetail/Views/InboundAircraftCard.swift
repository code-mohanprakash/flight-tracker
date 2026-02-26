import SwiftUI

/// Displays the inbound aircraft tracking status — "Where's My Plane?"
struct InboundAircraftCard: View {
    let inboundFlight: Flight?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                Image(systemName: "airplane.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.primary)
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("WHERE'S MY PLANE?")
                        .font(AppTypography.small)
                        .foregroundStyle(AppColors.textTertiary)
                        .tracking(1)
                    Text("Track the inbound aircraft")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
            }

            if isLoading {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Locating aircraft...")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            } else if let inbound = inboundFlight {
                // Inbound flight info
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        FlightNumberLabelCompact(flightNumber: inbound.displayName)
                        Spacer()
                        StatusBadge(status: inbound.status)
                    }

                    HStack {
                        Text("\(inbound.departure.displayCode) → \(inbound.arrival.displayCode)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        if let delay = inbound.delayMinutes, delay > 0 {
                            Text("+\(delay) min late")
                                .font(AppTypography.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(AppColors.delayed)
                        } else {
                            Text("On time")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.onTime)
                        }
                    }

                    if let arrTime = inbound.arrival.estimatedTime ?? inbound.arrival.scheduledTime {
                        HStack {
                            Text("Arriving at gate:")
                                .font(AppTypography.small)
                                .foregroundStyle(AppColors.textTertiary)
                            Spacer()
                            Text(arrTime.formatted(date: .omitted, time: .shortened))
                                .font(AppTypography.timeSmall)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    }

                    if let aircraft = inbound.aircraft {
                        HStack {
                            Text(aircraft.displayType)
                                .font(AppTypography.small)
                                .foregroundStyle(AppColors.textTertiary)
                            if let reg = aircraft.registration {
                                Text(reg)
                                    .font(AppTypography.small)
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                        }
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
            } else {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(AppColors.textTertiary)
                    Text("Aircraft not yet assigned or tracking unavailable")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
        }
        .card()
    }
}
