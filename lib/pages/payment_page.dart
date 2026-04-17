import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'booking_history.dart';
import '../utils/alert_utils.dart';
import './receipt_page.dart';
import '../utils/booking_utils.dart';
import './payment_instruction_page.dart';

class PaymentPage extends StatefulWidget {
  final String username;
  final String venueName;
  final String courtName;
  final String date;
  final String timeRange;
  final int price;
  final List<Map<String, String>> individualSlots;
  final String role;

  const PaymentPage({
    super.key,
    this.username = 'User',
    this.venueName = 'Bandung Elektrik Cigereleng Tennis Court',
    this.courtName = 'BEC Tennis Court Lap.A',
    this.date = 'Monday, 13 April 2026',
    this.timeRange = '06:00 - 07:00',
    this.price = 100000,
    this.individualSlots = const [],
    this.role = 'End User',
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isAgreed = false;
  bool _isTimeExpanded = false;
  String? _selectedPaymentMethodId;

  String _formatPrice(int price) {
    return 'IDR ${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Scrollable body ──────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Venue info card
                  _buildVenueCard(),
                  const SizedBox(height: 16),

                  // Booking detail card
                  _buildBookingDetailCard(),
                  const SizedBox(height: 12),

                  // Tambah Coach & Service button
                  _buildAddServiceButton(),
                  const SizedBox(height: 20),

                  // Detail Transaksi
                  _buildTransactionDetail(),
                  const SizedBox(height: 16),

                  // Metode Pembayaran
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Fixed bottom bar ─────────────────────────────
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Payment Details',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade100, height: 1),
      ),
    );
  }

  // ── Venue Card ──────────────────────────────────────────

  Widget _buildVenueCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Venue thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 62,
              height: 62,
              color: AppColors.secondary,
              child: Image.asset(
                'assets/images/leaf.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.secondary,
                  child: const Icon(Icons.sports_tennis_rounded,
                      color: AppColors.primary, size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Venue name
          Expanded(
            child: Text(
              widget.venueName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Booking Detail Card ─────────────────────────────────

  Widget _buildBookingDetailCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Court name header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Text(
              widget.courtName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date row
                _buildInfoRow(
                  icon: Icons.calendar_month_outlined,
                  label: widget.date,
                  isHighlight: false,
                ),
                const SizedBox(height: 10),

                // Time + price row (expandable)
                GestureDetector(
                  onTap: () =>
                      setState(() => _isTimeExpanded = !_isTimeExpanded),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.timeRange,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatPrice(widget.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isTimeExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),

                // Expanded detail
                if (_isTimeExpanded) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  _buildPriceRow('Court', widget.courtName, widget.price),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 14),

                // Court
                _buildDetailSection('Court', widget.courtName,
                    trailingPrice: widget.price),
                const SizedBox(height: 14),

                // Additional Service
                _buildDetailSection('Additional Service', '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required bool isHighlight,
  }) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: isHighlight ? AppColors.primary : AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
              color:
                  isHighlight ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, String value, {int? trailingPrice}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: value == '-'
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (trailingPrice != null)
              Text(
                _formatPrice(trailingPrice),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String sub, int price) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Text(
          _formatPrice(price),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // ── Add Service Button ──────────────────────────────────

  Widget _buildAddServiceButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add Service'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Transaction Detail ──────────────────────────────────

  Widget _buildTransactionDetail() {
    const platformFee = 0;
    final total = widget.price + platformFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with timer badge
          Row(
            children: [
              const Text(
                'Transaction Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Text(
                'Payment Limit',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '30 minutes',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),

          // Price rows
          _buildTransactionRow('Total Court Price', widget.price),
          const SizedBox(height: 10),
          _buildTransactionRow('Platform Fee', platformFee,
              isInfo: true, isFree: platformFee == 0),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          _buildTransactionRow('Total Payment', total, isBold: true),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(String label, int amount,
      {bool isInfo = false, bool isFree = false, bool isBold = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        if (isInfo) ...[
          const SizedBox(width: 4),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline_rounded,
                size: 10, color: AppColors.primary),
          ),
        ],
        const Spacer(),
        Text(
          isFree ? 'IDR 0' : _formatPrice(amount),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── Payment Method Section ──────────────────────────────

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'E-Wallet & QRIS',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _buildPaymentOption('qris', 'QRIS (Gopay, OVO, Dana)', Icons.qr_code_scanner_rounded),
          _buildPaymentOption('gopay', 'GoPay', Icons.account_balance_wallet_rounded),
          
          const SizedBox(height: 16),
          const Text(
            'Virtual Account (Bank Transfer)',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _buildPaymentOption('bca', 'BCA Virtual Account', Icons.account_balance_rounded),
          _buildPaymentOption('mandiri', 'Mandiri Virtual Account', Icons.account_balance_rounded),
          _buildPaymentOption('bni', 'BNI Virtual Account', Icons.account_balance_rounded),
          
          const SizedBox(height: 16),
          const Text(
            'Credit / Debit Card',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _buildPaymentOption('credit_card', 'Credit / Debit Card', Icons.credit_card_rounded),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String id, String name, IconData icon) {
    final isSelected = _selectedPaymentMethodId == id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethodId = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary)
            else
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Confirmation Dialog ──────────────────────────────────

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Payment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure the booking details and payment method are correct?',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Venue', widget.venueName),
                  _buildSummaryRow('Court', widget.courtName),
                  _buildSummaryRow('Date', widget.date),
                  _buildSummaryRow('Time', widget.timeRange),
                  _buildSummaryRow('Total', _formatPrice(widget.price)),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _processPayment(); // Finalize
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Yes, Pay Now'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Check Again',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    String paymentName = 'Virtual Account';
    if (_selectedPaymentMethodId == 'qris') paymentName = 'QRIS';
    if (_selectedPaymentMethodId == 'gopay') paymentName = 'GoPay';
    if (_selectedPaymentMethodId == 'bca') paymentName = 'BCA Virtual Account';
    if (_selectedPaymentMethodId == 'mandiri') paymentName = 'Mandiri Virtual Account';
    if (_selectedPaymentMethodId == 'bni') paymentName = 'BNI Virtual Account';
    if (_selectedPaymentMethodId == 'credit_card') paymentName = 'Credit / Debit Card';

    final orderId = 'ID${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentInstructionPage(
          paymentMethodId: _selectedPaymentMethodId ?? 'qris',
          paymentMethodName: paymentName,
          amount: widget.price,
          orderId: orderId,
          venueName: widget.venueName,
          courtName: widget.courtName,
          date: widget.date,
          timeRange: widget.timeRange,
          individualSlots: widget.individualSlots,
          username: widget.username,
          role: widget.role,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ──────────────────────────────────────────

  Widget _buildBottomBar() {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Agreement checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _isAgreed,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (v) => setState(() => _isAgreed = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms and Conditions',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Venue Policy',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Total + Pay button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Price',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatPrice(widget.price),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              // Pay button
              ElevatedButton(
                onPressed: (_isAgreed && _selectedPaymentMethodId != null)
                    ? () => _showConfirmationDialog()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.grey.shade500,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
