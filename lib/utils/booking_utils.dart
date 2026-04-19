import '../pages/booking_history.dart';

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

  /// Initial mock booked slots for consistency across all pages
  /// This ensures that 12:00 and 14:00 are consistently full even on first load,
  /// but ONLY for the current date.
  static bool _isInitialMockBooked(String dateStr, String startTime) {
    final todayStr = formatDate(DateTime.now());
    if (dateStr != todayStr) return false; // Available for any other date
    
    // We'll mark 12:00 and 14:00 as full for today
    return startTime == '12:00' || startTime == '14:00';
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

    // 4. Fallback to matching against history items
    return BookingHistoryPage.mockHistory.any((booking) {
      if (booking == null) return false;
      
      final bVenue = (booking['venueName'] ?? '').toString();
      final bCourt = (booking['courtName'] ?? '').toString();
      final bDate = (booking['date'] ?? '').toString();
      final bTime = (booking['time'] ?? '').toString();

      bool venueMatch = bVenue == venueName;
      bool courtMatch = bCourt.contains(courtName);
      bool dateMatch = bDate == dateStr;
      bool timeMatch = bTime.contains(startTime);

      return venueMatch && courtMatch && dateMatch && timeMatch;
    });
  }

  /// Calculates total revenue from history
  static int calculateRevenue({String? venueName, String period = 'Total'}) {
    final all = [...BookingHistoryPage.mockHistory, ...BookingHistoryPage.mockPastHistory];
    final filtered = (venueName == null || venueName == 'Semua') 
        ? all 
        : all.where((b) => b['venueName'] == venueName).toList();
    
    if (filtered.isEmpty) return 0;
    
    // Period logic (Simplified for mock)
    // In a real app, we would parse b['date'] and check against DateTime.now()
    int total = filtered.fold(0, (sum, b) => sum + (int.tryParse(b['price'].toString()) ?? 0));
    
    if (period == 'Bulan Ini') return (total * 0.8).toInt();
    if (period == 'Minggu Ini') return (total * 0.3).toInt();
    if (period == 'Hari Ini') return (total * 0.1).toInt();
    
    return total;
  }

  /// Returns recent transactions for owner
  static List<Map<String, dynamic>> getTransactionsForOwner(String? venueName) {
    final all = [...BookingHistoryPage.mockHistory, ...BookingHistoryPage.mockPastHistory];
    return (venueName == null || venueName == 'Semua')
        ? all
        : all.where((b) => b['venueName'] == venueName).toList();
  }

  /// Returns revenue data for the last 7 days for the line chart
  static List<double> getWeeklyDistribution({String? venueName}) {
    // In a real app we'd filter by actual dates. 
    // Here we'll simulate based on venue and total volume.
    final total = calculateRevenue(venueName: venueName, period: 'Total');
    if (total == 0) return [0, 0, 0, 0, 0, 0, 0];
    
    // Weighted random-looking distribution [Sen -> Min]
    return [0.4, 0.6, 0.3, 0.8, 0.5, 1.0, 0.7];
  }
}
