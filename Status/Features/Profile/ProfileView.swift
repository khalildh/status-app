import SwiftUI
@preconcurrency import FirebaseFirestore

struct ProfileView: View {
    @Environment(AuthService.self) private var auth
    @Environment(StatusEngine.self) private var statusEngine
    @Environment(LeaderboardService.self) private var leaderboardService
    @State private var showEditProfile = false
    @State private var showStore = false
    @State private var userNames: [String: String] = [:]

    private var user: User? { auth.currentUser }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let user {
                    profileHeader(user)
                    statsGrid(user)
                }

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

                    Button {
                        showStore = true
                    } label: {
                        Label("Buy More Points", systemImage: "cart")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)

                    NavigationLink {
                        StatusHistoryView()
                    } label: {
                        Label("Status History", systemImage: "clock.arrow.circlepath")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    if let user {
                        ShareLink(
                            item: DeepLinkHandler.profileURL(userId: user.id),
                            subject: Text("Check out my Status profile"),
                            message: Text("Give me status on the Status app!")
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    Button {
                        showEditProfile = true
                    } label: {
                        Image(systemName: "pencil.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showStore) {
            StoreView()
        }
        .task {
            if let user {
                try? await statusEngine.refillIfNeeded(user: user)
                await fetchUserNames()
            }
        }
    }

    // MARK: - Profile Header

    private func profileHeader(_ user: User) -> some View {
        VStack(spacing: 12) {
            AvatarView(user: user, size: 80)

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
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    StatusHistoryView()
                }
                .font(.subheadline)
            }
            .padding(.horizontal)

            let recentTransactions = statusEngine.transactions
                .filter { $0.fromUserId == user?.id || $0.toUserId == user?.id }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(3)

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
                            Text("Gave \(tx.amount) to \(userNames[tx.toUserId] ?? "someone")")
                        } else {
                            Text("Received \(tx.amount) from \(userNames[tx.fromUserId] ?? "someone")")
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

    private func fetchUserNames() async {
        let db = Firestore.firestore()
        let txns = statusEngine.transactions.filter { $0.fromUserId == user?.id || $0.toUserId == user?.id }
        let ids = Set(txns.flatMap { [$0.fromUserId, $0.toUserId] }).subtracting([user?.id ?? ""])
        for id in ids where userNames[id] == nil {
            if let doc = try? await db.collection("users").document(id).getDocument(),
               let u = try? doc.data(as: User.self) {
                userNames[id] = u.displayName
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
    .environment(StorageService.preview)
    .environment(StoreService.preview)
}
