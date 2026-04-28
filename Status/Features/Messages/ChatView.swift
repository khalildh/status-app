import SwiftUI

struct ChatView: View {
    @Environment(AuthService.self) private var auth
    @Environment(MessageService.self) private var messageService
    @Environment(StatusEngine.self) private var statusEngine
    let conversation: Conversation

    @State private var newMessage = ""
    @FocusState private var isFocused: Bool

    private var currentUserId: String { auth.currentUser?.id ?? "" }
    private var otherUserId: String {
        conversation.participantIds.first { $0 != currentUserId } ?? ""
    }
    private var messages: [Message] {
        messageService.messagesByConversation[conversation.id] ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == currentUserId
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let lastId = messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input bar
            HStack(spacing: 12) {
                TextField("Message", text: $newMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .focused($isFocused)

                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .navigationTitle(otherUserId)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    GiveStatusView(recipientId: otherUserId)
                } label: {
                    Image(systemName: "arrow.up.circle")
                }
            }
        }
        .task {
            await messageService.loadMessages(for: conversation.id)
        }
    }

    private func send() async {
        let text = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        newMessage = ""
        await messageService.sendMessage(
            conversationId: conversation.id,
            senderId: currentUserId,
            text: text
        )
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                Text(message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isFromCurrentUser ? Color.primary : Color(.systemGray5),
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .foregroundStyle(isFromCurrentUser ? Color(.systemBackground) : .primary)

                Text(timeString(message.sentAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }

            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
