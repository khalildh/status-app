import SwiftUI
@preconcurrency import FirebaseFirestore

enum HistoryFilter: String, CaseIterable {
    case all = "All"
    case sent = "Sent"
    case received = "Received"
}

struct StatusHistoryView: View {
    @Environment(AuthService.self) private var auth
    @Environment(StatusEngine.self) private var statusEngine
    @State private var filter: HistoryFilter = .all
    @State private var userNames: [String: String] = [:]

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
                        currentUserId: currentUserId,
                        userNames: userNames
                    )
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Status History")
        .task { await fetchUserNames() }
    }

    private func fetchUserNames() async {
        let db = Firestore.firestore()
        let txns = statusEngine.transactions.filter { $0.fromUserId == currentUserId || $0.toUserId == currentUserId }
        let ids = Set(txns.flatMap { [$0.fromUserId, $0.toUserId] }).subtracting([currentUserId])
        for id in ids where userNames[id] == nil {
            if let doc = try? await db.collection("users").document(id).getDocument(),
               let u = try? doc.data(as: User.self) {
                userNames[id] = u.displayName
            }
        }
    }
}

struct StatusTransactionRow: View {
    let transaction: StatusTransaction
    let currentUserId: String
    var userNames: [String: String] = [:]

    private var isSent: Bool { transaction.fromUserId == currentUserId }
    private var otherUserId: String {
        isSent ? transaction.toUserId : transaction.fromUserId
    }
    private var otherName: String {
        userNames[otherUserId] ?? otherUserId
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSent ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill")
                .font(.title2)
                .foregroundStyle(isSent ? .orange : .green)

            VStack(alignment: .leading, spacing: 2) {
                Text(isSent ? "Sent to \(otherName)" : "Received from \(otherName)")
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
