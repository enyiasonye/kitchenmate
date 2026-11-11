import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    @Published var token = "(waiting)"
    func application(_ app: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken t: Data) {
        let hex = t.map { String(format: "%02x", $0) }.joined()
        print("APNS_TOKEN=\(hex)")
        token = hex
    }
    func application(_ app: UIApplication, didFailToRegisterForRemoteNotificationsWithError e: Error) {
        token = "error: \(e.localizedDescription)"
    }
}

@main
struct APNsSpikeApp: App {
    @UIApplicationDelegateAdaptor var delegate: AppDelegate
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 16) {
                Text("Device token").font(.headline)
                Text(delegate.token).font(.caption.monospaced()).textSelection(.enabled)
                Button("Copy") { UIPasteboard.general.string = delegate.token }
            }
            .padding()
            .task {
                _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}
