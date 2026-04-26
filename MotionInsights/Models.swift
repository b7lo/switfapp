import Foundation

struct Vector3: Codable, Hashable {
    var x: Double
    var y: Double
    var z: Double
    static let zero = Vector3(x: 0, y: 0, z: 0)
}

enum ActivityClass: String, Codable, CaseIterable, Identifiable {
    case stationary, walking, running, vehicle, unknown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .stationary: return "Stationary"
        case .walking:    return "Walking"
        case .running:    return "Running"
        case .vehicle:    return "In vehicle"
        case .unknown:    return "Unknown"
        }
    }

    var systemImage: String {
        switch self {
        case .stationary: return "pause.circle.fill"
        case .walking:    return "figure.walk"
        case .running:    return "figure.run"
        case .vehicle:    return "car.fill"
        case .unknown:    return "questionmark.circle"
        }
    }
}

struct SensorSample: Codable, Hashable {
    var t: TimeInterval
    var acc: Vector3
    var gyro: Vector3
    var mag: Double
}

struct LocationPoint: Codable, Hashable {
    var t: TimeInterval
    var lat: Double
    var lon: Double
    var speed: Double?
}

struct SessionStats: Codable, Hashable {
    var stability: Int
    var smoothness: Int
    var activity: Int
    var overall: Int
    var dominant: ActivityClass
    var distribution: [String: Double]
    var distanceMeters: Double?
    var avgSpeedMps: Double?
    var meanAccMag: Double
    var meanGyroMag: Double
    var stdAccMag: Double
}

struct Session: Codable, Identifiable, Hashable {
    var id: String
    var createdAt: Date
    var endedAt: Date
    var label: String?
    var photoFilename: String?
    var stats: SessionStats
    var samples: [SensorSample]
    var locations: [LocationPoint]?

    var duration: TimeInterval { endedAt.timeIntervalSince(createdAt) }
}

struct Feedback: Codable, Identifiable, Hashable {
    var id: String
    var createdAt: Date
    var sessionId: String
    var rating: Int
    var matchedActivity: Bool
    var perceivedActivity: ActivityClass
    var note: String?
}
