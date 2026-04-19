import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../utils/alert_utils.dart';
import './receipt_page.dart';
import 'booking_history.dart';
import '../utils/booking_utils.dart';
import './dashboard_page.dart';
import '../data/venue_data.dart';
import '../data/notification_data.dart';
import '../data/auth_data.dart';
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
    required this.username,
    this.role = 'End User',
    this.usedPoints = 0,
  });

  final Map<String, int> selectedServices;

  @override
  State<PaymentInstructionPage> createState() => _PaymentInstructionPageState();
}

class _PaymentInstructionPageState extends State<PaymentInstructionPage> {
  bool _isCheckingStatus = false;
  late String _vaNumber;

  @override
  void initState() {
    super.initState();
    _vaNumber = '88062${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  String _formatPrice(int price) {
    return 'IDR ${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
  }

  void _checkPaymentStatus() async {
    setState(() => _isCheckingStatus = true);
    
    // Simulate network delay for verification
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _isCheckingStatus = false);

    final newBooking = {
      'orderId': widget.orderId,
      'venueName': widget.venueName,
      'courtName': widget.courtName,
      'date': widget.date,
      'time': widget.timeRange,
      'price': widget.amount,
      'paymentMethod': widget.paymentMethodName,
      'status': 'Menunggu Jadwal',
      'services': widget.selectedServices.isEmpty ? null : widget.selectedServices.entries.map((e) {
        final venueResults = GlobalVenueData.venues.where((v) => v['name'] == widget.venueName);
        final venue = venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
        final serviceList = (venue['services'] as List<dynamic>? ?? []);
        final serviceResults = serviceList.where((s) => s['id'] == e.key);
        if (serviceResults.isEmpty) return 'Unknown Service';
        final service = serviceResults.first;
        return '${service['name']} (x${e.value})';
      }).join(', '),
    };

    // Perform atomic slot reservation
    for (var slot in widget.individualSlots) {
      BookingUtils.reserveSlot(
        venueName: widget.venueName,
        courtName: slot['court'] ?? '',
        dateStr: widget.date,
        timeSlot: slot['time'] ?? '',
      );
    }

    // 3. Award Points (1% cashback)
    final pointsEarned = (widget.amount / 100).floor();
    final account = GlobalAuthData.getAccount(widget.username);
    if (account != null) {
      GlobalAuthData.updateAccount(
        widget.username,
        newPoints: account.points + pointsEarned - widget.usedPoints,
      );
    }

    BookingHistoryPage.mockHistory.insert(0, newBooking);

    // Notify End User
    final String startTimeStr = widget.timeRange.contains(' - ') 
        ? widget.timeRange.split(' - ')[0] 
        : widget.timeRange.split(' ')[0];

    // Notify End User - Confirmation
    GlobalNotificationData.addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: widget.username,
        title: 'Booking Berhasil Konfirmasi!',
        message: 'Pemesanan lapangan berhasil dilakukan di ${widget.venueName}',
        timestamp: DateTime.now(),
        icon: Icons.check_circle_outline,
        color: AppColors.accent,
      )
    );

    // Notify End User - 1 Hour Reminder
    GlobalNotificationData.addNotification(
      AppNotification(
        id: '${DateTime.now().millisecondsSinceEpoch}_rem1h',
        username: widget.username,
        title: 'Pengingat: 1 Jam Lagi',
        message: 'Sesi Anda di ${widget.venueName} akan dimulai dalam 1 jam (Pukul $startTimeStr).',
        timestamp: DateTime.now(),
        icon: Icons.access_time_filled_rounded,
        color: Colors.orange,
      )
    );

    // Notify End User - 15 Minute Reminder
    GlobalNotificationData.addNotification(
      AppNotification(
        id: '${DateTime.now().millisecondsSinceEpoch}_rem15m',
        username: widget.username,
        title: 'Pengingat: 15 Menit Lagi',
        message: 'Siap-siap! Sesi Anda di ${widget.venueName} akan dimulai dalam 15 menit.',
        timestamp: DateTime.now(),
        icon: Icons.notifications_active_rounded,
        color: AppColors.primary,
      )
    );

    // Notify Admin
    GlobalNotificationData.addNotification(
      AppNotification(
        id: '${DateTime.now().millisecondsSinceEpoch}_admin',
        username: 'admin',
        title: 'Pemesanan Baru',
        message: '${widget.username} telah memesan lapangan di ${widget.venueName}',
        timestamp: DateTime.now(),
        icon: Icons.receipt_long,
        color: AppColors.accent,
      )
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
                          'Menunggu pembayaran',
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
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pesanan Anda akan dibatalkan otomatis jika Anda tidak menyelesaikan pembayaran dalam waktu 30 menit.',
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
    if (widget.paymentMethodId == 'qris') {
      return _buildQRISLayout();
    } else if (widget.paymentMethodId == 'credit_card') {
      return _buildCardLayout();
    } else {
      return _buildVALayout();
    }
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
