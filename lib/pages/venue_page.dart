import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/venue_category_chips.dart';
import '../widgets/shared/venue_date_picker.dart';
import 'booking_page.dart';
import 'court_detail_page.dart';
import '../models/review_model.dart';
import '../utils/booking_utils.dart';
import '../widgets/empty_state_widget.dart';
import '../data/venue_data.dart';

class VenuePage extends StatefulWidget {
  final bool initialShowFavorites;

  const VenuePage({super.key, this.initialShowFavorites = false});

  @override
  State<VenuePage> createState() => _VenuePageState();
}

class _VenuePageState extends State<VenuePage> {
  DateTime _selectedDate = DateTime.now();
  late String _selectedCategory;

  static const List<CategoryItem> _categories = [
    CategoryItem('All'),
    CategoryItem('Favorite', Icons.bookmark_outline),
    CategoryItem('Mini Soccer', Icons.sports_soccer),
    CategoryItem('Soccer', Icons.sports_soccer),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialShowFavorites ? 'Favorite' : 'Semua';
  }

  static String _monthName(int month) {
    const names = [
      '',
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month];
  }

  @override
  Widget build(BuildContext context) {
    bool isShowingFavorites = _selectedCategory == 'Favorite';
    List<Map<String, dynamic>> displayedVenues = isShowingFavorites 
        ? GlobalVenueData.favorites 
        : [
            {
              'name': 'Bandung Elektrik Cigereleng Tennis Court',
              'type': 'Tenis',
              'address': 'Jl. PLN Cigereleng No.19, Ciseureuh, Kota Bandung',
              'hours': '06:00 - 22:00',
              'price': 'Rp125.000 ~ Rp175.000',
              'distance': '3 km',
              'courts': [
                {'name': 'BEC Tennis Court Lap.A', 'type': 'Tenis', 'size': 'P 23 X L 10'},
                {'name': 'BEC Tennis Court Lap.B', 'type': 'Tenis', 'size': 'P 23 X L 10'},
              ]
            }
          ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Stack(
            children: [
              Container(
                height: 130,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.stadium, color: Colors.white, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isShowingFavorites ? 'Venue Favorit Kamu' : 'Temukan Beragam Venue!',
                        style: const TextStyle(
                        'Discover Various Venues!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_basket_outlined, color: Colors.white),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 70, left: 20, right: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Venue',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Categories Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: VenueCategoryChips(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
            ),
          ),

          const SizedBox(height: 20),

          // Date Picker Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          _monthName(_selectedDate.month),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedDate = DateTime.now()),
                      child: const Text(
                        'Reset & Restart',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                VenueDatePicker(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) => setState(() => _selectedDate = date),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Venue Card Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    children: [
                      TextSpan(text: isShowingFavorites ? 'Favorit ' : 'Rekomendasi '),
                      TextSpan(text: 'Venue', style: const TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isShowingFavorites 
                      ? 'Daftar venue yang telah kamu tandai!' 
                      : 'Temukan venue terbaik untuk bermain!',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 20),
                if (isShowingFavorites && displayedVenues.isEmpty)
                  EmptyStateWidget(
                    message: 'Belum ada venue favorit',
                    subMessage: 'Tandai venue favoritmu untuk menemukannya di sini dengan mudah!',
                    onActionPressed: () => setState(() => _selectedCategory = 'Semua'),
                    actionLabel: 'Cari Venue',
                    actionIcon: Icons.search_rounded,
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedVenues.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                    itemBuilder: (context, index) => _buildDetailedVenueCard(displayedVenues[index]),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDetailedVenueCard(Map<String, dynamic> venue) {
    final String venueName = venue['name'] ?? 'Unknown Venue';
    final List<dynamic> courts = venue['courts'] ?? [];

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
                      builder: (context) => BookingPage(
                        venueName: venueName,
                        venueType: venue['type'] ?? 'Olahraga',
                        venueAddress: venue['address'] ?? venue['location'] ?? '',
                        venueHours: venue['hours'] ?? '06:00 - 22:00',
                      builder: (context) => const BookingPage(
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
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                venue['distance'] ?? '3 km',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venueName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text(
                                  Review.getAverageRating(venueName).toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${Review.mockReviews.where((r) => r.venueName == venueName).length})',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    venue['address'] ?? venue['location'] ?? '',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.apartment, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  venue['location']?.split(',').last.trim() ?? 'Kota',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.sports_tennis, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  venue['type'] ?? 'Olahraga',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                const Text(
                                  'Tennis',
                                  style: TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              venue['price'] ?? 'Hubungi Pengelola',
                              style: const TextStyle(
                            const Text(
                              'IDR 125,000 ~ IDR 175,000',
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
              
              if (courts.isNotEmpty) ...[
                const Divider(height: 1),
                ...courts.map((court) => Column(
                  children: [
                    _buildCourtItem(venueName, court),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Divider(height: 1),
                    ),
                  ],
                )).toList(),
              ],
              
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _goToCourtDetail(String venueName, String courtName, String sportType, {String? initialSlot}) {
  void _goToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BookingPage(
          venueName: 'Bandung Elektrik Cigereleng Tennis Court',
          venueType: 'Tennis',
          venueAddress: 'Jl. PLN Cigereleng No.19, Ciseureuh, Kota Bandung',
          venueHours: '06:00 - 22:00',
        ),
      ),
    );
  }

  void _goToCourtDetail(String courtName, {String? initialSlot}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourtDetailPage(
          courtName: courtName,
          venueName: venueName,
          sportType: sportType,
          venueName: 'Bandung Elektrik Cigereleng Tennis Court',
          sportType: 'Tennis',
          initialSelectedSlot: initialSlot,
        ),
      ),
    );
  }

  Widget _buildCourtItem(String venueName, Map<String, dynamic> court) {
    final String courtName = court['name'] ?? 'Unknown Court';
    final String sportType = court['type'] ?? 'Tenis';

    return InkWell(
      onTap: () => _goToCourtDetail(venueName, courtName, sportType),
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
                      courtName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.sports_tennis, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(sportType, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(width: 10),
                        Icon(Icons.grid_on, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(court['size'] ?? 'Standar', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        const Text('Tennis', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(width: 10),
                        Icon(Icons.grid_on, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        const Text('L 23 X W 10', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Learn More >',
                      style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose booking schedule:',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
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
          ),
        ],
      ),
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

    // Helper to map simplified time to range
    final startHour = int.tryParse(time.split(':')[0]) ?? 0;
    final endHour = startHour + 1;
    final timeRange = '$time - ${endHour.toString().padLeft(2, '0')}:00';

    return GestureDetector(
      onTap: effectiveAvailable
          ? () => _goToCourtDetail(venueName, courtName, 'Tenis', initialSlot: timeRange)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: effectiveAvailable ? Colors.white : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: effectiveAvailable ? AppColors.primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: effectiveAvailable ? AppColors.primary : Colors.grey[400],
            fontSize: 12,
            fontWeight: effectiveAvailable ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
