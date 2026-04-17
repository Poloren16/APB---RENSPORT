import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String username;
  final String title;
  final String message;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  bool isRead;

  AppNotification({
    required this.id,
    required this.username,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.color,
    this.isRead = false,
  });
}

class GlobalNotificationData {
  static List<AppNotification> notifications = [];

  static void addNotification(AppNotification notif) {
    notifications.insert(0, notif);
  }

  static List<AppNotification> getNotificationsForUser(String username, String role) {
    // If admin/owner, maybe see all 'admin' notifications. We'll use 'owner' or 'admin' as pseudo-usernames.
    String queryUser = (role == 'Admin' || role == 'Owner') ? 'admin' : username;
    return notifications.where((n) => n.username == queryUser).toList();
  }

  static int getUnreadCount(String username, String role) {
    String queryUser = (role == 'Admin' || role == 'Owner') ? 'admin' : username;
    return notifications.where((n) => n.username == queryUser && !n.isRead).length;
  }

  static void markAllAsRead(String username, String role) {
    String queryUser = (role == 'Admin' || role == 'Owner') ? 'admin' : username;
    for (var n in notifications) {
      if (n.username == queryUser) {
        n.isRead = true;
      }
    }
  }
}
