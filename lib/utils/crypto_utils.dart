import 'dart:convert';

class CryptoUtils {
  static const String _key = 'rensius_secret_key_2026';

  /// Mengenkripsi teks biasa menggunakan XOR cipher dan encoding Base64
  static String encrypt(String plaintext) {
    if (plaintext.isEmpty) return '';
    final bytes = utf8.encode(plaintext);
    final keyBytes = utf8.encode(_key);
    final encryptedBytes = List<int>.generate(bytes.length, (i) {
      return bytes[i] ^ keyBytes[i % keyBytes.length];
    });
    return base64.encode(encryptedBytes);
  }

  /// Mendekripsi teks terenkripsi Base64 kembali ke teks biasa
  static String decrypt(String ciphertext) {
    if (ciphertext.isEmpty) return '';
    try {
      final bytes = base64.decode(ciphertext);
      final keyBytes = utf8.encode(_key);
      final decryptedBytes = List<int>.generate(bytes.length, (i) {
        return bytes[i] ^ keyBytes[i % keyBytes.length];
      });
      return utf8.decode(decryptedBytes);
    } catch (e) {
      // Fallback jika ternyata teks di database masih berupa plaintext lama
      return ciphertext;
    }
  }
}
