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
import '../models/review_model.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String role;

  const DashboardPage({super.key, required this.username, required this.role});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Semua';

  static const List<CategoryItem> _categories = [
    CategoryItem('All'),
    CategoryItem('Favorite', Icons.bookmark_outline),
    CategoryItem('Mini Soccer', Icons.sports_soccer),
    CategoryItem('Soccer', Icons.sports_soccer),
  ];

  static String _monthName(int month) {
    const names = [
      '',
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // If navigating back to Home (index 0), reset category to 'Semua'
      if (index == 0) {
        _selectedCategory = 'Semua';
      }
    });
  }

  // Helper function to switch to Venue tab with specific category
  void _navigateToVenueWithCategory(String category) {
    setState(() {
      _selectedIndex = 1; // Index 1 is VenuePage
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      VenuePage(initialShowFavorites: _selectedCategory == 'Favorite'),
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
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.stadium_outlined),
            activeIcon: Icon(Icons.stadium),
            label: 'Venue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_basketball_outlined),
            activeIcon: Icon(Icons.sports_basketball),
            label: 'Activities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
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
                      Text('Hello, ${widget.username}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text('Your Location', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildCircleIcon(Icons.notifications_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotifikasiPage()));
                }),
                const SizedBox(width: 8),
                _buildCircleIcon(Icons.chat_bubble_outline, () {}),
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
                      TextSpan(text: 'Recommended '),
                      TextSpan(text: 'Venue', style: TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text('Find the best venues to play!', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 20),
                _buildVenueCard(),
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
      decoration: InputDecoration(
        hintText: 'Search Venue',
        prefixIcon: const Icon(Icons.search),
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
        Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(_monthName(_selectedDate.month), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          ],
        ),
        GestureDetector(
          onTap: () => setState(() => _selectedDate = DateTime.now()),
          child: const Text('Reset & Restart', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildVenueCard() {
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
              _buildVenueHeader(),
              const Divider(height: 1),
              _buildCourtItem('BEC Tennis Court Lap.A'),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Divider(height: 1)),
              _buildCourtItem('BEC Tennis Court Lap.B'),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVenueHeader() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingPage(
              username: widget.username,
              venueName: 'Bandung Elektrik Cigereleng Tennis Court',
              venueType: 'Tennis',
              venueAddress: 'Jl. PLN Cigereleng No.19, Ciseureuh, Kota Bandung',
              venueHours: '06:00 - 22:00',
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
                  const Text('Bandung Elektrik Cigereleng Tennis Court', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  _buildVenueStats(),
                  const SizedBox(height: 4),
                  _buildIconText(Icons.location_on, 'Jl. PLN Cigereleng No.19, Ciseureuh, Kota Bandung'),
                  const SizedBox(height: 4),
                  _buildIconText(Icons.sports_tennis, 'Tennis'),
                  const SizedBox(height: 8),
                  const Text('IDR 100,000 ~ IDR 125,000', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueStats() {
    final venueName = 'Bandung Elektrik Cigereleng Tennis Court';
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
        const SizedBox(width: 4),
        Text(Review.getAverageRating(venueName).toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
        const SizedBox(width: 4),
        Text('(${Review.mockReviews.where((r) => r.venueName == venueName).length} reviews)', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
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

  Widget _buildCourtItem(String name) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourtDetailPage(
              username: widget.username,
              courtName: name,
              venueName: 'Bandung Elektrik Cigereleng Tennis Court',
              sportType: 'Tenis',
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
                Expanded(child: _buildCourtInfo(name)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Choose booking schedule:', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            _buildTimeSlotsRow(name),
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

  Widget _buildCourtInfo(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.sports_tennis, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            const Text('Tennis', style: TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(width: 10),
            Icon(Icons.grid_on, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            const Text('L 23 X W 10', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Learn More >', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTimeSlotsRow(String courtName) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTimeSlot(courtName, '08:00', isAvailable: true),
          _buildTimeSlot(courtName, '10:00', isAvailable: true),
          _buildTimeSlot(courtName, '11:00', isAvailable: true),
          _buildTimeSlot(courtName, '12:00', isAvailable: true),
          _buildTimeSlot(courtName, '13:00', isAvailable: true),
          _buildTimeSlot(courtName, '14:00', isAvailable: true),
          _buildTimeSlot(courtName, '16:00', isAvailable: true),
          _buildTimeSlot(courtName, '18:00', isAvailable: true),
          _buildTimeSlot(courtName, '20:00', isAvailable: true),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String courtName, String time, {required bool isAvailable}) {
    final todayStr = BookingUtils.formatDate(DateTime.now());
    final isBooked = BookingUtils.isSlotBooked(
      venueName: 'Bandung Elektrik Cigereleng Tennis Court',
      courtName: courtName,
      dateStr: todayStr,
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
                      courtName: courtName,
                      initialSelectedSlot: timeRange,
                    ),
                  ),
                );
              }
            : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: effectiveAvailable ? AppColors.primary : Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: effectiveAvailable ? AppColors.primary : Colors.grey.shade400,
            fontSize: 12,
            fontWeight: effectiveAvailable ? FontWeight.w600 : FontWeight.normal,
            decoration: null, // No strikethrough
          ),
        ),
      ),
    );
  }
}
