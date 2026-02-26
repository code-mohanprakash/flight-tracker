import SwiftUI

struct FlightNumberLabel: View {
    let flightNumber: String

    var body: some View {
        Text(flightNumber.uppercased())
            .font(AppTypography.flightNumber)
            .foregroundStyle(AppColors.textPrimary)
            .tracking(1)
    }
}

struct FlightNumberLabelCompact: View {
    let flightNumber: String

    var body: some View {
        Text(flightNumber.uppercased())
            .font(AppTypography.iataCode)
            .foregroundStyle(AppColors.textPrimary)
            .tracking(0.5)
    }
}

#Preview {
    VStack {
        FlightNumberLabel(flightNumber: "UA 1234")
        FlightNumberLabelCompact(flightNumber: "UA 1234")
    }
    .padding()
    .background(AppColors.background)
}
