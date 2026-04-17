import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../widgets/booking/venue_header_slivers.dart';
import '../widgets/shared/venue_date_picker.dart';
import '../widgets/booking/court_slots_card.dart';
import '../widgets/booking/venue_contact_section.dart';
import 'court_detail_page.dart';
import 'payment_page.dart';
import '../models/review_model.dart';
import '../utils/booking_utils.dart';

class BookingPage extends StatefulWidget {
  final String username;
  final String venueName;
  final String venueType;
  final String venueAddress;
  final String venueHours;

  const BookingPage({
    super.key,
    this.username = 'User',
    this.venueName = 'Bandung Elektrik Cigereleng Tennis Court',
    this.venueType = 'Tenis',
    this.venueAddress = 'Jl. PLN Cigereleng No.19, Ciseureuh, K...',
    this.venueHours = '06:00 - 22:00',
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedSlots = {};

  final List<String> _tabs = ['Select Schedule', 'Service'];

  // Slot waktu
  final List<Map<String, dynamic>> _timeSlots = [
    {'time': '06:00 - 07:00', 'price': 100000, 'originalPrice': 125000, 'available': true, 'booked': false},
    {'time': '07:00 - 08:00', 'price': 100000, 'originalPrice': 125000, 'available': true, 'booked': false},
    {'time': '08:00 - 09:00', 'price': 100000, 'originalPrice': 125000, 'available': true, 'booked': false},
    {'time': '09:00 - 10:00', 'price': 100000, 'originalPrice': 125000, 'available': true, 'booked': false},
    {'time': '10:00 - 11:00', 'price': 100000, 'originalPrice': 125000, 'available': true, 'booked': false},
    {'time': '11:00 - 12:00', 'price': 100000, 'originalPrice': 125000, 'available': true, 'booked': false},
    {'time': '12:00 - 13:00', 'price': 100000, 'originalPrice': 125000, 'available': false, 'booked': true},
    {'time': '13:00 - 14:00', 'price': 100000, 'originalPrice': 125000, 'available': true, 'booked': false},
    {'time': '14:00 - 15:00', 'price': 100000, 'originalPrice': 125000, 'available': false, 'booked': true},
    {'time': '15:00 - 16:00', 'price': 125000, 'originalPrice': 150000, 'available': true, 'booked': false},
    {'time': '16:00 - 17:00', 'price': 125000, 'originalPrice': 150000, 'available': true, 'booked': false},
    {'time': '17:00 - 18:00', 'price': 125000, 'originalPrice': 150000, 'available': true, 'booked': false},
    {'time': '18:00 - 19:00', 'price': 125000, 'originalPrice': 150000, 'available': true, 'booked': false},
    {'time': '19:00 - 20:00', 'price': 125000, 'originalPrice': 150000, 'available': true, 'booked': false},
    {'time': '20:00 - 21:00', 'price': 125000, 'originalPrice': 150000, 'available': true, 'booked': false},
    {'time': '21:00 - 22:00', 'price': 125000, 'originalPrice': 150000, 'available': false, 'booked': true},
  ];

  final List<Map<String, dynamic>> _courts = [
    {'name': 'BEC Tennis Court Lap.A', 'type': 'Tenis'},
    {'name': 'BEC Tennis Court Lap.B', 'type': 'Tenis'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'IDR $formatted';
  }

  int get _totalSelected => _selectedSlots.length;
  
  int get _totalPrice => _selectedSlots.fold(0, (sum, key) {
    final parts = key.split('_');
    final slotIndex = int.tryParse(parts[0]) ?? 0;
    return sum + (_timeSlots[slotIndex]['price'] as int);
  });

  String _getMonthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[date.month - 1];
  }

  Widget _buildOperationalRow(String day, String hours, bool isHighlighted) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted ? Border.all(color: AppColors.primary.withOpacity(0.2)) : null,
      ),
      child: Row(
        children: [
          Icon(
            isHighlighted ? Icons.access_time_filled : Icons.access_time,
            size: 20,
            color: isHighlighted ? AppColors.primary : Colors.grey.shade600,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showOperationalHours() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        final currentDayName = days[_selectedDate.weekday % 7];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Operational Hours',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildOperationalRow('Sunday', '06:00 - 22:00', currentDayName == 'Sunday'),
                _buildOperationalRow('Monday', '06:00 - 22:00', currentDayName == 'Monday'),
                _buildOperationalRow('Tuesday', '06:00 - 22:00', currentDayName == 'Tuesday'),
                _buildOperationalRow('Wednesday', '06:00 - 21:00', currentDayName == 'Wednesday'),
                _buildOperationalRow('Thursday', '06:00 - 22:00', currentDayName == 'Thursday'),
                _buildOperationalRow('Friday', '06:00 - 22:00', currentDayName == 'Friday'),
                _buildOperationalRow('Saturday', '06:00 - 22:00', currentDayName == 'Saturday'),
                const SizedBox(height: 16),
                Text(
                  '*Opening hours may change at any time',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'OK, Go Back',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMaps() async {
    final query = Uri.encodeComponent(widget.venueName + ' ' + widget.venueAddress);
    final url = Uri.parse('https://www.openstreetmap.org/search?query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    }
  }

  void _showBookingConfirmation(BuildContext context) {
    final monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Confirmation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${_selectedDate.day} ${monthNames[_selectedDate.month - 1]} ${_selectedDate.year}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.sports_tennis,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '$_totalSelected time slots selected',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Payment',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 15),
                ),
                Text(
                  _formatCurrency(_totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final selectedCourts = <String>{};
                  final selectedTimes = <String>[];
                  for (final key in _selectedSlots) {
                    final parts = key.split('_');
                    final slotIndex = int.tryParse(parts[0]) ?? 0;
                    final courtIndex = int.tryParse(parts[1]) ?? 0;
                    selectedCourts.add(_courts[courtIndex]['name']);
                    selectedTimes.add(_timeSlots[slotIndex]['time'].split(' - ')[0]);
                  }
                  
                  // Sorting the times so they appear chronologically
                  selectedTimes.sort((a, b) {
                    final hA = int.tryParse(a.split(':')[0]) ?? 0;
                    final hB = int.tryParse(b.split(':')[0]) ?? 0;
                    return hA.compareTo(hB);
                  });

                  final dateStr = BookingUtils.formatDate(_selectedDate);
                  
                  // Prepare individual slots for atomic locking
                  final individualSlots = _selectedSlots.map((key) {
                    final parts = key.split('_');
                    final slotIdx = int.tryParse(parts[0]) ?? 0;
                    final courtIdx = int.tryParse(parts[1]) ?? 0;
                    return {
                      'court': _courts[courtIdx]['name'] as String,
                      'time': _timeSlots[slotIdx]['time'] as String,
                    };
                  }).toList();

                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(
                        username: widget.username,
                        venueName: widget.venueName,
                        courtName: selectedCourts.join(', '),
                        date: dateStr,
                        timeRange: '${selectedTimes.length} Time Slots (${selectedTimes.join(', ')})',
                        price: _totalPrice,
                        individualSlots: individualSlots,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm & Pay',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Scrollable Body
          Expanded(
            child: CustomScrollView(
              slivers: [
                VenueHeaderSlivers(
                  venueName: widget.venueName,
                  venueType: widget.venueType,
                  venueHours: widget.venueHours,
                  venueAddress: widget.venueAddress,
                  onShowOperationalHours: _showOperationalHours,
                  onOpenMaps: _openMaps,
                ),

                // Tab Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: _tabs.map((t) => Tab(text: t)).toList(),
                    ),
                  ),
                ),

                // Calendar Section
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  builder: (context, child) => Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppColors.primary,
                                        onPrimary: Colors.white,
                                        onSurface: AppColors.textPrimary,
                                      ),
                                    ),
                                    child: child ?? const SizedBox(),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedDate = picked;
                                    _selectedSlots.clear();
                                  });
                                }
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, color: AppColors.primary, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getMonthName(_selectedDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 18,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 20),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                _selectedDate = DateTime.now();
                                _selectedSlots.clear();
                              }),
                              child: const Text(
                                'Reset & Restart',
                                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: VenueDatePicker(
                          selectedDate: _selectedDate,
                          onDateSelected: (date) {
                            setState(() {
                              _selectedDate = date;
                              _selectedSlots.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Court Headers + Time Slots
                SliverToBoxAdapter(
                  child: CourtSlotsCard(
                    venueName: widget.venueName,
                    dateStr: BookingUtils.formatDate(_selectedDate),
                    courts: _courts,
                    timeSlots: _timeSlots,
                    selectedSlots: _selectedSlots,
                    onSlotSelected: (slotKey) {
                      setState(() {
                        if (_selectedSlots.contains(slotKey)) {
                          _selectedSlots.remove(slotKey);
                        } else {
                          _selectedSlots.add(slotKey);
                        }
                      });
                    },
                    formatCurrency: _formatCurrency,
                    onCourtTap: (court) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourtDetailPage(
                            username: widget.username,
                            courtName: court['name'] as String,
                            venueName: widget.venueName,
                            sportType: court['type'] as String,
                            dimensions: 'P 23 X L 10',
                            courtCategory: 'Outdoor',
                            floorType: 'Vinyl',
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Player Reviews Section
                SliverToBoxAdapter(
                  child: _buildPlayerReviewsSection(),
                ),

                // Venue Contact and Recommendation Section
                SliverToBoxAdapter(
                  child: VenueContactSection(
                    formatCurrency: _formatCurrency,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Booking Bar
          if (_selectedSlots.isNotEmpty)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_totalSelected slots selected',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatCurrency(_totalPrice),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _showBookingConfirmation(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerReviewsSection() {
    var venueReviews = Review.mockReviews.where((r) => r.venueName == widget.venueName).toList();
    venueReviews.sort((a, b) => b.date.compareTo(a.date));
    if (venueReviews.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Player Reviews',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    Review.getAverageRating(widget.venueName).toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' (${venueReviews.length})',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: venueReviews.length > 3 ? 3 : venueReviews.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final review = venueReviews[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          review.username[0],
                          style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        review.username,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '${review.date.day} ${_getMonthName(review.date)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) => Icon(
                      i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 14,
                      color: Colors.orange,
                    )),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.comment,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                ],
              );
            },
          ),
          if (venueReviews.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: GestureDetector(
                  onTap: () => _showAllReviews(context, venueReviews),
                  child: Text(
                    'Show All ${venueReviews.length} Reviews',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAllReviews(BuildContext context, List<Review> reviews) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'All Reviews',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  review.username[0],
                                  style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review.username,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    Row(
                                      children: [
                                        Row(
                                          children: List.generate(5, (i) => Icon(
                                            i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                            size: 14,
                                            color: Colors.orange,
                                          )),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${review.date.day} ${_getMonthName(review.date)} ${review.date.year}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            review.comment,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 6),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

}

// Sticky tab bar delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          tabBar,
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}
