import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LiveView()
                .tabItem { Label("Live", systemImage: "waveform") }
            SessionsView()
                .tabItem { Label("Sessions", systemImage: "clock") }
            FeedbackView()
                .tabItem { Label("Feedback", systemImage: "bubble.left") }
        }
        .tint(Color(red: 0.13, green: 0.65, blue: 0.42))
    }
}
