import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ================================================================
// BACKGROUND MESSAGE HANDLER
// ================================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  debugPrint(
    'Background message: ${message.messageId}',
  );
}

// ================================================================
// NOTIFICATION SERVICE
// ================================================================

class NotificationService {
  static const Color primaryGreen =
      Color(0xFF2E7D32);

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ============================================================
  // NOTIFICATION CHANNEL
  // ============================================================

  static const AndroidNotificationChannel
      _channel = AndroidNotificationChannel(
    'ecoscan_notifications',
    'EcoScan Notifications',
    description:
        'Notifications for likes, comments and messages',
    importance: Importance.high,
    playSound: true,
  );

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> initialize() async {
    try {
      // REQUEST PERMISSION
      final NotificationSettings settings =
          await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        'Notification permission: ${settings.authorizationStatus}',
      );

      // BACKGROUND HANDLER
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      // CREATE ANDROID CHANNEL
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            _channel,
          );

      // INITIALIZE LOCAL NOTIFICATIONS
      const AndroidInitializationSettings
          androidSettings =
          AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const InitializationSettings
          initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        initSettings,
      );

      // FOREGROUND NOTIFICATIONS
      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
          debugPrint(
            'Foreground message: ${message.messageId}',
          );

          _showLocalNotification(message);
        },
      );

      // SAVE TOKEN
      await _saveToken();

      // TOKEN REFRESH
      _messaging.onTokenRefresh.listen(
        (String token) async {
          await _updateToken(token);
        },
      );
    } catch (e) {
      debugPrint(
        'Notification initialize error: $e',
      );
    }
  }

  // ============================================================
  // SHOW LOCAL NOTIFICATION
  // ============================================================

  static void _showLocalNotification(
    RemoteMessage message,
  ) {
    final RemoteNotification? notification =
        message.notification;

    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription:
              _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: primaryGreen,
        ),
      ),
    );
  }

  // ============================================================
  // SAVE FCM TOKEN
  // ============================================================

  static Future<void> _saveToken() async {
    try {
      final String? token =
          await _messaging.getToken();

      if (token == null) return;

      debugPrint(
        'FCM Token: $token',
      );

      await _updateToken(token);
    } catch (e) {
      debugPrint(
        'Save token error: $e',
      );
    }
  }

  // ============================================================
  // UPDATE FCM TOKEN
  // ============================================================

  static Future<void> _updateToken(
    String token,
  ) async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': token,
        'tokenUpdatedAt':
            FieldValue.serverTimestamp(),
      });

      debugPrint(
        'FCM token saved.',
      );
    } catch (e) {
      debugPrint(
        'Update token error: $e',
      );
    }
  }

  // ============================================================
  // SEND LIKE NOTIFICATION
  // ============================================================

  static Future<void> sendLikeNotification({
    required String postId,
    required String postAuthorId,
    required String likerName,
    required String postContent,
  }) async {
    try {
      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      // DON'T NOTIFY YOURSELF
      if (currentUser?.uid == postAuthorId) {
        return;
      }

      if (currentUser == null) return;

      // SAVE NOTIFICATION
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'toUserId': postAuthorId,
        'fromUserId': currentUser.uid,
        'fromUserName': likerName,
        'type': 'like',
        'message':
            '$likerName liked your post',
        'postId': postId,
        'postContent': postContent,
        'read': false,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      debugPrint(
        'Like notification saved for $postAuthorId',
      );
    } catch (e) {
      debugPrint(
        'Send like notification error: $e',
      );
    }
  }

  // ============================================================
  // SEND COMMENT NOTIFICATION
  // ============================================================

  static Future<void> sendCommentNotification({
    required String postId,
    required String postAuthorId,
    required String commenterName,
    required String commentText,
  }) async {
    try {
      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      // DON'T NOTIFY YOURSELF
      if (currentUser?.uid == postAuthorId) {
        return;
      }

      if (currentUser == null) return;

      // SAVE NOTIFICATION
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'toUserId': postAuthorId,
        'fromUserId': currentUser.uid,
        'fromUserName': commenterName,
        'type': 'comment',
        'message':
            '$commenterName commented on your post',
        'postId': postId,
        'commentText': commentText,
        'read': false,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      debugPrint(
        'Comment notification saved for $postAuthorId',
      );
    } catch (e) {
      debugPrint(
        'Send comment notification error: $e',
      );
    }
  }

  // ============================================================
  // SEND MESSAGE NOTIFICATION
  // ============================================================

  static Future<void> sendMessageNotification({
    required String toUserId,
    required String senderName,
    required String messageText,
    required String chatId,
  }) async {
    try {
      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      // DON'T NOTIFY YOURSELF
      if (currentUser?.uid == toUserId) {
        return;
      }

      if (currentUser == null) return;

      // SAVE NOTIFICATION
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'toUserId': toUserId,
        'fromUserId': currentUser.uid,
        'fromUserName': senderName,
        'type': 'message',
        'message':
            '$senderName sent you a message',
        'messageText': messageText,

        // IMPORTANT:
        // This lets HomeScreen know exactly
        // which chat to open.
        'chatId': chatId,

        'read': false,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      debugPrint(
        'Message notification saved for $toUserId',
      );
      debugPrint(
        'Chat ID saved: $chatId',
      );
    } catch (e) {
      debugPrint(
        'Send message notification error: $e',
      );
    }
  }

  // ============================================================
  // GET UNREAD COUNT
  // ============================================================

  static Stream<int> getUnreadCount() {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('notifications')
        .where(
          'toUserId',
          isEqualTo: user.uid,
        )
        .where(
          'read',
          isEqualTo: false,
        )
        .snapshots()
        .map(
          (snap) => snap.docs.length,
        );
  }

  // ============================================================
  // MARK ONE NOTIFICATION AS READ
  // ============================================================

  static Future<void> markAsRead(
    String notificationId,
  ) async {
    try {
      if (notificationId.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({
        'read': true,
      });
    } catch (e) {
      debugPrint(
        'Mark notification as read error: $e',
      );
    }
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  static Future<void> markAllAsRead() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final QuerySnapshot unread =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where(
                'toUserId',
                isEqualTo: user.uid,
              )
              .where(
                'read',
                isEqualTo: false,
              )
              .get();

      final WriteBatch batch =
          FirebaseFirestore.instance.batch();

      for (final doc in unread.docs) {
        batch.update(
          doc.reference,
          {
            'read': true,
          },
        );
      }

      await batch.commit();

      debugPrint(
        'All notifications marked as read.',
      );
    } catch (e) {
      debugPrint(
        'Mark all as read error: $e',
      );
    }
  }
}
