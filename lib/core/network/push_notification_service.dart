import 'dart:async';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'callkit_service.dart';

// ── Android notification channel ──────────────────────────────────────────────
const AndroidNotificationChannel _messageChannel = AndroidNotificationChannel(
  'campus_connect_messages', // id
  'Messages', // name
  description: 'Chat message notifications',
  importance: Importance.high,
  playSound: true,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

// ── Background / terminated handler (top-level function required) ─────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background FCM message: ${message.messageId}');

  if (message.data['type'] == 'incoming_call') {
    final callerName = message.data['callerName'] ?? 'Unknown Caller';
    final callerId = message.data['callerId'];
    final signalData = message.data['signalData'];

    if (callerId != null && signalData != null) {
      await CallKitService.instance.showIncomingCall(
        callerId: callerId,
        callerName: callerName,
        signalData: signalData,
      );
    }
  }
  // Regular notifications (type == 'message') are shown automatically
  // by FCM when the app is in the background — no extra code needed.
}

// ─────────────────────────────────────────────────────────────────────────────

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  // Emits a roomId whenever a chat notification is tapped
  final _onNotificationTap = StreamController<String>.broadcast();
  Stream<String> get onNotificationTap => _onNotificationTap.stream;

  Future<void> initialize() async {
    // 1. Request permission (iOS & Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted push notification permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. Set up flutter_local_notifications for foreground messages
    await _initLocalNotifications();

    // 3. Tell FCM to deliver data-only messages even when app is in foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Get & sync the FCM device token
    _fcmToken = await _messaging.getToken();
    debugPrint('FCM Token: $_fcmToken');
    if (_fcmToken != null) {
      await syncTokenWithBackend();
    }

    // 5. Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      syncTokenWithBackend();
    });

    // 6. Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Foreground FCM message received');

      if (message.data['type'] == 'incoming_call') {
        // Show native CallKit-style UI even when app is open
        final callerName = message.data['callerName'] ?? 'Unknown Caller';
        final callerId = message.data['callerId'];
        final signalData = message.data['signalData'];

        if (callerId != null && signalData != null) {
          CallKitService.instance.showIncomingCall(
            callerId: callerId,
            callerName: callerName,
            signalData: signalData,
          );
        }
      } else if (message.data['type'] == 'message' || message.notification != null) {
        // Show a local notification for chat messages (or generic test messages) in the foreground
        _showLocalMessageNotification(message);
      }
    });

    // 7. Handle notification taps when app is in background (not killed)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 Notification tapped while in background: ${message.data}');
      final roomId = message.data['roomId'];
      if (roomId != null && roomId.toString().isNotEmpty) {
        _onNotificationTap.add(roomId.toString());
      }
    });
  }

  Future<void> _initLocalNotifications() async {
    // Create the Android notification channel
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_messageChannel);

    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOS = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Local notification tapped: ${details.payload}');
        final roomId = details.payload;
        if (roomId != null && roomId.isNotEmpty) {
          _onNotificationTap.add(roomId);
        }
      },
    );
  }

  void _showLocalMessageNotification(RemoteMessage message) {
    final senderName = message.notification?.title ??
        message.data['senderName'] ??
        'New message';
    final body = message.notification?.body ?? message.data['content'] ?? '';
    final roomId = message.data['roomId']?.toString() ?? 'global_chat';

    _localNotifications.show(
      id: message.hashCode,
      title: senderName,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _messageChannel.id,
          _messageChannel.name,
          channelDescription: _messageChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF0F62FE), // App primary color
          category: AndroidNotificationCategory.message,
          groupKey: roomId, // Groups multiple messages from same chat
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: senderName,
            summaryText: 'New messages',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
      payload: roomId,
    );
  }

  Future<void> syncTokenWithBackend() async {
    _fcmToken ??= await _messaging.getToken();
    if (_fcmToken == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return; // Not logged in yet

      final dio = Dio();
      await dio.patch(
        'http://192.168.2.1:3000/api/users/fcm-token',
        data: {'fcmToken': _fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      debugPrint('Synced FCM token with backend.');
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

  String? get fcmToken => _fcmToken;
}
