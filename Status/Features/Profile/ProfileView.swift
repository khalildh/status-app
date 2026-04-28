import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var auth
    @Environment(StatusEngine.self) private var statusEngine
    @Environment(LeaderboardService.self) private var leaderboardService
    @State private var showGiveStatus = false

    private var user: User? { auth.currentUser }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile header
                if let user {
                    profileHeader(user)
                }

                // Stats grid
                if let user {
                    statsGrid(user)
                }

                // Status activity
                statusActivity

                // Actions
                VStack(spacing: 12) {
                    NavigationLink {
                        UserSearchView()
                    } label: {
                        Label("Give Status", systemImage: "arrow.up.circle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)

                    Button(role: .destructive) {
                        auth.signOut()
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Profile")
    }

    // MARK: - Profile Header

    private func profileHeader(_ user: User) -> some View {
        VStack(spacing: 12) {
            Circle()
                .fill(.quaternary)
                .frame(width: 80, height: 80)
                .overlay {
                    Text(user.displayName.prefix(1).uppercased())
                        .font(.title)
                        .foregroundStyle(.secondary)
                }

            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.title2.weight(.bold))
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let bio = user.bio {
                Text(bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Stats Grid

    private func statsGrid(_ user: User) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 16) {
            statCard("Balance", value: "\(user.statusBalance)", icon: "diamond")
            statCard("Received", value: String(format: "%.0f", user.totalStatusReceived), icon: "arrow.down.circle")
            statCard("Rank", value: user.leaderboardRank.map { "#\($0)" } ?? "--", icon: "chart.bar")
        }
        .padding(.horizontal)
    }

    private func statCard(_ title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Status Activity

    private var statusActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)

            let recentTransactions = statusEngine.transactions
                .filter { $0.fromUserId == user?.id || $0.toUserId == user?.id }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(5)

            if recentTransactions.isEmpty {
                Text("No activity yet. Give someone status to get started.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(Array(recentTransactions)) { tx in
                    HStack {
                        Image(systemName: tx.fromUserId == user?.id ? "arrow.up.right" : "arrow.down.left")
                            .foregroundStyle(tx.fromUserId == user?.id ? .orange : .green)

                        if tx.fromUserId == user?.id {
                            Text("Gave \(tx.amount) to \(tx.toUserId)")
                        } else {
                            Text("Received \(tx.amount) from \(tx.fromUserId)")
                        }

                        Spacer()

                        Text(timeAgo(tx.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    .padding(.horizontal)
                }
            }
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Date.now.timeIntervalSince(date)
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h ago" }
        return "\(Int(seconds / 86400))d ago"
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(AuthService.preview)
    .environment(StatusEngine.preview)
    .environment(LeaderboardService.preview)
}
