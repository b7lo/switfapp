import SwiftUI

struct SessionDetailView: View {
    let session: Session
    @EnvironmentObject var sensor: SensorManager
    @Environment(\.dismiss) private var dismiss
    @State private var showDelete = false
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var showPhotoReview = false

    private var sparkValues: [Double] {
        let stride = max(1, session.samples.count / 120)
        return session.samples.enumerated()
            .filter { $0.offset % stride == 0 }
            .map { $0.element.mag }
    }

    /// Re-fetch from sensor.sessions to see latest photoFilename
    private var liveSession: Session {
        sensor.sessions.first(where: { $0.id == session.id }) ?? session
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                HStack {
                    ScoreRing(score: session.stats.overall,
                              label: "OVERALL",
                              caption: "Composite score",
                              size: 130)
                    VStack(alignment: .leading, spacing: 6) {
                        Pill(icon: session.stats.dominant.systemImage,
                             text: session.stats.dominant.label,
                             tone: .primary)
                        Label(Fmt.date(session.createdAt), systemImage: "calendar")
                            .font(.caption).foregroundStyle(.secondary)
                        Label(Fmt.duration(session.duration), systemImage: "clock")
                            .font(.caption).foregroundStyle(.secondary)
                        if let d = session.stats.distanceMeters {
                            Label(Fmt.meters(d), systemImage: "location")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if let s = session.stats.avgSpeedMps {
                            Label("avg \(Fmt.mps(s))", systemImage: "speedometer")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                // Session photo
                if let filename = liveSession.photoFilename,
                   let image = Storage.shared.loadPhoto(filename: filename) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Session photo")
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    Button {
                        showCamera = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(Color.accentColor)
                            Text("Attach a photo")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "plus.circle")
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(14)
                        .background(Color.accentColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Sub-scores")
                    HStack(spacing: 12) {
                        SubScoreTile(label: "STABILITY",  value: session.stats.stability)
                        SubScoreTile(label: "SMOOTHNESS", value: session.stats.smoothness)
                        SubScoreTile(label: "ACTIVITY",   value: session.stats.activity)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Acceleration magnitude",
                                  subtitle: "Full session timeline")
                    Sparkline(values: sparkValues)
                        .frame(height: 120)
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Activity mix")
                    ActivityMixView(distribution: session.stats.distribution)
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Sensor averages")
                    HStack(spacing: 12) {
                        MetricTile(label: "MEAN |a|",
                                   value: session.stats.meanAccMag, unit: "g",
                                   systemImage: "waveform.path.ecg")
                        MetricTile(label: "MEAN |ω|",
                                   value: session.stats.meanGyroMag, unit: "rad/s",
                                   systemImage: "rotate.3d")
                        MetricTile(label: "STD |a|",
                                   value: session.stats.stdAccMag, unit: "g",
                                   systemImage: "chart.bar.fill")
                    }
                }

                Button(role: .destructive) {
                    showDelete = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete session").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.red)
                }
                .alert("Delete this session?", isPresented: $showDelete) {
                    Button("Delete", role: .destructive) {
                        sensor.deleteSession(id: session.id)
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This cannot be undone.")
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(capturedImage: $capturedImage)
                .ignoresSafeArea()
        }
        .onChange(of: capturedImage) { newImage in
            if newImage != nil {
                showPhotoReview = true
            }
        }
        .sheet(isPresented: $showPhotoReview) {
            if let image = capturedImage {
                PhotoReviewSheet(image: image) {
                    sensor.attachPhoto(image, to: session.id)
                    capturedImage = nil
                } onRetake: {
                    capturedImage = nil
                    showPhotoReview = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showCamera = true
                    }
                }
            }
        }
    }
}

struct SubScoreTile: View {
    let label: String
    let value: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title.bold())
                .foregroundStyle(scoreColor(value))
                .monospacedDigit()
            ProgressView(value: Double(value) / 100)
                .tint(scoreColor(value))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ActivityMixView: View {
    let distribution: [String: Double]

    private var rows: [(ActivityClass, Double)] {
        ActivityClass.allCases
            .map { ($0, distribution[$0.rawValue] ?? 0) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        VStack(spacing: 10) {
            if rows.isEmpty {
                Text("No data").font(.callout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(rows, id: \.0) { row in
                    HStack {
                        Image(systemName: row.0.systemImage)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 22)
                        Text(row.0.label).font(.callout.weight(.semibold))
                        Spacer()
                        Text("\(Int((row.1 * 100).rounded()))%")
                            .font(.callout.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.accentColor)
                                .frame(width: geo.size.width * CGFloat(row.1))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
