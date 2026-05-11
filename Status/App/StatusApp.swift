import SwiftUI
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
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
    @State private var locationGate: LocationGate

    static let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")

    init() {
        FirebaseApp.configure()
        _authService = State(initialValue: AuthService())

        if Self.isUITesting {
            let gate = LocationGate()
            gate.isInNYC = true
            gate.isChecking = false
            _locationGate = State(initialValue: gate)
        } else {
            _locationGate = State(initialValue: LocationGate())
        }
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
                    if !Self.isUITesting {
                        notificationService.configure()
                    }
                }
                .onOpenURL { url in
                    deepLinkHandler.handle(url: url)
                }
        }
    }
}
