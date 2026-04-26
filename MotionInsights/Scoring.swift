import Foundation

enum Scoring {

    static func magnitude(_ v: Vector3) -> Double {
        sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    }

    static func classify(accMag: Double, gyroMag: Double) -> ActivityClass {
        let lin = abs(accMag - 1.0)
        if lin < 0.05 && gyroMag < 0.1 { return .stationary }
        if lin < 0.4  && gyroMag < 1.5 { return .walking }
        if lin >= 0.4 && lin < 1.0     { return .running }
        if lin >= 1.0 || gyroMag >= 2.5 { return .vehicle }
        return .unknown
    }

    private static func clamp(_ v: Double) -> Int {
        Int(max(0, min(100, (v * 100).rounded())))
    }

    static func compute(samples: [SensorSample], locations: [LocationPoint]) -> SessionStats {
        guard samples.count > 1 else {
            return SessionStats(stability: 0, smoothness: 0, activity: 0, overall: 0,
                                dominant: .unknown, distribution: [:],
                                distanceMeters: nil, avgSpeedMps: nil,
                                meanAccMag: 0, meanGyroMag: 0, stdAccMag: 0)
        }

        let mags = samples.map { $0.mag }
        let mean = mags.reduce(0, +) / Double(mags.count)
        let varSum = mags.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
        let std = sqrt(varSum / Double(mags.count))

        var jerks: [Double] = []
        for i in 1..<samples.count {
            let dt = max(0.01, samples[i].t - samples[i - 1].t)
            let dx = samples[i].acc.x - samples[i - 1].acc.x
            let dy = samples[i].acc.y - samples[i - 1].acc.y
            let dz = samples[i].acc.z - samples[i - 1].acc.z
            jerks.append(sqrt(dx * dx + dy * dy + dz * dz) / dt)
        }
        let meanJerk = jerks.isEmpty ? 0 : jerks.reduce(0, +) / Double(jerks.count)

        let gyroMags = samples.map { magnitude($0.gyro) }
        let meanGyro = gyroMags.reduce(0, +) / Double(gyroMags.count)
        let linG = abs(mean - 1.0)

        let stability  = clamp(1 - std / 0.6)
        let smoothness = clamp(1 - meanJerk / 0.25)
        let activity   = clamp(linG / 0.8)
        let inactivity = Double(100 - activity) / 100.0
        let overall = clamp(
            0.45 * Double(stability)  / 100 +
            0.40 * Double(smoothness) / 100 +
            0.15 * inactivity
        )

        var counts: [ActivityClass: Int] = [:]
        for s in samples {
            let c = classify(accMag: s.mag, gyroMag: magnitude(s.gyro))
            counts[c, default: 0] += 1
        }
        let total = Double(samples.count)
        var distribution: [String: Double] = [:]
        for (k, v) in counts {
            distribution[k.rawValue] = Double(v) / total
        }
        let dominant = counts.max(by: { $0.value < $1.value })?.key ?? .unknown

        var distance: Double? = nil
        var avgSpeed: Double? = nil
        if locations.count >= 2 {
            var d = 0.0
            for i in 1..<locations.count {
                d += haversine(lat1: locations[i - 1].lat, lon1: locations[i - 1].lon,
                               lat2: locations[i].lat,     lon2: locations[i].lon)
            }
            distance = d
            let speeds = locations.compactMap { $0.speed }.filter { $0 >= 0 }
            if !speeds.isEmpty {
                avgSpeed = speeds.reduce(0, +) / Double(speeds.count)
            }
        }

        return SessionStats(
            stability: stability, smoothness: smoothness,
            activity: activity, overall: overall,
            dominant: dominant, distribution: distribution,
            distanceMeters: distance, avgSpeedMps: avgSpeed,
            meanAccMag: mean, meanGyroMag: meanGyro, stdAccMag: std
        )
    }

    static func haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        return R * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
