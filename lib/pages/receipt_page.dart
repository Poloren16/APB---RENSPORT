import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ReceiptPage extends StatelessWidget {
  final Map<String, dynamic> booking;

  const ReceiptPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final timeSlots = _parseTimeSlots(booking['time']);
    final services = _parseServices(booking['services']);
    final status = booking['status']?.toString().trim().isNotEmpty == true
        ? booking['status'].toString()
        : 'Terbayar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kuitansi Pembayaran',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          children: [
            // --- The Receipt Card ---
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Section
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.green, size: 32),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Pembayaran Berhasil',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatPrice(booking['price']),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Order ID: ${booking['orderId'] ?? '-'}',
                              style: TextStyle(
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Dashed Line Separator
                      Row(
                        children: List.generate(
                          30,
                          (index) => Expanded(
                            child: Container(
                              color: index % 2 == 0
                                  ? Colors.transparent
                                  : Colors.grey.shade200,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),

                      // Details Section
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Venue',
                              booking['venueName']?.toString() ?? '-',
                              isBold: true,
                            ),
                            _buildInfoRow(
                              'Lapangan',
                              booking['courtName']?.toString() ?? '-',
                            ),
                            _buildInfoRow(
                              'Tanggal Pemesanan',
                              booking['date']?.toString() ?? '-',
                            ),
                            _buildChipInfoRow(
                              'Waktu Sewa',
                              timeSlots.isNotEmpty ? timeSlots : ['-'],
                            ),
                            if (services.isNotEmpty)
                              _buildChipInfoRow(
                                'Layanan Tambahan',
                                services,
                                icon: Icons.add_circle_outline_rounded,
                              ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              'Metode Pembayaran',
                              booking['paymentMethod']?.toString() ??
                                  'Virtual Account',
                            ),
                            _buildInfoRow(
                              'Status Pesanan',
                              status,
                              statusColor: _getStatusColor(status),
                            ),
                          ],
                        ),
                      ),

                      // Footer Section (Simplified)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 20),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.verified_user_rounded,
                                      color: AppColors.primary, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Pembayaran Terverifikasi',
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
                    ],
                  ),
                ),
                // Decorative punched holes (receipt effect)
                Positioned(
                  left: -12,
                  top: 155, // Approximately where the dashed line is
                  child: CircleAvatar(
                      radius: 12, backgroundColor: AppColors.background),
                ),
                Positioned(
                  right: -12,
                  top: 155,
                  child: CircleAvatar(
                      radius: 12, backgroundColor: AppColors.background),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Helpful text
            Text(
              'Tunjukkan e-receipt ini kepada staf lapangan saat tiba di lokasi untuk validasi pesanan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // Done Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Kembali ke Aktivitas',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'IDR 0';

    final raw = price.toString();
    final numeric = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeric.isEmpty) return 'IDR 0';

    final formatted = numeric.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    return 'IDR $formatted';
  }

  List<String> _parseTimeSlots(dynamic value) {
    if (value == null) return [];

    String raw = value.toString().trim();
    if (raw.isEmpty || raw == '-') return [];

    if (raw.contains('Slot:')) {
      raw = raw.split('Slot:').last.trim();
    } else if (raw.contains('(') && raw.contains(')')) {
      raw = raw.substring(raw.indexOf('(') + 1, raw.lastIndexOf(')')).trim();
    }

    raw = raw.replaceFirst(RegExp(r'^\d+\s*Slot\s*Waktu\s*:?\s*'), '');

    return raw
        .split(',')
        .map((slot) => _normalizeTimeSlot(slot.trim()))
        .where((slot) => slot.isNotEmpty)
        .toList();
  }

  String _normalizeTimeSlot(String value) {
    if (value.isEmpty || value == '-') return '';
    if (value.contains(' - ')) return value;

    final startHour = int.tryParse(value.split(':').first);
    if (startHour == null) return value;

    final endHour = startHour + 1;
    return '${startHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00';
  }

  List<String> _parseServices(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((service) => service.toString().trim())
          .where((service) => service.isNotEmpty && service != '-')
          .toList();
    }

    final raw = value.toString().trim();
    if (raw.isEmpty || raw == '-') return [];

    return raw
        .split(',')
        .map((service) => service.trim())
        .where((service) => service.isNotEmpty)
        .toList();
  }

  Color _getStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('batal') ||
        normalized.contains('cancel') ||
        normalized.contains('expired')) {
      return Colors.red;
    }
    if (normalized.contains('menunggu')) {
      return Colors.orange;
    }
    return Colors.green;
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value.isNotEmpty ? value : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: statusColor ?? AppColors.textPrimary,
                fontWeight: isBold || statusColor != null
                    ? FontWeight.bold
                    : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipInfoRow(String label, List<String> values,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: values.map((value) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 13, color: AppColors.primary),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
