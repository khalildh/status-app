import SwiftUI
import FirebaseCore

@main
struct StatusApp: App {
    @State private var authService: AuthService
    @State private var statusEngine = StatusEngine()
    @State private var messageService = MessageService()
    @State private var broadcastService = BroadcastService()
    @State private var leaderboardService = LeaderboardService()
    @State private var blockService = BlockService()
    @State private var notificationService = NotificationService()
    @State private var storageService = StorageService()
    @State private var storeService = StoreService()
    @State private var deepLinkHandler = DeepLinkHandler()
    @State private var locationGate = LocationGate()

    init() {
        FirebaseApp.configure()
        _authService = State(initialValue: AuthService())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(statusEngine)
                .environment(messageService)
                .environment(broadcastService)
                .environment(leaderboardService)
                .environment(blockService)
                .environment(notificationService)
                .environment(storageService)
                .environment(storeService)
                .environment(deepLinkHandler)
                .environment(locationGate)
                .onAppear {
                    notificationService.configure()
                }
                .onOpenURL { url in
                    deepLinkHandler.handle(url: url)
                }
        }
    }
}
