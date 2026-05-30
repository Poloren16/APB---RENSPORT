import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:rensius/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object catch (error, stackTrace) {
    debugPrint('Firebase background init skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class FirebaseService {
  FirebaseService._();

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static FirebaseAnalytics? get analytics {
    if (!_isInitialized) return null;
    return FirebaseAnalytics.instance;
  }

  static FirebaseMessaging? get messaging {
    if (!_isInitialized) return null;
    return FirebaseMessaging.instance;
  }

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _isInitialized = true;

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      try {
        await _configureMessaging();
      } on Object catch (error, stackTrace) {
        debugPrint('Firebase Messaging setup skipped: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      try {
        await logAppOpen();
      } on Object catch (error, stackTrace) {
        debugPrint('Firebase Analytics setup skipped: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      return true;
    } on UnsupportedError catch (error) {
      debugPrint(error.message);
      return false;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Firebase initialization failed: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } on Object catch (error, stackTrace) {
      debugPrint('Firebase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static Future<NotificationSettings?> requestNotificationPermission() async {
    final firebaseMessaging = messaging;
    if (firebaseMessaging == null) return null;

    return firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<String?> getFcmToken() async {
    return messaging?.getToken();
  }

  static Future<void> subscribeToTopic(String topic) async {
    await messaging?.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await messaging?.unsubscribeFromTopic(topic);
  }

  static Stream<RemoteMessage> get foregroundMessages {
    return FirebaseMessaging.onMessage;
  }

  static Future<void> logAppOpen() async {
    await analytics?.logAppOpen();
  }

  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    await analytics?.logEvent(name: name, parameters: parameters);
  }

  static Future<void> _configureMessaging() async {
    final firebaseMessaging = FirebaseMessaging.instance;

    await firebaseMessaging.setAutoInitEnabled(true);
    await requestNotificationPermission();

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification opened: ${message.messageId}');
    });
  }
}
