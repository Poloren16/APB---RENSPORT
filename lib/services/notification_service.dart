import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    try {
      await _notificationsPlugin.initialize(initializationSettings);
      
      // Buat notification channel khusus Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'rensius_notifications', // id
        'Notifikasi Rensius', // name
        description: 'Digunakan untuk notifikasi sistem Rensius', // description
        importance: Importance.max,
      );

      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Gagal inisialisasi local notification: $e');
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'rensius_notifications',
      'Notifikasi Rensius',
      channelDescription: 'Digunakan untuk notifikasi sistem Rensius',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Gagal memicu local notification: $e');
    }
  }
}
