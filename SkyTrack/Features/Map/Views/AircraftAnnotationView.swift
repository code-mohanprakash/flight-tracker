import SwiftUI

struct AircraftAnnotationView: View {
    let position: FlightPosition
    var isSelected: Bool = false

    var body: some View {
        Image(systemName: "airplane")
            .font(.system(size: isSelected ? 18 : 14, weight: .bold))
            .foregroundStyle(isSelected ? AppColors.primary : aircraftColor)
            .rotationEffect(.degrees(position.trueTrack - 90)) // Airplane icon points right by default
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private var aircraftColor: Color {
        if position.onGround {
            return AppColors.textTertiary
        }
        // Color by altitude
        let altFeet = position.altitudeFeet
        if altFeet < 10000 {
            return AppColors.onTime // Low altitude - green
        } else if altFeet < 25000 {
            return AppColors.delayed // Medium - yellow
        } else {
            return AppColors.primary // Cruise - blue
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AircraftAnnotationView(
            position: FlightPosition(
                id: "abc123", callsign: "UAL123",
                latitude: 37.7749, longitude: -122.4194,
                altitude: 10000, velocity: 250, trueTrack: 45,
                verticalRate: 5, onGround: false,
                lastUpdate: Date(), originCountry: "United States"
            )
        )
        AircraftAnnotationView(
            position: FlightPosition(
                id: "abc123", callsign: "UAL123",
                latitude: 37.7749, longitude: -122.4194,
                altitude: 10000, velocity: 250, trueTrack: 180,
                verticalRate: 0, onGround: false,
                lastUpdate: Date(), originCountry: "United States"
            ),
            isSelected: true
        )
    }
    .padding()
    .background(AppColors.background)
}
