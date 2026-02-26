import SwiftUI

struct FlightProgressBar: View {
    let departure: FlightEndpoint
    let arrival: FlightEndpoint
    let progress: Double?

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Airport codes with times
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(departure.displayCode)
                        .font(AppTypography.iataCode)
                        .foregroundStyle(AppColors.textPrimary)
                    if let time = departure.displayTime {
                        Text(time.formatted(date: .omitted, time: .shortened))
                            .font(AppTypography.timeSmall)
                            .foregroundStyle(departure.isDelayed ? AppColors.delayed : AppColors.textSecondary)
                    }
                }

                Spacer()

                // Duration
                if let depTime = departure.scheduledTime, let arrTime = arrival.scheduledTime {
                    let duration = arrTime.timeIntervalSince(depTime)
                    let hours = Int(duration) / 3600
                    let minutes = (Int(duration) % 3600) / 60
                    Text("\(hours)h \(minutes)m")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                    Text(arrival.displayCode)
                        .font(AppTypography.iataCode)
                        .foregroundStyle(AppColors.textPrimary)
                    if let time = arrival.displayTime {
                        Text(time.formatted(date: .omitted, time: .shortened))
                            .font(AppTypography.timeSmall)
                            .foregroundStyle(arrival.isDelayed ? AppColors.delayed : AppColors.textSecondary)
                    }
                }
            }

            // Progress bar
            RouteIndicator(progress: progress)
        }
    }
}
