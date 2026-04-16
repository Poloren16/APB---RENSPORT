import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'notifikasi.dart';
import 'akun_page.dart';
import 'venue_page.dart';
import 'booking_history.dart';
import '../widgets/shared/venue_date_picker.dart';
import '../widgets/shared/venue_category_chips.dart';
import 'booking_page.dart';
import 'court_detail_page.dart';
import '../models/review_model.dart';
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
    CategoryItem('Semua'),
    CategoryItem('Favorite', Icons.bookmark_outline),
    CategoryItem('Mini Soccer', Icons.sports_soccer),
    CategoryItem('Sepak Bola', Icons.sports_soccer),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      const VenuePage(),
      const BookingHistoryPage(),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container 1: Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    'G',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${widget.username}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            'Lokasimu',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotifikasiPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          // Container 2: Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari Venue',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                VenueCategoryChips(
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (cat) =>
                      setState(() => _selectedCategory = cat),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          _monthName(_selectedDate.month),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey[600]),
                      ],
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDate = DateTime.now()),
                      child: const Text(
                        'Reset & Mulai Ulang',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                VenueDatePicker(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) =>
                      setState(() => _selectedDate = date),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Container 3: Recommendations
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
                Text(
                  'Temukan venue terbaik untuk bermain!',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
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



  Widget _buildVenueCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Venue info header zone
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookingPage(
                        venueName: 'Bandung Elektrik Cigereleng Tennis Court',
                        venueType: 'Tenis',
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
                        child: Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 50, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bandung Elektrik Cigereleng Tennis Court',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text(
                                  Review.getAverageRating('Bandung Elektrik Cigereleng Tennis Court').toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${Review.mockReviews.where((r) => r.venueName == 'Bandung Elektrik Cigereleng Tennis Court').length} ulasan)',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                const Expanded(
                                  child: Text(
                                    'Jl. PLN Cigereleng No.19, Ciseureuh, Kota Bandung',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.sports_tennis, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                const Text(
                                  'Tenis',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Rp100.000 ~ Rp125.000',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Divider(height: 1),

              // Sub-Venue (Courts) List
              _buildCourtItem('BEC Tennis Court Lap.A'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Divider(height: 1),
              ),
              _buildCourtItem('BEC Tennis Court Lap.B'),
              
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourtItem(String name) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourtDetailPage(
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 30, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.sports_tennis, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          const Text('Tenis', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(width: 10),
                          Icon(Icons.grid_on, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          const Text('P 23 X L 10', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Selengkapnya >',
                        style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Pilih jadwal booking:',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTimeSlot(name, '08:00', isAvailable: true),
                  _buildTimeSlot(name, '10:00', isAvailable: true),
                  _buildTimeSlot(name, '12:00', isAvailable: false),
                  _buildTimeSlot(name, '14:00', isAvailable: false),
                  _buildTimeSlot(name, '16:00', isAvailable: true),
                  _buildTimeSlot(name, '18:00', isAvailable: true),
                  _buildTimeSlot(name, '20:00', isAvailable: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String courtName, String time, {required bool isAvailable}) {
    // Helper to map simplified time to range
    String timeRange = '$time - ${int.parse(time.split(':')[0]) + 1}:00';
    if (timeRange.length < 13) {
      if (int.parse(time.split(':')[0]) + 1 < 10) {
        timeRange = '$time - 0${int.parse(time.split(':')[0]) + 1}:00';
      }
    }

    return GestureDetector(
      onTap: isAvailable ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourtDetailPage(
              courtName: courtName,
              venueName: 'Bandung Elektrik Cigereleng Tennis Court',
              sportType: 'Tenis',
              initialSelectedSlot: timeRange,
            ),
          ),
        );
      } : () {},
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isAvailable ? Colors.black : Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
