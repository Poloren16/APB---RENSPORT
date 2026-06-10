import 'package:flutter/material.dart';
import 'package:rensius/services/supabase_service.dart';

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

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      timestamp: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString()).toLocal()
          : DateTime.now(),
      icon: IconData(
        (map['icon_code'] as int?) ?? Icons.notifications.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      color: Color((map['color_value'] as int?) ?? Colors.blue.value),
      isRead: map['is_read'] == true,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'username': username,
      'title': title,
      'message': message,
      'icon_code': icon.codePoint,
      'color_value': color.value.toSigned(32),
      'is_read': isRead,
      'created_at': timestamp.toUtc().toIso8601String(),
    };
  }
}

class GlobalNotificationData {
  /// In-memory list of notifications (cache dari Supabase)
  static List<AppNotification> notifications = [];

  // ===========================================================================
  // SUPABASE ONLINE OPERATIONS
  // ===========================================================================

  /// Memuat notifikasi dari Supabase berdasarkan username dan role.
  /// Panggil saat halaman notifikasi dibuka atau saat login.
  static Future<void> loadNotifications(String username, String role) async {
    if (!SupabaseService.isInitialized) return;
    try {
      final queryUser = (role == 'Admin' || role == 'Owner') ? 'admin' : username;

      final response = await SupabaseService.client
          .from('notifications')
          .select()
          .or('username.eq.$queryUser,username.eq.all')
          .order('created_at', ascending: false);

      notifications = response
          .map<AppNotification>((row) => AppNotification.fromMap(row))
          .toList();
    } catch (e) {
      debugPrint('Gagal memuat notifikasi dari Supabase: $e');
    }
  }

  /// Menambahkan notifikasi baru ke Supabase dan ke in-memory list.
  static Future<void> addNotification(AppNotification notif) async {
    // Tambahkan ke memory terlebih dahulu (optimistic)
    notifications.insert(0, notif);

    if (!SupabaseService.isInitialized) return;
    try {
      await SupabaseService.client
          .from('notifications')
          .upsert(notif.toSupabaseMap());
    } catch (e) {
      debugPrint('Gagal menyimpan notifikasi ke Supabase: $e');
    }
  }

  /// Mendapatkan daftar notifikasi untuk user/role tertentu (dari cache).
  static List<AppNotification> getNotificationsForUser(String username, String role) {
    final queryUser = (role == 'Admin' || role == 'Owner') ? 'admin' : username;
    final now = DateTime.now();
    return notifications
        .where((n) =>
            (n.username == queryUser || n.username == 'all') &&
            !n.timestamp.isAfter(now))
        .toList();
  }

  /// Mendapatkan jumlah notifikasi yang belum dibaca (dari cache).
  static int getUnreadCount(String username, String role) {
    final queryUser = (role == 'Admin' || role == 'Owner') ? 'admin' : username;
    final now = DateTime.now();
    return notifications
        .where((n) =>
            (n.username == queryUser || n.username == 'all') &&
            !n.isRead &&
            !n.timestamp.isAfter(now))
        .length;
  }

  /// Menandai semua notifikasi user ini sebagai sudah dibaca (lokal + Supabase).
  static Future<void> markAllAsRead(String username, String role) async {
    final queryUser = (role == 'Admin' || role == 'Owner') ? 'admin' : username;

    // Update memory cache
    for (var n in notifications) {
      if (n.username == queryUser || n.username == 'all') {
        n.isRead = true;
      }
    }

    // Update ke Supabase
    if (!SupabaseService.isInitialized) return;
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .or('username.eq.$queryUser,username.eq.all');
    } catch (e) {
      debugPrint('Gagal menandai notifikasi sebagai sudah dibaca di Supabase: $e');
    }
  }
}
