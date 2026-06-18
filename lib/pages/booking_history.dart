import 'dart:async';
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

class _BookingHistoryPageState extends State<BookingHistoryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
    _tabController = TabController(length: 2, vsync: this);
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
                    'Aktivitas',
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
                  Tab(text: 'Daftar Pesanan'),
                  Tab(text: 'Riwayat Transaksi'),
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
                              ? 'Cari Nama Pemesanan'
                              : 'Cari Transaksi',
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
                   _buildOrderList(),
                   _buildTransactionHistory(),
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
              ...['Semua', 'Pembayaran Berhasil', 'Menunggu Pembayaran'].map((status) => ListTile(
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

  Widget _buildOrderList() {
    final query = _searchController.text.toLowerCase();
    final filtered = BookingHistoryPage.mockHistory.where((item) {
      final matchesSearch = (item['venueName'] ?? '').toLowerCase().contains(query) || 
                            (item['courtName'] ?? '').toLowerCase().contains(query);
      final matchesStatus = _statusFilter == 'Semua' || 
                            (_statusFilter == 'Pembayaran Berhasil' && (item['status'] == 'Menunggu Jadwal' || item['status'] == 'Pembayaran Berhasil')) ||
                            (_statusFilter == 'Menunggu Pembayaran' && item['status'] == 'Menunggu Pembayaran');
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
                ? 'Tidak ada pesanan yang sesuai filter.'
                : 'Anda belum memiliki pesanan aktif.',
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
          return _buildHistoryCard(filtered[index], index: index);
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshBookingsOnline,
      child: body,
    );
  }

  Widget _buildTransactionHistory() {
    final query = _searchController.text.toLowerCase();
    final filtered = BookingHistoryPage.mockPastHistory.where((item) {
      final matchesSearch = (item['venueName'] ?? '').toLowerCase().contains(query) || 
                            (item['courtName'] ?? '').toLowerCase().contains(query);
      return matchesSearch;
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
                ? 'Tidak ada riwayat yang sesuai pencarian.'
                : 'Anda belum memiliki riwayat transaksi.',
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
          return _buildHistoryCard(filtered[index], isPast: true);
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshBookingsOnline,
      child: body,
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, {int? index, bool isPast = false}) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.primary.withValues(alpha: 0.05),
          highlightColor: AppColors.primary.withOpacity(0.1),
          splashColor: AppColors.primary.withOpacity(0.1),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order ID: ${item['orderId'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (item['status'] ?? '') == 'Completed' || (item['status'] ?? '') == 'Selesai'
                            ? Colors.grey.shade100
                            : (item['status'] ?? '') == 'Menunggu Pembayaran'
                                ? Colors.orange.shade50
                                : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (item['status'] ?? '') == 'Completed' ? 'Selesai' : (item['status'] ?? '-'),
                        style: TextStyle(
                          fontSize: 12,
                          color: (item['status'] ?? '') == 'Completed' || (item['status'] ?? '') == 'Selesai'
                              ? Colors.grey.shade600
                              : (item['status'] ?? '') == 'Menunggu Pembayaran'
                                  ? Colors.orange.shade700
                                  : Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item['courtName'] ?? 'Unknown Court',
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
                      item['venueName'] ?? 'Unknown Venue',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (item['services'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item['services'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                item['date'] ?? '-',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item['time'] ?? '-',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textPrimary),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'IDR ${(item['price'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (!isPast && index != null) ...[
                  const SizedBox(height: 12),
                  // Khusus status Menunggu Pembayaran: tampilkan countdown + tombol Bayar/Batalkan
                  if ((item['status'] ?? '') == 'Menunggu Pembayaran') ...[
                    Builder(builder: (context) {
                      final deadlineRaw = item['paymentDeadline'];
                      final createdAtRaw = item['createdAt'];
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final url = item['redirectUrl']?.toString() ?? '';
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
                                message: 'Apakah Anda yakin ingin membatalkan pesanan ini?',
                                onConfirm: () async {
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
                  ] else ...[
                    // Status lain (Menunggu Jadwal, dll): tombol E-Kuitansi + Selesaikan
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReceiptPage(booking: item),
                                ),
                              );
                            },
                            icon: const Icon(Icons.receipt_long_rounded, size: 16),
                            label: const Text('E-Kuitansi'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              AlertUtils.showConfirmationDialog(
                                context,
                                title: 'Selesaikan Pemesanan?',
                                message: 'Apakah Anda yakin ingin menyelesaikan pemesanan ini dan memindahkannya ke riwayat transaksi?',
                                onConfirm: () async {
                                  final finished = BookingHistoryPage.mockHistory[index];
                                  final orderId = finished['orderId']?.toString() ?? '';
                                  
                                  setState(() {
                                    BookingHistoryPage.mockHistory.removeAt(index);
                                    finished['status'] = 'Completed';
                                    BookingHistoryPage.mockPastHistory.insert(0, finished);
                                  });

                                  if (orderId.isNotEmpty) {
                                    await BookingService.updateBookingStatus(orderId, 'Completed');
                                  }

                                  AlertUtils.showToast(
                                    context,
                                    'Pemesanan selesai & dipindahkan ke riwayat!',
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                            label: const Text('Selesaikan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else if (isPast) ...[
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final existingReview = Review.findUserReview(widget.username, item['venueName'] ?? '');
                      final hasReviewed = existingReview != null;
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReceiptPage(booking: item),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.receipt_long_rounded, size: 16),
                              label: const Text('E-Kuitansi'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: () => _showReviewDialog(context, item, existingReview: existingReview),
                              icon: Icon(
                                hasReviewed ? Icons.edit_note_rounded : Icons.star_outline_rounded,
                                size: 18,
                              ),
                              label: Text(hasReviewed ? 'Edit Ulasan' : 'Beri Ulasan'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary, width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ],
            ),
          ),
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
