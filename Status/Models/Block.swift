import Foundation

struct Block: Identifiable, Codable {
    var id: String
    var blockerId: String       // User who blocked
    var blockedUserId: String   // User who got blocked
    var reason: BlockReason?
    var createdAt: Date
}

enum BlockReason: String, Codable, CaseIterable {
    case spam = "Spam"
    case harassment = "Harassment"
    case unwantedMessages = "Unwanted messages"
    case other = "Other"
}
