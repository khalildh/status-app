import SwiftUI
import UIKit

struct GiveStatusView: View {
    @Environment(AuthService.self) private var auth
    @Environment(StatusEngine.self) private var statusEngine
    @Environment(MessageService.self) private var messageService
    @Environment(\.dismiss) private var dismiss
    let recipientId: String

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
                Circle()
                    .fill(.quaternary)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Text(recipientId.prefix(1).uppercased())
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                Text(recipientId)
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
        .navigationBarTitleDisplayMode(.inline)
    }

    private func send() {
        guard let user = auth.currentUser else { return }
        Task {
            do {
                try await statusEngine.giveStatus(from: user, to: recipientId, amount: amount)
                // Create a conversation so they appear in messages
                let _ = try? await messageService.startConversation(between: user.id, and: recipientId)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                withAnimation(.spring(duration: 0.4)) {
                    didSend = true
                }
                try? await Task.sleep(for: .seconds(1.5))
                dismiss()
            } catch {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                statusEngine.error = error.localizedDescription
            }
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
