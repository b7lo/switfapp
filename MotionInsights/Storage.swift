import Foundation
import UIKit

final class Storage {
    static let shared = Storage()

    private let sessionsKey = "motion.sessions.v1"
    private let feedbackKey = "motion.feedback.v1"
    private let maxSessions = 50
    private let maxFeedback = 200

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Sessions

    func loadSessions() -> [Session] {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let arr = try? decoder.decode([Session].self, from: data) else { return [] }
        return arr.sorted(by: { $0.createdAt > $1.createdAt })
    }

    private func saveSessions(_ sessions: [Session]) {
        let trimmed = Array(sessions.sorted(by: { $0.createdAt > $1.createdAt }).prefix(maxSessions))
        if let data = try? encoder.encode(trimmed) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }

    @discardableResult
    func appendSession(_ s: Session) -> [Session] {
        var arr = loadSessions()
        arr.insert(s, at: 0)
        saveSessions(arr)
        return arr
    }

    @discardableResult
    func updateSession(_ updated: Session) -> [Session] {
        var arr = loadSessions()
        if let idx = arr.firstIndex(where: { $0.id == updated.id }) {
            arr[idx] = updated
        }
        saveSessions(arr)
        return arr
    }

    @discardableResult
    func deleteSession(id: String) -> [Session] {
        var arr = loadSessions()
        if let session = arr.first(where: { $0.id == id }),
           let photo = session.photoFilename {
            deletePhoto(filename: photo)
        }
        arr.removeAll { $0.id == id }
        saveSessions(arr)
        return arr
    }

    // MARK: - Feedback

    func loadFeedback() -> [Feedback] {
        guard let data = UserDefaults.standard.data(forKey: feedbackKey),
              let arr = try? decoder.decode([Feedback].self, from: data) else { return [] }
        return arr.sorted(by: { $0.createdAt > $1.createdAt })
    }

    @discardableResult
    func appendFeedback(_ f: Feedback) -> [Feedback] {
        var arr = loadFeedback()
        arr.insert(f, at: 0)
        let trimmed = Array(arr.prefix(maxFeedback))
        if let data = try? encoder.encode(trimmed) {
            UserDefaults.standard.set(data, forKey: feedbackKey)
        }
        return trimmed
    }

    // MARK: - Photo storage

    private var photosDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("session-photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Saves an image as compressed JPEG and returns the filename.
    func savePhoto(_ image: UIImage, sessionId: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = "\(sessionId).jpg"
        let url = photosDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            print("⚠️ Failed to save photo: \(error)")
            return nil
        }
    }

    /// Loads a photo by filename from the session-photos directory.
    func loadPhoto(filename: String) -> UIImage? {
        let url = photosDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Deletes a photo file.
    func deletePhoto(filename: String) {
        let url = photosDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}

