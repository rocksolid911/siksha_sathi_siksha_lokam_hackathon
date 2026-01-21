import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/snap/presentation/screens/snap_detail_screen.dart';

/// Service for handling Firebase Cloud Messaging notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Stream controller for notification taps
  final StreamController<RemoteMessage> _onMessageTapController =
      StreamController<RemoteMessage>.broadcast();

  // Stream controller for unread count
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  Stream<RemoteMessage> get onMessageTap => _onMessageTapController.stream;
  Stream<int> get unreadCount => _unreadCountController.stream;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _initializeLocalNotifications();
      await _setupMessageHandlers();
      _isInitialized = true;

      // Get and print FCM token for testing
      final token = await getToken();
      debugPrint('📱 FCM Token: $token');
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'shiksha_saathi_channel',
      'Shiksha Saathi Notifications',
      description: 'Notifications from Shiksha Saathi app',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Setup message handlers
  Future<void> _setupMessageHandlers() async {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated message tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔔 App opened from terminated via notification');
      _onMessageTapController.add(initialMessage);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'Shiksha Saathi',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle message opened app (background)
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 Message opened app: ${message.notification?.title}');
    _onMessageTapController.add(message);
  }

  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Handle local notification tap
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        if (data['type'] == 'snap_solution') {
          _navigatorKey?.currentState?.push(
            MaterialPageRoute(
              builder: (context) => SnapDetailScreen(snapData: data),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Show a local notification
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'shiksha_saathi_channel',
      'Shiksha Saathi Notifications',
      channelDescription: 'Notifications from Shiksha Saathi app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);

    // Save to history
    await _saveNotification(
      title: title,
      body: body,
      payload: payload,
      timestamp: DateTime.now(),
    );
  }

  /// Save notification to local storage
  Future<void> _saveNotification({
    required String title,
    required String body,
    String? payload,
    required DateTime timestamp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history =
        prefs.getStringList('notification_history') ?? [];

    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'isRead': false,
    };

    history.insert(0, jsonEncode(notification)); // Add to top
    await prefs.setStringList('notification_history', history);

    await _updateUnreadCount();
  }

  /// Get all notifications
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history =
        prefs.getStringList('notification_history') ?? [];

    return history.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history =
        prefs.getStringList('notification_history') ?? [];

    if (history.isEmpty) return;

    final updatedHistory = history.map((item) {
      final Map<String, dynamic> notification = jsonDecode(item);
      notification['isRead'] = true;
      return jsonEncode(notification);
    }).toList();

    await prefs.setStringList('notification_history', updatedHistory);
    await _updateUnreadCount();
  }

  /// Update unread count stream
  Future<void> _updateUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history =
        prefs.getStringList('notification_history') ?? [];

    int count = 0;
    for (final item in history) {
      final Map<String, dynamic> notification = jsonDecode(item);
      if (notification['isRead'] == false) {
        count++;
      }
    }

    _unreadCountController.add(count);
  }

  /// Initialize unread count
  Future<void> initUnreadCount() async {
    await _updateUnreadCount();
  }

  /// Delete a specific notification by ID
  Future<void> deleteNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history =
        prefs.getStringList('notification_history') ?? [];

    final updatedHistory = history.where((item) {
      final Map<String, dynamic> notification = jsonDecode(item);
      return notification['id'] != id;
    }).toList();

    await prefs.setStringList('notification_history', updatedHistory);
    await _updateUnreadCount();
  }

  /// Clear all read notifications
  Future<void> clearAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history =
        prefs.getStringList('notification_history') ?? [];

    final unreadOnly = history.where((item) {
      final Map<String, dynamic> notification = jsonDecode(item);
      return notification['isRead'] == false;
    }).toList();

    await prefs.setStringList('notification_history', unreadOnly);
    await _updateUnreadCount();
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _onMessageTapController.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message: ${message.notification?.title}');
  // Handle background message if needed
}
