import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_colors.dart';
import './payment_instruction_page.dart';
import '../data/venue_data.dart';
import '../data/auth_data.dart';
import '../services/midtrans_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/alert_utils.dart';
import '../utils/booking_utils.dart';


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

  void _clampSelectedServices(
    Map<String, int> selectedSvc, 
    String venueName, 
    String courtName, {
    String dateStr = '',
    String timeRange = '',
    List<Map<String, dynamic>> otherCheckedItems = const [],
  }) {
    try {
      final vRes = GlobalVenueData.venues.where((v) => v['name'] == venueName);
      if (vRes.isEmpty) return;
      final venue = vRes.first;
      final courtsList = venue['courts'] as List<dynamic>? ?? [];
      final targetCourts = courtName.isNotEmpty ? courtsList.where((c) => c['name'] == courtName).toList() : [];
      final sourceCourts = targetCourts.isNotEmpty ? targetCourts : courtsList;
      final seenSvc = <String>{};
      final sList = <Map<String, dynamic>>[];
      for (final c in sourceCourts) {
        final cs = c['services'] as List<dynamic>? ?? [];
        for (final s in cs) {
          final sm = Map<String, dynamic>.from(s as Map);
          final sn = sm['name']?.toString() ?? '';
          sm['id'] = sm['id']?.toString() ?? sn;
          if (sn.isNotEmpty && !seenSvc.contains(sn)) {
            seenSvc.add(sn);
            sList.add(sm);
          }
        }
      }
      for (final service in sList) {
        final id = service['id']?.toString() ?? '';
        final sName = service['name']?.toString() ?? id;
        final stockRaw = service['stock'];
        final baseStock = stockRaw is int ? stockRaw : int.tryParse(stockRaw?.toString() ?? '') ?? 99;
        
        // Hitung stok secara dinamis jika ada data tanggal dan jam sewa
        int stock = (dateStr.isNotEmpty && timeRange.isNotEmpty)
            ? BookingUtils.getAvailableServiceStock(
                venueName: venueName,
                serviceName: sName,
                baseStock: baseStock,
                dateStr: dateStr,
                timeRange: timeRange,
              )
            : baseStock;
            
        // Deduct quantities already allocated to the same service name on overlapping times in otherCheckedItems
        if (dateStr.isNotEmpty && timeRange.isNotEmpty && otherCheckedItems.isNotEmpty) {
          final List<String> selectedTimes = timeRange
              .split(',')
              .map((t) => t.trim().split(' - ')[0].trim())
              .where((t) => t.isNotEmpty)
              .toList();

          int alreadyAllocated = 0;
          for (final other in otherCheckedItems) {
            final otherVenue = (other['venueName'] ?? '').toString();
            final otherDate = (other['date'] ?? '').toString();
            final otherTime = (other['timeSlot'] ?? '').toString();
            if (otherVenue == venueName && otherDate == dateStr) {
              bool hasOverlap = false;
              for (final t in selectedTimes) {
                if (otherTime.contains(t)) {
                  hasOverlap = true;
                  break;
                }
              }
              if (hasOverlap) {
                final otherServices = other['services'];
                if (otherServices is Map) {
                  final otherQty = otherServices[id] ?? otherServices[sName] ?? 0;
                  if (otherQty is int) {
                    alreadyAllocated += otherQty;
                  } else {
                    alreadyAllocated += int.tryParse(otherQty.toString()) ?? 0;
                  }
                }
              }
            }
          }
          stock = (stock - alreadyAllocated).clamp(0, baseStock);
        }
            
        final qty = selectedSvc[id] ?? 0;
        if (qty > stock) {
          if (stock > 0) {
            selectedSvc[id] = stock;
          } else {
            selectedSvc.remove(id);
          }
        }
      }
    } catch (e) {
      print('Gagal clamp service qty di PaymentPage: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.items.length == 1) {
      final itemSvc = widget.items.first['services'];
      _localSelectedServices = itemSvc != null ? Map<String, int>.from(itemSvc) : {};
    } else {
      _localSelectedServices = Map<String, int>.from(widget.selectedServices);
    }

    GlobalVenueData.init().then((_) {
      if (mounted) {
        setState(() {
          // 1. Clamp services inside all items (both single-item and multi-item) and adjust item prices
          if (widget.items.isNotEmpty) {
            bool cartChanged = false;
            final List<Map<String, dynamic>> processedItems = [];
            for (final item in widget.items) {
              final itemSvc = item['services'];
              if (itemSvc != null) {
                final Map<String, int> svcMap = Map<String, int>.from(itemSvc);
                final oldSvcCost = _calcServiceCost(svcMap, item['venueName']?.toString() ?? '', item['courtName']?.toString() ?? '');
                _clampSelectedServices(
                  svcMap, 
                  item['venueName']?.toString() ?? '', 
                  item['courtName']?.toString() ?? '',
                  dateStr: item['date']?.toString() ?? '',
                  timeRange: item['timeSlot']?.toString() ?? '',
                  otherCheckedItems: processedItems,
                );
                final newSvcCost = _calcServiceCost(svcMap, item['venueName']?.toString() ?? '', item['courtName']?.toString() ?? '');
                
                // Simpan map hasil clamp kembali ke item agar booking dibuat dengan data yang benar
                item['services'] = svcMap;
                
                if (oldSvcCost != newSvcCost) {
                  final int oldPrice = item['price'] as int? ?? 0;
                  item['price'] = oldPrice - (oldSvcCost - newSvcCost);
                  cartChanged = true;
                }
              }
              processedItems.add(item);
            }
            if (cartChanged) {
              GlobalVenueData.saveCart();
            }
          }

          // 2. Sinkronisasikan _localSelectedServices dengan map yang sudah ter-clamp
          if (widget.items.length == 1) {
            final itemSvc = widget.items.first['services'];
            _localSelectedServices = itemSvc != null ? Map<String, int>.from(itemSvc) : {};
          } else if (widget.items.isEmpty) {
            // Sewa langsung: clamp direct selected services
            _clampSelectedServices(
              _localSelectedServices, 
              widget.venueName, 
              widget.courtName,
              dateStr: widget.date,
              timeRange: widget.timeRange,
            );
          }
        });
      }
    });


    _availablePoints = GlobalAuthData.getAccount(widget.username)?.points ?? 0;
  }

  int get _totalPrice {
    int basePrice = 0;

    if (widget.items.isNotEmpty) {
      if (widget.items.length == 1) {
        // Single cart item checkout: recalculate slot base price to avoid double counting services,
        // and allow dynamically updating services.
        final item = widget.items.first;
        final vName = item['venueName']?.toString() ?? widget.venueName;
        final cName = item['courtName']?.toString() ?? widget.courtName;
        final dStr = item['date']?.toString() ?? widget.date;
        final tSlot = item['timeSlot']?.toString() ?? widget.timeRange;
        final List<dynamic>? itemIndividualSlots = item['individualSlots'] as List<dynamic>?;
        if (itemIndividualSlots != null && itemIndividualSlots.isNotEmpty) {
          basePrice = itemIndividualSlots.fold(0, (sum, slotObj) {
            final slot = Map<String, dynamic>.from(slotObj as Map);
            final courtName = slot['court']?.toString() ?? cName;
            final timeStr = slot['time']?.toString() ?? '';
            final startStr = timeStr.contains(' - ') ? timeStr.split(' - ')[0] : timeStr;
            final h = int.tryParse(startStr.split(':')[0]) ?? 0;
            return sum + _getSlotPrice(vName, courtName, dStr, h);
          });
        } else {
          final hours = _parseStartHours(tSlot);
          if (hours.isNotEmpty) {
            basePrice = hours.fold(0, (sum, h) => sum + _getSlotPrice(vName, cName, dStr, h));
          } else {
            basePrice = item['price'] as int? ?? 0;
          }
        }
      } else {
        // Multiple cart items checkout: static sum of cart prices
        basePrice = widget.items.fold(0, (sum, item) => sum + (item['price'] as int));
      }
    } else {
      // Direct booking: widget.price include initial services (dari court_detail_page._totalPrice)
      // Recalculate court-only price dari slot data agar perubahan services akurat
      if (widget.individualSlots.isNotEmpty) {
        basePrice = widget.individualSlots.fold(0, (sum, slot) {
          final cName = slot['court'] ?? widget.courtName;
          final timeStr = slot['time'] ?? '';
          final startStr = timeStr.contains(' - ') ? timeStr.split(' - ')[0] : timeStr;
          final h = int.tryParse(startStr.split(':')[0]) ?? 0;
          return sum + _getSlotPrice(widget.venueName, cName, widget.date, h);
        });
      } else {
        final hours = _parseStartHours(widget.timeRange);
        if (hours.isNotEmpty) {
          basePrice = hours.fold(0, (sum, h) => sum + _getSlotPrice(widget.venueName, widget.courtName, widget.date, h));
        } else {
          // Fallback: tidak bisa recalculate, pakai widget.price langsung
          basePrice = widget.price;
        }
      }
    }

    if (basePrice <= 0) {
      if (widget.items.isNotEmpty && widget.items.length == 1) {
        final item = widget.items.first;
        final vName = item['venueName']?.toString() ?? widget.venueName;
        final cName = item['courtName']?.toString() ?? widget.courtName;
        final itemSvc = item['services'];
        final Map<String, int> itemSvcMap = itemSvc != null ? Map<String, int>.from(itemSvc) : {};
        final itemSvcTotal = _calcServiceCost(itemSvcMap, vName, cName);
        final cartPrice = item['price'] as int? ?? 0;
        basePrice = (cartPrice - itemSvcTotal).clamp(0, double.infinity).toInt();
      } else if (widget.items.isEmpty) {
        final serviceTotal = _calcServiceCost(widget.selectedServices, widget.venueName, widget.courtName);
        basePrice = (widget.price - serviceTotal).clamp(0, double.infinity).toInt();
      }
    }

    final activeVenueName = widget.items.isNotEmpty ? (widget.items.first['venueName']?.toString() ?? widget.venueName) : widget.venueName;
    final activeCourtName = widget.items.isNotEmpty ? (widget.items.first['courtName']?.toString() ?? widget.courtName) : widget.courtName;
    final serviceTotal = _calcServiceCost(_localSelectedServices, activeVenueName, activeCourtName);

    final subTotal = basePrice + serviceTotal;
    if (_usePoints) {
      return (subTotal - _availablePoints).clamp(0, double.infinity).toInt();
    }
    return subTotal;
  }

  /// Hitung total biaya services dari court-level data (bukan venue-level)
  int _calcServiceCost(Map<String, int> services, String venueName, String courtName) {
    if (services.isEmpty) return 0;
    final vRes = GlobalVenueData.venues.where((v) => v['name'] == venueName);
    if (vRes.isEmpty) return 0;
    final courtsList = vRes.first['courts'] as List<dynamic>? ?? [];
    final seenSvc = <String>{};
    final svcList = <Map<String, dynamic>>[];
    
    // 1. Kumpulkan service dari court spesifik terlebih dahulu
    final targetCourts = courtName.isNotEmpty ? courtsList.where((c) => c['name'] == courtName).toList() : [];
    for (final c in targetCourts) {
      final cs = c['services'] as List<dynamic>? ?? [];
      for (final s in cs) {
        final sm = Map<String, dynamic>.from(s as Map);
        final sn = sm['name']?.toString() ?? '';
        sm['id'] = sm['id']?.toString() ?? sn;
        if (sn.isNotEmpty && !seenSvc.contains(sn)) {
          seenSvc.add(sn);
          svcList.add(sm);
        }
      }
    }
    
    // 2. Kumpulkan service dari court lain sebagai fallback
    for (final c in courtsList) {
      final cs = c['services'] as List<dynamic>? ?? [];
      for (final s in cs) {
        final sm = Map<String, dynamic>.from(s as Map);
        final sn = sm['name']?.toString() ?? '';
        sm['id'] = sm['id']?.toString() ?? sn;
        if (sn.isNotEmpty && !seenSvc.contains(sn)) {
          seenSvc.add(sn);
          svcList.add(sm);
        }
      }
    }
    
    int total = 0;
    services.forEach((id, qty) {
      final match = svcList.where((s) => s['id'] == id || s['name'] == id);
      if (match.isNotEmpty) {
        final pr = match.first['price'];
        final sPrice = pr is int ? pr : int.tryParse(pr?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
        total += sPrice * qty;
      }
    });
    return total;
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp$formatted';
  }

  String _formatNumber(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  /// Parse start-time list dari string timeSlot (e.g. "2 Slot: 06:00, 07:00" atau "2 Slot Waktu (06:00, 07:00)")
  /// Hanya mengambil jam awal (start-time) dari setiap rentang untuk menghindari perhitungan ganda (double-counting).
  List<int> _parseStartHours(String timeSlot) {
    String cleaned = timeSlot;
    if (cleaned.contains('(')) {
      cleaned = cleaned.split('(').last.replaceAll(')', '');
    } else if (cleaned.contains('Slot: ')) {
      cleaned = cleaned.split('Slot: ').last;
    }
    
    final slots = cleaned.split(',');
    final hours = <int>[];
    for (final s in slots) {
      final part = s.split('-')[0].trim(); // Ambil hanya jam mulai, e.g. "08:00" dari "08:00 - 09:00"
      final regex = RegExp(r'\b(\d{2}):\d{2}\b');
      final match = regex.firstMatch(part);
      if (match != null) {
        final hStr = match.group(1);
        if (hStr != null) {
          final h = int.tryParse(hStr);
          if (h != null) hours.add(h);
        }
      }
    }
    hours.sort();
    return hours;
  }

  /// Kelompokkan jam-jam yang berurutan menjadi rentang, e.g.:
  /// [6,7,8] -> "(06:00-09:00)"
  /// [6,8]   -> "(06:00-07:00), (08:00-09:00)"
  String _groupHoursToRanges(List<int> hours) {
    if (hours.isEmpty) return '-';
    final groups = <String>[];
    int start = hours[0];
    int prev = hours[0];
    for (int i = 1; i < hours.length; i++) {
      if (hours[i] == prev + 1) {
        prev = hours[i];
      } else {
        groups.add('(${start.toString().padLeft(2,'0')}:00-${(prev+1).toString().padLeft(2,'0')}:00)');
        start = hours[i];
        prev = hours[i];
      }
    }
    groups.add('(${start.toString().padLeft(2,'0')}:00-${(prev+1).toString().padLeft(2,'0')}:00)');
    return groups.join(', ');
  }

  /// Ambil harga 1 slot dari venue data berdasarkan venueName, courtName, dateStr, startHour
  int _getSlotPrice(String venueName, String courtName, String dateStr, int startHour) {
    final venueRes = GlobalVenueData.venues.where((v) => v['name'] == venueName);
    if (venueRes.isEmpty) return 0;
    final venue = venueRes.first;
    final courts = venue['courts'] as List<dynamic>? ?? [];
    final courtRes = courts.where((c) => c['name'] == courtName);
    if (courtRes.isEmpty) return 0;
    final court = Map<String, dynamic>.from(courtRes.first as Map);

    // Dapatkan nama hari dari dateStr "Senin, 2 Juni 2026"
    String dayName = '';
    final parts = dateStr.split(',');
    if (parts.isNotEmpty) dayName = parts.first.trim();

    final dayNamesList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    if (!dayNamesList.contains(dayName)) {
      final parsedDate = BookingUtils.parseDateStr(dateStr);
      if (parsedDate != null) {
        dayName = dayNamesList[parsedDate.weekday - 1];
      }
    }

    final priceModeDay = court['priceModeDay'] as Map? ?? {};
    final priceMode = priceModeDay[dayName] ?? court['priceMode'] ?? 'perDay';
    if (priceMode == 'perSlot') {
      final pricePerSlot = court['pricePerSlot'] as Map? ?? {};
      final key = '${dayName}_${startHour.toString().padLeft(2,'0')}:00';
      final val = pricePerSlot[key]?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
      final p = int.tryParse(val);
      if (p != null && p >= 0) return p;
    }
    // Fallback: priceDay
    final priceDay = court['priceDay'] as Map? ?? {};
    final dayVal = priceDay[dayName]?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    return int.tryParse(dayVal) ?? 0;
  }

  Map<String, int> _filterServicesForCourt(String venueName, String courtName, Map<String, int> allServices) {
    final Map<String, int> filtered = {};
    final venueResults = GlobalVenueData.venues.where((v) => v['name'] == venueName);
    if (venueResults.isEmpty) return filtered;
    final venue = venueResults.first;
    final courts = venue['courts'] as List<dynamic>? ?? [];
    final courtRes = courts.where((c) => c['name'] == courtName);
    if (courtRes.isEmpty) return filtered;
    final court = courtRes.first;
    final courtServices = court['services'] as List<dynamic>? ?? [];
    final courtServiceIds = courtServices.map((s) => s['id']?.toString() ?? s['name']?.toString() ?? '').toSet();
    
    allServices.forEach((id, qty) {
      if (courtServiceIds.contains(id)) {
        filtered[id] = qty;
      }
    });
    return filtered;
  }

  List<BookingCardData> get _bookingCards {
    final List<BookingCardData> cards = [];
    
    if (widget.items.isNotEmpty) {
      for (final item in widget.items) {
        final vName = item['venueName']?.toString() ?? 'Venue';
        final cName = item['courtName']?.toString() ?? 'Lapangan';
        final dStr = item['date']?.toString() ?? '-';
        final tSlot = item['timeSlot']?.toString() ?? '-';
        final itemSvcRaw = item['services'];
        final Map<String, int> itemSvc = itemSvcRaw != null ? Map<String, int>.from(itemSvcRaw) : {};
        
        final List<dynamic>? itemIndividualSlots = item['individualSlots'] as List<dynamic>?;
        if (itemIndividualSlots != null && itemIndividualSlots.isNotEmpty) {
          final Map<String, List<String>> courtSlots = {};
          for (final slotObj in itemIndividualSlots) {
            final slot = Map<String, dynamic>.from(slotObj as Map);
            final court = slot['court']?.toString() ?? cName;
            final time = slot['time']?.toString() ?? '';
            courtSlots.putIfAbsent(court, () => []).add(time);
          }
          
          final Map<String, Map<String, int>> courtServices = {};
          final Set<String> assignedServices = {};
          
          courtSlots.keys.forEach((court) {
            final filtered = _filterServicesForCourt(vName, court, itemSvc);
            courtServices[court] = filtered;
            assignedServices.addAll(filtered.keys);
          });
          
          final leftover = <String, int>{};
          itemSvc.forEach((id, qty) {
            if (!assignedServices.contains(id)) {
              leftover[id] = qty;
            }
          });
          
          if (leftover.isNotEmpty && courtSlots.isNotEmpty) {
            final firstCourt = courtSlots.keys.first;
            courtServices[firstCourt]!.addAll(leftover);
          }
          
          courtSlots.forEach((court, times) {
            cards.add(BookingCardData(
              venueName: vName,
              courtName: court,
              date: dStr,
              timeRange: times.join(', '),
              services: courtServices[court] ?? {},
            ));
          });
        } else {
          final List<String> courts = cName.split(',').map((e) => e.trim()).toList();
          if (courts.length > 1) {
            final Map<String, Map<String, int>> courtServices = {};
            final Set<String> assignedServices = {};
            
            for (final court in courts) {
              final filtered = _filterServicesForCourt(vName, court, itemSvc);
              courtServices[court] = filtered;
              assignedServices.addAll(filtered.keys);
            }
            
            final leftover = <String, int>{};
            itemSvc.forEach((id, qty) {
              if (!assignedServices.contains(id)) {
                leftover[id] = qty;
              }
            });
            
            if (leftover.isNotEmpty) {
              courtServices[courts.first]!.addAll(leftover);
            }
            
            for (final court in courts) {
              cards.add(BookingCardData(
                venueName: vName,
                courtName: court,
                date: dStr,
                timeRange: tSlot,
                services: courtServices[court] ?? {},
              ));
            }
          } else {
            cards.add(BookingCardData(
              venueName: vName,
              courtName: cName,
              date: dStr,
              timeRange: tSlot,
              services: itemSvc,
            ));
          }
        }
      }
    } else {
      final vName = widget.venueName;
      final cName = widget.courtName;
      final dStr = widget.date;
      final tSlot = widget.timeRange;
      
      if (widget.individualSlots.isNotEmpty) {
        final Map<String, List<String>> courtSlots = {};
        for (final slot in widget.individualSlots) {
          final court = slot['court'] ?? cName;
          final time = slot['time'] ?? '';
          courtSlots.putIfAbsent(court, () => []).add(time);
        }
        
        final Map<String, Map<String, int>> courtServices = {};
        final Set<String> assignedServices = {};
        
        courtSlots.keys.forEach((court) {
          final filtered = _filterServicesForCourt(vName, court, _localSelectedServices);
          courtServices[court] = filtered;
          assignedServices.addAll(filtered.keys);
        });
        
        final leftover = <String, int>{};
        _localSelectedServices.forEach((id, qty) {
          if (!assignedServices.contains(id)) {
            leftover[id] = qty;
          }
        });
        
        if (leftover.isNotEmpty && courtSlots.isNotEmpty) {
          final firstCourt = courtSlots.keys.first;
          courtServices[firstCourt]!.addAll(leftover);
        }
        
        courtSlots.forEach((court, times) {
          cards.add(BookingCardData(
            venueName: vName,
            courtName: court,
            date: dStr,
            timeRange: times.join(', '),
            services: courtServices[court] ?? {},
          ));
        });
      } else {
        final List<String> courts = cName.split(',').map((e) => e.trim()).toList();
        if (courts.length > 1) {
          final Map<String, Map<String, int>> courtServices = {};
          final Set<String> assignedServices = {};
          
          for (final court in courts) {
            final filtered = _filterServicesForCourt(vName, court, _localSelectedServices);
            courtServices[court] = filtered;
            assignedServices.addAll(filtered.keys);
          }
          
          final leftover = <String, int>{};
          _localSelectedServices.forEach((id, qty) {
            if (!assignedServices.contains(id)) {
              leftover[id] = qty;
            }
          });
          
          if (leftover.isNotEmpty) {
            courtServices[courts.first]!.addAll(leftover);
          }
          
          for (final court in courts) {
            cards.add(BookingCardData(
              venueName: vName,
              courtName: court,
              date: dStr,
              timeRange: tSlot,
              services: courtServices[court] ?? {},
            ));
          }
        } else {
          cards.add(BookingCardData(
            venueName: vName,
            courtName: cName,
            date: dStr,
            timeRange: tSlot,
            services: _localSelectedServices,
          ));
        }
      }
    }
    
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _showBackConfirmation();
      },
      child: Scaffold(
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
                  _buildSectionHeader('Venue'),
                  _buildVenueCard(widget.items.isNotEmpty ? widget.items.first['venueName'] : widget.venueName),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Detail Pemesanan'),
                  ..._bookingCards.map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildBookingDetailCard(
                      venueName: card.venueName,
                      courtName: card.courtName,
                      date: card.date,
                      timeRange: card.timeRange,
                      price: 0,
                      services: card.services,
                    ),
                  )).toList(),
                  const SizedBox(height: 12),
                  _buildAddServiceButton(),

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
        onPressed: _showBackConfirmation,
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

  void _showBackConfirmation() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Batalkan Pembayaran?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Semua perubahan pada layanan tambahan akan hilang jika kamu keluar dari halaman ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Tetap di Sini',
                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx); // Tutup dialog
                            Navigator.pop(context); // Keluar dari payment page
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Ya, Keluar',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    final venueResults = GlobalVenueData.venues.where((v) => v['name'] == name);
    final venue = venueResults.isNotEmpty ? venueResults.first : null;
    final String imagePath = venue != null ? (venue['image']?.toString() ?? '') : '';

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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Builder(builder: (context) {
                if (imagePath.isEmpty) {
                  return const Icon(Icons.stadium_rounded, color: AppColors.primary, size: 24);
                }
                final isRemote = imagePath.startsWith('http://') || imagePath.startsWith('https://');
                final isAsset = imagePath.startsWith('assets/');
                try {
                  if (isRemote) {
                    return Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.stadium_rounded, color: AppColors.primary, size: 24),
                    );
                  } else if (isAsset) {
                    return Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.stadium_rounded, color: AppColors.primary, size: 24),
                    );
                  } else {
                    return Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.stadium_rounded, color: AppColors.primary, size: 24),
                    );
                  }
                } catch (e) {
                  return const Icon(Icons.stadium_rounded, color: AppColors.primary, size: 24);
                }
              }),
            ),
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
    final timeDisplay = _groupHoursToRanges(_parseStartHours(timeRange));

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
          // Header lapangan dengan gradient dan icon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primary.withValues(alpha: 0.02)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sports_tennis_rounded, size: 14, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    courtName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          // Grid info detail: 2 kolom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDetailCell(Icons.calendar_today_rounded, 'Tanggal', _cleanDate(date))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDetailCell(Icons.access_time_filled_rounded, 'Jam', timeDisplay.isEmpty ? '-' : timeDisplay)),
                  ],
                ),
                if (services != null && services.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.room_service_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      const Text('Layanan Tambahan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...services.entries.map((entry) {
                    final venueResults = GlobalVenueData.venues.where((v) => v['name'] == venueName);
                    final venue = venueResults.isNotEmpty ? venueResults.first : <String, dynamic>{};
                    final courts = venue['courts'] as List<dynamic>? ?? [];
                    final seen = <String>{};
                    final sList = <Map<String, dynamic>>[];
                    for (final c in courts) {
                      final courtServices = c['services'] as List<dynamic>? ?? [];
                      for (final s in courtServices) {
                        final sMap = Map<String, dynamic>.from(s as Map);
                        final name = sMap['name']?.toString() ?? '';
                        final sId = sMap['id']?.toString() ?? name;
                        sMap['id'] = sId;
                        if (name.isNotEmpty && !seen.contains(name)) { seen.add(name); sList.add(sMap); }
                      }
                    }
                    final sRes = sList.where((s) => s['id'] == entry.key || s['name'] == entry.key);
                    if (sRes.isEmpty) return const SizedBox.shrink();
                    final s = sRes.first;
                    final sPriceRaw = s['price'];
                    final sPrice = sPriceRaw is int ? sPriceRaw : int.tryParse(sPriceRaw?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('${s['name']} (x${entry.value})', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                            ],
                          ),
                          Text(_formatCurrency(sPrice * entry.value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
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

  /// Cell 1 kolom: icon + label kecil + nilai bold
  Widget _buildDetailCell(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.primary.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bersihkan format tanggal: "Senin, 2 Juni 2026" → "2 Juni 2026"
  String _cleanDate(String date) {
    if (date.contains(',')) {
      final parts = date.split(',');
      return parts.length > 1 ? parts[1].trim() : date;
    }
    return date;
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
          if (widget.items.isEmpty) ..._buildSingleItemTransactionRows()
          else ...widget.items.expand((item) => _buildCartItemTransactionRows(item)).toList(),
          
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

  Widget _buildTransactionRow(String label, int amount, {bool isFree = false, bool isBold = false, bool isSlot = false, bool isSubtotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label, 
            style: TextStyle(
              fontSize: isBold ? 15 : isSubtotal ? 13 : 12, 
              fontWeight: isBold ? FontWeight.bold : isSubtotal ? FontWeight.w600 : FontWeight.w400,
              color: isBold ? AppColors.textPrimary : isSubtotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontStyle: isSlot ? FontStyle.normal : FontStyle.normal,
            ),
          ),
        ),
        Text(
          isFree ? 'Gratis' : _formatCurrency(amount),
          style: TextStyle(
            fontSize: isBold ? 17 : isSubtotal ? 13 : 12, 
            fontWeight: isBold ? FontWeight.bold : isSubtotal ? FontWeight.bold : FontWeight.w500,
            color: isBold ? AppColors.primary : isSubtotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Bangun baris rincian per-slot + layanan untuk booking langsung (non-keranjang)
  List<Widget> _buildSingleItemTransactionRows() {
    final rows = <Widget>[];

    // Tentukan courtName yang aktif
    final activeCourtName = widget.items.isNotEmpty
        ? (widget.items.first['courtName']?.toString() ?? widget.courtName)
        : widget.courtName;
    final activeVenueName = widget.items.isNotEmpty
        ? (widget.items.first['venueName']?.toString() ?? widget.venueName)
        : widget.venueName;
    final activeDate = widget.items.isNotEmpty
        ? (widget.items.first['date']?.toString() ?? widget.date)
        : widget.date;
    final activeTimeRange = widget.items.isNotEmpty
        ? (widget.items.first['timeSlot']?.toString() ?? widget.timeRange)
        : widget.timeRange;

    if (widget.individualSlots.isNotEmpty) {
      // Group slots by court
      final Map<String, List<Map<String, String>>> grouped = {};
      for (final slot in widget.individualSlots) {
        final cName = slot['court'] ?? widget.courtName;
        grouped.putIfAbsent(cName, () => []).add(slot);
      }

      int courtSubTotal = 0;
      int idxGroup = 0;
      grouped.forEach((cName, slots) {
        rows.add(Padding(
          padding: EdgeInsets.only(top: idxGroup > 0 ? 12.0 : 0.0, bottom: 4),
          child: Text(
            cName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
        ));
        idxGroup++;

        for (final slot in slots) {
          final timeStr = slot['time'] ?? '';
          final startStr = timeStr.contains(' - ') ? timeStr.split(' - ')[0] : timeStr;
          final h = int.tryParse(startStr.split(':')[0]) ?? 0;
          final slotLabel = '${h.toString().padLeft(2,'0')}:00 - ${(h+1).toString().padLeft(2,'0')}:00';
          
          final slotPrice = _getSlotPrice(activeVenueName, cName, activeDate, h);
          courtSubTotal += slotPrice;

          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildTransactionRow(slotLabel, slotPrice, isSlot: true),
          ));
        }
      });

      if (widget.individualSlots.length > 1) {
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: _buildTransactionRow('Subtotal Lapangan', courtSubTotal, isSubtotal: true),
        ));
      }
    } else {
      // Header nama lapangan
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          activeCourtName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
      ));

      final hours = _parseStartHours(activeTimeRange);
      int courtSubTotal = 0;

      if (hours.isEmpty) {
        // Fallback: tampilkan total langsung
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildTransactionRow('Biaya Lapangan', widget.price),
        ));
      } else {
        // Tampilkan per-slot
        for (final h in hours) {
          final slotLabel = '${h.toString().padLeft(2,'0')}:00 - ${(h+1).toString().padLeft(2,'0')}:00';
          final slotPrice = _getSlotPrice(activeVenueName, activeCourtName, activeDate, h);
          courtSubTotal += slotPrice;
          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildTransactionRow(slotLabel, slotPrice, isSlot: true),
          ));
        }
        if (hours.length > 1) {
          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildTransactionRow('Subtotal Lapangan', courtSubTotal, isSubtotal: true),
          ));
        }
      }
    }

    // Layanan tambahan dari _localSelectedServices (direct booking)
    if (_localSelectedServices.isNotEmpty) {
      final vRes = GlobalVenueData.venues.where((v) => v['name'] == activeVenueName);
      final venue = vRes.isNotEmpty ? vRes.first : <String, dynamic>{};
      final courtsList = venue['courts'] as List<dynamic>? ?? [];
      final seenSvc = <String>{};
      final svcList = <Map<String, dynamic>>[];
      for (final c in courtsList) {
        final cs = c['services'] as List<dynamic>? ?? [];
        for (final s in cs) {
          final sm = Map<String, dynamic>.from(s as Map);
          final sn = sm['name']?.toString() ?? '';
          sm['id'] = sm['id']?.toString() ?? sn;
          if (sn.isNotEmpty && !seenSvc.contains(sn)) { seenSvc.add(sn); svcList.add(sm); }
        }
      }
      _localSelectedServices.forEach((key, qty) {
        final match = svcList.where((s) => s['id'] == key || s['name'] == key);
        if (match.isNotEmpty) {
          final s = match.first;
          final pr = s['price'];
          final sPrice = pr is int ? pr : int.tryParse(pr?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildTransactionRow('+ ${s['name']} (x$qty)', sPrice * qty),
          ));
        }
      });
    }

    rows.add(const SizedBox(height: 6));
    return rows;
  }

  /// Bangun baris rincian per-slot + layanan untuk item dari keranjang
  List<Widget> _buildCartItemTransactionRows(Map<String, dynamic> item) {
    final rows = <Widget>[];
    final venueName = item['venueName']?.toString() ?? '';
    final courtName = item['courtName']?.toString() ?? '';
    final dateStr = item['date']?.toString() ?? '';
    final timeSlot = item['timeSlot']?.toString() ?? '';
    final Map<String, int>? itemServices = (widget.items.length == 1)
        ? _localSelectedServices
        : (item['services'] != null ? Map<String, int>.from(item['services']) : null);

    // Kumpulkan services list dari venue
    final venueRes = GlobalVenueData.venues.where((v) => v['name'] == venueName);
    final venue = venueRes.isNotEmpty ? venueRes.first : <String, dynamic>{};
    final courtsList = venue['courts'] as List<dynamic>? ?? [];
    final seenSvc = <String>{};
    final svcList = <Map<String, dynamic>>[];
    for (final c in courtsList) {
      final cs = c['services'] as List<dynamic>? ?? [];
      for (final s in cs) {
        final sm = Map<String, dynamic>.from(s as Map);
        final sn = sm['name']?.toString() ?? '';
        sm['id'] = sm['id']?.toString() ?? sn;
        if (sn.isNotEmpty && !seenSvc.contains(sn)) { seenSvc.add(sn); svcList.add(sm); }
      }
    }

    final List<dynamic>? itemIndividualSlots = item['individualSlots'] as List<dynamic>?;

    if (itemIndividualSlots != null && itemIndividualSlots.isNotEmpty) {
      // Group slots by court
      final Map<String, List<Map<String, String>>> grouped = {};
      for (final slotObj in itemIndividualSlots) {
        final slot = Map<String, String>.from((slotObj as Map).map((k, v) => MapEntry(k.toString(), v.toString())));
        final cName = slot['court'] ?? courtName;
        grouped.putIfAbsent(cName, () => []).add(slot);
      }

      int courtSubTotal = 0;
      int idxGroup = 0;
      grouped.forEach((cName, slots) {
        rows.add(Padding(
          padding: EdgeInsets.only(top: idxGroup > 0 ? 12.0 : 0.0, bottom: 4),
          child: Text(
            cName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
        ));
        idxGroup++;

        for (final slot in slots) {
          final timeStr = slot['time'] ?? '';
          final startStr = timeStr.contains(' - ') ? timeStr.split(' - ')[0] : timeStr;
          final h = int.tryParse(startStr.split(':')[0]) ?? 0;
          final slotLabel = '${h.toString().padLeft(2,'0')}:00 - ${(h+1).toString().padLeft(2,'0')}:00';
          
          final slotPrice = _getSlotPrice(venueName, cName, dateStr, h);
          courtSubTotal += slotPrice;

          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildTransactionRow(slotLabel, slotPrice, isSlot: true),
          ));
        }
      });

      if (itemIndividualSlots.length > 1) {
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: _buildTransactionRow('Subtotal Lapangan', courtSubTotal, isSubtotal: true),
        ));
      }
    } else {
      // Header lapangan
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          courtName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
      ));

      // Per-slot rows
      final hours = _parseStartHours(timeSlot);
      int courtSubTotal = 0;
      if (hours.isEmpty) {
        // Fallback: hitung courtPrice = total - services
        int servicesTotal = 0;
        if (itemServices != null) {
          itemServices.forEach((key, qty) {
            final match = svcList.where((s) => s['id'] == key || s['name'] == key);
            if (match.isNotEmpty) {
              final pr = match.first['price'];
              final sp = pr is int ? pr : int.tryParse(pr?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
              servicesTotal += sp * qty;
            }
          });
        }
        final courtPrice = (item['price'] as int? ?? 0) - servicesTotal;
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _buildTransactionRow('Biaya Lapangan', courtPrice),
        ));
        courtSubTotal = courtPrice;
      } else {
        for (final h in hours) {
          final slotLabel = '${h.toString().padLeft(2,'0')}:00 - ${(h+1).toString().padLeft(2,'0')}:00';
          final slotPrice = _getSlotPrice(venueName, courtName, dateStr, h);
          courtSubTotal += slotPrice;
          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildTransactionRow(slotLabel, slotPrice, isSlot: true),
          ));
        }
        if (hours.length > 1) {
          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildTransactionRow('Subtotal Lapangan', courtSubTotal, isSubtotal: true),
          ));
        }
      }
    }

    // Services rows
    if (itemServices != null && itemServices.isNotEmpty) {
      itemServices.forEach((key, qty) {
        final match = svcList.where((s) => s['id'] == key || s['name'] == key);
        if (match.isNotEmpty) {
          final s = match.first;
          final pr = s['price'];
          final sPrice = pr is int ? pr : int.tryParse(pr?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildTransactionRow('+ ${s['name']} (x$qty)', sPrice * qty),
          ));
        }
      });
    }

    rows.add(const SizedBox(height: 6));
    return rows;
  }


  Widget _buildPaymentMethodSection() {
    return Column(
      children: [
        _buildPaymentOption('gopay', 'GoPay (Uang Elektronik)', Icons.account_balance_wallet_rounded),
        _buildPaymentOption('shopeepay', 'ShopeePay (Uang Elektronik)', Icons.wallet_rounded),
        _buildPaymentOption('bca', 'BCA Virtual Account', Icons.account_balance_rounded),
        _buildPaymentOption('mandiri', 'Mandiri Virtual Account', Icons.account_balance_rounded),
        _buildPaymentOption('bni', 'BNI Virtual Account', Icons.account_balance_rounded),
        _buildPaymentOption('bri', 'BRI Virtual Account', Icons.account_balance_rounded),
        _buildPaymentOption('cimb', 'CIMB Niaga Virtual Account', Icons.account_balance_rounded),
        _buildPaymentOption('permata', 'Permata Virtual Account', Icons.account_balance_rounded),
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
            'Tersedia: ${_formatNumber(_availablePoints)} Point (${_formatCurrency(_availablePoints)})',
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
            String activeCourtName = widget.items.isNotEmpty ? (widget.items.first['courtName'] ?? '') : widget.courtName;
            final vRes = GlobalVenueData.venues.where((v) => v['name'] == activeVenue);
            final venue = vRes.isNotEmpty ? vRes.first : <String, dynamic>{};
            final courtsList = venue['courts'] as List<dynamic>? ?? [];
            // Kumpulkan services dari court yang aktif, fallback ke semua courts
            final seenSvc = <String>{};
            final sList = <Map<String, dynamic>>[];
            final targetCourts = courtsList.where((c) => c['name'] == activeCourtName).toList();
            final sourceCourts = targetCourts.isNotEmpty ? targetCourts : courtsList;
            for (final c in sourceCourts) {
              final cs = c['services'] as List<dynamic>? ?? [];
              for (final s in cs) {
                final sm = Map<String, dynamic>.from(s as Map);
                final sn = sm['name']?.toString() ?? '';
                sm['id'] = sm['id']?.toString() ?? sn;
                if (sn.isNotEmpty && !seenSvc.contains(sn)) {
                  seenSvc.add(sn);
                  sList.add(sm);
                }
              }
            }
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
                        final id = s['id']?.toString() ?? '';
                        final sName = s['name']?.toString() ?? 'Layanan';
                        final priceRaw = s['price'];
                        final sPrice = priceRaw is int ? priceRaw : int.tryParse(priceRaw?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
                        final stockRaw = s['stock'];
                        final stock = stockRaw is int ? stockRaw : int.tryParse(stockRaw?.toString() ?? '') ?? 99;
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
                                    Text(sName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${_formatCurrency(sPrice)} (Stok: $stock)', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
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
                                    onPressed: qty < stock ? () { setState(() => _localSelectedServices[id] = qty + 1); setModalState(() {}); } : null,
                                    icon: Icon(Icons.add_circle_outline, color: qty < stock ? AppColors.primary : Colors.grey),
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

  void _processPayment() async {
    final account = GlobalAuthData.getAccount(widget.username);
    final email = account?.email ?? 'customer@rensius.com';
    final phone = account?.phoneNumber ?? '081234567890';
    final orderId = 'ID${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // Tampilkan loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 20),
            Expanded(child: Text("Menghubungkan ke sistem pembayaran...")),
          ],
        ),
      ),
    );

    try {
      // Map selected payment option ID to Midtrans supported enabled_payments codes
      List<String>? enabledPayments;
      if (_selectedPaymentMethodId != null) {
        switch (_selectedPaymentMethodId) {
          case 'qris':
            // Sekarang QRIS sudah diaktifkan di dashboard Midtrans, kita cukup mengirimkan ['qris']
            // agar langsung menampilkan QRIS Code/payment channel QRIS di Snap portal.
            enabledPayments = ['qris'];
            break;
          case 'gopay':
            enabledPayments = ['gopay'];
            break;
          case 'shopeepay':
            enabledPayments = ['shopeepay'];
            break;
          case 'bca':
            enabledPayments = ['bca_va'];
            break;
          case 'mandiri':
            enabledPayments = ['echannel'];
            break;
          case 'bni':
            enabledPayments = ['bni_va'];
            break;
          case 'bri':
            enabledPayments = ['bri_va'];
            break;
          case 'permata':
            enabledPayments = ['permata_va'];
            break;
          case 'cimb':
            enabledPayments = ['cimb_va'];
            break;
          case 'credit_card':
            enabledPayments = ['credit_card'];
            break;
        }
      }

      // Hubungkan live dengan Midtrans
      final snapData = await MidtransService.createTransaction(
        orderId: orderId,
        grossAmount: _totalPrice,
        username: widget.username,
        email: email,
        phone: phone,
        courtName: widget.items.isNotEmpty 
            ? (widget.items.length == 1 ? widget.items.first['courtName'] : '${widget.items.length} Lapangan') 
            : widget.courtName,
        venueName: widget.items.isNotEmpty ? widget.items.first['venueName'] : widget.venueName,
        enabledPayments: enabledPayments,
      );

      // Tutup loading dialog
      if (mounted) Navigator.pop(context);

      final redirectUrl = snapData['redirect_url'] as String?;

      if (redirectUrl != null) {
        final uri = Uri.parse(redirectUrl);
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('Error launching Midtrans URL: $e');
        }
      }

      // Hapus item dari keranjang (baik dari checkout keranjang maupun sewa langsung dari venue)
      if (widget.items.isNotEmpty) {
        for (var item in widget.items) {
          final itemHours = _parseStartHours(item['timeSlot']?.toString() ?? '');
          GlobalVenueData.cart.removeWhere((cartItem) {
            final cartHours = _parseStartHours(cartItem['timeSlot']?.toString() ?? '');
            final isVenueMatch = cartItem['venueName'] == item['venueName'];
            final isCourtMatch = cartItem['courtName'] == item['courtName'];
            final isDateMatch = cartItem['date'] == item['date'];
            final isTimeOverlap = cartHours.any((h) => itemHours.contains(h));
            return isVenueMatch && isCourtMatch && isDateMatch && isTimeOverlap;
          });
        }
      } else {
        // Direct booking: hapus item yang cocok dari keranjang jika ada
        final directHours = _parseStartHours(widget.timeRange);
        GlobalVenueData.cart.removeWhere((cartItem) {
          final cartHours = _parseStartHours(cartItem['timeSlot']?.toString() ?? '');
          final isVenueMatch = cartItem['venueName'] == widget.venueName;
          final isCourtMatch = widget.individualSlots.isNotEmpty
              ? widget.individualSlots.any((slot) => slot['court'] == cartItem['courtName'])
              : cartItem['courtName'] == widget.courtName;
          final isDateMatch = cartItem['date'] == widget.date;
          final isTimeOverlap = cartHours.any((h) => directHours.contains(h));
          return isVenueMatch && isCourtMatch && isDateMatch && isTimeOverlap;
        });
      }
      GlobalVenueData.saveCart(); // Simpan perubahan keranjang lokal & sync ke Supabase

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentInstructionPage(
              paymentMethodId: _selectedPaymentMethodId ?? 'gopay',
              paymentMethodName: _selectedPaymentMethodId?.toUpperCase() ?? 'GOPAY',
              amount: _totalPrice,
              usedPoints: _usePoints ? (_availablePoints > (widget.items.fold(0, (s, i) => s + (i['price'] as int)) + (widget.items.isEmpty ? widget.price : 0)) ? (widget.items.fold(0, (s, i) => s + (i['price'] as int)) + (widget.items.isEmpty ? widget.price : 0)) : _availablePoints) : 0,
              orderId: orderId,
              venueName: widget.items.isNotEmpty ? widget.items.first['venueName'] : widget.venueName,
              courtName: widget.items.isNotEmpty 
                  ? (widget.items.length == 1 ? widget.items.first['courtName'] : '${widget.items.length} Lapangan') 
                  : widget.courtName,
              date: widget.items.isNotEmpty ? widget.items.first['date'] : widget.date,
              timeRange: widget.items.isNotEmpty ? widget.items.first['timeSlot'] : widget.timeRange,
              individualSlots: widget.individualSlots.isNotEmpty 
                  ? widget.individualSlots 
                  : () {
                      final list = <Map<String, String>>[];
                      for (final item in widget.items) {
                        final itemSlots = item['individualSlots'] as List?;
                        if (itemSlots != null) {
                          list.addAll(itemSlots.map((e) => Map<String, String>.from(e as Map)));
                        } else {
                          list.add({
                            'court': item['courtName']?.toString() ?? '',
                            'time': item['timeSlot']?.toString() ?? '',
                          });
                        }
                      }
                      return list;
                    }(),
              selectedServices: _localSelectedServices,
              items: widget.items,
              username: widget.username,
              role: widget.role,
              redirectUrl: redirectUrl,
            ),
          ),
        );
      }
    } catch (e) {
      // Tutup loading dialog jika error
      if (mounted) Navigator.pop(context);
      
      // Tampilkan error
      if (mounted) {
        AlertUtils.showResultDialog(
          context,
          isSuccess: false,
          title: "Koneksi Terganggu",
          message: "Koneksi terganggu. Silakan periksa koneksi internet Anda dan coba lagi.",
        );
      }
    }
  }
}

class BookingCardData {
  final String venueName;
  final String courtName;
  final String date;
  final String timeRange;
  final Map<String, int> services;

  BookingCardData({
    required this.venueName,
    required this.courtName,
    required this.date,
    required this.timeRange,
    required this.services,
  });
}
