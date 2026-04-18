import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/notification_data.dart';
import '../widgets/empty_state_widget.dart';

class NotifikasiPage extends StatefulWidget {
  final String username;
  final String role;

  const NotifikasiPage({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  @override
  void initState() {
    super.initState();
    // Mark as read when opened
    GlobalNotificationData.markAllAsRead(widget.username, widget.role);
  }

  String _formatTime(DateTime time) {
    if (DateTime.now().difference(time).inDays == 0 && DateTime.now().day == time.day) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }

  @override
  Widget build(BuildContext context) {
    final List<AppNotification> notifications = 
        GlobalNotificationData.getNotificationsForUser(widget.username, widget.role);


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: notifications.isEmpty
          ? const EmptyStateWidget(
              message: 'Belum ada notifikasi.',
              subMessage: 'Kami akan memberitahu Anda ketika ada sesuatu yang penting terjadi.',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: notif.isRead
                          ? AppColors.surface
                          : AppColors.secondary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: notif.color.withOpacity(0.1),
                        radius: 24,
                        child: Icon(
                          notif.icon,
                          color: notif.color,
                        ),
                      ),
                      title: Text(
                        notif.title,
                        style: TextStyle(
                          fontWeight: notif.isRead
                              ? FontWeight.w600
                              : FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.message,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(notif.timestamp),
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        // Handle notification tap
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
