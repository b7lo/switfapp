import Foundation
import Combine
import CoreMotion
import CoreLocation
import UIKit

final class SensorManager: NSObject, ObservableObject {

    // MARK: - Published live state

    @Published var acc: Vector3 = .zero
    @Published var gyro: Vector3 = .zero
    @Published var accMag: Double = 1
    @Published var gyroMag: Double = 0
    @Published var activity: ActivityClass = .unknown
    @Published var liveStability: Int = 100
    @Published var liveSeries: [Double] = []

    @Published var isRecording = false
    @Published var recordSeconds: Int = 0
    @Published var trackLocation = false

    @Published var sessions: [Session] = []
    @Published var feedback: [Feedback] = []

    @Published var motionAvailable = false
    @Published var locationGranted: Bool? = nil

    // MARK: - Private

    private let motion = CMMotionManager()
    private let locationManager = CLLocationManager()

    private let sampleInterval: TimeInterval = 0.1
    private let liveBufferSize = 60

    private var samples: [SensorSample] = []
    private var locationsBuffer: [LocationPoint] = []
    private var startedAt: Date?
    private var ticker: Timer?
    private var secondTimer: Timer?
    private var liveAccBuffer: [Double] = []

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        sessions = Storage.shared.loadSessions()
        feedback = Storage.shared.loadFeedback()
        bootstrap()
    }

    private func bootstrap() {
        motionAvailable = motion.isAccelerometerAvailable && motion.isGyroAvailable
        guard motionAvailable else { return }

        motion.accelerometerUpdateInterval = sampleInterval
        motion.gyroUpdateInterval = sampleInterval

        motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let d = data else { return }
            self.acc = Vector3(x: d.acceleration.x, y: d.acceleration.y, z: d.acceleration.z)
        }
        motion.startGyroUpdates(to: .main) { [weak self] data, _ in
            guard let self, let d = data else { return }
            self.gyro = Vector3(x: d.rotationRate.x, y: d.rotationRate.y, z: d.rotationRate.z)
        }

        startTicker()
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        let a = acc
        let g = gyro
        let aMag = Scoring.magnitude(a)
        let gMag = Scoring.magnitude(g)

        accMag = aMag
        gyroMag = gMag
        activity = Scoring.classify(accMag: aMag, gyroMag: gMag)

        liveAccBuffer.append(aMag)
        if liveAccBuffer.count > liveBufferSize { liveAccBuffer.removeFirst() }
        let mean = liveAccBuffer.reduce(0, +) / Double(liveAccBuffer.count)
        let varSum = liveAccBuffer.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
        let sd = sqrt(varSum / Double(liveAccBuffer.count))
        liveStability = max(0, min(100, Int(((1 - sd / 0.6) * 100).rounded())))

        liveSeries.append(aMag)
        if liveSeries.count > liveBufferSize { liveSeries.removeFirst() }

        if isRecording {
            samples.append(SensorSample(t: Date().timeIntervalSince1970, acc: a, gyro: g, mag: aMag))
        }
    }

    // MARK: - Recording

    func startRecording() {
        guard !isRecording, motionAvailable else { return }
        samples.removeAll()
        locationsBuffer.removeAll()
        startedAt = Date()
        isRecording = true
        recordSeconds = 0

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        secondTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.startedAt else { return }
            self.recordSeconds = Int(Date().timeIntervalSince(start))
        }

        if trackLocation {
            requestAndStartLocation()
        }
    }

    @discardableResult
    func stopRecording(label: String? = nil) -> Session? {
        guard isRecording else { return nil }
        isRecording = false
        secondTimer?.invalidate()
        secondTimer = nil
        locationManager.stopUpdatingLocation()

        let started = startedAt ?? Date()
        startedAt = nil

        guard samples.count >= 5 else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return nil
        }

        let stats = Scoring.compute(samples: samples, locations: locationsBuffer)
        let session = Session(
            id: UUID().uuidString,
            createdAt: started,
            endedAt: Date(),
            label: label,
            stats: stats,
            samples: samples,
            locations: locationsBuffer.isEmpty ? nil : locationsBuffer
        )
        sessions = Storage.shared.appendSession(session)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        return session
    }

    func deleteSession(id: String) {
        sessions = Storage.shared.deleteSession(id: id)
    }

    func attachPhoto(_ image: UIImage, to sessionId: String) {
        guard var session = sessions.first(where: { $0.id == sessionId }) else { return }
        if let filename = Storage.shared.savePhoto(image, sessionId: sessionId) {
            session.photoFilename = filename
            sessions = Storage.shared.updateSession(session)
        }
    }

    // MARK: - Feedback

    func submitFeedback(sessionId: String,
                        rating: Int,
                        matchedActivity: Bool,
                        perceivedActivity: ActivityClass,
                        note: String?) {
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fb = Feedback(
            id: UUID().uuidString,
            createdAt: Date(),
            sessionId: sessionId,
            rating: max(1, min(5, rating)),
            matchedActivity: matchedActivity,
            perceivedActivity: perceivedActivity,
            note: (trimmed?.isEmpty ?? true) ? nil : trimmed
        )
        feedback = Storage.shared.appendFeedback(fb)
    }

    // MARK: - Location

    private func requestAndStartLocation() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationGranted = true
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 1
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            locationGranted = false
        @unknown default:
            locationGranted = false
        }
    }
}

extension SensorManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationGranted = true
            if isRecording && trackLocation {
                manager.desiredAccuracy = kCLLocationAccuracyBest
                manager.distanceFilter = 1
                manager.startUpdatingLocation()
            }
        case .denied, .restricted:
            locationGranted = false
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard isRecording else { return }
        let mapped = locs.map {
            LocationPoint(
                t: $0.timestamp.timeIntervalSince1970,
                lat: $0.coordinate.latitude,
                lon: $0.coordinate.longitude,
                speed: $0.speed >= 0 ? $0.speed : nil
            )
        }
        locationsBuffer.append(contentsOf: mapped)
    }
}
