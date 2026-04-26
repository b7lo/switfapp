import SwiftUI

struct SessionsView: View {
    @EnvironmentObject var sensor: SensorManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    if !sensor.sessions.isEmpty {
                        SummaryStrip(sessions: sensor.sessions)
                    }

                    if sensor.sessions.isEmpty {
                        EmptyState(systemImage: "tray",
                                   title: "No sessions yet",
                                   subtitle: "Start a recording from the Live tab to see it here.")
                    } else {
                        ForEach(sensor.sessions) { s in
                            NavigationLink(value: s.id) {
                                SessionCard(session: s)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Sessions")
            .navigationDestination(for: String.self) { id in
                if let s = sensor.sessions.first(where: { $0.id == id }) {
                    SessionDetailView(session: s)
                }
            }
        }
    }
}

struct SummaryStrip: View {
    let sessions: [Session]

    private var avgOverall: Int {
        let v = sessions.map(\.stats.overall).reduce(0, +)
        return sessions.isEmpty ? 0 : v / sessions.count
    }
    private var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }
    private var totalDistance: Double {
        sessions.reduce(0) { $0 + ($1.stats.distanceMeters ?? 0) }
    }

    var body: some View {
        HStack(spacing: 12) {
            StatBlock(label: "AVG SCORE", value: "\(avgOverall)",
                      tint: scoreColor(avgOverall))
            StatBlock(label: "TOTAL TIME", value: Fmt.duration(totalDuration),
                      tint: .accentColor)
            StatBlock(label: "DISTANCE", value: Fmt.meters(totalDistance),
                      tint: .blue)
        }
    }
}

struct StatBlock: View {
    let label: String
    let value: String
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            Text(value).font(.title3.bold()).monospacedDigit().foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SessionCard: View {
    let session: Session

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .stroke(scoreColor(session.stats.overall).opacity(0.2), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: CGFloat(session.stats.overall) / 100)
                    .stroke(scoreColor(session.stats.overall),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(session.stats.overall)").font(.callout.bold())
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(Fmt.date(session.createdAt))
                    .font(.callout.weight(.semibold))
                HStack(spacing: 6) {
                    Pill(icon: session.stats.dominant.systemImage,
                         text: session.stats.dominant.label,
                         tone: .primary)
                    Pill(icon: "clock",
                         text: Fmt.duration(session.duration),
                         tone: .neutral)
                    if let dist = session.stats.distanceMeters {
                        Pill(icon: "location",
                             text: Fmt.meters(dist),
                             tone: .neutral)
                    }
                    if session.photoFilename != nil {
                        Pill(icon: "camera.fill",
                             text: "Photo",
                             tone: .success)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
