import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/venue_date_picker.dart';
import 'payment_page.dart';
import '../models/review_model.dart';
import '../utils/alert_utils.dart';
import '../utils/booking_utils.dart';
import '../data/venue_data.dart';

class CourtDetailPage extends StatefulWidget {
  final String username;
  final String courtName;
  final String venueName;
  final String sportType;
  final String dimensions;
  final String courtCategory;
  final String floorType;
  final String role;

  const CourtDetailPage({
    super.key,
    this.username = 'User',
    this.role = 'End User',
    this.courtName = 'BEC Tennis Court Court A',
    this.venueName = 'Bandung Elektrik Cigereleng Tennis Court',
    this.sportType = 'Tennis',
    this.dimensions = 'L 23 X W 10',
    this.courtCategory = 'Outdoor',
    this.floorType = 'Vinyl',
    this.initialSelectedSlot,
  });

  final String? initialSelectedSlot;

  @override
  State<CourtDetailPage> createState() => _CourtDetailPageState();
}

class _CourtDetailPageState extends State<CourtDetailPage>
    with SingleTickerProviderStateMixin {
  static const Color _accent = AppColors.primary;

  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedSlots = {};
  final Set<int> _expandedGroups = {};
  final Map<String, int> _selectedServices = {};

  static const List<_TimeGroup> _timeGroups = [
    _TimeGroup(
      period: 'Pagi ke Siang',
      range: '06:00 - 10:00',
      icon: Icons.wb_twilight_rounded,
      slots: [
        _TimeSlot('06:00 - 07:00', 150000, 125000, true),
        _TimeSlot('07:00 - 08:00', 150000, 125000, true),
        _TimeSlot('08:00 - 09:00', 150000, 125000, true),
        _TimeSlot('09:00 - 10:00', 150000, 125000, true),
      ],
    ),
    _TimeGroup(
      period: 'Siang ke Sore',
      range: '10:00 - 16:00',
      icon: Icons.wb_sunny_rounded,
      slots: [
        _TimeSlot('10:00 - 11:00', 150000, 125000, true),
        _TimeSlot('11:00 - 12:00', 150000, 125000, true),
        _TimeSlot('12:00 - 13:00', 150000, 125000, true),
        _TimeSlot('13:00 - 14:00', 150000, 125000, true),
        _TimeSlot('14:00 - 15:00', 150000, 125000, true),
        _TimeSlot('15:00 - 16:00', 150000, 125000, true),
      ],
    ),
    _TimeGroup(
      period: 'Sore ke Malam',
      range: '16:00 - 22:00',
      icon: Icons.nightlight_round,
      slots: [
        _TimeSlot('16:00 - 17:00', 175000, 125000, true),
        _TimeSlot('17:00 - 18:00', 175000, 150000, true),
        _TimeSlot('18:00 - 19:00', 175000, 150000, true),
        _TimeSlot('19:00 - 20:00', 175000, 150000, true),
        _TimeSlot('20:00 - 21:00', 175000, 150000, true),
        _TimeSlot('21:00 - 22:00', 175000, 150000, false),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    
    if (widget.initialSelectedSlot != null) {
      String? foundKey;
      for (int g = 0; g < _timeGroups.length; g++) {
        for (int s = 0; s < _timeGroups[g].slots.length; s++) {
          if (_timeGroups[g].slots[s].time == widget.initialSelectedSlot) {
            foundKey = '${g}_$s';
            _expandedGroups.add(g);
            break;
          }
        }
        if (foundKey != null) break;
      }
      if (foundKey != null) {
        _selectedSlots.add(foundKey);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    return 'IDR ${price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    )}';
  }

  int get _totalPrice {
    int total = _selectedSlots.fold(0, (sum, key) {
      final parts = key.split('_');
      final g = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      return sum + _timeGroups[g].slots[s].price;
    });

    _selectedServices.forEach((id, qty) {
      final venueResults = GlobalVenueData.venues.where((v) => v['name'] == widget.venueName);
      final venue = venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
      final services = venue['services'] as List<dynamic>? ?? [];
      final serviceResults = services.where((s) => s['id'] == id);
      if (serviceResults.isNotEmpty) {
        final service = serviceResults.first;
        total += (service['price'] as int) * qty;
      }
    });

    return total;
  }

  String get _bookingPeriod {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month + 1, 0);
    const m = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${now.day} ${m[now.month]} ${now.year} - ${end.day} ${m[end.month]} ${end.year}';
  }

  List<String> get _selectedTimeStrings {
    final times = _selectedSlots.map((key) {
      final parts = key.split('_');
      final g = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      return _timeGroups[g].slots[s].time.split(' - ')[0];
    }).toList();
    times.sort();
    return times;
  }

  static String _monthName(int month) {
    const names = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return names[month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourtInfoCard(),
                  const SizedBox(height: 8),
                  _buildCourtSpecsCard(),
                  const SizedBox(height: 8),
                  _buildPlayerReviewsSection(),
                  const SizedBox(height: 8),
                  _buildBookingSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: Colors.black87, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Detail Lapangan',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      actions: const [],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  Widget _buildCourtInfoCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image, size: 40, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.courtName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.sports_tennis,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(widget.sportType,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(width: 8),
                    Text('•',
                        style: TextStyle(color: Colors.grey.shade400)),
                    const SizedBox(width: 8),
                    Icon(Icons.grid_on,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(widget.dimensions,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtSpecsCard() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _buildSpecItem('Tipe Lapangan', widget.courtCategory),
          Container(width: 1, height: 50, color: Colors.grey.shade200),
          _buildSpecItem('Tipe Lantai', widget.floorType),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerReviewsSection() {
    final venueReviews = Review.mockReviews.where((r) => r.venueName == widget.venueName).toList();
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apa kata pemain tentang lapangan ini',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (venueReviews.isNotEmpty) ...[
            Text(
              '⭐ ${Review.getAverageRating(widget.venueName).toStringAsFixed(1)} dari total ${venueReviews.length} ulasan pemain',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildReviewChip('🏟️', 'Fasilitas Bagus', 3),
              _buildReviewChip('👍', 'Tempat Bersih', 3),
              _buildReviewChip('⚡', 'Fasilitas Lengkap', 2),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReviewChip(String emoji, String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$label ($count)',
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildBookingSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black54,
                indicator: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Harian'),
                  Tab(text: 'Layanan'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (_tabController.index == 0) ...[
            const Text(
              'Pilih Jadwal Booking',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          size: 18, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(
                        _monthName(_selectedDate.month),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 18, color: Colors.black54),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedDate = DateTime.now();
                      _selectedSlots.clear();
                      _expandedGroups.clear();
                    }),
                    child: const Text(
                      'Reset & Ulang',
                      style: TextStyle(
                          color: _accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VenueDatePicker(
                selectedDate: _selectedDate,
                onDateSelected: (date) => setState(() {
                  _selectedDate = date;
                  _selectedSlots.clear();
                  _expandedGroups.clear();
                }),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: RichText(
                text: TextSpan(
                  style:
                      const TextStyle(fontSize: 12, color: Colors.black54),
                  children: [
                    const TextSpan(
                      text: '*Periode Tanggal Booking: ',
                      style: TextStyle(
                          color: _accent, fontWeight: FontWeight.w500),
                    ),
                    TextSpan(text: _bookingPeriod),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._timeGroups.asMap().entries.map(
                  (e) => _buildTimeGroup(e.key, e.value),
                ),
          ] else ...[
            _buildServicesList(),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTimeGroup(int groupIdx, _TimeGroup group) {
    final available =
        group.slots.where((s) => s.isAvailable).length;
    final isExpanded = _expandedGroups.contains(groupIdx);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedGroups.remove(groupIdx);
                } else {
                  _expandedGroups.add(groupIdx);
                }
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(group.icon, color: _accent, size: 26),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.period,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(group.range,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '$available Slot Tersedia',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade400),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 90,
              ),
              itemCount: group.slots.length,
              itemBuilder: (context, idx) {
                final slot = group.slots[idx];
                final key = '${groupIdx}_$idx';
                final isSelected = _selectedSlots.contains(key);
                return _buildSlotCard(slot, key, isSelected);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotCard(_TimeSlot slot, String key, bool isSelected) {
    final dateStr = BookingUtils.formatDate(_selectedDate);
    final isAlreadyBooked = BookingUtils.isSlotBooked(
      venueName: widget.venueName,
      courtName: widget.courtName,
      dateStr: dateStr,
      timeSlot: slot.time,
    );
    final bool isBooked = !slot.isAvailable || isAlreadyBooked;
    return GestureDetector(
      onTap: isBooked ? null : () => setState(() {
        if (isSelected) {
          _selectedSlots.remove(key);
        } else {
          _selectedSlots.add(key);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isBooked
              ? Colors.grey.shade50
              : isSelected
                  ? _accent.withValues(alpha: 0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _accent : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isBooked
                    ? Colors.grey.shade400
                    : isSelected
                        ? _accent
                        : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            if (!isBooked)
              Text(
                _formatPrice(slot.price),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _accent : AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasSelection = _selectedSlots.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSelection
                      ? '${_selectedSlots.length} slot dipilih'
                      : 'Belum ada slot',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  _formatPrice(_totalPrice),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasSelection ? AppColors.primary : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          // Tombol Keranjang (DI SINI - Samping Kiri)
          Container(
            height: 48,
            width: 48,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: hasSelection ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasSelection ? Colors.orange : Colors.grey.shade200,
              ),
            ),
            child: IconButton(
              onPressed: hasSelection 
                ? () {
                    final dateStr = BookingUtils.formatDate(_selectedDate);
                    final selectedTimes = _selectedTimeStrings;
                    GlobalVenueData.addToCart({
                      'venueName': widget.venueName,
                      'courtName': widget.courtName,
                      'date': dateStr,
                      'timeSlot': '${selectedTimes.length} Slot: ${selectedTimes.join(', ')}',
                      'price': _totalPrice,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Berhasil ditambahkan ke keranjang!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                : null,
              icon: Icon(
                Icons.add_shopping_cart_rounded, 
                color: hasSelection ? Colors.orange : Colors.grey.shade400,
                size: 20,
              ),
            ),
          ),
          // Tombol Pesan Sekarang
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: hasSelection
                  ? () {
                      final selectedTimes = _selectedTimeStrings;
                      final dateStr = BookingUtils.formatDate(_selectedDate);
                      final individualSlots = _selectedSlots.map((key) {
                        final parts = key.split('_');
                        final g = int.tryParse(parts[0]) ?? 0;
                        final s = int.tryParse(parts[1]) ?? 0;
                        return {
                          'court': widget.courtName,
                          'time': _timeGroups[g].slots[s].time,
                        };
                      }).toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(
                            username: widget.username,
                            role: widget.role,
                            venueName: widget.venueName,
                            courtName: widget.courtName,
                            date: dateStr,
                            timeRange: '${selectedTimes.length} Slot Waktu (${selectedTimes.join(', ')})',
                            price: _totalPrice,
                            individualSlots: individualSlots,
                            selectedServices: _selectedServices,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.grey.shade400,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Pesan Sekarang',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    final venueResults = GlobalVenueData.venues.where((v) => v['name'] == widget.venueName);
    final venue = venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
    final services = venue['services'] as List<dynamic>? ?? [];
    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text(
                'Tidak ada layanan tambahan tersedia di venue ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: services.map((service) => _buildServiceItem(service as Map<String, dynamic>)).toList(),
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final id = service['id'] as String;
    final name = service['name'] as String;
    final price = service['price'] as int;
    final stock = service['stock'] as int;
    final unit = service['unit'] as String;
    final currentQty = _selectedServices[id] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: _accent),
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
                Text(
                  '${_formatPrice(price)} / $unit',
                  style: const TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 12),
                ),
                Text(
                  'Stok: $stock',
                  style: TextStyle(color: stock == 0 ? Colors.red : Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: currentQty > 0
                    ? () {
                        setState(() {
                          if (currentQty > 1) {
                            _selectedServices[id] = currentQty - 1;
                          } else {
                            _selectedServices.remove(id);
                          }
                        });
                      }
                    : null,
                icon: Icon(Icons.remove_circle_outline, color: currentQty > 0 ? _accent : Colors.grey),
                iconSize: 22,
              ),
              const SizedBox(width: 8),
              Text(
                '$currentQty',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: currentQty < stock
                    ? () {
                        setState(() {
                          _selectedServices[id] = currentQty + 1;
                        });
                      }
                    : null,
                icon: Icon(Icons.add_circle_outline, color: currentQty < stock ? _accent : Colors.grey),
                iconSize: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeGroup {
  final String period;
  final String range;
  final IconData icon;
  final List<_TimeSlot> slots;
  const _TimeGroup({
    required this.period,
    required this.range,
    required this.icon,
    required this.slots,
  });
}

class _TimeSlot {
  final String time;
  final int originalPrice;
  final int price;
  final bool isAvailable;
  const _TimeSlot(this.time, this.originalPrice, this.price, this.isAvailable);
}
