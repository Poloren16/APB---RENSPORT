import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/booking_utils.dart';
import './payment_instruction_page.dart';
import '../data/venue_data.dart';
import '../models/review_model.dart';

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
    this.venueName = 'Bandung Elektrik Cigereleng Tennis Court',
    this.courtName = 'BEC Tennis Court Lap.A',
    this.date = 'Senin, 13 April 2026',
    this.timeRange = '06:00 - 07:00',
    this.price = 100000,
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
  
  int get _totalPrice {
    if (widget.items.isNotEmpty) {
      return widget.items.fold(0, (sum, item) => sum + (item['price'] as int));
    }
    
    int serviceTotal = 0;
    final venueResults = GlobalVenueData.venues.where((v) => v['name'] == widget.venueName);
    final venue = venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
    final services = venue['services'] as List<dynamic>? ?? [];
    _localSelectedServices.forEach((id, qty) {
      final serviceResults = services.where((s) => s['id'] == id);
      if (serviceResults.isNotEmpty) {
        final service = serviceResults.first;
        serviceTotal += (service['price'] as int) * qty;
      }
    });
    return widget.price + serviceTotal;
  }

  @override
  void initState() {
    super.initState();
    _localSelectedServices = Map<String, int>.from(widget.selectedServices);
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.items.isEmpty) ...[
                    _buildVenueCard(widget.venueName),
                    const SizedBox(height: 16),
                    _buildBookingDetailCard(
                      venueName: widget.venueName,
                      courtName: widget.courtName,
                      date: widget.date,
                      timeRange: widget.timeRange,
                      price: widget.price,
                      services: _localSelectedServices,
                    ),
                  ] else ...[
                    const Text(
                      'Rincian Pesanan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...widget.items.asMap().entries.map((entry) {
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
                  ],
                  
                  if (widget.items.isEmpty) ...[
                    const SizedBox(height: 12),
                    _buildAddServiceButton(),
                  ],
                  
                  const SizedBox(height: 20),
                  _buildTransactionDetail(),
                  const SizedBox(height: 16),
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
        'Rincian Pembayaran',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade100, height: 1),
      ),
    );
  }

  Widget _buildVenueCard(String name) {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 50,
              height: 50,
              color: AppColors.secondary,
              child: const Icon(Icons.stadium_outlined, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    venueName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                Text(
                  _formatPrice(price),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(courtName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                _buildInfoRow(icon: Icons.calendar_month_outlined, label: date),
                const SizedBox(height: 8),
                _buildInfoRow(icon: Icons.access_time_rounded, label: timeRange),
                
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                const Text('Layanan Tambahan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                if (services == null || services.isEmpty)
                  const Text('-', style: TextStyle(fontSize: 13, color: Colors.grey))
                else
                  ...services.entries.map((entry) {
                    final venueResults = GlobalVenueData.venues.where((v) => v['name'] == venueName);
                    final venue = venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
                    final servicesList = venue['services'] as List<dynamic>? ?? [];
                    final serviceResults = servicesList.where((s) => s['id'] == entry.key);
                    if (serviceResults.isEmpty) return const SizedBox.shrink();
                    final service = serviceResults.first;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${service['name']} (x${entry.value})', style: const TextStyle(fontSize: 13)),
                          Text(_formatPrice(service['price'] * entry.value), style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }).toList(),
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
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
      ],
    );
  }

  Widget _buildAddServiceButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showAddServiceSheet,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Tambah Layanan'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildTransactionDetail() {
    const platformFee = 0;
    final total = _totalPrice + platformFee;

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
          Row(
            children: [
              const Text('Rincian Transaksi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                child: const Text('Batas 30 Menit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          
          if (widget.items.isEmpty)
            _buildTransactionRow('Harga Lapangan', widget.price)
          else
            ...widget.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTransactionRow(item['courtName'], item['price']),
            )).toList(),

          if (widget.items.isEmpty) ..._buildServiceTransactionRows(),
          
          const SizedBox(height: 10),
          _buildTransactionRow('Biaya Platform', platformFee, isFree: platformFee == 0),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _buildTransactionRow('Total Pembayaran', total, isBold: true),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(String label, int amount, {bool isFree = false, bool isBold = false}) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w600 : FontWeight.w400)),
        const Spacer(),
        Text(
          isFree ? 'Gratis' : _formatPrice(amount),
          style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: isBold ? AppColors.primary : AppColors.textPrimary),
        ),
      ],
    );
  }

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
          const Text('Metode Pembayaran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _buildPaymentOption('qris', 'QRIS (Gopay, OVO, Dana)', Icons.qr_code_scanner_rounded),
          _buildPaymentOption('bca', 'BCA Virtual Account', Icons.account_balance_rounded),
          _buildPaymentOption('mandiri', 'Mandiri Virtual Account', Icons.account_balance_rounded),
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
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400))),
            if (isSelected) const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildServiceTransactionRows() {
    if (_localSelectedServices.isEmpty) return [];
    final venueResults = GlobalVenueData.venues.where((v) => v['name'] == widget.venueName);
    final venue = venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
    final services = venue['services'] as List<dynamic>? ?? [];
    return _localSelectedServices.entries.map((entry) {
      final serviceResults = services.where((s) => s['id'] == entry.key);
      if (serviceResults.isEmpty) return const SizedBox.shrink();
      final service = serviceResults.first;
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _buildTransactionRow('${service['name']} (x${entry.value})', service['price'] * entry.value),
      );
    }).toList();
  }

  void _showAddServiceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final venueResults = GlobalVenueData.venues.where((v) => v['name'] == widget.venueName);
            final venue = venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
            final services = venue['services'] as List<dynamic>? ?? [];
            return DraggableScrollableSheet(
              initialChildSize: 0.6, expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text('Kelola Layanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          final service = services[index];
                          final id = service['id'] as String;
                          final currentQty = _localSelectedServices[id] ?? 0;
                          return ListTile(
                            title: Text(service['name']),
                            subtitle: Text(_formatPrice(service['price'])),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(onPressed: currentQty > 0 ? () { setState(() => currentQty > 1 ? _localSelectedServices[id] = currentQty - 1 : _localSelectedServices.remove(id)); setModalState(() {}); } : null, icon: const Icon(Icons.remove_circle_outline)),
                                Text('$currentQty'),
                                IconButton(onPressed: () { setState(() => _localSelectedServices[id] = currentQty + 1); setModalState(() {}); }, icon: const Icon(Icons.add_circle_outline)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Simpan')),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Checkbox(value: _isAgreed, activeColor: AppColors.primary, onChanged: (v) => setState(() => _isAgreed = v ?? false)),
              const Expanded(child: Text('Saya menyetujui Syarat & Ketentuan dan Kebijakan Venue', style: TextStyle(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pembayaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(_formatPrice(_totalPrice), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ],
              ),
              ElevatedButton(
                onPressed: (_isAgreed && _selectedPaymentMethodId != null) ? _processPayment : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    final orderId = 'ID${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentInstructionPage(
          paymentMethodId: _selectedPaymentMethodId ?? 'qris',
          paymentMethodName: _selectedPaymentMethodId?.toUpperCase() ?? 'QRIS',
          amount: _totalPrice,
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

class _TimeGroup {
  final String period;
  final String range;
  final IconData icon;
  final List<_TimeSlot> slots;
  const _TimeGroup({required this.period, required this.range, required this.icon, required this.slots});
}

class _TimeSlot {
  final String time;
  final int originalPrice;
  final int price;
  final bool isAvailable;
  const _TimeSlot(this.time, this.originalPrice, this.price, this.isAvailable);
}
