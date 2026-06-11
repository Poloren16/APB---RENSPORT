import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../utils/alert_utils.dart';
import 'booking_history.dart';
import '../utils/booking_utils.dart';
import './dashboard_page.dart';
import '../data/venue_data.dart';
import '../data/notification_data.dart';
import '../data/auth_data.dart';
import '../services/midtrans_service.dart';
import '../services/notification_service.dart';
import '../services/booking_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentInstructionPage extends StatefulWidget {
  final String paymentMethodId;
  final String paymentMethodName;
  final int amount;
  final String orderId;
  final String venueName;
  final String courtName;
  final String date;
  final String timeRange;
  final List<Map<String, String>> individualSlots;
  final String username;
  final String role;
  final int usedPoints;
  final String? redirectUrl;

  final List<Map<String, dynamic>> items;
  final Map<String, int> selectedServices;

  const PaymentInstructionPage({
    super.key,
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.amount,
    required this.orderId,
    required this.venueName,
    required this.courtName,
    required this.date,
    required this.timeRange,
    required this.individualSlots,
    this.selectedServices = const {},
    this.items = const [],
    required this.username,
    this.role = 'End User',
    this.usedPoints = 0,
    this.redirectUrl,
  });

  @override
  State<PaymentInstructionPage> createState() => _PaymentInstructionPageState();
}

class _PaymentInstructionPageState extends State<PaymentInstructionPage> {
  bool _isCheckingStatus = false;
  late String _vaNumber;
  late DateTime _paymentDeadline;
  Duration _remainingTime = Duration.zero;
  Timer? _countdownTimer;
  bool _isPendingBookingCreated = false;

