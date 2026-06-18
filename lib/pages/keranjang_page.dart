import 'package:flutter/material.dart';
import 'dart:io';
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
  final Set<String> _selectedRows = {};

  @override
  void initState() {
    super.initState();
    // Muat data venue terbaru dari Supabase agar stok layanan di keranjang akurat
    GlobalVenueData.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  // Gunakan getter dengan pengaman list kosong jika null
  List<Map<String, dynamic>> get _cartItems => GlobalVenueData.cart;

  int get _selectedTotalPrice {
    int total = 0;
    final rows = _cartRows;
    for (final row in rows) {
      if (_selectedRows.contains(row.selectionKey)) {
        total += row.price;
      }
    }
    return total;
  }

  List<_CartCourtRow> get _cartRows {
    final rows = <_CartCourtRow>[];
    final items = _cartItems;
    for (int i = 0; i < items.length; i++) {
      rows.addAll(_buildCourtRowsForItem(items[i], i));
    }
    return rows;
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
    final groupedItems = _groupCartItemsByVenue(items);
    final selectableRows = _cartRows;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Keranjang Saya',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedRows.length == selectableRows.length) {
                      _selectedRows.clear();
                    } else {
                      _selectedRows
                        ..clear()
                        ..addAll(selectableRows.map((row) => row.selectionKey));
                    }
                  });
                },
                child: Text(
                  _selectedRows.length == selectableRows.length
                      ? 'Batal Semua'
                      : 'Pilih Semua',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Container(color: Colors.grey.withValues(alpha: 0.1), height: 1),
        ),
      ),
      body: items.isEmpty
          ? EmptyStateWidget(
              message: 'Keranjangmu masih kosong',
              subMessage:
                  'Yuk, cari venue favoritmu dan mulai booking sekarang!',
              onActionPressed: () => Navigator.pop(context),
              actionLabel: 'Cari Venue',
              actionIcon: Icons.search_rounded,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedItems.length,
              itemBuilder: (context, index) {
                final group = groupedItems[index];
                return _buildVenueCartCard(group.key, group.value);
              },
            ),
      bottomNavigationBar: items.isEmpty ? null : _buildCheckoutSection(),
    );
  }

  List<MapEntry<String, List<MapEntry<int, Map<String, dynamic>>>>>
      _groupCartItemsByVenue(
    List<Map<String, dynamic>> items,
  ) {
    final grouped = <String, List<MapEntry<int, Map<String, dynamic>>>>{};
    for (int i = 0; i < items.length; i++) {
      final venueName = items[i]['venueName']?.toString() ?? 'Nama Venue';
      grouped.putIfAbsent(venueName, () => []).add(MapEntry(i, items[i]));
    }
    return grouped.entries.toList();
  }

  Widget _buildVenueCartCard(
    String venueName,
    List<MapEntry<int, Map<String, dynamic>>> entries,
  ) {
    final venueResults =
        GlobalVenueData.venues.where((v) => v['name'] == venueName);
    final venue = venueResults.isNotEmpty ? venueResults.first : null;
    final imagePath = venue != null ? (venue['image']?.toString() ?? '') : '';
    final rows = entries
        .expand((entry) => _buildCourtRowsForItem(entry.value, entry.key))
        .toList();
    final isVenueSelected = rows.isNotEmpty &&
        rows.every((row) => _selectedRows.contains(row.selectionKey));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isVenueSelected
              ? AppColors.primary.withValues(alpha: 0.45)
              : Colors.grey.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  _buildVenueImage(imagePath),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      venueName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.12)),
            ...rows.asMap().entries.map((entry) {
              final isLast = entry.key == rows.length - 1;
              return _buildBookingRow(entry.value, isLast: isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueImage(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 58,
        height: 58,
        color: Colors.grey[200],
        child: Builder(builder: (context) {
          if (imagePath.isEmpty) {
            return const Icon(Icons.image, color: Colors.grey, size: 28);
          }
          final isRemote = imagePath.startsWith('http://') ||
              imagePath.startsWith('https://');
          final isAsset = imagePath.startsWith('assets/');
          try {
            if (isRemote) {
              return Image.network(
                imagePath,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, color: Colors.grey, size: 28),
              );
            } else if (isAsset) {
              return Image.asset(
                imagePath,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, color: Colors.grey, size: 28),
              );
            } else {
              return Image.file(
                File(imagePath),
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, color: Colors.grey, size: 28),
              );
            }
          } catch (e) {
            return const Icon(Icons.image, color: Colors.grey, size: 28);
          }
        }),
      ),
    );
  }

  Widget _buildBookingRow(_CartCourtRow row, {required bool isLast}) {
    final isSelected = _selectedRows.contains(row.selectionKey);
    final services = row.services;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.025)
            : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isLast
                ? Colors.transparent
                : Colors.grey.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: InkWell(
        onTap: () => _toggleSelected(row.selectionKey),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                onChanged: (_) => _toggleSelected(row.selectionKey),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSlotGroupInfo({
                      'courtName': row.courtName,
                      'date': row.date,
                      'times': row.times,
                      'price': row.courtPrice,
                    }),
                    if (services.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildServicesInfo(row.item, services),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Hapus',
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 20),
                ),
                onPressed: () => _removeCourtRow(row),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotGroupInfo(Map<String, dynamic> group) {
    final times = group['times'] as List<String>;
    final date = group['date']?.toString() ?? '-';
    final price = group['price'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group['courtName']?.toString() ?? 'Lapangan',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        if (times.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: times.map((time) => _buildTimeChip(time)).toList(),
          ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                date,
                style: TextStyle(
                    color: Colors.grey[600], fontSize: 12, height: 1.35),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatCurrency(price),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeChip(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildServicesInfo(
      Map<String, dynamic> item, Map<String, int> services) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: services.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline,
                    size: 10, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_getServiceName(item, entry.key)} (x${entry.value})',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _buildDisplaySlotGroups(
      Map<String, dynamic> item) {
    final date = item['date']?.toString() ?? '-';
    final individualSlots = item['individualSlots'] as List<dynamic>?;
    if (individualSlots != null && individualSlots.isNotEmpty) {
      final grouped = <String, List<String>>{};
      for (final slotObj in individualSlots) {
        final slot = Map<String, dynamic>.from(slotObj as Map);
        final courtName = slot['court']?.toString() ??
            item['courtName']?.toString() ??
            'Lapangan';
        final time = _normalizeTime(slot['time']?.toString() ?? '');
        grouped.putIfAbsent(courtName, () => []);
        if (time.isNotEmpty) grouped[courtName]!.add(time);
      }

      final result = grouped.entries.map((entry) {
        final times = entry.value..sort();
        return {
          'courtName': entry.key,
          'date': date,
          'times': times,
          'price': _calculateCourtPrice(item, entry.key, times),
        };
      }).toList();

      if (result.isNotEmpty &&
          result.every((group) => (group['price'] as int? ?? 0) == 0)) {
        final fallbackPrice =
            ((item['price'] as int? ?? 0) - _calculateServicesTotal(item))
                .clamp(0, double.infinity)
                .toInt();
        final basePrice = fallbackPrice ~/ result.length;
        final remainder = fallbackPrice % result.length;
        for (int i = 0; i < result.length; i++) {
          result[i]['price'] =
              basePrice + (i == result.length - 1 ? remainder : 0);
        }
      }

      return result;
    }

    final times = _splitTimes(item['timeSlot']?.toString() ?? '');
    return [
      {
        'courtName': item['courtName']?.toString() ?? 'Lapangan',
        'date': date,
        'times': times,
        'price': _calculateCourtPrice(
            item, item['courtName']?.toString() ?? 'Lapangan', times),
      },
    ];
  }

  List<_CartCourtRow> _buildCourtRowsForItem(
      Map<String, dynamic> item, int itemIndex) {
    final groups = _buildDisplaySlotGroups(item);
    final itemServices = item['services'] != null
        ? Map<String, int>.from(item['services'])
        : <String, int>{};
    final servicesByGroup =
        _allocateServicesToGroups(item, groups, itemServices);

    return groups.asMap().entries.map((entry) {
      final groupIndex = entry.key;
      final group = entry.value;
      final courtName = group['courtName']?.toString() ?? 'Lapangan';
      final times = List<String>.from(group['times'] as List);
      final courtPrice = group['price'] as int? ?? 0;
      final services = servicesByGroup[groupIndex];
      return _CartCourtRow(
        selectionKey: '$itemIndex:$groupIndex',
        itemIndex: itemIndex,
        item: item,
        courtName: courtName,
        date: group['date']?.toString() ?? '-',
        times: times,
        courtPrice: courtPrice,
        services: services,
        price: courtPrice + _calculateServicesTotalForMap(item, services),
      );
    }).toList();
  }

  List<Map<String, int>> _allocateServicesToGroups(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> groups,
    Map<String, int> itemServices,
  ) {
    final allocated = List.generate(groups.length, (_) => <String, int>{});
    if (itemServices.isEmpty || groups.isEmpty) return allocated;

    final assigned = <String>{};
    for (int i = 0; i < groups.length; i++) {
      final courtName = groups[i]['courtName']?.toString() ?? '';
      final filtered = _filterServicesForCourt(item, courtName, itemServices);
      filtered.forEach((key, qty) {
        if (!assigned.contains(key)) {
          allocated[i][key] = qty;
          assigned.add(key);
        }
      });
    }

    final leftovers = <String, int>{};
    itemServices.forEach((key, qty) {
      if (!assigned.contains(key)) leftovers[key] = qty;
    });
    if (leftovers.isNotEmpty) {
      allocated.first.addAll(leftovers);
    }

    return allocated;
  }

  Map<String, int> _filterServicesForCourt(
    Map<String, dynamic> item,
    String courtName,
    Map<String, int> services,
  ) {
    if (services.isEmpty) return {};

    final venueName = item['venueName']?.toString() ?? '';
    final venueResults =
        GlobalVenueData.venues.where((v) => v['name'] == venueName);
    if (venueResults.isEmpty) return {};

    final courts = venueResults.first['courts'] as List<dynamic>? ?? [];
    final courtResults = courts.where((c) {
      final court = Map<String, dynamic>.from(c as Map);
      return court['name']?.toString() == courtName;
    });
    if (courtResults.isEmpty) return {};

    final court = Map<String, dynamic>.from(courtResults.first as Map);
    final courtServices = court['services'] as List<dynamic>? ?? [];
    final serviceKeys = <String>{};
    for (final serviceObj in courtServices) {
      final service = Map<String, dynamic>.from(serviceObj as Map);
      final name = service['name']?.toString() ?? '';
      final id = service['id']?.toString() ?? name;
      if (id.isNotEmpty) serviceKeys.add(id);
      if (name.isNotEmpty) serviceKeys.add(name);
    }

    final filtered = <String, int>{};
    services.forEach((key, qty) {
      if (serviceKeys.contains(key)) filtered[key] = qty;
    });
    return filtered;
  }

  int _calculateCourtPrice(
      Map<String, dynamic> item, String courtName, List<String> times) {
    final venueName = item['venueName']?.toString() ?? '';
    final dateStr = item['date']?.toString() ?? '';
    int total = 0;
    for (final time in times) {
      final start = time.contains(' - ') ? time.split(' - ').first : time;
      final startHour = int.tryParse(start.split(':').first);
      if (startHour != null) {
        total += _getSlotPrice(venueName, courtName, dateStr, startHour);
      }
    }
    if (total > 0) return total;

    final servicesTotal = _calculateServicesTotal(item);
    return ((item['price'] as int? ?? 0) - servicesTotal)
        .clamp(0, double.infinity)
        .toInt();
  }

  int _getSlotPrice(
      String venueName, String courtName, String dateStr, int startHour) {
    final venueResults =
        GlobalVenueData.venues.where((v) => v['name'] == venueName);
    if (venueResults.isEmpty) return 0;

    final courts = venueResults.first['courts'] as List<dynamic>? ?? [];
    final courtResults = courts.where((c) {
      final court = Map<String, dynamic>.from(c as Map);
      return court['name']?.toString() == courtName;
    });
    if (courtResults.isEmpty) return 0;

    final court = Map<String, dynamic>.from(courtResults.first as Map);
    final dayName =
        dateStr.contains(',') ? dateStr.split(',').first.trim() : '';
    if (dayName.isEmpty) return 0;

    final priceModeDay = court['priceModeDay'] as Map? ?? {};
    final priceMode = priceModeDay[dayName] ?? court['priceMode'] ?? 'perDay';
    final startStr = '${startHour.toString().padLeft(2, '0')}:00';

    if (priceMode == 'perSlot') {
      final pricePerSlot = court['pricePerSlot'] as Map? ?? {};
      final val = pricePerSlot['${dayName}_$startStr']
              ?.toString()
              .replaceAll(RegExp(r'[^0-9]'), '') ??
          '';
      final slotPrice = int.tryParse(val);
      if (slotPrice != null && slotPrice >= 0) return slotPrice;
    }

    final priceDay = court['priceDay'] as Map? ?? {};
    final dayVal =
        priceDay[dayName]?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    return int.tryParse(dayVal) ?? 0;
  }

  List<String> _splitTimes(String rawTime) {
    String timeDisplay = rawTime;
    if (timeDisplay.contains('Slot: ')) {
      timeDisplay = timeDisplay.split('Slot: ').last;
    }
    return timeDisplay
        .split(',')
        .map((time) => _normalizeTime(time.trim()))
        .where((time) => time.isNotEmpty)
        .toList();
  }

  String _normalizeTime(String rawTime) {
    final time = rawTime.trim();
    if (time.isEmpty) return '';
    if (time.contains(' - ')) return time;

    final startHour = int.tryParse(time.split(':').first);
    if (startHour == null) return time;
    final endHour = startHour + 1;
    return '${startHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00';
  }

  int _calculateServicesTotal(Map<String, dynamic> item) {
    final services = item['services'] != null
        ? Map<String, int>.from(item['services'])
        : null;
    if (services == null || services.isEmpty) return 0;

    int total = 0;
    final servicesList = _getVenueServices(item['venueName']?.toString() ?? '');
    services.forEach((key, qty) {
      final match =
          servicesList.where((s) => s['id'] == key || s['name'] == key);
      if (match.isNotEmpty) {
        final priceRaw = match.first['price'];
        final price = priceRaw is int
            ? priceRaw
            : int.tryParse(
                    priceRaw?.toString().replaceAll(RegExp(r'[^0-9]'), '') ??
                        '') ??
                0;
        total += price * qty;
      }
    });
    return total;
  }

  int _calculateServicesTotalForMap(
      Map<String, dynamic> item, Map<String, int> services) {
    if (services.isEmpty) return 0;

    int total = 0;
    final servicesList = _getVenueServices(item['venueName']?.toString() ?? '');
    services.forEach((key, qty) {
      final match =
          servicesList.where((s) => s['id'] == key || s['name'] == key);
      if (match.isNotEmpty) {
        final priceRaw = match.first['price'];
        final price = priceRaw is int
            ? priceRaw
            : int.tryParse(
                    priceRaw?.toString().replaceAll(RegExp(r'[^0-9]'), '') ??
                        '') ??
                0;
        total += price * qty;
      }
    });
    return total;
  }

  String _getServiceName(Map<String, dynamic> item, String key) {
    final servicesList = _getVenueServices(item['venueName']?.toString() ?? '');
    final serviceResults =
        servicesList.where((s) => s['id'] == key || s['name'] == key);
    return serviceResults.isNotEmpty
        ? serviceResults.first['name']?.toString() ?? key
        : key;
  }

  List<Map<String, dynamic>> _getVenueServices(String venueName) {
    final venueResults =
        GlobalVenueData.venues.where((v) => v['name'] == venueName);
    final venue =
        venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
    final courtsList = venue['courts'] as List<dynamic>? ?? [];
    final seen = <String>{};
    final services = <Map<String, dynamic>>[];
    for (final c in courtsList) {
      final courtServices = (c as Map)['services'] as List<dynamic>? ?? [];
      for (final s in courtServices) {
        final sMap = Map<String, dynamic>.from(s as Map);
        final name = sMap['name']?.toString() ?? '';
        final id = sMap['id']?.toString() ?? name;
        sMap['id'] = id;
        if (name.isNotEmpty && !seen.contains(name)) {
          seen.add(name);
          services.add(sMap);
        }
      }
    }
    return services;
  }

  void _toggleSelected(String selectionKey) {
    setState(() {
      if (_selectedRows.contains(selectionKey)) {
        _selectedRows.remove(selectionKey);
      } else {
        _selectedRows.add(selectionKey);
      }
    });
  }

  void _removeCourtRow(_CartCourtRow row) {
    setState(() {
      final item = GlobalVenueData.cart[row.itemIndex];
      final individualSlots = item['individualSlots'] as List<dynamic>?;
      final hasMultipleCourts = individualSlots != null &&
          individualSlots
                  .map((slotObj) =>
                      Map<String, dynamic>.from(slotObj as Map)['court']
                          ?.toString())
                  .where((court) => court != null && court.isNotEmpty)
                  .toSet()
                  .length >
              1;

      if (individualSlots == null ||
          individualSlots.isEmpty ||
          !hasMultipleCourts) {
        GlobalVenueData.cart.removeAt(row.itemIndex);
      } else {
        final remainingSlots = individualSlots.where((slotObj) {
          final slot = Map<String, dynamic>.from(slotObj as Map);
          return slot['court']?.toString() != row.courtName;
        }).toList();

        if (remainingSlots.isEmpty) {
          GlobalVenueData.cart.removeAt(row.itemIndex);
        } else {
          item['individualSlots'] = remainingSlots;
          final remainingCourts = remainingSlots
              .map((slotObj) =>
                  Map<String, dynamic>.from(slotObj as Map)['court']
                      ?.toString())
              .where((court) => court != null && court.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();
          final remainingTimes = remainingSlots
              .map((slotObj) => _normalizeTime(
                  Map<String, dynamic>.from(slotObj as Map)['time']
                          ?.toString() ??
                      ''))
              .where((time) => time.isNotEmpty)
              .toList()
            ..sort();
          item['courtName'] = remainingCourts.join(', ');
          item['timeSlot'] = remainingTimes.join(', ');
          final remainingGroups = _buildDisplaySlotGroups(item);
          final remainingCourtTotal = remainingGroups.fold<int>(
            0,
            (sum, group) => sum + (group['price'] as int? ?? 0),
          );
          item['price'] = remainingCourtTotal + _calculateServicesTotal(item);
        }
      }
      _selectedRows.clear();
      GlobalVenueData.saveCart();
    });
  }

  Map<String, dynamic> _buildCheckoutItem(_CartCourtRow row) {
    final checkoutItem = Map<String, dynamic>.from(row.item);
    final originalSlots = row.item['individualSlots'] as List<dynamic>?;
    final selectedSlots = originalSlots != null && originalSlots.isNotEmpty
        ? originalSlots
            .where((slotObj) {
              final slot = Map<String, dynamic>.from(slotObj as Map);
              return slot['court']?.toString() == row.courtName;
            })
            .map((slotObj) => Map<String, dynamic>.from(slotObj as Map))
            .toList()
        : row.times
            .map((time) => {'court': row.courtName, 'time': time})
            .toList();

    checkoutItem['courtName'] = row.courtName;
    checkoutItem['timeSlot'] =
        '${row.times.length} Slot: ${row.times.join(', ')}';
    checkoutItem['individualSlots'] = selectedSlots;
    checkoutItem['price'] = row.price;
    checkoutItem['services'] = Map<String, int>.from(row.services);
    return checkoutItem;
  }

  Widget _buildCheckoutSection() {
    final int count = _selectedRows.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total ($count Item)',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatCurrency(_selectedTotalPrice),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 54,
              width: 160,
              child: ElevatedButton(
                onPressed: count > 0
                    ? () {
                        final List<Map<String, dynamic>> itemsToCheckout = [];
                        for (final row in _cartRows) {
                          if (_selectedRows.contains(row.selectionKey)) {
                            itemsToCheckout.add(_buildCheckoutItem(row));
                          }
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentPage(
                              username: widget.username,
                              role: widget.role,
                              venueName: itemsToCheckout.length == 1
                                  ? itemsToCheckout.first['venueName']
                                  : 'Beberapa Venue',
                              items: itemsToCheckout,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.grey.shade200,
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartCourtRow {
  final String selectionKey;
  final int itemIndex;
  final Map<String, dynamic> item;
  final String courtName;
  final String date;
  final List<String> times;
  final int courtPrice;
  final Map<String, int> services;
  final int price;

  const _CartCourtRow({
    required this.selectionKey,
    required this.itemIndex,
    required this.item,
    required this.courtName,
    required this.date,
    required this.times,
    required this.courtPrice,
    required this.services,
    required this.price,
  });
}
