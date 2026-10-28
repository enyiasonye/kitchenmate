// PROTOTYPE — throwaway. The App Intent the Shortcuts Time of Day automation runs.
import AppIntents

struct RunSyncProbe: AppIntent {
    static let title: LocalizedStringResource = "Run Grocery Sync Probe"
    static let description = IntentDescription("Reads the Synced List and logs that the Shortcut ran.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let e = await Probe.run(.shortcut)
        return .result(dialog: "\(e.summary)")
    }
}

struct ProbeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: RunSyncProbe(), phrases: ["Run \(.applicationName)"],
                    shortTitle: "Grocery Sync Probe", systemImageName: "cart")
    }
}
