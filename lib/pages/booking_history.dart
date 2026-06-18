import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/review_model.dart';
import '../utils/alert_utils.dart';
import 'package:rensius/pages/receipt_page.dart';
import 'package:rensius/pages/venue_page.dart';
import 'package:rensius/widgets/empty_state_widget.dart';
import 'package:rensius/services/booking_service.dart';
import 'package:rensius/services/review_service.dart';
import 'package:rensius/data/auth_data.dart';
import 'package:rensius/utils/booking_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/midtrans_service.dart';
import '../data/notification_data.dart';
import '../services/notification_service.dart';

class BookingHistoryPage extends StatefulWidget {
  final String username;
  final VoidCallback? onNavigateToVenue;
  const BookingHistoryPage({
    super.key, 
    this.username = 'User',
    this.onNavigateToVenue,
  });

  static List<Map<String, dynamic>> mockHistory = [];

  static List<Map<String, dynamic>> mockPastHistory = [];

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class TimeRange {
  final int startHour;
  final int endHour;
  TimeRange(this.startHour, this.endHour);
}

class SplitSlot {
  final Map<String, dynamic> parentBooking;
  final String venueName;
  final String courtName;
  final String date;
  final int startHour;
  final int endHour;

  SplitSlot({
    required this.parentBooking,
    required this.venueName,
    required this.courtName,
    required this.date,
    required this.startHour,
    required this.endHour,
  });
}

class MergedSlot {
  final String venueName;
  final String courtName;
  final String date;
  final int startHour;
  final int endHour;
  final List<Map<String, dynamic>> parentBookings;

  MergedSlot({
    required this.venueName,
    required this.courtName,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.parentBookings,
  });

  String get timeRangeStr {
    final startStr = '${startHour.toString().padLeft(2, '0')}:00';
    final endStr = '${endHour.toString().padLeft(2, '0')}:00';
    return '$startStr - $endStr';
  }

  String getDynamicStatus() {
    final firstBooking = parentBookings.first;
    final baseOid = _BookingHistoryPageState._getBaseOrderId(firstBooking['orderId']?.toString() ?? '');
    final overrideKey = '$baseOid|$courtName|$date|$startHour';
    if (_BookingHistoryPageState._manuallyCompletedSlots.contains(overrideKey)) {
      return 'Selesai';
    }

    final hasSelesaiStatus = parentBookings.any((b) {
      final s = b['status']?.toString().toLowerCase();
      return s == 'selesai' || s == 'completed';
    });
    if (hasSelesaiStatus) {
      return 'Selesai';
    }

    final dateVal = BookingUtils.parseDateStr(date);
    if (dateVal != null) {
      final now = DateTime.now();
      final startDateTime = DateTime(dateVal.year, dateVal.month, dateVal.day, startHour, 0);
      final endDateTime = DateTime(dateVal.year, dateVal.month, dateVal.day, endHour, 0);
      
      if (now.isAfter(endDateTime)) {
        return 'Selesai';
      } else if (now.isAfter(startDateTime) && now.isBefore(endDateTime)) {
        return 'Sedang Berlangsung';
      } else {
        return 'Menunggu Jadwal';
      }
    }
    return 'Menunggu Jadwal';
  }
}

class _BookingHistoryPageState extends State<BookingHistoryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static final Set<String> _manuallyCompletedSlots = {};

  late TabController _tabController;
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'Semua';

