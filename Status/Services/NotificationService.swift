import Foundation
import UIKit
import FirebaseMessaging
import FirebaseFirestore

@Observable
final class NotificationService: NSObject {
    var fcmToken: String?

    @ObservationIgnored private var _db: Firestore?
    private var db: Firestore { if _db == nil { _db = Firestore.firestore() }; return _db! }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        } catch {
            return false
        }
    }

    func configure() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }

    func saveToken(userId: String) async {
        guard let token = fcmToken else { return }
        try? await db.collection("users").document(userId).updateData([
            "fcmToken": token
        ])
    }

    // MARK: - Send notifications (called from services after writes)

    func notifyStatusReceived(recipientId: String, senderName: String, amount: Int) async {
        try? await db.collection("notifications").addDocument(data: [
            "recipientId": recipientId,
            "type": "status_received",
            "title": "Status Received",
            "body": "\(senderName) sent you \(amount) status",
            "createdAt": Timestamp(date: .now),
            "read": false
        ])
    }

    func notifyNewMessage(recipientId: String, senderName: String) async {
        try? await db.collection("notifications").addDocument(data: [
            "recipientId": recipientId,
            "type": "new_message",
            "title": "New Message",
            "body": "\(senderName) sent you a message",
            "createdAt": Timestamp(date: .now),
            "read": false
        ])
    }

    func notifyBroadcast(recipientIds: [String], authorName: String) async {
        // Batch notifications for broadcast recipients
        let batch = db.batch()
        for recipientId in recipientIds.prefix(500) {
            let ref = db.collection("notifications").document()
            batch.setData([
                "recipientId": recipientId,
                "type": "broadcast",
                "title": "New Broadcast",
                "body": "\(authorName) posted a broadcast",
                "createdAt": Timestamp(date: .now),
                "read": false
            ], forDocument: ref)
        }
        try? await batch.commit()
    }

    static var preview: NotificationService {
        NotificationService()
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Handle notification tap — could deep link to messages/profile
    }
}
