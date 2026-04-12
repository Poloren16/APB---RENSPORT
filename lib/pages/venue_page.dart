import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
<<<<<<< HEAD
import '../data/venue_data.dart';
=======

>>>>>>> a301a937d336de204cafa46fa4686289bc1dac3b
class VenuePage extends StatefulWidget {
  const VenuePage({super.key});

  @override
  State<VenuePage> createState() => _VenuePageState();
}

class _VenuePageState extends State<VenuePage> {
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
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip('Semua', isSelected: true),
                  _buildCategoryChip('Favorite', icon: Icons.bookmark_outline),
                  _buildCategoryChip('Mini Soccer', icon: Icons.sports_soccer),
                  _buildCategoryChip('Sepak Bola', icon: Icons.sports_soccer),
                ],
              ),
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
                        const Text(
                          'April',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                      ],
                    ),
                    const Text(
                      'Reset & Mulai Ulang',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildDatePicker(),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Venue Card Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
<<<<<<< HEAD
            child: Column(
              children: GlobalVenueData.venues.map((v) => _buildDetailedVenueCard(v)).toList(),
            ),
=======
            child: _buildDetailedVenueCard(),
>>>>>>> a301a937d336de204cafa46fa4686289bc1dac3b
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, {bool isSelected = false, IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 16, color: isSelected ? AppColors.primary : Colors.grey[600]),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    List<Map<String, String>> days = [
      {'day': 'Rab', 'date': '8'},
      {'day': 'Kam', 'date': '9'},
      {'day': 'Jum', 'date': '10'},
      {'day': 'Sab', 'date': '11'},
      {'day': 'Min', 'date': '12'},
      {'day': 'Sen', 'date': '13'},
      {'day': 'Sel', 'date': '14'},
    ];

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          bool isSelected = index == 4;
          return Container(
            width: 55,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  days[index]['day']!,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  days[index]['date']!,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildDetailedVenueCard(Map<String, dynamic> venue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
=======
  Widget _buildDetailedVenueCard() {
    return Container(
>>>>>>> a301a937d336de204cafa46fa4686289bc1dac3b
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
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
<<<<<<< HEAD
                      Text(
                        venue['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
=======
                      const Text(
                        'Bandung Elektrik Cigereleng Tennis Court',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
>>>>>>> a301a937d336de204cafa46fa4686289bc1dac3b
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
<<<<<<< HEAD
                          Expanded(
                            child: Text(
                              venue['location'] ?? '',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
=======
                          const Expanded(
                            child: Text(
                              'Jl. PLN Cigereleng No.19, Ciseureu...',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
>>>>>>> a301a937d336de204cafa46fa4686289bc1dac3b
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
<<<<<<< HEAD
                          Text(
                            venue['type'] ?? '',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
=======
                          const Text(
                            'Tenis',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
>>>>>>> a301a937d336de204cafa46fa4686289bc1dac3b
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
<<<<<<< HEAD
                      Text(
                        venue['price'] ?? '',
                        style: const TextStyle(
=======
                      const Text(
                        'Rp125.000 ~ Rp175.000',
                        style: TextStyle(
>>>>>>> a301a937d336de204cafa46fa4686289bc1dac3b
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
          
<<<<<<< HEAD
          if (venue['courts'] != null && (venue['courts'] as List).isNotEmpty)
            const Divider(height: 1),

          if (venue['courts'] != null)
            ...(venue['courts'] as List).map((court) => _buildCourtItem(court)),
=======
          const Divider(height: 1),

          // Sub-Venue (Courts) List
          _buildCourtItem('BEC Tennis Court Lap.A'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Divider(height: 1),
          ),
          _buildCourtItem('BEC Tennis Court Lap.B'),
>>>>>>> a301a937d336de204cafa46fa4686289bc1dac3b
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildCourtItem(Map<String, dynamic> court) {
=======
  Widget _buildCourtItem(String name) {
>>>>>>> a301a937d336de204cafa46fa4686289bc1dac3b
    return Padding(
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
<<<<<<< HEAD
                      court['name'] ?? '',
=======
                      name,
>>>>>>> a301a937d336de204cafa46fa4686289bc1dac3b
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
<<<<<<< HEAD
                        Icon(Icons.grid_on, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(court['size'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
=======
                        Icon(Icons.sports_tennis, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        const Text('Tenis', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(width: 10),
                        Icon(Icons.grid_on, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        const Text('P 23 X L 10', style: TextStyle(color: Colors.grey, fontSize: 11)),
>>>>>>> a301a937d336de204cafa46fa4686289bc1dac3b
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
<<<<<<< HEAD
              children: (court['schedules'] as List? ?? []).map<Widget>((schedule) {
                return _buildTimeSlot(schedule['time'] ?? '', isAvailable: schedule['isAvailable'] ?? true);
              }).toList(),
=======
              children: [
                _buildTimeSlot('14:00', isAvailable: false),
                _buildTimeSlot('15:00', isAvailable: false),
                _buildTimeSlot('16:00', isAvailable: false),
                _buildTimeSlot('17:00', isAvailable: false),
                _buildTimeSlot('18:00', isAvailable: true),
                _buildTimeSlot('19:00', isAvailable: true),
              ],
>>>>>>> a301a937d336de204cafa46fa4686289bc1dac3b
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String time, {required bool isAvailable}) {
    return Container(
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
    );
  }
}