  @override
  void initState() {
    super.initState();
    _vaNumber = '88062${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    // Midtrans default payment deadline: 24 jam
    _paymentDeadline = DateTime.now().add(const Duration(hours: 24));
    _remainingTime = _paymentDeadline.difference(DateTime.now());
    _startCountdown();
    _createPendingBooking();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _paymentDeadline.difference(DateTime.now());
      if (remaining.isNegative || remaining == Duration.zero) {
        _countdownTimer?.cancel();
        setState(() => _remainingTime = Duration.zero);
        _onPaymentExpired();
      } else {
        setState(() => _remainingTime = remaining);
      }
    });
  }

  void _onPaymentExpired() {
    // Kumpulkan semua orderId yang perlu dibatalkan
    final orderIds = widget.items.isNotEmpty
        ? List.generate(widget.items.length, (i) => '${widget.orderId}-${i + 1}')
        : [widget.orderId];

    // Pindahkan semua booking terkait dari active → past dengan status Dibatalkan
    for (final oid in orderIds) {
      final idx = BookingHistoryPage.mockHistory.indexWhere((b) => b['orderId'] == oid);
      if (idx >= 0) {
        final cancelled = Map<String, dynamic>.from(BookingHistoryPage.mockHistory[idx]);
        BookingHistoryPage.mockHistory.removeAt(idx);
        cancelled['status'] = 'Dibatalkan';
        BookingHistoryPage.mockPastHistory.insert(0, cancelled);
      }
      // Cancel di Supabase juga
      BookingService.cancelPendingBooking(oid);
    }

    if (mounted) {
      AlertUtils.showResultDialog(
        context,
        isSuccess: false,
        title: 'Waktu Pembayaran Habis',
        message: 'Batas waktu pembayaran telah habis. Pesanan Anda otomatis dibatalkan. Silakan buat pesanan baru.',
        onConfirm: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(username: widget.username, role: widget.role, initialIndex: 2),
            ),
            (route) => false,
          );
        },
      );
    }
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Buat booking sementara dengan status "Menunggu Pembayaran" segera setelah halaman ini dibuka
  Future<void> _createPendingBooking() async {
    if (_isPendingBookingCreated) return;
    _isPendingBookingCreated = true;

    String? formattedServicesStr;
    if (widget.selectedServices.isNotEmpty) {
      formattedServicesStr = _buildServicesString(widget.venueName, widget.selectedServices);
    }

    if (widget.items.isNotEmpty) {
      // Multi-item: buat pending booking per item
      for (int i = 0; i < widget.items.length; i++) {
        final item = widget.items[i];
        final itemOrderId = '${widget.orderId}-${i + 1}';
        final itemServices = item['services'] as Map<String, dynamic>? ?? {};
        final sStr = itemServices.isEmpty ? null : _buildServicesString(item['venueName']?.toString() ?? widget.venueName, itemServices.map((k, v) => MapEntry(k, v as int)));
        final pendingBooking = {
          'orderId': itemOrderId,
          'username': widget.username,
          'venueName': item['venueName'] ?? widget.venueName,
          'courtName': item['courtName'] ?? widget.courtName,
          'date': item['date'] ?? widget.date,
          'time': item['timeSlot'] ?? widget.timeRange,
          'price': item['price'] as int? ?? 0,
          'paymentMethod': widget.paymentMethodName,
          'status': 'Menunggu Pembayaran',
          'services': sStr,
          'paymentDeadline': _paymentDeadline,
          'redirectUrl': widget.redirectUrl,
        };
        await BookingService.createBooking(pendingBooking);
        // Guard: cegah duplikasi di memory list
        final alreadyInList = BookingHistoryPage.mockHistory.any((b) => b['orderId'] == itemOrderId);
        if (!alreadyInList) {
          BookingHistoryPage.mockHistory.insert(0, pendingBooking);
        }
      }
    } else {
      final pendingBooking = {
        'orderId': widget.orderId,
        'username': widget.username,
        'venueName': widget.venueName,
        'courtName': widget.courtName,
        'date': widget.date,
        'time': widget.timeRange,
        'price': widget.amount,
        'paymentMethod': widget.paymentMethodName,
        'status': 'Menunggu Pembayaran',
        'services': formattedServicesStr,
        'paymentDeadline': _paymentDeadline,
        'redirectUrl': widget.redirectUrl,
      };
      await BookingService.createBooking(pendingBooking);
      // Guard: cegah duplikasi di memory list
      final alreadyInList = BookingHistoryPage.mockHistory.any((b) => b['orderId'] == widget.orderId);
      if (!alreadyInList) {
        BookingHistoryPage.mockHistory.insert(0, pendingBooking);
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatPrice(int price) {
    return 'IDR ${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
  }

  DateTime _getBookingStartDateTime() {
    try {
      final cleanDate = widget.date.contains(',') ? widget.date.split(',')[1].trim() : widget.date.trim();
      final parts = cleanDate.split(' ');
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final monthStr = parts[1].toLowerCase();
        final year = int.parse(parts[2]);
        
        int month = 1;
        switch (monthStr) {
          case 'januari': month = 1; break;
          case 'februari': month = 2; break;
          case 'maret': month = 3; break;
          case 'april': month = 4; break;
          case 'mei': month = 5; break;
          case 'juni': month = 6; break;
          case 'juli': month = 7; break;
          case 'agustus': month = 8; break;
          case 'september': month = 9; break;
          case 'oktober': month = 10; break;
          case 'november': month = 11; break;
          case 'desember': month = 12; break;
        }

        final startTimeStr = widget.timeRange.contains(' - ') 
            ? widget.timeRange.split(' - ')[0] 
            : widget.timeRange.split(' ')[0];
        
        final timeParts = startTimeStr.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        return DateTime(year, month, day, hour, minute);
      }
    } catch (e) {
      // Fallback to now
    }
    return DateTime.now();
  }

  /// Helper: build formatted services string from selectedServices map
  String _buildServicesString(String venueName, Map<String, int> services) {
    if (services.isEmpty) return '';
    final venueResults = GlobalVenueData.venues.where((v) => v['name'] == venueName);
    final venue = venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
    final courts = venue['courts'] as List<dynamic>? ?? [];
    final seenSvc = <String>{};
    final sList = <Map<String, dynamic>>[];
    for (final c in courts) {
      final courtServices = c['services'] as List<dynamic>? ?? [];
      for (final s in courtServices) {
        final sMap = Map<String, dynamic>.from(s as Map);
        final name = sMap['name']?.toString() ?? '';
        final sId = sMap['id']?.toString() ?? name;
        sMap['id'] = sId;
        if (name.isNotEmpty && !seenSvc.contains(name)) {
          seenSvc.add(name);
          sList.add(sMap);
        }
      }
    }
    return services.entries.map((e) {
      final sRes = sList.where((s) => s['id'] == e.key || s['name'] == e.key);
      if (sRes.isEmpty) return 'Layanan (x${e.value})';
      return '${sRes.first['name']} (x${e.value})';
    }).join(', ');
  }

  void _checkPaymentStatus() async {
    setState(() => _isCheckingStatus = true);
    
    try {
      final status = await MidtransService.checkTransactionStatus(widget.orderId);
      
      if (!mounted) return;
      setState(() => _isCheckingStatus = false);

      if (status == 'settlement' || status == 'capture') {
        // Stop countdown
        _countdownTimer?.cancel();

        // Update semua pending booking yang sudah dibuat di initState → status "Menunggu Jadwal"
        final orderIds = widget.items.isNotEmpty
            ? List.generate(widget.items.length, (i) => '${widget.orderId}-${i + 1}')
            : [widget.orderId];

        for (final oid in orderIds) {
          // Update di in-memory
          final idx = BookingHistoryPage.mockHistory.indexWhere((b) => b['orderId'] == oid);
          if (idx >= 0) {
            BookingHistoryPage.mockHistory[idx]['status'] = 'Menunggu Jadwal';
            BookingHistoryPage.mockHistory[idx]['paymentDeadline'] = null;
            BookingHistoryPage.mockHistory[idx]['redirectUrl'] = null;
          }
          // Update di Supabase
          await BookingService.markBookingPaid(oid, 'Menunggu Jadwal');
        }

        // Perform atomic slot reservation
        for (var slot in widget.individualSlots) {
          BookingUtils.reserveSlot(
            venueName: widget.venueName,
            courtName: slot['court'] ?? '',
            dateStr: widget.date,
            timeSlot: slot['time'] ?? '',
          );
        }

        // Award Points (1% cashback)
        final pointsEarned = (widget.amount / 100).floor();
        final account = GlobalAuthData.getAccount(widget.username);
        if (account != null) {
          await GlobalAuthData.updateAccount(
            widget.username,
            newPoints: account.points + pointsEarned - widget.usedPoints,
          );
        }

        // Notify End User
        final String startTimeStr = widget.timeRange.contains(' - ') 
            ? widget.timeRange.split(' - ')[0] 
            : widget.timeRange.split(' ')[0];

        await GlobalNotificationData.addNotification(
          AppNotification(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            username: widget.username,
            title: 'Pembayaran Sukses! 🎉',
            message: 'Anda berhasil membayar ${_formatPrice(widget.amount)} untuk booking di ${widget.venueName}.',
            timestamp: DateTime.now(),
            icon: Icons.check_circle_outline,
            color: AppColors.accent,
          )
        );

        final bookingStart = _getBookingStartDateTime();

        await GlobalNotificationData.addNotification(
          AppNotification(
            id: '${DateTime.now().millisecondsSinceEpoch}_rem1h',
            username: widget.username,
            title: 'Pengingat: Kurang dari 1 Jam Lagi',
            message: 'Sesi Anda di ${widget.venueName} akan dimulai sebentar lagi (Pukul $startTimeStr).',
            timestamp: bookingStart.subtract(const Duration(hours: 1)),
            icon: Icons.access_time_filled_rounded,
            color: Colors.orange,
          )
        );

        await GlobalNotificationData.addNotification(
          AppNotification(
            id: '${DateTime.now().millisecondsSinceEpoch}_rem15m',
            username: widget.username,
            title: 'Pengingat: 15 Menit Lagi',
            message: 'Siap-siap! Sesi Anda di ${widget.venueName} akan dimulai dalam 15 menit.',
            timestamp: bookingStart.subtract(const Duration(minutes: 15)),
            icon: Icons.notifications_active_rounded,
            color: AppColors.primary,
          )
        );

        await GlobalNotificationData.addNotification(
          AppNotification(
            id: '${DateTime.now().millisecondsSinceEpoch}_admin',
            username: 'admin',
            title: 'Pemesanan Baru Masuk! 💰',
            message: '${widget.username} telah membayar ${_formatPrice(widget.amount)} untuk ${widget.venueName}.',
            timestamp: DateTime.now(),
            icon: Icons.receipt_long,
            color: AppColors.accent,
          )
        );

        LocalNotificationService.showNotification(
          id: widget.orderId.hashCode + 1,
          title: 'Pembayaran Sukses! 🎉',
          body: 'Anda berhasil membayar ${_formatPrice(widget.amount)} untuk booking di ${widget.venueName}.',
        );

        LocalNotificationService.showNotification(
          id: widget.orderId.hashCode + 2,
          title: 'Pemesanan Baru Masuk! 💰',
          body: '${widget.username} telah membayar ${_formatPrice(widget.amount)} untuk ${widget.venueName}.',
        );

        AlertUtils.showResultDialog(
          context,
          isSuccess: true,
          title: 'Pembayaran Berhasil!',
          message: 'Kami telah menerima pembayaran Anda. Anda mendapatkan $pointsEarned Rensius Point! Pantau status pesanan di menu Aktivitas.',
          onConfirm: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardPage(
                  username: widget.username,
                  role: widget.role,
                  initialIndex: 2,
                ),
              ),
              (route) => false,
            );
          },
        );
      } else if (status == 'pending') {
        AlertUtils.showToast(
          context,
          'Pembayaran Anda masih berstatus PENDING. Silakan selesaikan pembayaran di portal Midtrans terlebih dahulu!',
          isSuccess: false,
        );
      } else {
        // expire / cancel / deny → batalkan pending booking
        _countdownTimer?.cancel();
        for (final oid in widget.items.isNotEmpty
            ? List.generate(widget.items.length, (i) => '${widget.orderId}-${i + 1}')
            : [widget.orderId]) {
          final idx = BookingHistoryPage.mockHistory.indexWhere((b) => b['orderId'] == oid);
          if (idx >= 0) {
            final cancelled = BookingHistoryPage.mockHistory.removeAt(idx);
            cancelled['status'] = 'Dibatalkan';
            BookingHistoryPage.mockPastHistory.insert(0, cancelled);
          }
          await BookingService.cancelPendingBooking(oid);
        }
        AlertUtils.showResultDialog(
          context,
          isSuccess: false,
          title: 'Pembayaran Gagal',
          message: 'Transaksi Anda berstatus "$status". Pesanan dibatalkan. Silakan buat pesanan baru.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingStatus = false);
      AlertUtils.showToast(
        context,
        'Gagal memeriksa status pembayaran. Silakan coba beberapa saat lagi.',
        isSuccess: false,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Selesaikan Pembayaran',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Amount Display
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(widget.amount),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: Colors.orange.shade800),
                        const SizedBox(width: 6),
                        Text(
                          _remainingTime == Duration.zero
                              ? 'Waktu Habis'
                              : '⏱ Batas: ${_formatCountdown(_remainingTime)}',
                          style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instruction Content
            _buildInstructionBody(),
            
            const SizedBox(height: 24),
            
            // Step Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pesanan Anda akan otomatis dibatalkan jika tidak menyelesaikan pembayaran dalam 24 jam. Pantau status di menu Aktivitas.',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Actions
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isCheckingStatus ? null : _checkPaymentStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isCheckingStatus
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Cek Status Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ubah Metode Pembayaran', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionBody() {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Midtrans Snap Gateway',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Portal Pembayaran Aman',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Order ID Anda:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.orderId,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textPrimary),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.orderId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order ID Berhasil Disalin!')),
                    );
                  },
                  child: const Text(
                    'Salin',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (widget.redirectUrl != null) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(widget.redirectUrl!);
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      // Fallback: try launching directly
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    AlertUtils.showToast(context, 'Tidak dapat membuka portal pembayaran. Pastikan browser terinstal.', isSuccess: false);
                  }
                },
                icon: const Icon(Icons.open_in_browser_rounded, size: 20, color: Colors.white),
                label: const Text(
                  'Buka Portal Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          const Text(
            'Petunjuk Pembayaran:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildStepRow('1', 'Klik tombol "Buka Portal Pembayaran" di atas.'),
          _buildStepRow('2', 'Pilih metode pembayaran (E-wallet, VA, atau kartu kredit) di portal Midtrans Snap.'),
          _buildStepRow('3', 'Selesaikan transaksi di layar simulator pembayaran.'),
          _buildStepRow('4', 'Kembali ke aplikasi Rensius ini, lalu klik tombol "Cek Status Pembayaran" di bawah.'),
        ],
      ),
    );
  }

  Widget _buildQRISLayout() {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('QRIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B4E9B))),
              const SizedBox(width: 8),
              const Icon(Icons.qr_code_2_rounded, color: Color(0xFF1B4E9B)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.qr_code_2_rounded, size: 200, color: Colors.black.withOpacity(0.8)),
                const Text('Scan dengan Gopay, OVO, Dana, atau Aplikasi Bank', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildStepRow('1', 'Simpan atau screenshot kode QR ini'),
          _buildStepRow('2', 'Buka aplikasi pembayaran atau bank Anda'),
          _buildStepRow('3', 'Scan QR dan selesaikan pembayaran'),
        ],
      ),
    );
  }

  Widget _buildVALayout() {
    String bankName = widget.paymentMethodName.replaceAll(' Virtual Account', '');
    
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.account_balance_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('Nomor Virtual Account', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _vaNumber,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _vaNumber));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor VA Berhasil Disalin!')));
                  },
                  child: const Text('Salin', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Instruksi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _buildStepRow('1', 'Pilih Transfer > Virtual Account'),
          _buildStepRow('2', 'Masukkan nomor VA di atas'),
          _buildStepRow('3', 'Pastikan total pembayaran sesuai dan konfirmasi'),
        ],
      ),
    );
  }

  Widget _buildCardLayout() {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detail Kartu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildCardField('Nomor Kartu', '0000 0000 0000 0000'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildCardField('Masa Berlaku', 'MM/YY')),
              const SizedBox(width: 16),
              Expanded(child: _buildCardField('CVV', '***')),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.security_rounded, color: Colors.green, size: 14),
              SizedBox(width: 6),
              Text('Diproses aman oleh Midtrans (Simulasi)', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
