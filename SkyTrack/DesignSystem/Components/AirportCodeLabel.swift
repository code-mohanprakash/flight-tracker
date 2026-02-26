import SwiftUI

struct AirportCodeLabel: View {
    let code: String
    let cityName: String?
    let alignment: HorizontalAlignment

    init(code: String, cityName: String? = nil, alignment: HorizontalAlignment = .leading) {
        self.code = code
        self.cityName = cityName
        self.alignment = alignment
    }

    var body: some View {
        VStack(alignment: alignment, spacing: AppSpacing.xxs) {
            Text(code.uppercased())
                .font(AppTypography.iataCode)
                .foregroundStyle(AppColors.textPrimary)
            if let cityName {
                Text(cityName)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        AirportCodeLabel(code: "SFO", cityName: "San Francisco", alignment: .leading)
        AirportCodeLabel(code: "JFK", cityName: "New York", alignment: .trailing)
    }
    .padding()
    .background(AppColors.background)
}
