import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
    }
}
