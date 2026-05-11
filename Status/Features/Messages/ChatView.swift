import SwiftUI

struct ChatView: View {
    @Environment(AuthService.self) private var auth
    @Environment(MessageService.self) private var messageService
    @Environment(StatusEngine.self) private var statusEngine
    @Environment(BlockService.self) private var blockService
    @Environment(CryptoService.self) private var crypto
    let conversation: Conversation

    @State private var newMessage = ""
    @State private var showBlockConfirmation = false
    @State private var decryptedTexts: [String: String] = [:]
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
                                displayText: decryptedTexts[message.id] ?? message.text,
                                isFromCurrentUser: message.senderId == currentUserId
                            )
                            .id(message.id)
                            .task {
                                await decryptIfNeeded(message)
                            }
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
                HStack(spacing: 12) {
                    NavigationLink {
                        GiveStatusView(recipientId: otherUserId)
                    } label: {
                        Image(systemName: "arrow.up.circle")
                    }

                    Menu {
                        Button(role: .destructive) {
                            showBlockConfirmation = true
                        } label: {
                            Label("Block User", systemImage: "hand.raised")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog(
            "Block \(otherUserId)?",
            isPresented: $showBlockConfirmation,
            titleVisibility: .visible
        ) {
            ForEach(BlockReason.allCases, id: \.self) { reason in
                Button(reason.rawValue, role: .destructive) {
                    Task {
                        try? await blockService.blockUser(
                            blockerId: currentUserId,
                            blockedUserId: otherUserId,
                            reason: reason
                        )
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They won't be able to message you or send you status. Select a reason:")
        }
        .task {
            messageService.startListeningToMessages(for: conversation.id)
        }
        .onDisappear {
            messageService.stopListeningToMessages(for: conversation.id)
        }
    }

    private func send() async {
        let text = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        newMessage = ""

        // Encrypt before sending
        var textToSend = text
        if let encrypted = try? await crypto.encrypt(text, for: otherUserId) {
            textToSend = encrypted.ciphertext
        }

        try? await messageService.sendMessage(
            conversationId: conversation.id,
            senderId: currentUserId,
            text: textToSend
        )

        // Cache the decrypted version for immediate display
        if let lastMsg = messages.last {
            decryptedTexts[lastMsg.id] = text
        }
    }

    private func decryptIfNeeded(_ message: Message) async {
        guard decryptedTexts[message.id] == nil else { return }
        let senderId = message.senderId == currentUserId ? otherUserId : message.senderId
        if let decrypted = try? await crypto.decrypt(
            EncryptedMessage(ciphertext: message.text, isEncrypted: true),
            from: senderId
        ) {
            decryptedTexts[message.id] = decrypted
        } else {
            // Not encrypted or decryption failed — show as-is
            decryptedTexts[message.id] = message.text
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message
    var displayText: String
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                Text(displayText)
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
