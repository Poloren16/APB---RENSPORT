import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state_widget.dart';
import '../data/venue_data.dart';
import 'payment_page.dart';

class KeranjangPage extends StatefulWidget {
  final String username;
  final String role;

  const KeranjangPage({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  final Set<int> _selectedItems = {};
  
  // Gunakan getter dengan pengaman list kosong jika null
  List<Map<String, dynamic>> get _cartItems => GlobalVenueData.cart;

  int get _selectedTotalPrice {
    int total = 0;
    final items = _cartItems;
    for (int i = 0; i < items.length; i++) {
      if (_selectedItems.contains(i)) {
        final price = items[i]['price'];
        if (price is int) total += price;
      }
    }
    return total;
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
    final items = _cartItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Keranjang Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedItems.length == items.length) {
                    _selectedItems.clear();
                  } else {
                    _selectedItems.addAll(List.generate(items.length, (i) => i));
                  }
                });
              },
              child: Text(
                _selectedItems.length == items.length ? 'Batal Semua' : 'Pilih Semua',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? EmptyStateWidget(
              message: 'Keranjangmu masih kosong',
              subMessage: 'Yuk, cari venue favoritmu dan mulai booking sekarang!',
              onActionPressed: () => Navigator.pop(context),
              actionLabel: 'Cari Venue',
              actionIcon: Icons.search_rounded,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildCartCard(items[index], index);
              },
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : _buildCheckoutSection(),
    );
  }

  Widget _buildCartCard(Map<String, dynamic> item, int index) {
    final Map<String, int>? services = item['services'] != null 
        ? Map<String, int>.from(item['services']) 
        : null;

    String timeDisplay = item['timeSlot']?.toString() ?? '';
    if (timeDisplay.contains('Slot: ')) {
      timeDisplay = timeDisplay.split('Slot: ').last;
    }

    final bool isSelected = _selectedItems.contains(index);

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
        border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Checkbox Area
              InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedItems.remove(index);
                    } else {
                      _selectedItems.add(index);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                  child: Checkbox(
                    value: isSelected,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedItems.add(index);
                        } else {
                          _selectedItems.remove(index);
                        }
                      });
                    },
                  ),
                ),
              ),
              
              // Content Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey, size: 30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['venueName'] ?? 'Nama Venue',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item['courtName'] ?? 'Lapangan'} • ${item['date'] ?? '-'}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            if (timeDisplay.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: timeDisplay.split(', ').map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(t, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10)),
                                )).toList(),
                              ),
                            if (services != null && services.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...services.entries.map((entry) {
                                final venueResults = GlobalVenueData.venues.where((v) => v['name'] == item['venueName']);
                                final venue = venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
                                final servicesList = venue['services'] as List<dynamic>? ?? [];
                                final serviceResults = servicesList.where((s) => s['id'] == entry.key);
                                String sName = serviceResults.isNotEmpty ? serviceResults.first['name'] : entry.key;
                                return Text('• $sName (x${entry.value})', style: const TextStyle(fontSize: 10, color: Colors.black54));
                              }).toList(),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              _formatCurrency(item['price'] as int? ?? 0),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () {
                          setState(() {
                            GlobalVenueData.cart.removeAt(index);
                            _selectedItems.remove(index);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutSection() {
    final int count = _selectedItems.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total ($count Item)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  _formatCurrency(_selectedTotalPrice),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: count > 0 ? () {
                  final List<Map<String, dynamic>> itemsToCheckout = [];
                  final currentCart = _cartItems;
                  for (int i = 0; i < currentCart.length; i++) {
                    if (_selectedItems.contains(i)) {
                      itemsToCheckout.add(currentCart[i]);
                    }
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(
                        username: widget.username,
                        role: widget.role,
                        venueName: itemsToCheckout.length == 1 ? itemsToCheckout.first['venueName'] : 'Beberapa Venue',
                        items: itemsToCheckout,
                      ),
                    ),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