  bool _isLoadingBookings = false;
  Timer? _countdownRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });
    _searchController.addListener(() => setState(() {}));
    _refreshBookingsOnline();
    // Refresh setiap detik agar countdown berjalan di kartu Aktivitas
    _countdownRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _refreshBookingsOnline() async {
    if (mounted) {
      setState(() => _isLoadingBookings = true);
    }
    final currentUser = GlobalAuthData.currentUser;
    final role = currentUser?.role ?? 'End User';
    
    await BookingService.loadBookings(widget.username, role);
    
    // Check pending bookings status in Midtrans and update if paid
    if (BookingHistoryPage.mockHistory.isNotEmpty) {
      final List<Map<String, dynamic>> pendingBookings = List<Map<String, dynamic>>.from(
        BookingHistoryPage.mockHistory.where((b) => b['status'] == 'Menunggu Pembayaran')
      );
      
      for (final pb in pendingBookings) {
        final orderId = pb['orderId']?.toString() ?? '';
        final vName = pb['venueName']?.toString() ?? '';
        if (orderId.isNotEmpty) {
          try {
            // Strip suffix like "-1", "-2" if present for Midtrans transaction query
            String midtransOrderId = orderId;
            if (midtransOrderId.contains('-')) {
              midtransOrderId = midtransOrderId.split('-').first;
            }
            final status = await MidtransService.checkTransactionStatus(midtransOrderId);
            if (status == 'settlement' || status == 'capture') {
              await BookingService.markBookingPaid(orderId, 'Menunggu Jadwal');
              
              // Reserve slots locally to immediately reflect in UI
              final cName = pb['courtName']?.toString() ?? '';
              final dateStr = pb['date']?.toString() ?? '';
              final timeStr = pb['time']?.toString() ?? '';
              if (vName.isNotEmpty && cName.isNotEmpty && dateStr.isNotEmpty && timeStr.isNotEmpty) {
                final times = timeStr.split(',').map((t) => t.trim());
                for (final t in times) {
                  if (t.isNotEmpty) {
                    BookingUtils.reserveSlot(
                      venueName: vName,
                      courtName: cName,
                      dateStr: dateStr,
                      timeSlot: t,
                    );
                  }
                }
              }

              // Award points if not already awarded (1% cashback)
              final bookingPrice = pb['price'] as int? ?? 0;
              final pointsEarned = (bookingPrice / 100).floor();
              if (pointsEarned > 0) {
                final account = GlobalAuthData.getAccount(widget.username);
                if (account != null) {
                  await GlobalAuthData.updateAccount(
                    widget.username,
                    newPoints: account.points + pointsEarned,
                  );
                }
              }

              // Save notification to DB and in-memory cache
              await GlobalNotificationData.addNotification(
                AppNotification(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  username: widget.username,
                  title: 'Pembayaran Sukses! 🎉',
                  message: 'Pembayaran Anda sebesar IDR ${bookingPrice.toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+$)"), (m) => "${m[1]}.")} untuk booking di $vName sukses terverifikasi.',
                  timestamp: DateTime.now(),
                  icon: Icons.check_circle_outline,
                  color: AppColors.accent,
                )
              );

              // Trigger local push notification
              LocalNotificationService.showNotification(
                id: orderId.hashCode,
                title: 'Pembayaran Sukses! 🎉',
                body: 'Pembayaran Anda untuk booking di $vName sukses terverifikasi.',
              );
            } else if (status == 'expire' || status == 'cancel' || status == 'deny') {
              await BookingService.cancelPendingBooking(orderId);

              // Save notification to DB and in-memory cache
              await GlobalNotificationData.addNotification(
                AppNotification(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  username: widget.username,
                  title: 'Pembayaran Gagal/Kadaluwarsa ❌',
                  message: 'Pembayaran untuk booking di $vName gagal dilakukan atau telah kadaluwarsa. Silakan lakukan pembayaran.',
                  timestamp: DateTime.now(),
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                )
              );

              // Trigger local push notification
              LocalNotificationService.showNotification(
                id: orderId.hashCode,
                title: 'Pembayaran Gagal/Kadaluwarsa ❌',
                body: 'Pembayaran untuk booking di $vName gagal. Silakan lakukan pembayaran.',
              );
            }
          } catch (e) {
            print('Gagal cek status transaksi Midtrans $orderId: $e');
          }
        }
      }
      // Re-load bookings to get updated statuses
      await BookingService.loadBookings(widget.username, role);
    }

    await BookingUtils.loadGlobalBookingsOnline();
    await ReviewService.loadReviews();
    
    if (mounted) {
      setState(() => _isLoadingBookings = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownRefreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshBookingsOnline();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Riwayat',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab Bar ─────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.primary, width: 2.5),
                ),
                tabs: const [
                  Tab(text: 'Transaksi'),
                  Tab(text: 'Aktivitas'),
                  Tab(text: 'Selesai'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Search Bar ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: _selectedTab == 0
                              ? 'Cari Transaksi'
                              : _selectedTab == 1
                                  ? 'Cari Jadwal Aktif'
                                  : 'Cari Jadwal Selesai',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty 
                              ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => _searchController.clear()) 
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  if (_selectedTab == 0) ...[
                    const SizedBox(width: 10),
                    _buildIconButton(Icons.filter_list_rounded, () => _showFilterOptions()),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Tab Content ──────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                   _buildTransactionHistoryGrouped(),
                   _buildActiveSchedules(),
                   _buildCompletedSchedules(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Filter Berdasarkan Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...['Semua', 'Sudah Bayar', 'Belum Bayar', 'Dibatalkan'].map((status) => ListTile(
                title: Text(status),
                trailing: _statusFilter == status ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _statusFilter = status);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getGroupedTransactions() {
    final allBookings = [
      ...BookingHistoryPage.mockHistory,
      ...BookingHistoryPage.mockPastHistory
    ];

    // Group bookings by base orderId
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final b in allBookings) {
      final orderId = b['orderId']?.toString() ?? '';
      String baseOrderId = orderId;
      if (orderId.contains('-')) {
        final parts = orderId.split('-');
        if (int.tryParse(parts.last) != null) {
          baseOrderId = parts.sublist(0, parts.length - 1).join('-');
        }
      }
      groups.putIfAbsent(baseOrderId, () => []).add(b);
    }

    final List<Map<String, dynamic>> groupedTransactions = [];

    groups.forEach((baseId, items) {
      // Calculate group status:
      // - If any is 'Menunggu Pembayaran', status is 'Belum Bayar'
      // - Else if all are 'Dibatalkan', 'Expired', or 'Refunded', status is 'Dibatalkan'
      // - Otherwise, status is 'Sudah Bayar'
      String status = 'Sudah Bayar';
      bool hasUnpaid = items.any((b) => b['status']?.toString().toLowerCase() == 'menunggu pembayaran');
      bool allCancelled = items.every((b) {
        final s = b['status']?.toString().toLowerCase();
        return s == 'dibatalkan' || s == 'expired' || s == 'refunded';
      });

      if (hasUnpaid) {
        status = 'Belum Bayar';
      } else if (allCancelled) {
        status = 'Dibatalkan';
      } else {
        status = 'Sudah Bayar';
      }

      int totalPrice = items.fold(0, (sum, b) => sum + (int.tryParse(b['price'].toString()) ?? 0));

      String? redirectUrl;
      dynamic paymentDeadline;
      dynamic createdAt;
      for (final b in items) {
        if (b['redirectUrl'] != null) {
          redirectUrl = b['redirectUrl'];
        }
        if (b['paymentDeadline'] != null) {
          paymentDeadline = b['paymentDeadline'];
        }
        if (b['createdAt'] != null) {
          createdAt = b['createdAt'];
        }
      }

      groupedTransactions.add({
        'orderId': baseId,
        'status': status,
        'price': totalPrice,
        'redirectUrl': redirectUrl,
        'paymentDeadline': paymentDeadline,
        'createdAt': createdAt,
        'items': items,
        'username': items.first['username'] ?? '',
        'venueName': items.first['venueName'] ?? '',
      });
    });

    groupedTransactions.sort((a, b) {
      final aTime = a['createdAt'] != null ? DateTime.tryParse(a['createdAt'].toString()) : null;
      final bTime = b['createdAt'] != null ? DateTime.tryParse(b['createdAt'].toString()) : null;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return groupedTransactions;
  }

  List<MergedSlot> _getSplitSessions(bool getCompleted) {
    final allBookings = [
      ...BookingHistoryPage.mockHistory,
      ...BookingHistoryPage.mockPastHistory
    ];

    // Filter to paid bookings only
    final paidBookings = allBookings.where((b) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      return status == 'confirmed' ||
          status == 'pembayaran berhasil' ||
          status == 'menunggu jadwal' ||
          status == 'selesai' ||
          status == 'completed';
    }).toList();

    final List<SplitSlot> splitSlots = [];
    for (final b in paidBookings) {
      final slots = parseSlots(b);
      final venueName = b['venueName']?.toString() ?? '';
      final date = b['date']?.toString() ?? '';
      for (final s in slots) {
        final courtName = s['court'] ?? '';
        final timeStr = s['time'] ?? '';
        final range = parseTimeRange(timeStr);
        splitSlots.add(SplitSlot(
          parentBooking: b,
          venueName: venueName,
          courtName: courtName,
          date: date,
          startHour: range.startHour,
          endHour: range.endHour,
        ));
      }
    }

    // Group by venueName, courtName, date, and baseOrderId
    final Map<String, List<SplitSlot>> groups = {};
    for (final s in splitSlots) {
      final orderId = s.parentBooking['orderId']?.toString() ?? '';
      String baseOrderId = orderId;
      if (orderId.contains('-')) {
        final parts = orderId.split('-');
        if (int.tryParse(parts.last) != null) {
          baseOrderId = parts.sublist(0, parts.length - 1).join('-');
        }
      }
      final key = '${s.venueName}|${s.courtName}|${s.date}|$baseOrderId';
      groups.putIfAbsent(key, () => []).add(s);
    }

    final List<MergedSlot> mergedSlots = [];
    groups.forEach((key, slotsInGroup) {
      mergedSlots.addAll(mergeSlots(slotsInGroup));
    });

    final filteredMerged = mergedSlots.where((m) {
      final isComp = m.getDynamicStatus() == 'Selesai';
      return getCompleted ? isComp : !isComp;
    }).toList();

    filteredMerged.sort((a, b) {
      final aDate = BookingUtils.parseDateStr(a.date);
      final bDate = BookingUtils.parseDateStr(b.date);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      
      final dateCompare = getCompleted ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
      if (dateCompare != 0) return dateCompare;
      
      return getCompleted ? b.startHour.compareTo(a.startHour) : a.startHour.compareTo(b.startHour);
    });

    return filteredMerged;
  }

  List<Map<String, String>> parseSlots(Map<String, dynamic> booking) {
    final servicesStr = booking['services']?.toString() ?? '';
    if (servicesStr.contains('|slots:')) {
      try {
        final jsonStr = servicesStr.split('|slots:')[1].trim();
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded.map((e) => Map<String, String>.from(e as Map)).toList();
      } catch (e) {
        print('Error parsing slots from services: $e');
      }
    }
    // Fallback parsing
    final courtName = booking['courtName']?.toString() ?? '';
    final timeStr = booking['time']?.toString() ?? '';
    final courts = courtName.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    final times = timeStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    
    final List<Map<String, String>> slots = [];
    if (courts.length == times.length) {
      for (int i = 0; i < courts.length; i++) {
        slots.add({'court': courts[i], 'time': times[i]});
      }
    } else {
      for (final c in courts) {
        for (final t in times) {
          slots.add({'court': c, 'time': t});
        }
      }
    }
    return slots;
  }

  TimeRange parseTimeRange(String timeSlot) {
    final normalized = timeSlot.contains(' - ') 
        ? timeSlot 
        : (int.tryParse(timeSlot.split(':').first) != null 
            ? '${timeSlot.split(':').first.padLeft(2, '0')}:00 - ${(int.parse(timeSlot.split(':').first) + 1).toString().padLeft(2, '0')}:00'
            : '00:00 - 00:00');
    final parts = normalized.split(' - ');
    final start = int.tryParse(parts[0].split(':').first) ?? 0;
    final end = int.tryParse(parts[1].split(':').first) ?? 0;
    return TimeRange(start, end);
  }

  List<MergedSlot> mergeSlots(List<SplitSlot> slots) {
    if (slots.isEmpty) return [];
    slots.sort((a, b) => a.startHour.compareTo(b.startHour));

    final List<MergedSlot> merged = [];
    var current = slots[0];
    var currentStart = current.startHour;
    var currentEnd = current.endHour;
    final List<Map<String, dynamic>> parents = [current.parentBooking];

    for (int i = 1; i < slots.length; i++) {
      final next = slots[i];
      if (next.startHour <= currentEnd) {
        if (next.endHour > currentEnd) {
          currentEnd = next.endHour;
        }
        parents.add(next.parentBooking);
      } else {
        merged.add(MergedSlot(
          venueName: current.venueName,
          courtName: current.courtName,
          date: current.date,
          startHour: currentStart,
          endHour: currentEnd,
          parentBookings: List.from(parents),
        ));
        current = next;
        currentStart = current.startHour;
        currentEnd = current.endHour;
        parents.clear();
        parents.add(current.parentBooking);
      }
    }
    merged.add(MergedSlot(
      venueName: current.venueName,
      courtName: current.courtName,
      date: current.date,
      startHour: currentStart,
      endHour: currentEnd,
      parentBookings: List.from(parents),
    ));
    return merged;
  }

  Widget _buildTransactionHistoryGrouped() {
    if (_isLoadingBookings) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    final query = _searchController.text.toLowerCase();
    final grouped = _getGroupedTransactions();
    final filtered = grouped.where((group) {
      final matchesSearch = group['orderId'].toString().toLowerCase().contains(query) ||
          group['items'].any((b) =>
              (b['venueName'] ?? '').toString().toLowerCase().contains(query) ||
              (b['courtName'] ?? '').toString().toLowerCase().contains(query));
      final matchesStatus = _statusFilter == 'Semua' || group['status'] == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    Widget body;
    if (filtered.isEmpty) {
      body = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          alignment: Alignment.center,
          child: EmptyStateWidget(
            message: _searchController.text.isNotEmpty || _statusFilter != 'Semua'
                ? 'Tidak ada transaksi yang sesuai filter.'
                : 'Anda belum memiliki riwayat transaksi.',
            onActionPressed: () {
              if (_searchController.text.isNotEmpty || _statusFilter != 'Semua') {
                setState(() {
                  _searchController.clear();
                  _statusFilter = 'Semua';
                });
              } else {
                if (widget.onNavigateToVenue != null) {
                  widget.onNavigateToVenue!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VenuePage(username: widget.username),
                    ),
                  );
                }
              }
            },
            actionLabel: _searchController.text.isNotEmpty || _statusFilter != 'Semua' ? 'Reset Filter' : 'Buat Pesanan',
          ),
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _buildGroupedTransactionCard(filtered[index]);
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshBookingsOnline,
      child: body,
    );
  }

  Widget _buildActiveSchedules() {
    if (_isLoadingBookings) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    final query = _searchController.text.toLowerCase();
    final allActive = _getSplitSessions(false);
    final filtered = allActive.where((m) {
      return m.venueName.toLowerCase().contains(query) ||
             m.courtName.toLowerCase().contains(query);
    }).toList();

    Widget body;
    if (filtered.isEmpty) {
      body = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          alignment: Alignment.center,
          child: EmptyStateWidget(
            message: _searchController.text.isNotEmpty 
                ? 'Tidak ada jadwal aktif yang sesuai pencarian.'
                : 'Anda belum memiliki jadwal aktif.',
            onActionPressed: () {
              if (_searchController.text.isNotEmpty) {
                setState(() {
                  _searchController.clear();
                });
              } else {
                if (widget.onNavigateToVenue != null) {
                  widget.onNavigateToVenue!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VenuePage(username: widget.username),
                    ),
                  );
                }
              }
            },
            actionLabel: _searchController.text.isNotEmpty ? 'Reset Pencarian' : 'Buat Pesanan',
          ),
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _buildActiveSessionCard(filtered[index]);
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshBookingsOnline,
      child: body,
    );
  }

  Widget _buildCompletedSchedules() {
    if (_isLoadingBookings) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    final query = _searchController.text.toLowerCase();
    final allCompleted = _getSplitSessions(true);
    final filtered = allCompleted.where((m) {
      return m.venueName.toLowerCase().contains(query) ||
             m.courtName.toLowerCase().contains(query);
    }).toList();

    Widget body;
    if (filtered.isEmpty) {
      body = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          alignment: Alignment.center,
          child: EmptyStateWidget(
            message: _searchController.text.isNotEmpty
                ? 'Tidak ada jadwal selesai yang sesuai pencarian.'
                : 'Anda belum memiliki jadwal selesai.',
            onActionPressed: () {
              if (_searchController.text.isNotEmpty) {
                setState(() {
                  _searchController.clear();
                });
              }
            },
            actionLabel: _searchController.text.isNotEmpty ? 'Reset Pencarian' : null,
          ),
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _buildCompletedSessionCard(filtered[index]);
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshBookingsOnline,
      child: body,
    );
  }

  Widget _buildActiveSessionCard(MergedSlot item) {
    final status = item.getDynamicStatus();
    final isOngoing = status == 'Sedang Berlangsung';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: isOngoing ? Border.all(color: AppColors.primary, width: 1.5) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jadwal Main',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOngoing ? Colors.orange.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      if (isOngoing) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          color: isOngoing ? Colors.orange.shade700 : Colors.amber.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.courtName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  item.venueName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.date,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.timeRangeStr,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final firstBooking = item.parentBookings.first;
                  final baseOid = _getBaseOrderId(firstBooking['orderId']?.toString() ?? '');
                  final key = '$baseOid|${item.courtName}|${item.date}|${item.startHour}';
                  
                  setState(() {
                    _manuallyCompletedSlots.add(key);
                  });
                  
                  AlertUtils.showToast(context, 'Jadwal berhasil diselesaikan!', isUserFacing: true);
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Selesaikan Jadwal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedSessionCard(MergedSlot item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jadwal Selesai',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.courtName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  item.venueName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.date,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.timeRangeStr,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final existingReview = Review.findUserReview(widget.username, item.venueName);
                final hasReviewed = existingReview != null;
                
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final dummyItem = {
                        'venueName': item.venueName,
                        'courtName': item.courtName,
                      };
                      _showReviewDialog(context, dummyItem, existingReview: existingReview);
                    },
                    icon: Icon(
                      hasReviewed ? Icons.edit_note_rounded : Icons.star_outline_rounded,
                      size: 18,
                    ),
                    label: Text(hasReviewed ? 'Edit Ulasan' : 'Beri Ulasan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  static String _getBaseOrderId(String orderId) {
    if (orderId.contains('-')) {
      final parts = orderId.split('-');
      if (int.tryParse(parts.last) != null) {
        return parts.sublist(0, parts.length - 1).join('-');
      }
    }
    return orderId;
  }

  Map<String, dynamic> _createConsolidatedBookingForBaseOrderId(String baseOrderId) {
    final allBookings = [
      ...BookingHistoryPage.mockHistory,
      ...BookingHistoryPage.mockPastHistory
    ];
    
    final items = allBookings.where((b) {
      final oid = b['orderId']?.toString() ?? '';
      return _getBaseOrderId(oid) == baseOrderId;
    }).toList();
    
    if (items.isEmpty) {
      return {};
    }
    
    // Group values
    final int price = items.fold<int>(0, (sum, b) => sum + (int.tryParse(b['price'].toString()) ?? 0));
    final String status = items.first['status']?.toString() ?? 'Sudah Bayar';
    final String paymentMethod = items.first['paymentMethod']?.toString() ?? 'Virtual Account';
    
    // Venues, courts, dates
    final venues = items.map((e) => e['venueName']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList();
    final courts = items.map((e) => e['courtName']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList();
    final dates = items.map((e) => e['date']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList();
    
    final venueName = venues.join(', ');
    final courtName = courts.join(', ');
    final date = dates.join(', ');
    
    // Extract times
    final List<String> allSlots = [];
    for (final item in items) {
      final tVal = item['time'];
      if (tVal != null) {
        String t = tVal.toString().trim();
        if (t.contains('Slot:')) {
          t = t.split('Slot:').last.trim();
        } else if (t.contains('Slot Waktu:')) {
          t = t.split('Slot Waktu:').last.trim();
        }
        final slots = t.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
        allSlots.addAll(slots);
      }
    }
    final uniqueSlots = allSlots.toSet().toList();
    final time = uniqueSlots.join(', ');
    
    // Services
    final List<String> allServices = [];
    for (final item in items) {
      final sVal = item['services'];
      if (sVal != null) {
        if (sVal is List) {
          allServices.addAll(sVal.map((e) => e.toString().trim()));
        } else {
          String s = sVal.toString().trim();
          if (s.contains('|slots:')) {
            s = s.split('|slots:')[0].trim();
          }
          if (s.isNotEmpty && s != '-') {
            allServices.addAll(s.split(',').map((e) => e.trim()));
          }
        }
      }
    }
    final uniqueServices = allServices.toSet().toList();

    // Decompose items if any bookings contain merged slots in their |slots: payload
    final List<Map<String, dynamic>> decomposedItems = [];
    for (final item in items) {
      final servicesStr = item['services']?.toString() ?? '';
      if (servicesStr.contains('|slots:')) {
        try {
          final jsonStr = servicesStr.split('|slots:')[1].trim();
          final List<dynamic> decoded = jsonDecode(jsonStr);
          final parsedSlots = decoded.map((e) => Map<String, String>.from(e as Map)).toList();
          
          final Map<String, List<Map<String, String>>> slotsByCourt = {};
          for (final s in parsedSlots) {
            final c = s['court'] ?? 'Lapangan';
            slotsByCourt.putIfAbsent(c, () => []).add(s);
          }
          
          int totalHours = 0;
          final Map<String, List<MergedSlot>> mergedSlotsByCourt = {};
          
          slotsByCourt.forEach((courtName, cSlots) {
            final List<SplitSlot> splitList = cSlots.map((s) {
              final range = parseTimeRange(s['time'] ?? '');
              return SplitSlot(
                parentBooking: item,
                venueName: item['venueName'] ?? 'Venue',
                courtName: courtName,
                date: item['date'] ?? '',
                startHour: range.startHour,
                endHour: range.endHour,
              );
            }).toList();
            
            final mergedList = mergeSlots(splitList);
            mergedSlotsByCourt[courtName] = mergedList;
            
            for (final m in mergedList) {
              totalHours += (m.endHour - m.startHour);
            }
          });
          
          final totalPrice = int.tryParse(item['price']?.toString() ?? '0') ?? 0;
          final servicesText = servicesStr.split('|slots:')[0].trim();
          
          final List<Map<String, dynamic>> courtItems = [];
          mergedSlotsByCourt.forEach((courtName, mergedList) {
            for (final m in mergedList) {
              final hours = m.endHour - m.startHour;
              int itemPrice = 0;
              if (totalHours > 0) {
                itemPrice = (totalPrice * hours) ~/ totalHours;
              }
              
              courtItems.add({
                'courtName': courtName,
                'venueName': item['venueName'] ?? 'Venue',
                'date': item['date'] ?? '',
                'time': m.timeRangeStr,
                'price': itemPrice,
                'services': '',
              });
            }
          });
          
          if (courtItems.isNotEmpty) {
            final sumPrices = courtItems.fold<int>(0, (sum, ci) => sum + (ci['price'] as int));
            final diff = totalPrice - sumPrices;
            if (diff != 0) {
              courtItems.last['price'] = (courtItems.last['price'] as int) + diff;
            }
            if (servicesText.isNotEmpty && servicesText != '-') {
              courtItems.first['services'] = servicesText;
            }
          }
          
          decomposedItems.addAll(courtItems);
        } catch (e) {
          print('Error decomposing consolidated items: $e');
          decomposedItems.add(item);
        }
      } else {
        decomposedItems.add(item);
      }
    }
    
    return {
      'orderId': baseOrderId,
      'price': price,
      'status': status,
      'paymentMethod': paymentMethod,
      'venueName': venueName,
      'courtName': courtName,
      'date': date,
      'time': time,
      'services': uniqueServices,
      'items': decomposedItems,
    };
  }

  Widget _buildGroupedTransactionCard(Map<String, dynamic> group) {
    final status = group['status'];
    final items = group['items'] as List<dynamic>;

    Color statusBgColor = Colors.green.shade50;
    Color statusTextColor = Colors.green.shade700;
    if (status == 'Belum Bayar') {
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange.shade700;
    } else if (status == 'Dibatalkan') {
      statusBgColor = Colors.grey.shade100;
      statusTextColor = Colors.grey.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order ID: ${group['orderId']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_tennis_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items.map((e) => e['venueName']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().join(', '),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${items.length} Lapangan • ${items.map((e) => e['courtName']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().join(', ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items.map((e) => e['date']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().join(', '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Bayar',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'IDR ${group['price'].toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+$)"), (m) => "${m[1]}.")}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            
            if (status == 'Belum Bayar') ...[
              const SizedBox(height: 16),
              Builder(builder: (context) {
                final deadlineRaw = group['paymentDeadline'];
                final createdAtRaw = group['createdAt'];
                String countdownText = '';
                DateTime? deadline;

                if (createdAtRaw != null) {
                  final createdAt = createdAtRaw is DateTime
                      ? createdAtRaw
                      : DateTime.tryParse(createdAtRaw.toString());
                  if (createdAt != null) {
                    deadline = createdAt.add(const Duration(hours: 24));
                  }
                }

                if (deadline == null && deadlineRaw != null) {
                  deadline = deadlineRaw is DateTime
                      ? deadlineRaw
                      : DateTime.tryParse(deadlineRaw.toString());
                }

                if (deadline != null) {
                  final remaining = deadline.difference(DateTime.now());
                  if (remaining.isNegative) {
                    countdownText = 'Waktu Habis';
                  } else {
                    final h = remaining.inHours.toString().padLeft(2, '0');
                    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
                    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
                    countdownText = 'Bayar dalam: $h:$m:$s';
                  }
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Text(
                        countdownText.isEmpty ? 'Menunggu Pembayaran' : countdownText,
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final url = group['redirectUrl']?.toString() ?? '';
                        if (url.isEmpty) {
                          AlertUtils.showToast(context, 'Link pembayaran tidak tersedia.', isSuccess: false, isUserFacing: true);
                          return;
                        }
                        final uri = Uri.parse(url);
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {
                          AlertUtils.showToast(context, 'Tidak dapat membuka portal pembayaran.', isSuccess: false, isUserFacing: true);
                        }
                      },
                      icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                      label: const Text('Bayar Sekarang'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AlertUtils.showConfirmationDialog(
                          context,
                          title: 'Batalkan Pesanan?',
                          message: 'Apakah Anda yakin ingin membatalkan semua pesanan dalam transaksi ini?',
                          onConfirm: () async {
                            final List<dynamic> groupItems = group['items'];
                            for (final item in groupItems) {
                              final oid = item['orderId']?.toString() ?? '';
                              setState(() {
                                final idx = BookingHistoryPage.mockHistory.indexWhere((b) => b['orderId'] == oid);
                                if (idx >= 0) {
                                  final cancelled = BookingHistoryPage.mockHistory.removeAt(idx);
                                  cancelled['status'] = 'Dibatalkan';
                                  BookingHistoryPage.mockPastHistory.insert(0, cancelled);
                                }
                              });
                              if (oid.isNotEmpty) {
                                await BookingService.cancelPendingBooking(oid);
                              }
                            }
                            AlertUtils.showToast(context, 'Pesanan berhasil dibatalkan.', isUserFacing: true);
                          },
                        );
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Batalkan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'Sudah Bayar') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final baseOid = group['orderId']?.toString() ?? '';
                    final consolidated = _createConsolidatedBookingForBaseOrderId(baseOid);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceiptPage(booking: consolidated),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text('E-Kuitansi Pembayaran'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context, Map<String, dynamic> item, {Review? existingReview}) {
    int selectedRating = existingReview?.rating.toInt() ?? 0;
    final TextEditingController reviewController = TextEditingController(text: existingReview?.comment ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Text(
                existingReview == null ? 'Berikan Ulasan' : 'Edit Ulasan',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                item['venueName'] ?? 'Venue',
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: index < selectedRating
                          ? Colors.amber
                          : Colors.grey.shade400,
                      size: 36,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        selectedRating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tulis pengalaman Anda di sini...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () async {
                      final newReview = Review(
                        username: widget.username,
                        venueName: item['venueName'] ?? 'Venue',
                        rating: selectedRating.toDouble(),
                        comment: reviewController.text,
                        date: DateTime.now(),
                      );

                      await ReviewService.saveReview(newReview);

                      if (!mounted) return;
                      setState(() {});
                      
                      Navigator.pop(context);
                      AlertUtils.showResultDialog(
                        context,
                        isSuccess: true,
                        title: existingReview == null ? 'Ulasan Terkirim!' : 'Ulasan Diperbarui!',
                        message: existingReview == null 
                          ? 'Terima kasih! Ulasan Anda telah berhasil diterima.'
                          : 'Ulasan Anda telah berhasil diperbarui.',
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(existingReview == null ? 'Kirim Ulasan' : 'Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}
