// PROTOTYPE — throwaway. One "sync" = read the Synced List's incomplete reminders and log
// which trigger fired, when, and in what device state. Read-only: nothing is completed.
import EventKit
import UIKit
import UserNotifications

enum Trigger: String, Codable, CaseIterable {
    case shortcut, bgRefresh, silentPush, appOpen, syncNow
    var label: String {
        switch self {
        case .shortcut: "Shortcut"
        case .bgRefresh: "Background refresh"
        case .silentPush: "Silent push"
        case .appOpen: "App open"
        case .syncNow: "Sync now"
        }
    }
}

struct ProbeEvent: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var trigger: Trigger
    var appState: String
    var protectedDataAvailable: Bool
    var lowPowerMode: Bool
    var bootTime: Date
    var build: String
    var remindersAuth: String
    var listTitle: String?
    var reminderCount: Int?
    var titles: [String]?
    var error: String?
    var durationMs: Int
    var summary: String {
        if let error { return "\(trigger.label): \(error)" }
        return "\(trigger.label): \(reminderCount ?? 0) reminders in \(listTitle ?? "?")"
    }
}

enum Settings {
    static let d = UserDefaults.standard
    static var listID: String? { get { d.string(forKey: "listID") } set { d.set(newValue, forKey: "listID") } }
    static var listTitle: String? { get { d.string(forKey: "listTitle") } set { d.set(newValue, forKey: "listTitle") } }
    static var pushToken: String? { get { d.string(forKey: "pushToken") } set { d.set(newValue, forKey: "pushToken") } }
    static var notify: Bool { get { d.object(forKey: "notify") as? Bool ?? true } set { d.set(newValue, forKey: "notify") } }
    /// Minutes after midnight. Default 7 AM, as in the real design.
    static var dailyMinutes: Int { get { d.object(forKey: "dailyMinutes") as? Int ?? 7 * 60 } set { d.set(newValue, forKey: "dailyMinutes") } }
}

/// Events live in a JSON file with no data protection, so runs before the first unlock
/// after a reboot still get recorded (UserDefaults and default files are locked then).
enum EventLog {
    static let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("PROTOTYPE-wipe-me-events.json")
    static let lock = NSLock()

    static func all() -> [ProbeEvent] {
        lock.lock(); defer { lock.unlock() }
        return read()
    }
    static func append(_ e: ProbeEvent) {
        lock.lock(); defer { lock.unlock() }
        var events = read()
        events.append(e)
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        try? enc.encode(events).write(to: url, options: [.atomic, .noFileProtection])
    }
    static func wipe() { try? FileManager.default.removeItem(at: url) }
    private static func read() -> [ProbeEvent] {
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? dec.decode([ProbeEvent].self, from: data)) ?? []
    }
}

enum Probe {
    static func run(_ trigger: Trigger) async -> ProbeEvent {
        let start = Date()
        let (state, protected) = await MainActor.run { () -> (String, Bool) in
            let s: String = switch UIApplication.shared.applicationState {
            case .active: "active"
            case .inactive: "inactive"
            case .background: "background"
            @unknown default: "unknown"
            }
            return (s, UIApplication.shared.isProtectedDataAvailable)
        }
        var e = ProbeEvent(
            date: start, trigger: trigger, appState: state, protectedDataAvailable: protected,
            lowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled, bootTime: bootTime(),
            build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?",
            remindersAuth: authLabel(), durationMs: 0)
        do {
            let (title, titles) = try await readList()
            e.listTitle = title; e.titles = titles; e.reminderCount = titles.count
        } catch {
            e.error = "\(error)"
        }
        e.durationMs = Int(Date().timeIntervalSince(start) * 1000)
        EventLog.append(e)
        if Settings.notify, [.shortcut, .bgRefresh, .silentPush].contains(trigger) { await notify(e) }
        return e
    }

    struct ProbeError: Error, CustomStringConvertible { let description: String }

    static func syncedList(_ store: EKEventStore) throws -> EKCalendar {
        guard Settings.listID != nil || Settings.listTitle != nil else { throw ProbeError(description: "No Synced List picked") }
        if let id = Settings.listID, let cal = store.calendar(withIdentifier: id) { return cal }
        if let cal = store.calendars(for: .reminder).first(where: { $0.title == Settings.listTitle }) { return cal }
        throw ProbeError(description: "Synced List not found")
    }

    static func readList() async throws -> (String, [String]) {
        guard EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else {
            throw ProbeError(description: "No Reminders access (\(authLabel()))")
        }
        let store = EKEventStore()
        let cal = try syncedList(store)
        let pred = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [cal])
        let titles = await withCheckedContinuation { c in
            store.fetchReminders(matching: pred) { rs in c.resume(returning: (rs ?? []).map { $0.title ?? "" }) }
        }
        return (cal.title, titles)
    }

    static func authLabel() -> String {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .fullAccess: "full"
        case .writeOnly: "writeOnly"
        case .denied: "denied"
        case .restricted: "restricted"
        case .notDetermined: "notDetermined"
        @unknown default: "unknown"
        }
    }

    static func bootTime() -> Date {
        var tv = timeval(); var size = MemoryLayout<timeval>.size
        sysctlbyname("kern.boottime", &tv, &size, nil, 0)
        return Date(timeIntervalSince1970: TimeInterval(tv.tv_sec))
    }

    static func notify(_ e: ProbeEvent) async {
        let c = UNMutableNotificationContent()
        c.title = "Sync probe · \(e.trigger.label)"
        c.body = e.summary
        try? await UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: e.id.uuidString, content: c, trigger: nil))
    }
}

/// Everything EventKit exposes about the Synced List, to see how a Groceries list
/// (sections, auto-categories) looks from the API.
enum ListInspector {
    static func dump() async -> String {
        let store = EKEventStore()
        guard let cal = try? Probe.syncedList(store) else { return "No Synced List" }
        let all = await withCheckedContinuation { c in
            store.fetchReminders(matching: store.predicateForReminders(in: [cal])) { rs in
                c.resume(returning: (rs ?? []).map(describe))
            }
        }
        let header: [String: Any] = [
            "title": cal.title, "calendarIdentifier": cal.calendarIdentifier,
            "type": cal.type.rawValue, "source": "\(cal.source.title) (type \(cal.source.sourceType.rawValue))",
            "allowsContentModifications": cal.allowsContentModifications, "isSubscribed": cal.isSubscribed,
            "allowedEntityTypes": cal.allowedEntityTypes.rawValue, "reminderCount": all.count,
            "otherLists": store.calendars(for: .reminder).map(\.title),
        ]
        let obj: [String: Any] = ["list": header, "reminders": all]
        let data = (try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    static func describe(_ r: EKReminder) -> [String: Any] {
        var d: [String: Any] = [
            "title": r.title ?? "", "isCompleted": r.isCompleted, "priority": r.priority,
            "hasNotes": r.hasNotes, "hasAlarms": r.hasAlarms, "hasRecurrenceRules": r.hasRecurrenceRules,
            "calendarItemExternalIdentifier": r.calendarItemExternalIdentifier ?? "",
            "calendarItemIdentifier": r.calendarItemIdentifier,
            // Raw object description — may leak section/category info the public API hides.
            "debugDescription": String(String(describing: r).prefix(600)),
        ]
        if let n = r.notes { d["notes"] = n }
        if let u = r.url { d["url"] = u.absoluteString }
        if let c = r.creationDate { d["created"] = c.ISO8601Format() }
        if let m = r.lastModifiedDate { d["modified"] = m.ISO8601Format() }
        if let due = r.dueDateComponents { d["due"] = "\(due)" }
        return d
    }
}
