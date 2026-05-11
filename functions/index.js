const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

// Send push notification when a new message is created in any conversation
exports.onNewMessage = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const message = event.data.data();
    const conversationId = event.params.conversationId;
    const senderId = message.senderId;

    // Get conversation to find the other participant
    const convDoc = await db.collection("conversations").doc(conversationId).get();
    if (!convDoc.exists) return;

    const participants = convDoc.data().participantIds || [];
    const recipientId = participants.find((id) => id !== senderId);
    if (!recipientId) return;

    // Get sender's display name
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.exists
      ? senderDoc.data().displayName || "Someone"
      : "Someone";

    // Get recipient's FCM token
    const recipientDoc = await db.collection("users").doc(recipientId).get();
    if (!recipientDoc.exists) return;
    const fcmToken = recipientDoc.data().fcmToken;
    if (!fcmToken) return;

    // Send push
    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: senderName,
          body: "Sent you a message",
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        data: {
          type: "message",
          conversationId: conversationId,
          senderId: senderId,
        },
      });
    } catch (err) {
      console.error("Failed to send message notification:", err);
    }
  }
);

// Send push notification when a new broadcast is created
exports.onNewBroadcast = onDocumentCreated(
  "broadcasts/{broadcastId}",
  async (event) => {
    const broadcast = event.data.data();
    const authorId = broadcast.authorId;

    // Get author's display name
    const authorDoc = await db.collection("users").doc(authorId).get();
    const authorName = authorDoc.exists
      ? authorDoc.data().displayName || "Someone"
      : "Someone";

    // Find all users who gave status to this author (the audience)
    const txns = await db
      .collection("statusTransactions")
      .where("toUserId", "==", authorId)
      .get();

    const recipientIds = [
      ...new Set(txns.docs.map((doc) => doc.data().fromUserId)),
    ].filter((id) => id !== authorId);

    // Send to each recipient
    for (const recipientId of recipientIds) {
      const recipientDoc = await db.collection("users").doc(recipientId).get();
      if (!recipientDoc.exists) continue;
      const fcmToken = recipientDoc.data().fcmToken;
      if (!fcmToken) continue;

      try {
        await getMessaging().send({
          token: fcmToken,
          notification: {
            title: `${authorName} broadcast`,
            body:
              broadcast.text.length > 100
                ? broadcast.text.substring(0, 100) + "..."
                : broadcast.text,
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
          data: {
            type: "broadcast",
            broadcastId: event.params.broadcastId,
            authorId: authorId,
          },
        });
      } catch (err) {
        console.error(
          `Failed to send broadcast notification to ${recipientId}:`,
          err
        );
      }
    }
  }
);

// Send push when someone gives you status
exports.onStatusGiven = onDocumentCreated(
  "statusTransactions/{txId}",
  async (event) => {
    const tx = event.data.data();
    const senderId = tx.fromUserId;
    const recipientId = tx.toUserId;

    if (senderId === recipientId) return;

    // Get sender's display name
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.exists
      ? senderDoc.data().displayName || "Someone"
      : "Someone";

    // Get recipient's FCM token
    const recipientDoc = await db.collection("users").doc(recipientId).get();
    if (!recipientDoc.exists) return;
    const fcmToken = recipientDoc.data().fcmToken;
    if (!fcmToken) return;

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: "Status Received",
          body: `${senderName} sent you ${tx.amount} status`,
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        data: {
          type: "status_received",
          senderId: senderId,
          amount: String(tx.amount),
        },
      });
    } catch (err) {
      console.error("Failed to send status notification:", err);
    }
  }
);
