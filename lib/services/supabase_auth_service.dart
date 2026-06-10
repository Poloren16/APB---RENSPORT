import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rensius/data/auth_data.dart';
import 'package:rensius/services/supabase_service.dart';

class SupabaseAuthService {
  SupabaseAuthService._();

  static GoTrueClient get _auth => SupabaseService.client.auth;
  static SupabaseClient get _client => SupabaseService.client;

  static User? get currentUser {
    if (!SupabaseService.isInitialized) return null;
    return _auth.currentUser;
  }

  static Stream<User?> authStateChanges() {
    if (!SupabaseService.isInitialized) {
      return const Stream<User?>.empty();
    }
    return _auth.onAuthStateChange.map((data) => data.session?.user);
  }

  /// Mendaftarkan pengguna baru (End User / Owner) ke Supabase Auth
  static Future<AuthResponse> registerEndUser({
    required UserAccount account,
  }) async {
    _assertInitialized();

    // 1. Registrasi ke Supabase Auth
    final response = await _auth.signUp(
      email: account.email,
      password: account.password,
      data: {
        'username': account.username,
        'applicant_name': account.applicantName,
        'role': account.role,
      },
    );

    final user = response.user;
    if (user == null) {
      throw AuthException('Registrasi berhasil tetapi gagal membuat sesi pengguna.');
    }

    // 2. Simpan profil lengkap ke tabel PostgreSQL 'users'
    await saveUserProfile(account, uid: user.id);

    return response;
  }

  /// Masuk dengan email dan kata sandi via Supabase Auth
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _assertInitialized();
    return _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Memperbarui kata sandi pengguna yang sedang masuk di Supabase Auth
  static Future<UserResponse> updatePassword(String newPassword) async {
    _assertInitialized();
    return await _auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Mengirim link reset kata sandi ke email pengguna
  static Future<void> sendPasswordResetEmail(String email) async {
    _assertInitialized();
    await _auth.resetPasswordForEmail(email);
  }

  /// Logout dari Supabase
  static Future<void> signOut() async {
    if (!SupabaseService.isInitialized) return;
    await _auth.signOut();
  }

  /// Menyimpan atau memperbarui profil pengguna ke PostgreSQL 'users'
  static Future<void> saveUserProfile(
    UserAccount account, {
    String? uid,
  }) async {
    _assertInitialized();

    final userId = uid ?? _auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Tidak ada pengguna Supabase yang sedang masuk.');
    }

    // Siapkan data untuk disinkronisasi ke PostgreSQL table 'users'
    // Memetakan camelCase dari Dart ke snake_case pada kolom database PostgreSQL
    final data = {
      'id': userId,
      'username': account.username,
      'applicant_name': account.applicantName,
      'email': account.email,
      'phone_number': account.phoneNumber,
      'role': account.role,
      'bio': account.bio,
      'sports_interests': account.sportsInterests,
      'instagram': account.instagram,
      'twitter': account.twitter,
      'facebook': account.facebook,
      'profile_image_path': account.profileImagePath,
      'ktp_image_path': account.ktpImagePath,
      'gender': account.gender,
      'date_of_birth': account.dateOfBirth.isNotEmpty ? account.dateOfBirth : null,
      'points': account.points,
      'cart': account.cart,
      'favorites': account.favorites,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Lakukan upsert (insert atau update jika primary key 'id' sudah ada)
    try {
      await _client.from('users').upsert(data);
    } on PostgrestException catch (e) {
      if (e.message.contains('column "cart"') || e.message.contains('column "favorites"') || e.code == 'PGRST204' || e.message.contains('does not exist')) {
        print('==================================================================');
        print('PERINGATAN: Kolom "cart" atau "favorites" belum dibuat di tabel "users" Supabase.');
        print('Silakan jalankan SQL migration berikut di Supabase SQL Editor Anda:');
        print('ALTER TABLE public.users ADD COLUMN IF NOT EXISTS cart jsonb DEFAULT \'[]\'::jsonb NOT NULL;');
        print('ALTER TABLE public.users ADD COLUMN IF NOT EXISTS favorites jsonb DEFAULT \'[]\'::jsonb NOT NULL;');
        print('==================================================================');
        // Hapus field cart dan favorites dari map payload, lalu coba upsert kembali tanpa field-field tersebut agar aplikasi tidak crash
        data.remove('cart');
        data.remove('favorites');
        await _client.from('users').upsert(data);
      } else {
        rethrow;
      }
    }
  }

  /// Mendapatkan data profil pengguna dari tabel PostgreSQL 'users'
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    _assertInitialized();
    try {
      final response = await _client.from('users').select().eq('id', uid).maybeSingle();
      return response;
    } on PostgrestException catch (error) {
      // Jika tabel belum di-setup, kita tangani dengan anggun agar aplikasi tidak crash
      print('Postgrest error fetching user profile: ${error.message}');
      return null;
    }
  }

  static void _assertInitialized() {
    if (!SupabaseService.isInitialized) {
      throw StateError(
        'Supabase belum aktif. Pastikan variabel lingkungan SUPABASE_URL dan '
        'SUPABASE_ANON_KEY telah dikonfigurasi di berkas .env dengan benar.',
      );
    }
  }
}
