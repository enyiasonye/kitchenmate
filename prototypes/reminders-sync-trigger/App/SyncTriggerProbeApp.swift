// PROTOTYPE — throwaway. Logs every sync trigger (Shortcut, background refresh, silent push,
// app open, Sync now) so a few days of real use show which ones actually fire.
import BackgroundTasks
import EventKit
import SwiftUI
import UserNotifications

let refreshID = "com.roehaus.prototype.SyncTriggerProbe.refresh"

func scheduleRefresh() {
    let r = BGAppRefreshTaskRequest(identifier: refreshID)
    r.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
    Task { try? await BGTaskScheduler.shared.submitTaskRequest(r) }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        app.registerForRemoteNotifications()
        return true
    }
    func application(_ app: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken token: Data) {
        Settings.pushToken = token.map { String(format: "%02x", $0) }.joined()
    }
    func application(_ app: UIApplication, didReceiveRemoteNotification info: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        _ = await Probe.run(.silentPush)
        return .newData
    }
}

@main
struct SyncTriggerProbeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup { Home() }
            .onChange(of: phase) { _, p in
                if p == .active { Task { _ = await Probe.run(.appOpen); NotificationCenter.default.post(name: .probeRan, object: nil) } }
                if p == .background { scheduleRefresh() }
            }
            .backgroundTask(.appRefresh(refreshID)) {
                scheduleRefresh()
                _ = await Probe.run(.bgRefresh)
            }
    }
}

extension Notification.Name { static let probeRan = Notification.Name("probeRan") }

struct Home: View {
    @State private var events: [ProbeEvent] = []
    @State private var auth = Probe.authLabel()
    @State private var lists: [EKCalendar] = []
    @State private var listID = Settings.listID ?? ""
    @State private var notify = Settings.notify
    @State private var dailyTime = Calendar.current.date(bySettingHour: Settings.dailyMinutes / 60, minute: Settings.dailyMinutes % 60, second: 0, of: .now)!
    @State private var dump = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Setup") {
                    LabeledContent("Reminders access", value: auth)
                    if auth != "full" {
                        Button("Grant Reminders access") {
                            Task {
                                _ = try? await EKEventStore().requestFullAccessToReminders()
                                _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                                reload()
                            }
                        }
                    }
                    Picker("Synced List", selection: $listID) {
                        Text("None").tag("")
                        ForEach(lists, id: \.calendarIdentifier) { Text($0.title).tag($0.calendarIdentifier) }
                    }
                    .onChange(of: listID) { _, id in
                        Settings.listID = id.isEmpty ? nil : id
                        Settings.listTitle = lists.first { $0.calendarIdentifier == id }?.title
                    }
                    DatePicker("Daily sync time", selection: $dailyTime, displayedComponents: .hourAndMinute)
                        .onChange(of: dailyTime) { _, t in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: t)
                            Settings.dailyMinutes = c.hour! * 60 + c.minute!
                        }
                    Toggle("Notify on background runs", isOn: $notify).onChange(of: notify) { _, v in Settings.notify = v }
                    if let token = Settings.pushToken {
                        Button("Copy push token") { UIPasteboard.general.string = token }
                    }
                }
                Section {
                    Button("Sync now") { Task { _ = await Probe.run(.syncNow); reload() } }
                    Button("Inspect Synced List") { Task { dump = await ListInspector.dump() } }
                    ShareLink("Export results", item: exportJSON())
                }
                Section("Days (expected Shortcut run at \(dailyTime.formatted(date: .omitted, time: .shortened)))") {
                    ForEach(days, id: \.self) { day in
                        NavigationLink { EventList(events: events.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }) } label: { DayRow(day: day, events: events) }
                    }
                }
                Section {
                    Button("Wipe log", role: .destructive) { EventLog.wipe(); reload() }
                }
            }
            .navigationTitle("Sync Probe")
            .refreshable { reload() }
            .sheet(isPresented: Binding(get: { !dump.isEmpty }, set: { if !$0 { dump = "" } })) {
                NavigationStack {
                    ScrollView { Text(dump).font(.system(.caption2, design: .monospaced)).textSelection(.enabled).padding() }
                        .toolbar { ShareLink(item: dump) }
                        .navigationTitle("Synced List dump")
                }
            }
        }
        .onAppear(perform: reload)
        .onReceive(NotificationCenter.default.publisher(for: .probeRan)) { _ in reload() }
    }

    var days: [Date] {
        guard let first = events.map(\.date).min() else { return [] }
        let cal = Calendar.current
        var d = cal.startOfDay(for: .now), out: [Date] = []
        while d >= cal.startOfDay(for: first) { out.append(d); d = cal.date(byAdding: .day, value: -1, to: d)! }
        return out
    }

    func reload() {
        events = EventLog.all()
        auth = Probe.authLabel()
        lists = auth == "full" ? EKEventStore().calendars(for: .reminder) : []
    }

    func exportJSON() -> String {
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601; enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        struct Export: Encodable {
            let exported: Date; let device: String; let os: String; let dailyMinutes: Int; let listTitle: String?; let events: [ProbeEvent]
        }
        let x = Export(exported: .now, device: UIDevice.current.model, os: UIDevice.current.systemVersion,
                       dailyMinutes: Settings.dailyMinutes, listTitle: Settings.listTitle, events: events)
        return String(decoding: (try? enc.encode(x)) ?? Data(), as: UTF8.self)
    }
}

struct DayRow: View {
    let day: Date
    let events: [ProbeEvent]
    var body: some View {
        let today = events.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
        let shortcut = today.filter { $0.trigger == .shortcut }
        VStack(alignment: .leading, spacing: 2) {
            Text(day.formatted(.dateTime.weekday().month().day())).font(.headline)
            Text(shortcut.isEmpty ? "Shortcut: missed" : "Shortcut: " + shortcut.map { $0.date.formatted(date: .omitted, time: .shortened) }.joined(separator: ", "))
                .foregroundStyle(shortcut.isEmpty ? .red : .primary)
            Text([Trigger.bgRefresh, .silentPush, .appOpen, .syncNow].map { t in "\(t.label) \(today.filter { $0.trigger == t }.count)" }.joined(separator: " · "))
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct EventList: View {
    let events: [ProbeEvent]
    var body: some View {
        List(events.reversed()) { e in
            VStack(alignment: .leading, spacing: 2) {
                Text("\(e.date.formatted(date: .omitted, time: .standard)) · \(e.trigger.label)").font(.headline)
                Text(e.summary).foregroundStyle(e.error == nil ? Color.primary : .red)
                Text("app \(e.appState) · unlocked-since-boot \(e.protectedDataAvailable ? "yes" : "no") · low power \(e.lowPowerMode ? "on" : "off") · \(e.durationMs) ms · build \(e.build)")
                    .font(.caption).foregroundStyle(.secondary)
                Text("booted \(e.bootTime.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Events")
    }
}
