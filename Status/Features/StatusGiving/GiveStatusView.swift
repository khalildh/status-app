import SwiftUI
import UIKit
@preconcurrency import FirebaseFirestore

struct GiveStatusView: View {
    @Environment(AuthService.self) private var auth
    @Environment(StatusEngine.self) private var statusEngine
    @Environment(MessageService.self) private var messageService
    @Environment(\.dismiss) private var dismiss
    let recipientId: String
    @State private var recipientName: String = ""

    @State private var amount: Int = 1
    @State private var didSend = false

    private var maxAmount: Int {
        auth.currentUser?.statusBalance ?? 0
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Recipient
            VStack(spacing: 8) {
                AvatarPlaceholder(name: recipientName.isEmpty ? recipientId : recipientName, size: 80)
                Text(recipientName.isEmpty ? recipientId : recipientName)
                    .font(.headline)
            }

            // Amount selector
            VStack(spacing: 16) {
                Text("Give Status")
                    .font(.title2.weight(.bold))

                HStack(spacing: 24) {
                    Button {
                        if amount > 1 {
                            amount -= 1
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                    }
                    .disabled(amount <= 1)

                    Text("\(amount)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .frame(minWidth: 80)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: amount)

                    Button {
                        if amount < maxAmount {
                            amount += 1
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                    .disabled(amount >= maxAmount)
                }

                Text("\(maxAmount) points available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Send button
            if didSend {
                Label("Status sent!", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    send()
                } label: {
                    Text("Send \(amount) Status")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
                .disabled(maxAmount == 0)
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .navigationTitle("Give Status")
        .task {
            let db = Firestore.firestore()
            if let doc = try? await db.collection("users").document(recipientId).getDocument(),
               let user = try? doc.data(as: User.self) {
                recipientName = user.displayName
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func send() {
        guard let user = auth.currentUser else { return }
        Task {
            statusEngine.error = nil
            do {
                try await statusEngine.giveStatus(from: user, to: recipientId, amount: amount)
            } catch {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                statusEngine.error = error.localizedDescription
                return
            }

            // Check if giveStatus set a validation error (e.g. self-send, no balance)
            if statusEngine.error != nil { return }

            // Create a conversation so they appear in messages
            do {
                let _ = try await messageService.startConversation(between: user.id, and: recipientId)
            } catch {
                print("[GiveStatus] Failed to create conversation: \(error)")
            }

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            withAnimation(.spring(duration: 0.4)) {
                didSend = true
            }
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        GiveStatusView(recipientId: "maya")
    }
    .environment(AuthService.preview)
    .environment(StatusEngine.preview)
}
