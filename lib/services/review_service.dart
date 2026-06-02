import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rensius/services/supabase_service.dart';
import 'package:rensius/models/review_model.dart';

class ReviewService {
  ReviewService._();

  static SupabaseClient get _client => SupabaseService.client;

  /// Memuat semua review/ulasan dari Supabase ke memory (Review.mockReviews)
  static Future<void> loadReviews() async {
    if (!SupabaseService.isInitialized) return;
    try {
      final response = await _client.from('reviews').select();
      
      final List<Review> loadedReviews = [];
      for (var row in response) {
        loadedReviews.add(Review(
          username: row['username'] ?? '',
          venueName: row['venue_name'] ?? '',
          rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
          comment: row['comment'] ?? '',
          date: row['date'] != null ? DateTime.parse(row['date'].toString()) : DateTime.now(),
        ));
      }

      // Urutkan review berdasarkan tanggal descending
      loadedReviews.sort((a, b) => b.date.compareTo(a.date));

      // Sinkronkan ke Review.mockReviews
      Review.mockReviews.clear();
      Review.mockReviews.addAll(loadedReviews);
    } on PostgrestException catch (e) {
      if (e.message.contains('relation "public.reviews" does not exist') || e.code == 'PGRST204') {
        print('==================================================================');
        print('PERINGATAN: Tabel "reviews" belum dibuat di Supabase.');
        print('Silakan jalankan SQL migration untuk tabel reviews.');
        print('==================================================================');
      } else {
        print('Gagal memuat ulasan dari Supabase: ${e.message}');
      }
    } catch (e) {
      print('Kesalahan sistem memuat ulasan: $e');
    }
  }

  /// Membuat atau memperbarui ulasan di Supabase
  static Future<void> saveReview(Review review) async {
    if (!SupabaseService.isInitialized) return;
    try {
      final payload = {
        'username': review.username,
        'venue_name': review.venueName,
        'rating': review.rating,
        'comment': review.comment,
        'date': review.date.toIso8601String(),
      };
      
      // Gunakan upsert dengan matching columns username & venue_name
      // Karena kita mendefinisikan UNIQUE (username, venue_name) di database
      await _client.from('reviews').upsert(
        payload,
        onConflict: 'username, venue_name',
      );

      // Muat ulang dari online agar data lokal ter-refresh secara valid
      await loadReviews();
    } catch (e) {
      print('Gagal menyimpan ulasan ke Supabase: $e');
    }
  }

  /// Menghapus ulasan dari Supabase
  static Future<void> deleteReview(String username, String venueName) async {
    if (!SupabaseService.isInitialized) return;
    try {
      await _client
          .from('reviews')
          .delete()
          .match({'username': username, 'venue_name': venueName});
      
      // Muat ulang dari online
      await loadReviews();
    } catch (e) {
      print('Gagal menghapus ulasan dari Supabase: $e');
    }
  }
}
