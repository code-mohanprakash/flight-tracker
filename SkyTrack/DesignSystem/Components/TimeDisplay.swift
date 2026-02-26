import SwiftUI

struct TimeDisplay: View {
    let scheduled: Date?
    let actual: Date?
    let label: String
    let alignment: HorizontalAlignment

    init(
        scheduled: Date?,
        actual: Date? = nil,
        label: String,
        alignment: HorizontalAlignment = .leading
    ) {
        self.scheduled = scheduled
        self.actual = actual
        self.label = label
        self.alignment = alignment
    }

    private var isDelayed: Bool {
        guard let scheduled, let actual else { return false }
        return actual.timeIntervalSince(scheduled) > 300 // > 5 min
    }

    private var displayTime: Date? {
        actual ?? scheduled
    }

    var body: some View {
        VStack(alignment: alignment, spacing: AppSpacing.xxs) {
            Text(label.uppercased())
                .font(AppTypography.small)
                .foregroundStyle(AppColors.textTertiary)
                .tracking(0.5)

            if let displayTime {
                Text(displayTime.formatted(date: .omitted, time: .shortened))
                    .font(AppTypography.time)
                    .foregroundStyle(isDelayed ? AppColors.delayed : AppColors.textPrimary)
            } else {
                Text("--:--")
                    .font(AppTypography.time)
                    .foregroundStyle(AppColors.textTertiary)
            }

            if isDelayed, let scheduled {
                Text(scheduled.formatted(date: .omitted, time: .shortened))
                    .font(AppTypography.timeSmall)
                    .foregroundStyle(AppColors.textTertiary)
                    .strikethrough(color: AppColors.textTertiary)
            }
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        TimeDisplay(
            scheduled: Date(),
            label: "Departure"
        )
        TimeDisplay(
            scheduled: Date(),
            actual: Date().addingTimeInterval(1800),
            label: "Arrival"
        )
    }
    .padding()
    .background(AppColors.background)
}
