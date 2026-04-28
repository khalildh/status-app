import SwiftUI

struct LeaderboardView: View {
    @Environment(AuthService.self) private var auth
    @Environment(LeaderboardService.self) private var leaderboardService
    @State private var scope: LeaderboardScope = .weekly

    var body: some View {
        VStack(spacing: 0) {
            // Scope picker
            Picker("Scope", selection: $scope) {
                ForEach(LeaderboardScope.allCases, id: \.self) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Leaderboard list
            if leaderboardService.entries.isEmpty && !leaderboardService.isLoading {
                ContentUnavailableView(
                    "No Rankings Yet",
                    systemImage: "chart.bar",
                    description: Text("Start giving status to populate the leaderboard.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Top 3 podium
                        if leaderboardService.entries.count >= 3 {
                            PodiumView(
                                entries: Array(leaderboardService.entries.prefix(3)),
                                currentUserId: auth.currentUser?.id
                            )
                            .padding(.bottom, 16)
                        }

                        // Rest of the list
                        let startIndex = min(3, leaderboardService.entries.count)
                        ForEach(leaderboardService.entries.dropFirst(startIndex)) { entry in
                            LeaderboardRow(
                                entry: entry,
                                isCurrentUser: entry.userId == auth.currentUser?.id
                            )
                        }

                        // Current user's position if not in visible list
                        if let userId = auth.currentUser?.id,
                           let userEntry = leaderboardService.userRank(userId: userId),
                           userEntry.rank > leaderboardService.entries.count {
                            Divider().padding(.vertical, 8)
                            LeaderboardRow(entry: userEntry, isCurrentUser: true)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Leaderboard")
        .onChange(of: scope) {
            Task { await leaderboardService.loadLeaderboard(scope: scope) }
        }
        .task {
            await leaderboardService.loadLeaderboard(scope: scope)
        }
    }
}

// MARK: - Podium

struct PodiumView: View {
    let entries: [LeaderboardEntry]
    let currentUserId: String?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if entries.count >= 2 {
                podiumItem(entries[1], height: 80)
            }
            if entries.count >= 1 {
                podiumItem(entries[0], height: 110)
            }
            if entries.count >= 3 {
                podiumItem(entries[2], height: 60)
            }
        }
        .padding(.top, 16)
    }

    private func podiumItem(_ entry: LeaderboardEntry, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            // Avatar
            Circle()
                .fill(entry.userId == currentUserId ? Color.blue.opacity(0.2) : Color(.systemGray5))
                .frame(width: 48, height: 48)
                .overlay {
                    Text(entry.displayName.prefix(1).uppercased())
                        .font(.headline)
                }

            Text(entry.displayName)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            Text(String(format: "%.0f", entry.weightedScore))
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Podium bar
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .frame(height: height)
                .overlay(alignment: .top) {
                    Text("#\(entry.rank)")
                        .font(.title3.weight(.bold))
                        .padding(.top, 12)
                }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("\(entry.rank)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 30)

            // Trend
            Group {
                if entry.isRising {
                    Image(systemName: "arrow.up")
                        .foregroundStyle(.green)
                } else if entry.isFalling {
                    Image(systemName: "arrow.down")
                        .foregroundStyle(.red)
                } else {
                    Image(systemName: "minus")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
            .frame(width: 16)

            Circle()
                .fill(isCurrentUser ? Color.blue.opacity(0.2) : Color(.systemGray5))
                .frame(width: 36, height: 36)
                .overlay {
                    Text(entry.displayName.prefix(1).uppercased())
                        .font(.subheadline.weight(.medium))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.subheadline.weight(isCurrentUser ? .bold : .medium))
                Text("@\(entry.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(String(format: "%.0f", entry.weightedScore))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            isCurrentUser ? Color.blue.opacity(0.05) : .clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
    .environment(AuthService.preview)
    .environment(LeaderboardService.preview)
}
