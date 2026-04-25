import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'management_venue.dart';
import '../notifikasi.dart';
import '../akun_page.dart';
import '../chat_page.dart';
import 'owner_activity_page.dart';
import '../../widgets/empty_state_widget.dart';
import '../../data/auth_data.dart';
import '../../data/venue_data.dart';
import '../../utils/booking_utils.dart';

class OwnerDashboardPage extends StatefulWidget {
  final String username;
  final String role;

  const OwnerDashboardPage({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      ManagementVenuePage(ownerUsername: widget.username),
      OwnerActivityPage(username: widget.username),
      ChatPage(username: widget.username, role: widget.role),
      AkunPage(
        username: widget.username, 
        role: widget.role,
        onNavigateToVenue: () => _onItemTapped(1),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.stadium_outlined),
            activeIcon: Icon(Icons.stadium),
            label: 'Venue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
          const Text(
            'Pesanan Terbaru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRecentBookings(),
          const SizedBox(height: 32),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader() {
    final account = GlobalAuthData.getAccount(widget.username);
    final displayName = account?.applicantName ?? widget.username;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'O';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary,
          child: Text(
            initial,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $displayName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Pantau bisnis venue Anda hari ini.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotifikasiPage(
                username: widget.username,
                role: widget.role,
              )
            )
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard('Booking Hari Ini', '0', Icons.calendar_today, Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard('Pendapatan', 'Rp 0', Icons.payments_outlined, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookings() {
    // Filter by owner's venues
    final ownerVenues = GlobalVenueData.getVenuesForOwner(widget.username)
        .map((v) => v['name'] as String)
        .toSet();

    final recentBookings = BookingUtils
        .getTransactionsForOwner(null)
        .where((b) => ownerVenues.contains(b['venueName']))
        .toList()
        .reversed
        .take(5)
        .toList();

    if (recentBookings.isEmpty) {
            return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const EmptyStateWidget(
          message: 'Belum Ada Pesanan',
          subMessage: 'Pantau terus bisnis Anda, pesanan terbaru akan muncul di sini!',
        ),
      );
    }

    return Column(
      children: recentBookings.map((booking) => _buildBookingItem(booking)).toList(),
    );
  }

  Widget _buildBookingItem(Map<String, dynamic> booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.secondary,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking['courtName'] ?? booking['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(booking['venueName'] ?? booking['court'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(booking['time'] ?? '-', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              // Tombol Chat & Rincian di sisi kanan atas pesanan
              Row(
                children: [
                  _buildActionIcon(Icons.chat_bubble_outline, () {
                    // Logika ke halaman chat
                  }),
                  const SizedBox(width: 8),
                  _buildActionIcon(Icons.receipt_long_outlined, () {}),
                ],
              ),
            ],
          ),
          if ((booking['services'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text('Layanan Tambahan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (booking['services'] as List).map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Text(s, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran:', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                _formatCurrency((booking['price'] is int) 
                    ? booking['price'] as int 
                    : int.tryParse(booking['price'].toString()) ?? 0),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp$formatted';
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
    );
  }
}
