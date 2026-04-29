import SwiftUI

/// Shown after signup — encourages the user to give their first status point
struct FirstStatusView: View {
    @Environment(AuthService.self) private var auth
    @Environment(StatusEngine.self) private var statusEngine
    @AppStorage("hasGivenFirstStatus") private var hasGivenFirstStatus = false
    @State private var suggestedUsers: [User] = []
    @State private var givenTo: Set<String> = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 56))

            Text("Give Your First Status")
                .font(.title2.weight(.bold))

            Text("Pick someone to give status to. This unlocks messaging and starts building your network.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Suggested users
            if isLoading {
                ProgressView()
                    .padding(.top, 20)
            } else if suggestedUsers.isEmpty {
                Text("No users yet — invite friends to get started!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(suggestedUsers) { user in
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

                                if givenTo.contains(user.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.title3)
                                } else {
                                    Button("Give 1") {
                                        Task { await give(to: user) }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.primary)
                                    .controlSize(.small)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }

            Spacer()

            Button {
                hasGivenFirstStatus = true
            } label: {
                Text(givenTo.isEmpty ? "Skip for Now" : "Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(givenTo.isEmpty ? Color(.systemGray4) : .primary)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .task {
            await loadSuggested()
        }
    }

    private func loadSuggested() async {
        isLoading = true
        guard let userId = auth.currentUser?.id else {
            isLoading = false
            return
        }
        suggestedUsers = (try? await statusEngine.fetchSuggestedUsers(
            currentUserId: userId, limit: 5
        )) ?? []
        isLoading = false
    }

    private func give(to user: User) async {
        guard let currentUser = auth.currentUser else { return }
        try? await statusEngine.giveStatus(from: currentUser, to: user.id, amount: 1)
        withAnimation {
            givenTo.insert(user.id)
        }
    }
}
