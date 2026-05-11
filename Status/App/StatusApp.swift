import SwiftUI
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // FirebaseApp.configure() is called in StatusApp.init() before this runs,
        // but the delegate is needed for Messaging swizzling
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

@main
struct StatusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
