import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ReceiptPage extends StatelessWidget {
  final Map<String, dynamic> booking;

  const ReceiptPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    // Format price to IDR format
    String formatPrice(dynamic price) {
      if (price == null) return 'IDR 0';
      return 'IDR ${price.toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+$)"), (m) => "${m[1]},")}';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'E-Receipt',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary, size: 22),
            onPressed: () {},
          ),
        ],
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
                        color: Colors.black.withOpacity(0.06),
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
                              child: const Icon(Icons.check_rounded, color: Colors.green, size: 32),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Payment Successful',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatPrice(booking['price']),
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
                                color: AppColors.textSecondary.withOpacity(0.7),
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
                              color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade200,
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
                            _buildInfoRow('Venue', booking['venueName'] ?? '-', isBold: true),
                            _buildInfoRow('Court Type', booking['courtName'] ?? '-'),
                            _buildInfoRow('Booking Date', booking['date'] ?? '-'),
                            _buildInfoRow('Time / Duration', booking['time'] ?? '-'),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            _buildInfoRow('Payment Method', booking['paymentMethod'] ?? 'Virtual Account'),
                            _buildInfoRow('Order Status', 'Paid', statusColor: Colors.green),
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
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Verified Payment',
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
                  child: CircleAvatar(radius: 12, backgroundColor: AppColors.background),
                ),
                Positioned(
                  right: -12,
                  top: 155,
                  child: CircleAvatar(radius: 12, backgroundColor: AppColors.background),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Helpful text
            Text(
              'Show this e-receipt to the field staff upon arrival at the location for order validation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to Activities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: statusColor ?? AppColors.textPrimary,
                fontWeight: isBold || statusColor != null ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
