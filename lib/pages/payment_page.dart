import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/booking_utils.dart';
import './payment_instruction_page.dart';
import '../data/venue_data.dart';
import '../data/auth_data.dart';

class PaymentPage extends StatefulWidget {
  final String username;
  final String venueName;
  final String courtName;
  final String date;
  final String timeRange;
  final int price;
  final List<Map<String, String>> individualSlots;
  final Map<String, int> selectedServices;
  final String role;
  final List<Map<String, dynamic>> items;

  const PaymentPage({
    super.key,
    this.username = 'User',
    this.venueName = 'Venue Name',
    this.courtName = 'Court Name',
    this.date = 'Date',
    this.timeRange = 'Time',
    this.price = 0,
    this.individualSlots = const [],
    this.selectedServices = const {},
    this.role = 'End User',
    this.items = const [],
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isAgreed = false;
  String? _selectedPaymentMethodId;
  late Map<String, int> _localSelectedServices;
  bool _usePoints = false;
  int _availablePoints = 0;

  @override
  void initState() {
    super.initState();
    _localSelectedServices = Map<String, int>.from(widget.selectedServices);
    _availablePoints = GlobalAuthData.getAccount(widget.username)?.points ?? 0;
  }

  int get _totalPrice {
    int basePrice = 0;
    if (widget.items.isNotEmpty) {
      basePrice = widget.items.fold(0, (sum, item) => sum + (item['price'] as int));
    } else {
      basePrice = widget.price;
    }

    int serviceTotal = 0;
    // Gunakan venue name dari field atau item pertama jika dari keranjang
    String activeVenue = widget.items.isNotEmpty ? widget.items.first['venueName'] : widget.venueName;
    
    final venueResults = GlobalVenueData.venues.where((v) => v['name'] == activeVenue);
    final venue = venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
    final services = venue['services'] as List<dynamic>? ?? [];
    
    _localSelectedServices.forEach((id, qty) {
      final serviceResults = services.where((s) => s['id'] == id);
      if (serviceResults.isNotEmpty) {
        final service = serviceResults.first;
        serviceTotal += (service['price'] as int) * qty;
      }
    });
    
    int subTotal = basePrice + serviceTotal;
    if (_usePoints) {
      return (subTotal - _availablePoints).clamp(0, double.infinity).toInt();
    }
    return subTotal;
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.items.length <= 1) ...[
                    _buildSectionHeader('Venue'),
                    _buildVenueCard(widget.items.isNotEmpty ? widget.items.first['venueName'] : widget.venueName),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Detail Pemesanan'),
                    _buildBookingDetailCard(
                      venueName: widget.items.isNotEmpty ? widget.items.first['venueName'] : widget.venueName,
                      courtName: widget.items.isNotEmpty ? widget.items.first['courtName'] : widget.courtName,
                      date: widget.items.isNotEmpty ? widget.items.first['date'] : widget.date,
                      timeRange: widget.items.isNotEmpty ? widget.items.first['timeSlot'] : widget.timeRange,
                      price: widget.items.isNotEmpty ? widget.items.first['price'] : widget.price,
                      services: widget.items.isNotEmpty 
                          ? (widget.items.first['services'] != null ? Map<String, int>.from(widget.items.first['services']) : null)
                          : _localSelectedServices,
                    ),
                    const SizedBox(height: 12),
                    _buildAddServiceButton(),
                  ] else ...[
                    _buildSectionHeader('Rincian Pesanan (${widget.items.length})'),
                    ...widget.items.asMap().entries.map((entry) {
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildBookingDetailCard(
                          venueName: item['venueName'] ?? 'Venue',
                          courtName: item['courtName'] ?? 'Lapangan',
                          date: item['date'] ?? '-',
                          timeRange: item['timeSlot'] ?? '-',
                          price: item['price'] ?? 0,
                          services: item['services'] != null 
                              ? Map<String, int>.from(item['services']) 
                              : null,
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                    _buildAddServiceButton(),
                  ],

                  const SizedBox(height: 24),
                  _buildPointsSection(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Rincian Transaksi'),
                  _buildTransactionDetail(),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('Metode Pembayaran'),
                  _buildPaymentMethodSection(),
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
        icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Pembayaran',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.withValues(alpha: 0.1), height: 1),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildVenueCard(String name) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.stadium_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailCard({
    required String venueName,
    required String courtName,
    required String date,
    required String timeRange,
    required int price,
    Map<String, int>? services,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Text(
              courtName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(icon: Icons.calendar_today_rounded, label: date),
                const SizedBox(height: 10),
                _buildInfoRow(icon: Icons.access_time_filled_rounded, label: timeRange),
                
                if (services != null && services.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1),
                  ),
                  const Text('Layanan Tambahan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ...services.entries.map((entry) {
                    final venueResults = GlobalVenueData.venues.where((v) => v['name'] == venueName);
                    final venue = venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
                    final sList = venue['services'] as List<dynamic>? ?? [];
                    final sRes = sList.where((s) => s['id'] == entry.key);
                    if (sRes.isEmpty) return const SizedBox.shrink();
                    final s = sRes.first;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${s['name']} (x${entry.value})', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                          Text(_formatCurrency(s['price'] * entry.value), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAddServiceButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _showAddServiceSheet,
        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
        label: const Text('Tambah Layanan', style: TextStyle(fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: AppColors.primary.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildTransactionDetail() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          if (widget.items.isEmpty)
            _buildTransactionRow('Biaya Lapangan', widget.price)
          else ...[
            ...widget.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildTransactionRow(item['courtName'], item['price']),
            )).toList(),
          ],
          
          _buildServiceTransactionRows(),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          if (_usePoints && _availablePoints > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dipotong Poin Rensius', style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500)),
                  Text('-${_formatCurrency(_availablePoints > (widget.items.fold(0, (s, i) => s + (i['price'] as int)) + (widget.items.isEmpty ? widget.price : 0)) ? (widget.items.fold(0, (s, i) => s + (i['price'] as int)) + (widget.items.isEmpty ? widget.price : 0)) : _availablePoints)}', 
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          _buildTransactionRow('Biaya Layanan/Platform', 0, isFree: true),
          const SizedBox(height: 12),
          _buildTransactionRow('Total Pembayaran', _totalPrice, isBold: true),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(String label, int amount, {bool isFree = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: TextStyle(
            fontSize: isBold ? 15 : 13, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          isFree ? 'Gratis' : _formatCurrency(amount),
          style: TextStyle(
            fontSize: isBold ? 17 : 13, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
            color: isBold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTransactionRows() {
    if (_localSelectedServices.isEmpty) return const SizedBox.shrink();
    
    String activeVenue = widget.items.isNotEmpty ? widget.items.first['venueName'] : widget.venueName;
    final venueResults = GlobalVenueData.venues.where((v) => v['name'] == activeVenue);
    final venue = venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
    final services = venue['services'] as List<dynamic>? ?? [];
    
    return Column(
      children: _localSelectedServices.entries.map((entry) {
        final sRes = services.where((s) => s['id'] == entry.key);
        if (sRes.isEmpty) return const SizedBox.shrink();
        final s = sRes.first;
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _buildTransactionRow('${s['name']} (x${entry.value})', s['price'] * entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      children: [
        _buildPaymentOption('qris', 'QRIS (Gopay, OVO, Dana)', Icons.qr_code_2_rounded),
        _buildPaymentOption('gopay', 'GoPay (Uang Elektronik)', Icons.account_balance_wallet_rounded),
        _buildPaymentOption('bca', 'BCA Virtual Account', Icons.account_balance_rounded),
        _buildPaymentOption('mandiri', 'Mandiri Virtual Account', Icons.account_balance_rounded),
        _buildPaymentOption('bni', 'BNI Virtual Account', Icons.account_balance_rounded),
        _buildPaymentOption('credit_card', 'Kartu Kredit / Debit', Icons.credit_card_rounded),
      ],
    );
  }

  Widget _buildPointsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Rensius Point', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const Spacer(),
              Switch(
                value: _usePoints,
                onChanged: _availablePoints > 0 ? (v) => setState(() => _usePoints = v) : null,
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gunakan point kamu untuk memotong biaya pembayaran.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            'Tersedia: $_availablePoints Point (Rp$_availablePoints)',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String id, String name, IconData icon) {
    final isSelected = _selectedPaymentMethodId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethodId = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.02) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name, 
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected) 
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
            else
              Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.withValues(alpha: 0.3)))),
          ],
        ),
      ),
    );
  }

  void _showAddServiceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String activeVenue = widget.items.isNotEmpty ? widget.items.first['venueName'] : widget.venueName;
            final vRes = GlobalVenueData.venues.where((v) => v['name'] == activeVenue);
            final venue = vRes.isNotEmpty ? vRes.first : <String, dynamic>{};
            final sList = venue['services'] as List<dynamic>? ?? [];
            return Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  const Text('Tambah Layanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: sList.length,
                      itemBuilder: (context, i) {
                        final s = sList[i];
                        final id = s['id'] as String;
                        final qty = _localSelectedServices[id] ?? 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(_formatCurrency(s['price']), style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: qty > 0 ? () { setState(() => qty > 1 ? _localSelectedServices[id] = qty - 1 : _localSelectedServices.remove(id)); setModalState(() {}); } : null,
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                  ),
                                  Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    onPressed: () { setState(() => _localSelectedServices[id] = qty + 1); setModalState(() {}); },
                                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24, height: 24,
                  child: Checkbox(
                    value: _isAgreed, 
                    activeColor: AppColors.primary, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => setState(() => _isAgreed = v ?? false),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Saya menyetujui Syarat & Ketentuan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Bayar', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(_formatCurrency(_totalPrice), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 54,
                  width: 160,
                  child: ElevatedButton(
                    onPressed: (_isAgreed && _selectedPaymentMethodId != null) ? _processPayment : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: Colors.grey.shade200,
                    ),
                    child: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment() {
    // Hapus item dari keranjang jika berasal dari keranjang
    if (widget.items.isNotEmpty) {
      for (var item in widget.items) {
        GlobalVenueData.cart.removeWhere((cartItem) => 
          cartItem['venueName'] == item['venueName'] &&
          cartItem['courtName'] == item['courtName'] &&
          cartItem['date'] == item['date'] &&
          cartItem['timeSlot'] == item['timeSlot']
        );
      }
    }

    final orderId = 'ID${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentInstructionPage(
          paymentMethodId: _selectedPaymentMethodId ?? 'qris',
          paymentMethodName: _selectedPaymentMethodId?.toUpperCase() ?? 'QRIS',
          amount: _totalPrice,
          usedPoints: _usePoints ? (_availablePoints > (widget.items.fold(0, (s, i) => s + (i['price'] as int)) + (widget.items.isEmpty ? widget.price : 0)) ? (widget.items.fold(0, (s, i) => s + (i['price'] as int)) + (widget.items.isEmpty ? widget.price : 0)) : _availablePoints) : 0,
          orderId: orderId,
          venueName: widget.items.isNotEmpty ? widget.items.first['venueName'] : widget.venueName,
          courtName: widget.items.isNotEmpty ? '${widget.items.length} Lapangan' : widget.courtName,
          date: widget.items.isNotEmpty ? widget.items.first['date'] : widget.date,
          timeRange: widget.items.isNotEmpty ? widget.items.first['timeSlot'] : widget.timeRange,
          individualSlots: widget.individualSlots,
          selectedServices: _localSelectedServices,
          username: widget.username,
          role: widget.role,
        ),
      ),
    );
  }
}
