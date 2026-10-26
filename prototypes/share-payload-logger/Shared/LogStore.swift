// PROTOTYPE — throwaway. Shared by the app and the share extension.
import Foundation

let appGroupID = "group.com.roehaus.prototype.payloadlogger"

struct ShareLog: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var source = "Unlabelled"
    var itemCount = 0
    var contentText: String?
    var attachments: [AttachmentLog] = []
}

struct AttachmentLog: Codable {
    var itemIndex: Int
    var attachmentIndex: Int
    var suggestedName: String?
    var registeredTypes: [String]
    var loads: [TypeLoad] = []
}

struct TypeLoad: Codable {
    var type: String
    var valueClass: String
    var summary: String
    var byteCount: Int?
    var error: String?
}

enum LogStore {
    static var directory: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
        let dir = base.appendingPathComponent("PROTOTYPE-wipe-me-logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func save(_ log: ShareLog) {
        let url = directory.appendingPathComponent("\(log.id.uuidString).json")
        try? encoder.encode(log).write(to: url)
    }

    static func all() -> [ShareLog] {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(ShareLog.self, from: Data(contentsOf: $0)) }
            .sorted { $0.date > $1.date }
    }

    static func wipe() {
        try? FileManager.default.removeItem(at: directory)
    }

    static func exportJSON() -> String {
        String(data: (try? encoder.encode(all())) ?? Data(), encoding: .utf8) ?? "[]"
    }
}
