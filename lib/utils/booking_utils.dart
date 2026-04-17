import '../pages/booking_history.dart';

class BookingUtils {
  static const List<String> dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
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

    // 2. Check initial mock data (Date-aware static system)
    if (_isInitialMockBooked(dateStr, startTime)) return true;

    // 3. Fallback to matching against history items
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
}
