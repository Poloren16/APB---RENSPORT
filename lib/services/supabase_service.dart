import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class SupabaseService {
  SupabaseService._();

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError('SupabaseClient belum diinisialisasi. Pastikan memanggil initialize() terlebih dahulu.');
    }
    return Supabase.instance.client;
  }

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (url == null || anonKey == null || url.isEmpty || anonKey.isEmpty || url.contains('your-project-id')) {
        debugPrint('Supabase credentials are not configured or are placeholder.');
        _isInitialized = false;
        return false;
      }

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );

      _isInitialized = true;
      debugPrint('Supabase successfully initialized.');
      return true;
    } on Object catch (error, stackTrace) {
      debugPrint('Supabase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _isInitialized = false;
      return false;
    }
  }

  /// Mengunggah berkas ke Supabase Storage Bucket
  static Future<String?> uploadFile({
    required String bucketName,
    required String filePath,
    required String destinationPath,
  }) async {
    if (!_isInitialized) return null;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File tidak ditemukan pada path: $filePath');
        return null;
      }

      // Unggah ke bucket
      await client.storage.from(bucketName).upload(
            destinationPath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // Dapatkan public URL
      final String publicUrl = client.storage.from(bucketName).getPublicUrl(destinationPath);
      return publicUrl;
    } on Object catch (error, stackTrace) {
      debugPrint('Gagal mengunggah berkas ke Supabase Storage: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Shortcut untuk mengunggah foto KTP
  static Future<String?> uploadKtp(String filePath, String username) async {
    final extension = filePath.split('.').last;
    final destination = 'ktp_${username}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    return uploadFile(
      bucketName: 'documents',
      filePath: filePath,
      destinationPath: destination,
    );
  }

  /// Shortcut untuk mengunggah foto profil
  static Future<String?> uploadProfileImage(String filePath, String username) async {
    final extension = filePath.split('.').last;
    final destination = 'avatar_${username}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    return uploadFile(
      bucketName: 'profiles',
      filePath: filePath,
      destinationPath: destination,
    );
  }
}
