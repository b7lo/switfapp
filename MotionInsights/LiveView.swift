import SwiftUI

struct LiveView: View {
    @EnvironmentObject var sensor: SensorManager
    @State private var savedSessionId: String?
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var showPhotoReview = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("REAL-TIME ANALYSIS")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .tracking(0.6)
                            Text("Motion Insights")
                                .font(.largeTitle.bold())
                        }
                        Spacer()
                        Pill(
                            icon: sensor.isRecording ? "record.circle" : "circle",
                            text: sensor.isRecording ? "Recording" : "Idle",
                            tone: sensor.isRecording ? .danger : .neutral
                        )
                    }

                    if !sensor.motionAvailable {
                        WarningCard(text: "Motion sensors are unavailable on this device.")
                    }

                    HeroCard(
                        score: sensor.liveStability,
                        activity: sensor.activity,
                        accMag: sensor.accMag,
                        gyroMag: sensor.gyroMag,
                        recordSeconds: sensor.isRecording ? sensor.recordSeconds : nil
                    )

                    SignalCard(series: sensor.liveSeries)

                    HStack(spacing: 12) {
                        MetricTile(label: "ACCEL X", value: sensor.acc.x, unit: "g",     systemImage: "arrow.up.right")
                        MetricTile(label: "ACCEL Y", value: sensor.acc.y, unit: "g",     systemImage: "arrow.up")
                        MetricTile(label: "ACCEL Z", value: sensor.acc.z, unit: "g",     systemImage: "arrow.up.left")
                    }
                    HStack(spacing: 12) {
                        MetricTile(label: "GYRO X",  value: sensor.gyro.x, unit: "rad/s", systemImage: "arrow.clockwise")
                        MetricTile(label: "GYRO Y",  value: sensor.gyro.y, unit: "rad/s", systemImage: "arrow.triangle.2.circlepath")
                        MetricTile(label: "GYRO Z",  value: sensor.gyro.z, unit: "rad/s", systemImage: "arrow.counterclockwise")
                    }

                    LocationToggleCard(trackLocation: $sensor.trackLocation,
                                       granted: sensor.locationGranted)

                    PrimaryButton(
                        title: sensor.isRecording ? "Stop recording" : "Start recording",
                        systemImage: sensor.isRecording ? "stop.fill" : "play.fill",
                        tone: sensor.isRecording ? .danger : .primary
                    ) {
                        if sensor.isRecording {
                            if let s = sensor.stopRecording() {
                                savedSessionId = s.id
                            }
                        } else {
                            sensor.startRecording()
                        }
                    }

                    if let id = savedSessionId {
                        VStack(spacing: 10) {
                            NavigationLink(value: id) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Session saved — view details")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(14)
                                .background(Color.green.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.primary)
                            }

                            // Attach photo button
                            let hasPhoto = sensor.sessions.first(where: { $0.id == id })?.photoFilename != nil
                            Button {
                                showCamera = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: hasPhoto ? "checkmark.circle.fill" : "camera.fill")
                                        .foregroundStyle(hasPhoto ? .green : Color.accentColor)
                                    Text(hasPhoto ? "Photo attached" : "Attach photo")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    if !hasPhoto {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .padding(14)
                                .background(Color.accentColor.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.primary)
                            }
                            .buttonStyle(.plain)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(16)
            }
            .navigationDestination(for: String.self) { id in
                if let s = sensor.sessions.first(where: { $0.id == id }) {
                    SessionDetailView(session: s)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarHidden(true)
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
                        // Confirm
                        if let id = savedSessionId {
                            sensor.attachPhoto(image, to: id)
                        }
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
        .animation(.easeInOut(duration: 0.3), value: savedSessionId)
    }
}
