import SwiftUI

enum HistoryFilter: String, CaseIterable {
    case all = "All"
    case sent = "Sent"
    case received = "Received"
}

struct StatusHistoryView: View {
    @Environment(AuthService.self) private var auth
    @Environment(StatusEngine.self) private var statusEngine
    @State private var filter: HistoryFilter = .all

    private var currentUserId: String { auth.currentUser?.id ?? "" }

    private var filteredTransactions: [StatusTransaction] {
        let sorted = statusEngine.transactions.sorted { $0.createdAt > $1.createdAt }
        switch filter {
        case .all:
            return sorted.filter { $0.fromUserId == currentUserId || $0.toUserId == currentUserId }
        case .sent:
            return sorted.filter { $0.fromUserId == currentUserId }
        case .received:
            return sorted.filter { $0.toUserId == currentUserId }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $filter) {
                ForEach(HistoryFilter.allCases, id: \.self) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if filteredTransactions.isEmpty {
                ContentUnavailableView(
                    "No Status History",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Your status transactions will appear here.")
                )
            } else {
                List(filteredTransactions) { tx in
                    StatusTransactionRow(
                        transaction: tx,
                        currentUserId: currentUserId
                    )
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Status History")
    }
}

struct StatusTransactionRow: View {
    let transaction: StatusTransaction
    let currentUserId: String

    private var isSent: Bool { transaction.fromUserId == currentUserId }
    private var otherUserId: String {
        isSent ? transaction.toUserId : transaction.fromUserId
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSent ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill")
                .font(.title2)
                .foregroundStyle(isSent ? .orange : .green)

            VStack(alignment: .leading, spacing: 2) {
                Text(isSent ? "Sent to \(otherUserId)" : "Received from \(otherUserId)")
                    .font(.subheadline.weight(.medium))
                Text(timeAgo(transaction.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(isSent ? "-" : "+")\(transaction.amount)")
                    .font(.headline)
                    .foregroundStyle(isSent ? .orange : .green)
                if transaction.isExpired {
                    Text("Expired")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Date.now.timeIntervalSince(date)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h ago" }
        return "\(Int(seconds / 86400))d ago"
    }
}
