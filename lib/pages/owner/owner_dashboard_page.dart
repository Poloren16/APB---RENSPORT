import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'management_venue.dart';
import '../booking_history.dart';
import '../notifikasi.dart';
import '../akun_page.dart';
import '../chat_page.dart';
import 'owner_activity_page.dart';
import '../../widgets/empty_state_widget.dart';
import '../../data/venue_data.dart';
import '../../utils/booking_utils.dart';
import 'package:rensius/services/booking_service.dart';
import '../chat_detail_page.dart';
import '../receipt_page.dart';


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
  final List<int> _navigationHistory = [0];

  @override
  void initState() {
    super.initState();
    // Sync data venue terbaru saat owner login
    GlobalVenueData.init();
    BookingService.loadBookings(widget.username, widget.role);
    BookingUtils.loadGlobalBookingsOnline();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _navigationHistory.add(index);
      _selectedIndex = index;
    });
  }

  void _onBackFromTab() {
    if (_navigationHistory.length > 1) {
      setState(() {
        _navigationHistory.removeLast(); // Remove current tab
        _selectedIndex = _navigationHistory.last;
      });
    } else {
      setState(() {
        _selectedIndex = 0; // Fallback to Home
        _navigationHistory.clear();
        _navigationHistory.add(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      ManagementVenuePage(
        ownerUsername: widget.username,
        onBack: _onBackFromTab,
      ),
      OwnerActivityPage(username: widget.username),
      ChatPage(
        username: widget.username, 
        role: widget.role, 
        onBack: _onBackFromTab,
      ),
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
    final ownerVenues = GlobalVenueData.getVenuesForOwner(widget.username)
        .map((v) => v['name'] as String)
        .toSet();

    final all = [...BookingHistoryPage.mockHistory, ...BookingHistoryPage.mockPastHistory];
    final ownerBookings = all.where((b) => ownerVenues.contains(b['venueName'])).toList();

    // 1. Booking Hari Ini
    final todayStr = BookingUtils.formatDate(DateTime.now());
    final todayBookingsCount = ownerBookings.where((b) => b['date'] == todayStr).length;

    // 2. Pendapatan — hitung semua status yang sudah bayar
    final totalRevenue = ownerBookings.fold(0, (sum, b) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      // Termasuk: sudah bayar (menunggu jadwal) dan yang sudah selesai
      final isPaid = status == 'confirmed' ||
          status == 'pembayaran berhasil' ||
          status == 'menunggu jadwal' ||
          status == 'selesai' ||
          status == 'completed';
      if (!isPaid) return sum;
      return sum + (int.tryParse(b['price'].toString()) ?? 0);
    });

    return Row(
      children: [
        _buildStatCard('Booking Hari Ini', '$todayBookingsCount', Icons.calendar_today, Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard('Pendapatan', _formatCurrency(totalRevenue), Icons.payments_outlined, Colors.green),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailPage(
                          username: booking['username'] ?? '',
                          venueName: booking['venueName'] ?? '',
                          role: widget.role,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  _buildActionIcon(Icons.receipt_long_outlined, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceiptPage(booking: booking),
                      ),
                    );
                  }),

                ],
              ),
            ],
          ),
          Builder(
            builder: (context) {
              List<String> servicesList = [];
              final rawServices = booking['services'];
              if (rawServices != null) {
                if (rawServices is List) {
                  servicesList = rawServices.map((e) => e.toString()).toList();
                } else if (rawServices is String && rawServices.isNotEmpty) {
                  final String cleanServices = rawServices.contains('|slots:')
                      ? rawServices.split('|slots:')[0].trim()
                      : rawServices.trim();
                  if (cleanServices.isNotEmpty) {
                    servicesList = cleanServices.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  }
                }
              }

              if (servicesList.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  const Text('Layanan Tambahan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: servicesList.map((s) => Container(
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
              );
            }
          ),
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
