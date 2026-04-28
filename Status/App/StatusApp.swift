import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct StatusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authService = AuthService()
    @State private var statusEngine = StatusEngine()
    @State private var messageService = MessageService()
    @State private var broadcastService = BroadcastService()
    @State private var leaderboardService = LeaderboardService()
    @State private var blockService = BlockService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(statusEngine)
                .environment(messageService)
                .environment(broadcastService)
                .environment(leaderboardService)
                .environment(blockService)
        }
    }
}
