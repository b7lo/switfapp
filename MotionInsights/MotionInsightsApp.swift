import SwiftUI

@main
struct MotionInsightsApp: App {
    @StateObject private var sensor = SensorManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sensor)
        }
    }
}
