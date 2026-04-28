import SwiftUI

struct UserSearchView: View {
    @Environment(StatusEngine.self) private var statusEngine
    @State private var query = ""
    @State private var results: [User] = []
    @FocusState private var isFocused: Bool

    var body: some View {
        List {
            if results.isEmpty && !query.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                ForEach(results) { user in
                    NavigationLink {
                        GiveStatusView(recipientId: user.id)
                    } label: {
                        UserRow(user: user)
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $query, prompt: "Search users")
        .focused($isFocused)
        .navigationTitle("Give Status")
        .onChange(of: query) {
            search()
        }
        .onAppear {
            // Show all mock users initially
            results = User.mockOthers
            isFocused = true
        }
    }

    private func search() {
        if query.isEmpty {
            results = User.mockOthers
        } else {
            results = User.mockOthers.filter {
                $0.username.localizedCaseInsensitiveContains(query) ||
                $0.displayName.localizedCaseInsensitiveContains(query)
            }
        }
    }
}

// MARK: - User Row

struct UserRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.quaternary)
                .frame(width: 44, height: 44)
                .overlay {
                    Text(user.displayName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.subheadline.weight(.semibold))
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let rank = user.leaderboardRank {
                Text("#\(rank)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
