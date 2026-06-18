import 'dart:convert';
import '../pages/booking_history.dart';
import 'package:rensius/services/supabase_service.dart';

class BookingUtils {
  static const List<String> dayNames = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  static const List<String> monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  /// A set of universally reserved slots. 
  /// Key format: "venueName|courtName|dateString|timeStart"
  /// e.g., "BEC Tennis|Court A|Senin, 13 April 2026|08:00"
  static final Set<String> _reservedSlots = {};

  /// Cache list of all global bookings from Supabase
  static List<Map<String, dynamic>> globalBookings = [];

  /// Loads all global bookings from Supabase to prevent slot clashes
  static Future<void> loadGlobalBookingsOnline() async {
    if (!SupabaseService.isInitialized) return;
    try {
      final response = await SupabaseService.client.from('bookings').select();
      globalBookings.clear();
      for (var row in response) {
        globalBookings.add({
          'orderId': row['order_id'] ?? '',
          'username': row['username'] ?? '',
          'venueName': row['venue_name'] ?? '',
          'courtName': row['court_name'] ?? '',
          'date': row['date'] ?? '',
          'time': row['time'] ?? '',
          'price': row['price'] ?? 0,
          'paymentMethod': row['payment_method'] ?? '',
          'status': row['status'] ?? 'Menunggu Jadwal',
          'services': row['services'],
          'createdAt': row['created_at'],
        });
      }
    } catch (e) {
      print('Gagal memuat global bookings online: $e');
    }
  }

  /// Calculates available stock dynamically for a service based on active bookings for the same date and overlapping time slots.
  static int getAvailableServiceStock({
    required String venueName,
    required String serviceName,
    required int baseStock,
    required String dateStr,
    required String timeRange,
  }) {
    final all = [...globalBookings, ...BookingHistoryPage.mockHistory];
    int rentedCount = 0;

    // Normalisasikan slot waktu sewa ke format jam awal (misal "18:00, 22:00" -> ["18:00", "22:00"])
    final List<String> selectedTimes = timeRange
        .split(',')
        .map((t) => t.trim().split(' - ')[0].trim())
        .where((t) => t.isNotEmpty)
        .toList();

    for (final b in all) {
      final bVenue = (b['venueName'] ?? '').toString();
      final bDate = (b['date'] ?? '').toString();
      final bTime = (b['time'] ?? '').toString();
      final bStatus = (b['status'] ?? '').toString().toLowerCase();

      // Abaikan booking yang dibatalkan, kadaluwarsa, atau di-refund
      if (bStatus == 'dibatalkan' || bStatus == 'expired' || bStatus == 'refunded') continue;

      if (bVenue == venueName && bDate == dateStr) {
        // Cek jika ada bentrokan jam sewa
        bool hasOverlap = false;
        for (final t in selectedTimes) {
          if (bTime.contains(t)) {
            hasOverlap = true;
            break;
          }
        }

        if (hasOverlap) {
          // Parse string layanan (misal "bola (x3), raket (x5)")
          final servicesStr = (b['services'] ?? '').toString();
          if (servicesStr.isNotEmpty) {
            final parts = servicesStr.split(',').map((p) => p.trim());
            for (final p in parts) {
              final match = RegExp(r'^(.+)\s+\(x(\d+)\)$').firstMatch(p);
              if (match != null) {
                final name = match.group(1)?.trim() ?? '';
                final qty = int.tryParse(match.group(2) ?? '0') ?? 0;
                if (name == serviceName && qty > 0) {
                  rentedCount += qty;
                }
              }
            }
          }
        }
      }
    }

    final available = baseStock - rentedCount;
    return available < 0 ? 0 : available;
  }

  /// Standardizes date to "Hari, Tanggal Bulan Tahun" (e.g., "Senin, 13 April 2026")
  static String formatDate(DateTime date) {
    String day = dayNames[date.weekday - 1];
    String month = monthNames[date.month - 1];
    return '$day, ${date.day} $month ${date.year}';
  }

  /// Reserves a specific slot atomically
  static void reserveSlot({
    required String venueName,
    required String courtName,
    required String dateStr,
    required String timeSlot,
  }) {
    final startTime = timeSlot.split(' ')[0]; // Gets "08:00" from "08:00 - 09:00"
    final key = '$venueName|$courtName|$dateStr|$startTime';
    _reservedSlots.add(key);
  }

  /// Checks if a slot is booked globally
  static bool isSlotBooked({
    required String venueName,
    required String courtName,
    required String dateStr,
    required String timeSlot,
  }) {
    final startTime = timeSlot.split(' ')[0];
    final key = '$venueName|$courtName|$dateStr|$startTime';
    
    // 1. Check atomic reservations first (Interactive system)
    if (_reservedSlots.contains(key)) return true;

    // 3. Real-time check: Disable slots in the past for today
    final now = DateTime.now();
    final todayStr = formatDate(now);
    if (dateStr == todayStr) {
      final hour = int.tryParse(startTime.split(':')[0]) ?? 0;
      if (hour <= now.hour) return true; // Mark as "booked" (disabled) if time has passed
    }

    // Helper to check if a booking matches the given slot
    bool matchBooking(Map<String, dynamic> booking) {
      final bVenue = (booking['venueName'] ?? '').toString();
      final bStatus = (booking['status'] ?? '').toString().toLowerCase();

      // Don't block slots if the booking has been cancelled, expired, or refunded
      if (bStatus == 'dibatalkan' || bStatus == 'expired' || bStatus == 'refunded') return false;
      if (bVenue != venueName) return false;

      final bDate = (booking['date'] ?? '').toString();
      if (bDate != dateStr) return false;

      // Check for |slots: payload in services for direct bookings with multiple courts/slots
      final servicesStr = (booking['services'] ?? '').toString();
      if (servicesStr.contains('|slots:')) {
        try {
          final jsonStr = servicesStr.split('|slots:')[1].trim();
          final List<dynamic> decoded = jsonDecode(jsonStr);
          final List<Map<String, String>> slots = decoded.map((e) => Map<String, String>.from(e as Map)).toList();
          
          return slots.any((s) {
            final sCourt = s['court'] ?? '';
            final sTime = s['time'] ?? '';
            final sStart = sTime.split(' ')[0];
            return sCourt == courtName && sStart == startTime;
          });
        } catch (e) {
          // Fallback to simple matching if json parsing fails
        }
      }

      final bCourt = (booking['courtName'] ?? '').toString();
      final bTime = (booking['time'] ?? '').toString();

      final courts = bCourt.split(',').map((c) => c.trim());
      bool courtMatch = courts.contains(courtName) || bCourt == courtName;
      bool timeMatch = bTime.contains(startTime);

      return courtMatch && timeMatch;
    }

    // 4. Check against global bookings online
    if (globalBookings.any(matchBooking)) return true;

    // 5. Fallback to matching against user's history items in memory
    return BookingHistoryPage.mockHistory.any(matchBooking);
  }

