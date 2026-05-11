import Foundation
import UIKit
import FirebaseMessaging
@preconcurrency import FirebaseFirestore

@MainActor
@Observable
final class NotificationService: NSObject {
    var fcmToken: String?
    private var currentUserId: String?

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
        currentUserId = userId
        guard let token = fcmToken else {
            print("[Notifications] No FCM token yet, will save when received")
            return
        }
        print("[Notifications] Saving FCM token for \(userId)")
        try? await db.collection("users").document(userId).updateData([
            "fcmToken": token
        ])
    }

    // MARK: - Send notifications (called from services after writes)

    func notifyStatusReceived(recipientId: String, senderName: String, amount: Int) async {
        _ = try? await db.collection("notifications").addDocument(data: [
            "recipientId": recipientId,
            "type": "status_received",
            "title": "Status Received",
            "body": "\(senderName) sent you \(amount) status",
            "createdAt": Timestamp(date: .now),
            "read": false
        ])
    }

    func notifyNewMessage(recipientId: String, senderName: String) async {
        _ = try? await db.collection("notifications").addDocument(data: [
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
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in
            self.fcmToken = fcmToken
            print("[Notifications] FCM token received: \(fcmToken?.prefix(20) ?? "nil")...")
            // Save immediately if we have a userId
            if let userId = self.currentUserId, let token = fcmToken {
                print("[Notifications] Auto-saving FCM token for \(userId)")
                try? await self.db.collection("users").document(userId).updateData([
                    "fcmToken": token
                ])
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Handle notification tap — could deep link to messages/profile
    }
}
