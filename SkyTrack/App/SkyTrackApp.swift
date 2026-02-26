import SwiftUI

@main
struct SkyTrackApp: App {
    @State private var container = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(container)
                .preferredColorScheme(.dark)
        }
    }
}