  /// Calculates total revenue from history
  static int calculateRevenue({String? venueName, String period = 'Total'}) {
    final all = [...BookingHistoryPage.mockHistory, ...BookingHistoryPage.mockPastHistory];
    final filtered = (venueName == null || venueName == 'Semua') 
        ? all 
        : all.where((b) => b['venueName'] == venueName).toList();
    
    if (filtered.isEmpty) return 0;
    
    final now = DateTime.now();
    final List<Map<String, dynamic>> periodFiltered;

    if (period == 'Hari Ini') {
      final todayStr = formatDate(now);
      periodFiltered = filtered.where((b) => b['date'] == todayStr).toList();
    } else if (period == 'Minggu Ini') {
      // Senin awal minggu ini
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      periodFiltered = filtered.where((b) {
        final dateStr = b['date']?.toString() ?? '';
        final dt = parseDateStr(dateStr);
        return dt != null && !dt.isBefore(startDay) && dt.isBefore(startDay.add(const Duration(days: 7)));
      }).toList();
    } else if (period == 'Bulan Ini') {
      periodFiltered = filtered.where((b) {
        final dateStr = b['date']?.toString() ?? '';
        final dt = parseDateStr(dateStr);
        return dt != null && dt.year == now.year && dt.month == now.month;
      }).toList();
    } else {
      periodFiltered = filtered;
    }

    return periodFiltered.fold(0, (sum, b) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      final isPaid = status == 'confirmed' || status == 'pembayaran berhasil' ||
          status == 'menunggu jadwal' || status == 'selesai' || status == 'completed';
      if (!isPaid) return sum;
      return sum + (int.tryParse(b['price'].toString()) ?? 0);
    });
  }

  /// Parse date string "Senin, 13 April 2026" atau "13 April 2026" ke DateTime
  static DateTime? parseDateStr(String dateStr) {
    try {
      final clean = dateStr.contains(',') ? dateStr.split(',')[1].trim() : dateStr.trim();
      final parts = clean.split(' ');
      if (parts.length < 3) return null;
      final day = int.parse(parts[0]);
      final monthIdx = monthNames.indexWhere((m) => m.toLowerCase() == parts[1].toLowerCase());
      if (monthIdx < 0) return null;
      final year = int.parse(parts[2]);
      return DateTime(year, monthIdx + 1, day);
    } catch (_) {
      return null;
    }
  }

  /// Returns recent transactions for owner
  static List<Map<String, dynamic>> getTransactionsForOwner(String? venueName) {
    final all = [...BookingHistoryPage.mockHistory, ...BookingHistoryPage.mockPastHistory];
    return (venueName == null || venueName == 'Semua')
        ? all
        : all.where((b) => b['venueName'] == venueName).toList();
  }

  /// Returns revenue data for the current week (Monday to Sunday) for the line chart (real data)
  static List<double> getWeeklyDistribution({String? venueName}) {
    final all = [...BookingHistoryPage.mockHistory, ...BookingHistoryPage.mockPastHistory];
    final filtered = (venueName == null || venueName == 'Semua')
        ? all
        : all.where((b) => b['venueName'] == venueName).toList();

    // Hitung pendapatan per hari (Senin=0 ... Minggu=6) untuk minggu berjalan ini
    final now = DateTime.now();
    // Cari Senin dari minggu ini pukul 00:00:00
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7)); // Batas akhir: Senin depan 00:00:00
    
    final List<int> revenuePerDay = List.filled(7, 0);

    for (final b in filtered) {
      final status = (b['status'] ?? '').toString().toLowerCase();
      final isPaid = status == 'confirmed' || status == 'pembayaran berhasil' ||
          status == 'menunggu jadwal' || status == 'selesai' || status == 'completed';
      if (!isPaid) continue;

      final dt = parseDateStr(b['date']?.toString() ?? '');
      if (dt == null) continue;

      // Cek apakah tanggal booking masuk dalam rentang Senin s.d. Minggu minggu ini
      if (dt.isBefore(startOfWeek) || !dt.isBefore(endOfWeek)) continue;

      // weekday: Mon=1..Sun=7, jadikan index 0..6
      final idx = dt.weekday - 1;
      revenuePerDay[idx] += int.tryParse(b['price'].toString()) ?? 0;
    }

    final maxRevenue = revenuePerDay.fold(0, (a, b) => a > b ? a : b);
    if (maxRevenue == 0) return [0, 0, 0, 0, 0, 0, 0];
    // Normalisasi ke 0.0-1.0
    return revenuePerDay.map((r) => r / maxRevenue).toList();
  }
}
