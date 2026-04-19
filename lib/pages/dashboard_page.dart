import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/booking_utils.dart';
import 'notifikasi.dart';
import 'akun_page.dart';
import 'venue_page.dart';
import 'booking_history.dart';
import '../widgets/shared/venue_date_picker.dart';
import '../widgets/shared/venue_category_chips.dart';
import 'booking_page.dart';
import 'court_detail_page.dart';
import 'chat_page.dart';
import '../models/review_model.dart';
import '../data/chat_data.dart';
import '../data/notification_data.dart';
import '../data/venue_data.dart';
import '../widgets/empty_state_widget.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String role;
  final int initialIndex;

  const DashboardPage({
    super.key,
    required this.username,
    required this.role,
    this.initialIndex = 0,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late int _selectedIndex;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const List<CategoryItem> _categories = [
    CategoryItem('Semua'),
    CategoryItem('Favorit', Icons.bookmark_outline),
    CategoryItem('Mini Soccer', Icons.sports_soccer),
    CategoryItem('Sepak Bola', Icons.sports_soccer),
    CategoryItem('Badminton', Icons.sports_tennis),
    CategoryItem('Tennis', Icons.sports_tennis),
  ];

  static String _monthName(int month) {
    const names = [
      '',
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return names[month];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _selectedCategory = 'Semua';
        _searchController.clear();
      }
    });
  }

  void _navigateToVenueWithCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedIndex = 1;
    });
  }

  Future<void> _selectDateViaCalendar() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      VenuePage(
        username: widget.username, 
        role: widget.role, 
        initialCategory: _selectedCategory == 'Favorit' ? 'Favorite' : _selectedCategory,
        initialDate: _selectedDate,
      ),
      BookingHistoryPage(username: widget.username),
      AkunPage(username: widget.username, role: widget.role),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.stadium_outlined),
            activeIcon: Icon(Icons.stadium),
            label: 'Venue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_basketball_outlined),
            activeIcon: Icon(Icons.sports_basketball),
            label: 'Aktivitas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHomeContent() {
    // Determine filtered venues
    final List<Map<String, dynamic>> allVenues = GlobalVenueData.venues;
    final String query = _searchController.text.toLowerCase();
    final bool isShowingFavorites = _selectedCategory == 'Favorit';
    
    final List<Map<String, dynamic>> filteredVenues = allVenues.where((v) {
      final bool isApproved = v['status'] == 'Aktif';
      final bool matchesCategory = _selectedCategory == 'Semua' || 
                                  isShowingFavorites || 
                                  v['type'] == _selectedCategory;
      final bool matchesSearch = (v['name'] ?? '').toLowerCase().contains(query) || 
                                (v['location'] ?? '').toLowerCase().contains(query) ||
                                (v['type'] ?? '').toLowerCase().contains(query);
      return isApproved && matchesCategory && matchesSearch;
    }).toList();

    // Show top 5 or all if filtered
    final List<Map<String, dynamic>> displayVenues = query.isEmpty && _selectedCategory == 'Semua' 
        ? filteredVenues.take(5).toList() 
        : filteredVenues;

    final bool hasNoResults = filteredVenues.isEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo, ${widget.username}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text('Lokasi Kamu', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    _buildCircleIcon(Icons.notifications_outlined, () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => NotifikasiPage(username: widget.username, role: widget.role)));
                      setState(() {});
                    }),
                    if (GlobalNotificationData.getUnreadCount(widget.username, widget.role) > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            GlobalNotificationData.getUnreadCount(widget.username, widget.role).toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    _buildCircleIcon(Icons.chat_bubble_outline, () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(username: widget.username, role: widget.role)));
                      setState(() {});
                    }),
                    if (GlobalChatData.getTotalUnreadCount(widget.username, widget.role) > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            GlobalChatData.getTotalUnreadCount(widget.username, widget.role).toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 20),
                VenueCategoryChips(
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (cat) {
                    setState(() => _selectedCategory = cat);
                    if (cat == 'Favorite') {
                      _navigateToVenueWithCategory('Favorite');
                    }
                  },
                ),
                const SizedBox(height: 20),
                _buildDateSelector(),
                const SizedBox(height: 15),
                VenueDatePicker(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) => setState(() => _selectedDate = date),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Recommendations
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    children: [
                      TextSpan(text: 'Rekomendasi '),
                      TextSpan(text: 'Venue', style: TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text('Temukan venue terbaik untuk bermain!', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 20),
                if (hasNoResults)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: EmptyStateWidget(
                      message: 'Tidak ada venue yang sesuai dengan filter atau pencarian Anda.',
                      actionLabel: query.isNotEmpty || _selectedCategory != 'Semua' ? 'Reset Filter' : null,
                      onActionPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedCategory = 'Semua';
                        });
                      },
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayVenues.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      return _buildVenueCard(displayVenues[index]);
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: AppColors.primary), onPressed: onTap),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari Venue',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => _searchController.clear()) 
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _selectDateViaCalendar,
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(_monthName(_selectedDate.month), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => setState(() {
            _selectedDate = DateTime.now();
            _selectedCategory = 'Semua';
            _searchController.clear();
          }),
          child: const Text('Reset & Ulang', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildVenueCard(Map<String, dynamic> venue) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVenueHeader(venue),
              if (venue['courts'] != null && (venue['courts'] as List).isNotEmpty) ...[
                const Divider(height: 1),
                ... (venue['courts'] as List).take(1).map((court) => _buildCourtItem(venue, court)),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVenueHeader(Map<String, dynamic> venue) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingPage(
              username: widget.username,
              venueName: venue['name'] ?? 'Venue',
              venueType: venue['type'] ?? 'Umum',
              venueAddress: venue['address'] ?? venue['location'] ?? 'Lokasi',
              venueHours: venue['hours'] ?? '06:00 - 22:00',
            ),
          ),
        );
      },
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(width: 100, height: 100, color: Colors.grey[300], child: const Icon(Icons.image, size: 50, color: Colors.grey)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(venue['name'] ?? 'Venue', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  _buildVenueStats(venue['name']),
                  const SizedBox(height: 4),
                  _buildIconText(Icons.location_on, venue['location'] ?? 'Tidak Diketahui'),
                  const SizedBox(height: 4),
                  _buildIconText(Icons.sports_tennis, venue['type'] ?? 'Umum'),
                  const SizedBox(height: 8),
                  Text(venue['price'] ?? 'Hubungi Pengelola', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueStats(String? venueName) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
        const SizedBox(width: 4),
        Text(Review.getAverageRating(venueName ?? '').toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
        const SizedBox(width: 4),
        Text('(${Review.mockReviews.where((r) => r.venueName == venueName).length} ulasan)', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildCourtItem(Map<String, dynamic> venue, Map<String, dynamic> court) {
    final String courtName = court['name'] ?? 'Lapangan';
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourtDetailPage(
              username: widget.username,
              role: widget.role,
              courtName: courtName,
              venueName: venue['name'] ?? 'Venue',
              sportType: venue['type'] ?? 'Umum',
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSmallImage(),
                const SizedBox(width: 12),
                Expanded(child: _buildCourtInfo(courtName, venue['type'] ?? 'Umum', court['size'] ?? 'Standar')),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Pilih jadwal booking:', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            _buildTimeSlotsRow(venue['name'] ?? '', courtName),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.image, size: 30, color: Colors.grey)),
    );
  }

  Widget _buildCourtInfo(String name, String type, String size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.sports_tennis, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(type, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(width: 10),
            Icon(Icons.grid_on, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(size, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Selengkapnya >', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTimeSlotsRow(String venueName, String courtName) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTimeSlot(venueName, courtName, '08:00', isAvailable: true),
          _buildTimeSlot(venueName, courtName, '10:00', isAvailable: true),
          _buildTimeSlot(venueName, courtName, '11:00', isAvailable: true),
          _buildTimeSlot(venueName, courtName, '12:00', isAvailable: true),
          _buildTimeSlot(venueName, courtName, '13:00', isAvailable: true),
          _buildTimeSlot(venueName, courtName, '14:00', isAvailable: true),
          _buildTimeSlot(venueName, courtName, '16:00', isAvailable: true),
          _buildTimeSlot(venueName, courtName, '18:00', isAvailable: true),
          _buildTimeSlot(venueName, courtName, '20:00', isAvailable: true),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String venueName, String courtName, String time, {required bool isAvailable}) {
    final dateStr = BookingUtils.formatDate(_selectedDate);
    final isBooked = BookingUtils.isSlotBooked(
      venueName: venueName,
      courtName: courtName,
      dateStr: dateStr,
      timeSlot: time,
    );
    final bool effectiveAvailable = isAvailable && !isBooked;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: effectiveAvailable
            ? () {
                final hour = int.tryParse(time.split(':')[0]) ?? 0;
                final nextHour = hour + 1;
                final timeRange = '$time - ${nextHour.toString().padLeft(2, '0')}:00';

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourtDetailPage(
                      username: widget.username,
                      role: widget.role,
                      courtName: courtName,
                      venueName: venueName,
                      initialSelectedSlot: timeRange,
                      initialSelectedDate: _selectedDate,
                    ),
                  ),
                );
              }
            : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveAvailable ? AppColors.primary : Colors.grey.shade400,
          backgroundColor: effectiveAvailable ? Colors.white : Colors.grey.shade100,
          side: BorderSide(color: effectiveAvailable ? AppColors.primary : Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: effectiveAvailable ? AppColors.primary : Colors.grey.shade500,
            fontSize: 12,
            fontWeight: effectiveAvailable ? FontWeight.w600 : FontWeight.normal,
            decoration: null,
          ),
        ),
      ),
    );
  }
}
