import SwiftUI

// MARK: - Score color helper

func scoreColor(_ score: Int) -> Color {
    if score >= 75 { return Color(red: 0.13, green: 0.65, blue: 0.42) }
    if score >= 50 { return Color(red: 0.16, green: 0.50, blue: 0.92) }
    if score >= 30 { return Color(red: 0.95, green: 0.62, blue: 0.18) }
    return Color(red: 0.86, green: 0.30, blue: 0.30)
}

// MARK: - Pill

enum PillTone { case neutral, primary, success, warning, danger }

struct Pill: View {
    let icon: String
    let text: String
    var tone: PillTone = .neutral

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption.weight(.semibold))
            Text(text).font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(bg)
        .foregroundStyle(fg)
        .clipShape(Capsule())
    }

    private var bg: Color {
        switch tone {
        case .neutral: return Color.gray.opacity(0.15)
        case .primary: return Color.accentColor.opacity(0.15)
        case .success: return Color.green.opacity(0.15)
        case .warning: return Color.orange.opacity(0.15)
        case .danger:  return Color.red.opacity(0.15)
        }
    }
    private var fg: Color {
        switch tone {
        case .neutral: return .secondary
        case .primary: return Color.accentColor
        case .success: return .green
        case .warning: return .orange
        case .danger:  return .red
        }
    }
}

// MARK: - Score ring

struct ScoreRing: View {
    let score: Int
    let label: String
    let caption: String
    var size: CGFloat = 140

    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.15), lineWidth: 12)
            Circle()
                .trim(from: 0, to: CGFloat(min(100, max(0, score))) / 100)
                .stroke(scoreColor(score),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.25), value: score)
            VStack(spacing: 2) {
                Text("\(score)").font(.system(size: 36, weight: .bold))
                Text(label).font(.caption.weight(.semibold)).foregroundStyle(scoreColor(score))
                Text(caption).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Sparkline

struct Sparkline: View {
    let values: [Double]
    var lineColor: Color = .accentColor

    var body: some View {
        GeometryReader { geo in
            if values.count >= 2 {
                let lo = values.min() ?? 0
                let hi = values.max() ?? 1
                let range = max(0.001, hi - lo)
                let stepX = geo.size.width / CGFloat(values.count - 1)
                Path { p in
                    for (i, v) in values.enumerated() {
                        let x = CGFloat(i) * stepX
                        let y = geo.size.height * (1 - CGFloat((v - lo) / range))
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                        else      { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(lineColor,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                Path { p in
                    for (i, v) in values.enumerated() {
                        let x = CGFloat(i) * stepX
                        let y = geo.size.height * (1 - CGFloat((v - lo) / range))
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                        else      { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    p.addLine(to: CGPoint(x: 0, y: geo.size.height))
                    p.closeSubpath()
                }
                .fill(lineColor.opacity(0.12))
            } else {
                Rectangle().fill(Color.clear)
            }
        }
    }
}

// MARK: - Metric tile

struct MetricTile: View {
    let label: String
    let value: Double
    let unit: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.12))
                Image(systemName: systemImage)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 30, height: 30)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formattedValue)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var formattedValue: String {
        String(format: "%.2f", value)
    }
}

// MARK: - Primary button

enum ButtonTone { case primary, danger, neutral }

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var tone: ButtonTone = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(bg)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var bg: Color {
        switch tone {
        case .primary: return Color.accentColor
        case .danger:  return Color.red
        case .neutral: return Color.gray
        }
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.headline)
            if let s = subtitle {
                Text(s).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Hero card

struct HeroCard: View {
    let score: Int
    let activity: ActivityClass
    let accMag: Double
    let gyroMag: Double
    let recordSeconds: Int?

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ScoreRing(score: score,
                      label: "STABILITY",
                      caption: recordSeconds.map(formatClock) ?? "Live signal")
            VStack(alignment: .leading, spacing: 8) {
                Pill(icon: activity.systemImage, text: activity.label, tone: .primary)
                Text("Acceleration magnitude")
                    .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.2f", accMag))
                        .font(.title.bold()).monospacedDigit()
                    Text("g").font(.caption).foregroundStyle(.secondary)
                }
                Text("Rotation rate")
                    .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.2f", gyroMag))
                        .font(.title.bold()).monospacedDigit()
                    Text("rad/s").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func formatClock(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}

// MARK: - Signal card

struct SignalCard: View {
    let series: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Signal").font(.headline)
                    Text("Last 6 seconds, 10 Hz sample rate")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Pill(icon: "waveform.path", text: intensityLabel, tone: .warning)
            }
            Sparkline(values: series).frame(height: 90)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var intensityLabel: String {
        guard let last = series.last else { return "—" }
        let intensity = Int(min(100, max(0, abs(last - 1) * 100)))
        return "\(intensity)% INTENSITY"
    }
}

// MARK: - Warning card

struct WarningCard: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(text).font(.callout)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Location toggle card

struct LocationToggleCard: View {
    @Binding var trackLocation: Bool
    let granted: Bool?

    var body: some View {
        HStack {
            Image(systemName: "location.fill")
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text("Track location").font(.callout.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $trackLocation).labelsHidden()
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var subtitle: String {
        switch granted {
        case .some(true):  return "Permission granted — distance & speed will be recorded"
        case .some(false): return "Permission denied — enable in Settings"
        case .none:        return "Will request permission when recording starts"
        }
    }
}

// MARK: - Empty state

struct EmptyState: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(subtitle).font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Format helpers

enum Fmt {
    static func clock(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
    static func duration(_ t: TimeInterval) -> String {
        let s = Int(t)
        return clock(s)
    }
    static func date(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }
    static func relative(_ d: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: d, relativeTo: Date())
    }
    static func meters(_ m: Double) -> String {
        if m < 1000 { return "\(Int(m.rounded())) m" }
        return String(format: "%.2f km", m / 1000)
    }
    static func mps(_ s: Double) -> String {
        String(format: "%.1f m/s", s)
    }
}
