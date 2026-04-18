import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'management_venue.dart';
import '../login_page.dart';
import '../../data/venue_data.dart';
import '../../models/review_model.dart';
import '../notifikasi.dart';
import '../akun_page.dart';

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
      const ManagementVenuePage(),
      const Center(child: Text('Laporan Pendapatan', style: TextStyle(fontSize: 18))),
      AkunPage(username: widget.username, role: widget.role),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: pages[_selectedIndex],
      ),
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
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
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
          const SizedBox(height: 24),
          const Text(
            'Review Venue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildVenueReviews(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary,
          child: Text(
            widget.username.isNotEmpty ? widget.username[0].toUpperCase() : 'O',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${widget.username}',
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
        _buildStatCard('Booking Hari Ini', '12', Icons.calendar_today, Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard('Pendapatan', 'Rp 2.4jt', Icons.payments_outlined, Colors.green),
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
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(backgroundColor: AppColors.secondary, child: Icon(Icons.person, color: AppColors.primary)),
            title: const Text('Budi Santoso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('BEC Tennis Court Lap.A • 18:00', style: TextStyle(fontSize: 12)),
            trailing: const Text('Rp 125rb', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          );
        },
      ),
    );
  }

  Widget _buildVenueReviews() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildReviewItem('Andi', 'Tempatnya bersih dan lampunya terang.', 5),
          const Divider(),
          _buildReviewItem('Sari', 'Sangat puas dengan pelayanannya.', 4),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, String comment, int rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Row(children: List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, size: 14, color: Colors.orange))),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
