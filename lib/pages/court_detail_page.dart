import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/venue_date_picker.dart';
import 'payment_page.dart';
import '../models/review_model.dart';

class CourtDetailPage extends StatefulWidget {
  final String courtName;
  final String venueName;
  final String sportType;
  final String dimensions;
  final String courtCategory;
  final String floorType;

  const CourtDetailPage({
    super.key,
    this.courtName = 'BEC Tennis Court Lap.A',
    this.venueName = 'Bandung Elektrik Cigereleng Tennis Court',
    this.sportType = 'Tenis',
    this.dimensions = 'P 23 X L 10',
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
  // ── Warna accent mengikuti tema utama aplikasi ──────────────────────────────
  static const Color _accent = AppColors.primary;

  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedSlots = {};
  final Set<int> _expandedGroups = {};

  // ── Data slot waktu ──────────────────────────────────────────────────────────
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
    
    // Find key for initial selected slot if provided
    if (widget.initialSelectedSlot != null) {
      String? foundKey;
      for (int g = 0; g < _timeGroups.length; g++) {
        for (int s = 0; s < _timeGroups[g].slots.length; s++) {
          if (_timeGroups[g].slots[s].time == widget.initialSelectedSlot) {
            foundKey = '${g}_$s';
            
            // Also ensure the group is expanded so the user sees their selection
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

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatPrice(int price) {
    return 'Rp${price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    )}';
  }

  int get _totalPrice => _selectedSlots.fold(0, (sum, key) {
        final parts = key.split('_');
        final g = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        return sum + _timeGroups[g].slots[s].price;
      });

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
      return _timeGroups[g].slots[s].time.split(' - ')[0]; // e.g. "06:00"
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

  // ── Build ────────────────────────────────────────────────────────────────────

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

  // ── AppBar ───────────────────────────────────────────────────────────────────

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
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded, color: _accent),
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  // ── Court info card ──────────────────────────────────────────────────────────

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

  // ── Court specs card (Tipe Lapangan | Tipe Lantai) ───────────────────────────

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

  // ── Player reviews ───────────────────────────────────────────────────────────

  Widget _buildPlayerReviewsSection() {
    final canReview = Review.canUserReview('Salsabila', widget.courtName);
    final courtReviews = Review.mockReviews.where((r) => r.courtName == widget.courtName).toList();
    
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lapangan ini menurut Players',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (canReview)
                TextButton.icon(
                  onPressed: () => _showReviewDialog(),
                  icon: const Icon(Icons.rate_review_outlined, size: 16, color: _accent),
                  label: const Text('Tulis Ulasan', style: TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.bold)),
                )
              else
                const Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text('Sudah diulas', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (courtReviews.isNotEmpty) ...[
            Text(
              '⭐ ${Review.getAverageRating(widget.venueName).toStringAsFixed(1)} dari total ${courtReviews.length} ulasan Player',
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
        ],
      ),
    );
  }

  void _showReviewDialog() {
    double selectedRating = 5;
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tulis Ulasan Lapangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => GestureDetector(
                  onTap: () => setDialogState(() => selectedRating = index + 1.0),
                  child: Icon(
                    index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.orange,
                    size: 36,
                  ),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Bagaimana pengalamanmu bermain di sini?',
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (commentController.text.isEmpty) return;
                
                setState(() {
                  Review.mockReviews.add(Review(
                    username: 'Salsabila',
                    venueName: widget.venueName,
                    courtName: widget.courtName,
                    rating: selectedRating,
                    comment: commentController.text,
                    date: DateTime.now(),
                  ));
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ulasan berhasil dikirim!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
              child: const Text('Kirim Ulasan'),
            ),
          ],
        ),
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

  // ── Booking section ──────────────────────────────────────────────────────────

  Widget _buildBookingSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Tab Harian / Membership
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
                  Tab(text: 'Membership'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // "Pilih Jadwal Booking" header
          const Text(
            'Pilih Jadwal Booking',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 12),

          // Month row + reset
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
                    'Reset & Mulai Ulang',
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

          // Date picker (reusable)
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

          // Period info
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

          // Time groups
          ..._timeGroups.asMap().entries.map(
                (e) => _buildTimeGroup(e.key, e.value),
              ),

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
          // Section header
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
                    '$available Jadwal Tersedia',
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
            // 2-column grid of slots
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: 64, // Ukuran di-fix agar tidak terlalu besar (gede banget)
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

  Widget _buildSlotCard(
      _TimeSlot slot, String key, bool isSelected) {
    final bool isBooked = !slot.isAvailable;

    return GestureDetector(
      onTap: isBooked
          ? null
          : () => setState(() {
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
              ? Colors.white
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
            if (isBooked)
              Text(
                'Booked',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
              )
            else ...[
              Text(
                _formatPrice(slot.price),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _accent : AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final hasSelection = _selectedSlots.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
            child: Text(
              hasSelection
                  ? '${_selectedSlots.length} slot dipilih • ${_formatPrice(_totalPrice)}'
                  : 'Silahkan pilih jadwal booking',
              style: TextStyle(
                fontSize: 13,
                color: hasSelection
                    ? Colors.black87
                    : Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: hasSelection
                  ? () {
                      final selectedTimes = _selectedTimeStrings;
                      final dateStr = '${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(
                            venueName: widget.venueName,
                            courtName: widget.courtName,
                            date: dateStr,
                            timeRange: '${selectedTimes.length} Slot Waktu (${selectedTimes.join(', ')})',
                            price: _totalPrice,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                disabledBackgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.grey.shade400,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(Icons.shopping_cart_rounded, size: 16),
              label: Text(
                hasSelection ? 'Pesan Sekarang' : 'Belum Dipilih',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

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

  const _TimeSlot(
      this.time, this.originalPrice, this.price, this.isAvailable);
}
