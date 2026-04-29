import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth
    @Environment(NotificationService.self) private var notifications
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasGivenFirstStatus") private var hasGivenFirstStatus = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if !auth.isAuthenticated {
                AuthView()
            } else if !hasGivenFirstStatus {
                FirstStatusView()
            } else {
                MainTabView()
                    .task {
                        let _ = await notifications.requestPermission()
                        if let userId = auth.currentUser?.id {
                            await notifications.saveToken(userId: userId)
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: hasSeenOnboarding)
        .animation(.easeInOut(duration: 0.3), value: hasGivenFirstStatus)
    }
}
