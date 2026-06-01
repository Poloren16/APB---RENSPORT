import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../theme/app_colors.dart';
import '../widgets/shared/venue_category_chips.dart';
import '../widgets/shared/venue_date_picker.dart';
import 'booking_page.dart';
import 'court_detail_page.dart';
import '../models/review_model.dart';
import '../utils/booking_utils.dart';
import '../widgets/empty_state_widget.dart';
import '../data/venue_data.dart';
import 'keranjang_page.dart';

class VenuePage extends StatefulWidget {
  final String username;
  final String role;
  final bool initialShowFavorites;
  final String? initialCategory;
  final DateTime? initialDate;

  const VenuePage({
    super.key, 
    this.username = 'User', 
    this.role = 'End User', 
    this.initialShowFavorites = false,
    this.initialCategory,
    this.initialDate,
  });

  @override
  State<VenuePage> createState() => _VenuePageState();
}

class _VenuePageState extends State<VenuePage> {
  late DateTime _selectedDate;
  late String _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  static const List<CategoryItem> _categories = [
    CategoryItem('Semua'),
    CategoryItem('Favorit', Icons.bookmark_outline),
    CategoryItem('Mini Soccer', Icons.sports_soccer),
    CategoryItem('Sepak Bola', Icons.sports_soccer),
    CategoryItem('Badminton', Icons.sports_tennis),
    CategoryItem('Tennis', Icons.sports_tennis),
    CategoryItem('Futsal', Icons.sports_soccer),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedCategory = widget.initialCategory ?? (widget.initialShowFavorites ? 'Favorit' : 'Semua');
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _monthName(int month) {
    const names = [
      '',
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return names[month];
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
    bool isShowingFavorites = _selectedCategory == 'Favorit' || _selectedCategory == 'Favorite';
    
    // Logic to determine which venues to show
    List<Map<String, dynamic>> displayedVenues;
    if (isShowingFavorites) {
      displayedVenues = GlobalVenueData.favorites;
    } else if (_selectedCategory == 'Semua') {
      displayedVenues = GlobalVenueData.venues;
    } else {
      displayedVenues = GlobalVenueData.venues
          .where((v) => v['type'] == _selectedCategory)
          .toList();
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      displayedVenues = displayedVenues.where((v) {
        return (v['name'] ?? '').toLowerCase().contains(query) ||
               (v['location'] ?? '').toLowerCase().contains(query) ||
               (v['address'] ?? '').toLowerCase().contains(query);
      }).toList();
    }

    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: statusBarHeight + 135,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0A1975), // Rich deep navy blue
                          Color(0xFF152FD6), // Bright dynamic royal blue
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: statusBarHeight + 14,
                      left: 24,
                      right: 24,
                      bottom: 28,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.stadium_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isShowingFavorites ? 'Venue Favorit' : 'Temukan Venue',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isShowingFavorites 
                                    ? 'Daftar lapangan pilihan Anda' 
                                    : 'Pilih lapangan dan mulai bermain!',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => KeranjangPage(
                                  username: widget.username,
                                  role: widget.role,
                                ),
                              ),
                            );
                            setState(() {}); // Refresh lencana merah notifikasi saat kembali dari keranjang!
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                                ),
                                child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                              ),
                              if (GlobalVenueData.cart.isNotEmpty)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF152FD6), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                        )
                                      ]
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 10,
                                      minHeight: 10,
                                    ),
                                  ),
                                )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: -22,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari Venue',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                          suffixIcon: _searchController.text.isNotEmpty 
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20, color: Colors.grey), 
                                  onPressed: () => _searchController.clear(),
                                ) 
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    
              const SizedBox(height: 38),
  
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
                      GestureDetector(
                        onTap: _selectDateViaCalendar,
                        child: Row(
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
                  if (displayedVenues.isEmpty)
                    isShowingFavorites 
                      ? EmptyStateWidget(
                          message: 'Belum ada venue favorit',
                          subMessage: 'Tandai venue favoritmu untuk menemukannya di sini dengan mudah!',
                          onActionPressed: () => setState(() => _selectedCategory = 'Semua'),
                          actionLabel: 'Cari Venue',
                          actionIcon: Icons.search_rounded,
                        )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: EmptyStateWidget(
                              message: 'Tidak ada venue ditemukan untuk kategori ini.',
                              actionLabel: _selectedCategory != 'Semua' ? 'Tampilkan Semua' : null,
                              onActionPressed: () => setState(() => _selectedCategory = 'Semua'),
                            ),
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
      ),
    ),
    );
  }

  // Helper: hitung harga terkecil-terbesar dari semua courts
  String _getPriceDisplay(Map<String, dynamic> venue) {
    final courts = venue['courts'] as List<dynamic>? ?? [];
    final prices = <int>[];
    for (final c in courts) {
      final cMap = Map<String, dynamic>.from(c as Map);
      final priceMode = cMap['priceMode'] ?? 'perDay';
      if (priceMode == 'perSlot') {
        final pricePerSlot = cMap['pricePerSlot'] as Map? ?? {};
        for (final val in pricePerSlot.values) {
          final v = val?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
          if (v.isNotEmpty) {
            final n = int.tryParse(v);
            if (n != null && n > 0) prices.add(n);
          }
        }
      } else {
        final priceDay = cMap['priceDay'] as Map? ?? {};
        for (final val in priceDay.values) {
          final v = val?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
          if (v.isNotEmpty) {
            final n = int.tryParse(v);
            if (n != null && n > 0) prices.add(n);
          }
        }
      }
    }
    if (prices.isEmpty) {
      final priceVal = venue['price'];
      if (priceVal == null) return 'Hubungi Pengelola';
      if (priceVal is int) return 'Rp ${priceVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}/jam';
      return priceVal.toString();
    }
    prices.sort();
    final min = prices.first;
    final max = prices.last;
    String fmt(int n) => 'Rp ${n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    return min == max ? '${fmt(min)}/jam' : '${fmt(min)} - ${fmt(max)}/jam';
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
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingPage(
                        username: widget.username,
                        venueName: venueName,
                        venueType: venue['type'] ?? 'Olahraga',
                        venueAddress: venue['address'] ?? venue['location'] ?? '',
                        venueHours: venue['hours'] ?? '06:00 - 22:00',
                      ),
                    ),
                  );
                  setState(() {}); // Refresh red notification badge upon returning!
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Builder(builder: (context) {
                          final imgPath = venue['image']?.toString() ?? '';
                          if (imgPath.isNotEmpty) {
                            final isRemote = imgPath.startsWith('http://') || imgPath.startsWith('https://');
                            final isAsset = imgPath.startsWith('assets/');
                            if (isRemote) {
                              return Image.network(
                                imgPath,
                                width: 120, height: 120, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 120, height: 120, color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                ),
                              );
                            } else if (isAsset) {
                              return Image.asset(
                                imgPath,
                                width: 120, height: 120, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 120, height: 120, color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                ),
                              );
                            } else {
                              return Image.file(
                                File(imgPath),
                                width: 120, height: 120, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 120, height: 120, color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                ),
                              );
                            }
                          }
                          return Container(
                            width: 120, height: 120, color: Colors.grey[300],
                            child: const Icon(Icons.stadium, size: 50, color: Colors.grey),
                          );
                        }),
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
                                Icon(_getSportIcon(venue['type'] ?? 'Olahraga'), size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  venue['type'] ?? 'Olahraga',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _getPriceDisplay(venue),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
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
                    _buildCourtItem(venueName, court, venue),
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

  void _goToCourtDetail(String venueName, String courtName, String sportType, {String? initialSlot}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourtDetailPage(
          username: widget.username,
          role: widget.role,
          courtName: courtName,
          venueName: venueName,
          sportType: sportType,
          initialSelectedSlot: initialSlot,
          initialSelectedDate: _selectedDate,
        ),
      ),
    );
    setState(() {}); // Refresh red notification badge upon returning!
  }

  Widget _buildSmallImage(String courtImg) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Builder(builder: (context) {
        final isRemote = courtImg.startsWith('http://') || courtImg.startsWith('https://');
        final isAsset = courtImg.startsWith('assets/');
        if (isRemote) {
          return Image.network(
            courtImg,
            width: 60, height: 60, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );
        } else if (isAsset) {
          return Image.asset(
            courtImg,
            width: 60, height: 60, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );
        } else {
          return Image.file(
            File(courtImg),
            width: 60, height: 60, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );
        }
      }),
    );
  }

  Widget _buildCourtItem(String venueName, Map<String, dynamic> court, Map<String, dynamic> venue) {
    final String courtName = court['name'] ?? 'Unknown Court';
    final String sportType = court['type'] ?? 'Tenis';
    final String courtImg = court['image']?.toString() ?? '';
    final bool hasImg = courtImg.isNotEmpty;

    return InkWell(
      onTap: () => _goToCourtDetail(venueName, courtName, sportType),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (hasImg) ...[
                  _buildSmallImage(courtImg),
                  const SizedBox(width: 12),
                ],
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
                          Icon(_getSportIcon(sportType), size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(sportType, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(width: 10),
                          Icon(Icons.grid_on, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(court['size'] ?? 'Standar', style: const TextStyle(color: Colors.grey, fontSize: 11)),
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
              child: Builder(builder: (context) {
                // Ambil hari aktif dari nama hari sesuai tanggal yang dipilih
                const dayNames = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
                final dayIdx = _selectedDate.weekday - 1; // 1=Mon..7=Sun
                final activeDay = dayNames[dayIdx];
                final availability = court['availability'] as Map? ?? {};
                final slots = availability[activeDay] as List<dynamic>? ?? [];
                if (slots.isEmpty) {
                  return const Text('Tidak ada jadwal', style: TextStyle(color: Colors.grey, fontSize: 11));
                }
                final sortedSlots = List<String>.from(slots)..sort();
                return Row(
                  children: sortedSlots.map((time) =>
                    _buildTimeSlot(venueName, courtName, sportType, time, isAvailable: true)
                  ).toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String venueName, String courtName, String sportType, String time, {required bool isAvailable}) {
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
          ? () => _goToCourtDetail(venueName, courtName, sportType, initialSlot: timeRange)
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

  IconData _getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'futsal':
        return Icons.sports_soccer_outlined;
      case 'sepak bola':
      case 'mini soccer':
        return Icons.sports_soccer;
      case 'badminton':
        return Icons.sports_tennis_rounded;
      case 'tennis':
      case 'tenis':
        return Icons.sports_tennis;
      case 'basket':
      case 'basketball':
        return Icons.sports_basketball;
      case 'voli':
      case 'volleyball':
        return Icons.sports_volleyball;
      default:
        return Icons.sports_soccer_outlined;
    }
  }
}
