import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth
    @Environment(NotificationService.self) private var notifications
    @Environment(LocationGate.self) private var locationGate
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasGivenFirstStatus") private var hasGivenFirstStatus = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if locationGate.isChecking || !locationGate.isInNYC {
                LocationGateView()
                    .onAppear { locationGate.checkLocation() }
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
        .animation(.easeInOut(duration: 0.3), value: locationGate.isInNYC)
    }
}
