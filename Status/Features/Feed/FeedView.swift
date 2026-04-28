import SwiftUI

struct FeedView: View {
    @Environment(AuthService.self) private var auth
    @Environment(BroadcastService.self) private var broadcastService
    @Environment(StatusEngine.self) private var statusEngine
    @State private var showCompose = false

    private var currentUser: User? { auth.currentUser }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Status balance card
                if let user = currentUser {
                    StatusBalanceCard(user: user)
                        .padding(.horizontal)
                }

                // Compose broadcast prompt
                if let user = currentUser, statusEngine.canBroadcast(user: user) {
                    ComposeBroadcastButton {
                        showCompose = true
                    }
                    .padding(.horizontal)
                }

                // Broadcast feed
                if broadcastService.feed.isEmpty && !broadcastService.isLoading {
                    ContentUnavailableView(
                        "No Broadcasts Yet",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("Give status to people to see their broadcasts here.")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(broadcastService.feed) { broadcast in
                        BroadcastCard(broadcast: broadcast)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Feed")
        .refreshable {
            if let user = currentUser {
                let audience = statusEngine.broadcastAudience(for: user.id)
                await broadcastService.loadFeed(for: user.id, audience: audience)
            }
        }
        .sheet(isPresented: $showCompose) {
            ComposeBroadcastView()
        }
        .task {
            if let user = currentUser {
                let audience = statusEngine.broadcastAudience(for: user.id)
                await broadcastService.loadFeed(for: user.id, audience: audience)
            }
        }
    }
}

// MARK: - Status Balance Card

struct StatusBalanceCard: View {
    let user: User

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Status Balance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(user.statusBalance)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Received")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f", user.totalStatusReceived))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))

                if let rank = user.leaderboardRank {
                    Text("#\(rank)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Compose Button

struct ComposeBroadcastButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Text("Broadcast to your audience")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Broadcast Card

struct BroadcastCard: View {
    let broadcast: Broadcast

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author row
            HStack {
                Circle()
                    .fill(.quaternary)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(broadcast.authorId.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(broadcast.authorId)
                        .font(.subheadline.weight(.semibold))
                    Text(timeAgo(broadcast.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Time remaining badge
                Text(timeRemaining(broadcast.expiresAt))
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            // Content
            Text(broadcast.text)
                .font(.body)

            // Stats
            HStack(spacing: 16) {
                Label("\(broadcast.reachCount)", systemImage: "eye")
                Label("\(broadcast.statusReactions)", systemImage: "arrow.up.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Date.now.timeIntervalSince(date)
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h ago" }
        return "\(Int(seconds / 86400))d ago"
    }

    private func timeRemaining(_ date: Date) -> String {
        let remaining = date.timeIntervalSince(.now)
        if remaining <= 0 { return "Expired" }
        let hours = Int(remaining / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 { return "\(hours)h left" }
        return "\(minutes)m left"
    }
}

#Preview {
    NavigationStack {
        FeedView()
    }
    .environment(AuthService.preview)
    .environment(BroadcastService.preview)
    .environment(StatusEngine.preview)
}
