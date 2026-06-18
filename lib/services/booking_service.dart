import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rensius/services/supabase_service.dart';
import 'package:rensius/data/auth_data.dart';
import 'package:rensius/pages/booking_history.dart';
import 'package:rensius/utils/booking_utils.dart';
import 'package:rensius/data/venue_data.dart';

class BookingService {
  BookingService._();

  static SupabaseClient get _client => SupabaseService.client;

  /// Memuat riwayat booking milik user aktif dari Supabase
  static Future<void> loadBookings(String username, String role) async {
    if (!SupabaseService.isInitialized) return;
    try {
      final response = await _client.from('bookings').select();
      
      // Bersihkan list in-memory lama
      BookingHistoryPage.mockHistory.clear();
      BookingHistoryPage.mockPastHistory.clear();

      final List<Map<String, dynamic>> allBookings = [];
      for (var row in response) {
        allBookings.add({
          'id': row['id'],
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
          'paymentDeadline': row['payment_deadline'],
          'redirectUrl': row['redirect_url'],
        });
      }

      // Urutkan berdasarkan tanggal pembuatan (createdAt) descending
      allBookings.sort((a, b) {
        final aTime = a['createdAt'] != null ? DateTime.tryParse(a['createdAt'].toString()) : null;
        final bTime = b['createdAt'] != null ? DateTime.tryParse(b['createdAt'].toString()) : null;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      // Filter berdasarkan role & username
      for (var b in allBookings) {
        bool shouldInclude = false;
        if (role == 'Admin') {
          shouldInclude = true;
        } else if (role == 'Owner') {
          // Owner dapat melihat seluruh transaksi atau memfilternya berdasarkan venue
          shouldInclude = true;
        } else {
          // End User hanya melihat booking miliknya sendiri
          shouldInclude = b['username'].toString().toLowerCase() == username.toLowerCase();
        }

        if (shouldInclude) {
          final statusStr = b['status'].toString().toLowerCase();
          if (statusStr == 'completed' || 
              statusStr == 'selesai' || 
              statusStr == 'dibatalkan' || 
              statusStr == 'expired' || 
              statusStr == 'refunded') {
            BookingHistoryPage.mockPastHistory.add(b);
          } else {
            BookingHistoryPage.mockHistory.add(b);
          }
        }
      }
    } on PostgrestException catch (e) {
      if (e.message.contains('relation "public.bookings" does not exist') || e.code == 'PGRST204') {
        print('==================================================================');
        print('PERINGATAN: Tabel "bookings" belum dibuat di Supabase.');
        print('Silakan jalankan SQL migration yang terdapat di SUPABASE_SETUP.md.');
        print('==================================================================');
      } else {
        print('Gagal memuat bookings dari Supabase: ${e.message}');
      }
    } catch (e) {
      print('Kesalahan sistem memuat bookings: $e');
    }
  }

  /// Membuat pesanan booking baru secara online di Supabase
  static Future<void> createBooking(Map<String, dynamic> booking) async {
    if (!SupabaseService.isInitialized) return;
    try {
      final payload = {
        'order_id': booking['orderId'],
        'username': booking['username'] ?? GlobalAuthData.currentUser?.username ?? 'customer',
        'venue_name': booking['venueName'],
        'court_name': booking['courtName'],
        'date': booking['date'],
        'time': booking['time'],
        'price': booking['price'],
        'payment_method': booking['paymentMethod'],
        'status': booking['status'],
        'services': booking['services'],
        if (booking['paymentDeadline'] != null)
          'payment_deadline': booking['paymentDeadline'] is DateTime
              ? (booking['paymentDeadline'] as DateTime).toUtc().toIso8601String()
              : (DateTime.tryParse(booking['paymentDeadline'].toString())?.toUtc().toIso8601String() ?? booking['paymentDeadline'].toString()),
        if (booking['redirectUrl'] != null) 'redirect_url': booking['redirectUrl'],
      };
      await _client.from('bookings').upsert(payload);
      
      // Auto-refresh slots global setelah berhasil membuat booking
      await BookingUtils.loadGlobalBookingsOnline();
    } on PostgrestException catch (e) {
      print('Postgrest error creating booking: ${e.message}');
    } catch (e) {
      print('Gagal membuat booking: $e');
    }
  }

  /// Memperbarui status pesanan secara online di Supabase
  static Future<void> updateBookingStatus(String orderId, String newStatus) async {
    if (!SupabaseService.isInitialized) return;
    try {
      await _client
          .from('bookings')
          .update({'status': newStatus})
          .eq('order_id', orderId);
      
      // Auto-refresh slots global
      await BookingUtils.loadGlobalBookingsOnline();
    } on PostgrestException catch (e) {
      print('Postgrest error updating booking status: ${e.message}');
    } catch (e) {
      print('Gagal memperbarui status booking: $e');
    }
  }

  /// Memperbarui status sekaligus menghapus payment_deadline (setelah bayar)
  static Future<void> markBookingPaid(String orderId, String newStatus) async {
    if (!SupabaseService.isInitialized) return;
    try {
      await _client
          .from('bookings')
          .update({
            'status': newStatus,
            'payment_deadline': null,
            'redirect_url': null,
          })
          .eq('order_id', orderId);
      await BookingUtils.loadGlobalBookingsOnline();
    } on PostgrestException catch (e) {
      print('Postgrest error marking booking paid: ${e.message}');
    } catch (e) {
      print('Gagal mark booking paid: $e');
    }
  }

  /// Menghapus/membatalkan booking pending yang sudah expire
  static Future<void> cancelPendingBooking(String orderId) async {
    if (!SupabaseService.isInitialized) return;
    try {
      await _client
          .from('bookings')
          .update({'status': 'Dibatalkan', 'payment_deadline': null, 'redirect_url': null})
          .eq('order_id', orderId);
      await BookingUtils.loadGlobalBookingsOnline();
    } on PostgrestException catch (e) {
      print('Postgrest error cancelling booking: ${e.message}');
    } catch (e) {
      print('Gagal membatalkan booking: $e');
    }
  }

  /// Menghapus booking secara permanen (misal karena ganti metode pembayaran)
  static Future<void> deleteBooking(String orderId) async {
    if (!SupabaseService.isInitialized) return;
    try {
      await _client
          .from('bookings')
          .delete()
          .eq('order_id', orderId);
      await BookingUtils.loadGlobalBookingsOnline();
    } on PostgrestException catch (e) {
      print('Postgrest error deleting booking: ${e.message}');
    } catch (e) {
      print('Gagal menghapus booking: $e');
    }
  }
}


