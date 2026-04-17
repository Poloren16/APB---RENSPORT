import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NotifikasiPage extends StatelessWidget {
  const NotifikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy notification data matching the context of a sports app
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Booking Confirmed!',
        'message': 'Your booking at Gor Laga Tangkas for Futsal is confirmed.',
        'time': '2 mins ago',
        'icon': Icons.check_circle_outline,
        'color': AppColors.accent,
        'isRead': false,
      },
      {
        'title': 'New Match Request',
        'message': 'Budi sent you a request to join the Badminton match.',
        'time': '1 hour ago',
        'icon': Icons.person_add_alt_1,
        'color': AppColors.primary,
        'isRead': false,
      },
      {
        'title': 'Reminder: Upcoming Match',
        'message': 'You have a Basketball match scheduled in 2 hours at GOR Padjadjaran.',
        'time': '2 hours ago',
        'icon': Icons.sports_basketball,
        'color': AppColors.primary,
        'isRead': true,
      },
      {
        'title': 'Promo 50% Off!',
        'message': 'Book a venue this weekend and get 50% off. Limited time only!',
        'time': '1 day ago',
        'icon': Icons.local_offer_outlined,
        'color': Colors.redAccent,
        'isRead': true,
      },
      {
        'title': 'Review Your Experience',
        'message': 'How was your recent visit to Gor Saparua? Leave a review!',
        'time': '2 days ago',
        'icon': Icons.star_rate_outlined,
        'color': Colors.amber,
        'isRead': true,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
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
                      color: notif['isRead']
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
                        backgroundColor: notif['color'].withValues(alpha: 0.1),
                        radius: 24,
                        child: Icon(
                          notif['icon'],
                          color: notif['color'],
                        ),
                      ),
                      title: Text(
                        notif['title'],
                        style: TextStyle(
                          fontWeight: notif['isRead']
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
                              notif['message'],
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notif['time'],
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
