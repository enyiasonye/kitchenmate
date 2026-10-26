// PROTOTYPE — throwaway. Lists the logs the share extension saved; export them as JSON.
import SwiftUI

@main
struct PayloadLoggerApp: App {
    var body: some Scene {
        WindowGroup { LogList() }
    }
}

struct LogList: View {
    @State private var logs: [ShareLog] = []
    @Environment(\.scenePhase) private var phase

    var body: some View {
        NavigationStack {
            List(logs) { log in
                NavigationLink {
                    List { LogDetail(log: log) }.navigationTitle(log.source)
                } label: {
                    VStack(alignment: .leading) {
                        Text(log.source).font(.headline)
                        Text("\(log.attachments.count) attachments · \(log.date.formatted(date: .omitted, time: .shortened))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .overlay {
                if logs.isEmpty {
                    ContentUnavailableView("No shares yet", systemImage: "square.and.arrow.up",
                                           description: Text("Share from any app and pick \"Log Payload\"."))
                }
            }
            .navigationTitle("Payload Logger")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Wipe", role: .destructive) { LogStore.wipe(); logs = [] }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: LogStore.exportJSON()) { Label("Export", systemImage: "square.and.arrow.up") }
                }
            }
            .refreshable { logs = LogStore.all() }
        }
        .onAppear { logs = LogStore.all() }
        .onChange(of: phase) { _, p in if p == .active { logs = LogStore.all() } }
    }
}
