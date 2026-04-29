import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth
    @Environment(NotificationService.self) private var notifications
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if auth.isAuthenticated {
                MainTabView()
                    .task {
                        await notifications.requestPermission()
                        if let userId = auth.currentUser?.id {
                            await notifications.saveToken(userId: userId)
                        }
                    }
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: hasSeenOnboarding)
    }
}
