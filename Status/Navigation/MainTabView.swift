import SwiftUI

enum AppTab: String, CaseIterable {
    case feed = "Feed"
    case messages = "Messages"
    case leaderboard = "Leaderboard"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .feed: "antenna.radiowaves.left.and.right"
        case .messages: "bubble.left.and.bubble.right"
        case .leaderboard: "chart.bar"
        case .profile: "person.crop.circle"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .feed

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { FeedView() }
                .tabItem { Label(AppTab.feed.rawValue, systemImage: AppTab.feed.icon) }
                .tag(AppTab.feed)

            NavigationStack { ConversationsView() }
                .tabItem { Label(AppTab.messages.rawValue, systemImage: AppTab.messages.icon) }
                .tag(AppTab.messages)

            NavigationStack { LeaderboardView() }
                .tabItem { Label(AppTab.leaderboard.rawValue, systemImage: AppTab.leaderboard.icon) }
                .tag(AppTab.leaderboard)

            NavigationStack { ProfileView() }
                .tabItem { Label(AppTab.profile.rawValue, systemImage: AppTab.profile.icon) }
                .tag(AppTab.profile)
        }
        .tint(.primary)
    }
}
