import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/venue_category_chips.dart';
import '../widgets/shared/venue_date_picker.dart';
import 'booking_page.dart';

class VenuePage extends StatefulWidget {
  const VenuePage({super.key});

  @override
  State<VenuePage> createState() => _VenuePageState();
}

class _VenuePageState extends State<VenuePage> {
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
  @override
  Widget build(BuildContext context) {
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
                    const Expanded(
                      child: Text(
                        'Temukan Beragam Venue!',
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
                            color: Colors.white.withOpacity(0.2),
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari Venue',
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
                        'Reset & Mulai Ulang',
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
            child: _buildDetailedVenueCard(),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDetailedVenueCard() {
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
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Main Venue Info
          Padding(
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
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '3 km',
                          style: TextStyle(color: Colors.white, fontSize: 10),
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
                      const Text(
                        'Bandung Elektrik Cigereleng Tennis Court',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Jl. PLN Cigereleng No.19, Ciseureu...',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
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
                          const Text(
                            'Bandung',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
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
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Rp125.000 ~ Rp175.000',
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
      ),
    );
  }

  void _goToBooking() {
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
  }

  Widget _buildCourtItem(String name) {
    return InkWell(
      onTap: _goToBooking,
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
                _buildTimeSlot('14:00', isAvailable: false),
                _buildTimeSlot('15:00', isAvailable: false),
                _buildTimeSlot('16:00', isAvailable: false),
                _buildTimeSlot('17:00', isAvailable: false),
                _buildTimeSlot('18:00', isAvailable: true),
                _buildTimeSlot('19:00', isAvailable: true),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTimeSlot(String time, {required bool isAvailable}) {
    return GestureDetector(
      onTap: isAvailable ? _goToBooking : null,
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
            decoration: isAvailable ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }
}
