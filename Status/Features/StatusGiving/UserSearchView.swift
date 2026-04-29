import SwiftUI

struct UserSearchView: View {
    @Environment(AuthService.self) private var auth
    @Environment(StatusEngine.self) private var statusEngine
    @State private var query = ""
    @State private var results: [User] = []
    @State private var isSearching = false
    @FocusState private var isFocused: Bool

    var body: some View {
        List {
            if query.isEmpty {
                // Suggested users section
                Section("Suggested") {
                    if statusEngine.isLoading {
                        ProgressView()
                    } else if results.isEmpty {
                        Text("No users yet. Invite friends to get started!")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(results) { user in
                            if user.id != auth.currentUser?.id {
                                NavigationLink {
                                    GiveStatusView(recipientId: user.id)
                                } label: {
                                    UserRow(user: user)
                                }
                            }
                        }
                    }
                }
            } else {
                // Search results
                if isSearching {
                    ProgressView()
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    ForEach(results) { user in
                        if user.id != auth.currentUser?.id {
                            NavigationLink {
                                GiveStatusView(recipientId: user.id)
                            } label: {
                                UserRow(user: user)
                            }
                        }
                    }
                }
            }

            // Invite section
            Section {
                ShareLink(
                    item: "Join me on Status — where social capital determines access.",
                    subject: Text("Join Status"),
                    message: Text("Check out Status, a new social app where your reputation determines who you can talk to.")
                ) {
                    Label("Invite Friends", systemImage: "person.badge.plus")
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, prompt: "Search by username")
        .navigationTitle("Give Status")
        .onChange(of: query) {
            Task { await search() }
        }
        .task {
            await loadSuggested()
        }
    }

    private func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await loadSuggested()
            return
        }
        isSearching = true
        do {
            results = try await statusEngine.searchUsers(query: trimmed)
        } catch {
            results = []
        }
        isSearching = false
    }

    private func loadSuggested() async {
        do {
            results = try await statusEngine.fetchSuggestedUsers(
                currentUserId: auth.currentUser?.id ?? ""
            )
        } catch {
            results = []
        }
    }
}

// MARK: - User Row

struct UserRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(user: user, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.subheadline.weight(.semibold))
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let rank = user.leaderboardRank {
                    Text("#\(rank)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Text(String(format: "%.0f", user.totalStatusReceived))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
