import SwiftUI

struct ComposeBroadcastView: View {
    @Environment(AuthService.self) private var auth
    @Environment(BroadcastService.self) private var broadcastService
    @Environment(StatusEngine.self) private var statusEngine
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var isSending = false
    @FocusState private var isFocused: Bool

    private var audienceCount: Int {
        guard let user = auth.currentUser else { return 0 }
        return statusEngine.broadcastAudience(for: user.id).count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Audience info
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Broadcasting to \(audienceCount) people")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)

                // Text editor
                TextEditor(text: $text)
                    .focused($isFocused)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .scrollContentBackground(.hidden)

                // Character count
                HStack {
                    Spacer()
                    Text("\(text.count)/280")
                        .font(.caption)
                        .foregroundStyle(text.count > 280 ? .red : .secondary)
                }
                .padding(.horizontal)
            }
            .padding(.top)
            .navigationTitle("New Broadcast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await send() }
                    } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Text("Broadcast")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text.count > 280 || isSending)
                }
            }
            .onAppear { isFocused = true }
        }
    }

    private func send() async {
        guard let user = auth.currentUser else { return }
        isSending = true
        let audience = statusEngine.broadcastAudience(for: user.id)
        let _ = try? await broadcastService.createBroadcast(
            authorId: user.id,
            text: text,
            audience: audience
        )
        isSending = false
        dismiss()
    }
}
